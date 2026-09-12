

    #!/bin/bash
    

    # Update package lists
    apt update


    # Wait for volume to be attached and mount it
    DEVICE="/dev/nvme1n1"
    # MOUNT_POINT="/data"
    DOCKER_DEFAULT_DIRECTORY="/var/lib/docker"

    # Create direcotry for docker if exists or not

    mkdir -p $DOCKER_DEFAULT_DIRECTORY

    # Wait until EBS volume appears
    while [ ! -b $DEVICE ]; do
        sleep 2
    done


    # Create filesystem only if empty
    if ! blkid $DEVICE; then
        mkfs -t xfs $DEVICE
    fi


    # mkdir -p $MOUNT_POINT


    # Mount
    mount $DEVICE $DOCKER_DEFAULT_DIRECTORY


    # Persist mount
    UUID=$(blkid -s UUID -o value $DEVICE)

    echo "UUID=$UUID $DOCKER_DEFAULT_DIRECTORY xfs defaults,nofail 0 2" >> /etc/fstab

    # Install Docker

    apt update
    apt install -y ca-certificates curl gnupg lsb-release

    mkdir -p /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin


    # Enable Docker
    systemctl enable docker
    systemctl start docker


    # Wait for Docker to be ready
    sleep 10

    # Run Docker Images

    docker run -d --name postgis-15 -e POSTGRES_USER=postgis -e POSTGRES_PASSWORD=SysAdm1n -e POSTGRES_DB=coredb -p 5432:5432 -v core-app-data:/var/lib/postgresql/data postgis/postgis:15-3.4
    
    docker run -d -p 8080:8080 tareq23/clean-city:latest

    docker run -d -p 3000:3000 tareq23/clean-city-frontend-dep-test:latest

    mkdir -p /opt/nginx


    cat <<NGINX > /opt/nginx/default.conf
    server {

        listen 80;

        server_name _;


        location / {
            proxy_pass http://localhost:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        location /api/ {
            proxy_pass http://localhost:8080/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

    }
    NGINX

    docker run -d --name nginx-proxy --restart unless-stopped -p 80:80 -v /opt/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro nginx:latest

