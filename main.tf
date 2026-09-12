

provider "aws" {
  region     = var.aws_region
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
}

module "network" {
  source = "./modules/network"
  
  environment                 = "dev"
  availability_zone   = ["${var.aws_region}a", "${var.aws_region}b"]
  
}

resource "aws_key_pair" "main_key" {

  key_name   = "mti_key_pair"
  public_key = file("/home/tareq/.ssh/id_rsa.pub")

}




resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.main_key.key_name
  subnet_id     = module.network.public_subnet_1_id
  vpc_security_group_ids = [module.network.security_group_id]


  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = <<-EOF

    #!/bin/bash
    set -e -x

    # Redirect all output to log file
    exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

    echo "===== Starting EC2 initialization ====="

    # Force IPv4 for apt (fixes connectivity issues)
    echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

    #############################################
    # Variables - UPDATED FOR X86_64
    #############################################

    # On x86_64 instances, EBS volumes appear as /dev/xvd* not /dev/nvme*
    DEVICE="/dev/xvdf"
    DOCKER_DIR="/var/lib/docker"

    #############################################
    # Update packages
    #############################################

    apt update -y
    apt upgrade -y

    #############################################
    # Install dependencies
    #############################################

    apt install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        xfsprogs

    #############################################
    # Wait for EBS volume
    #############################################

    echo "Waiting for EBS device: $DEVICE"

    while [ ! -b "$DEVICE" ]; do
        sleep 2
    done

    echo "EBS device found: $DEVICE"

    #############################################
    # Prepare Docker volume
    #############################################

    mkdir -p "$DOCKER_DIR"

    # Create filesystem only if empty volume
    if [ -z "$(lsblk -no FSTYPE $DEVICE)" ]; then
        echo "Creating XFS filesystem on $DEVICE"
        mkfs.xfs -f "$DEVICE"
    else
        echo "Filesystem already exists on $DEVICE"
    fi

    #############################################
    # Mount Docker volume
    #############################################

    if ! mountpoint -q "$DOCKER_DIR"; then
        mount "$DEVICE" "$DOCKER_DIR"
        echo "Mounted $DEVICE to $DOCKER_DIR"
    fi

    # Verify mount
    if ! mountpoint -q "$DOCKER_DIR"; then
        echo "ERROR: Docker volume mount failed"
        exit 1
    fi

    #############################################
    # Persist mount in fstab
    #############################################

    UUID=$(blkid -s UUID -o value "$DEVICE")

    if ! grep -q "$UUID" /etc/fstab; then
        echo "UUID=$UUID $DOCKER_DIR xfs defaults,nofail 0 2" >> /etc/fstab
        echo "Added $DOCKER_DIR mount to fstab"
    fi

    #############################################
    # Install Docker
    #############################################

    # Create keyrings directory
    install -m 0755 -d /etc/apt/keyrings

    # Add Docker's official GPG key (force IPv4)
    curl -4 -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    apt update -y
    apt install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-compose-plugin

    #############################################
    # Configure Docker to use IPv4
    #############################################

    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'DOCKER_EOF'
    {
      "iptables": true,
      "ip-forward": true
    }
    DOCKER_EOF

    #############################################
    # Configure Docker dependency on EBS mount
    #############################################

    mkdir -p /etc/systemd/system/docker.service.d

    cat > /etc/systemd/system/docker.service.d/mount.conf << 'SERVICE_EOF'
    [Unit]
    RequiresMountsFor=/var/lib/docker
    After=var-lib-docker.mount
    SERVICE_EOF

    #############################################
    # Reload systemd and enable services
    #############################################

    systemctl daemon-reload
    systemctl enable containerd
    systemctl enable docker

    # Start services
    systemctl restart containerd
    systemctl restart docker

    #############################################
    # Allow ubuntu user to run docker commands
    #############################################

    usermod -aG docker ubuntu

    #############################################
    # Validation
    #############################################

    echo "Docker version:"
    docker --version

    echo "Docker info:"
    docker info

    # Test Docker works
    echo "Testing Docker with hello-world..."
    docker pull hello-world
    docker run --rm hello-world

    echo "===== EC2 initialization completed successfully ====="

  EOF

}

# Separate EBS volume resource
resource "aws_ebs_volume" "data_volume" {
  availability_zone = "${var.aws_region}a"
  size              = 50
  type              = "gp3"
  encrypted         = true

  tags = {
    Name        = "${var.environment}-data-volume"
    Environment = var.environment
  }

  # Protect the volume from accidental deletion
  # lifecycle {
  #  prevent_destroy = true
  # }
}

# Attach the volume to the instance
resource "aws_volume_attachment" "data_attachment" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.data_volume.id
  instance_id = aws_instance.web.id

  # Prevent Terraform from trying to delete the attachment during destroy
  # skip_destroy = true
}
