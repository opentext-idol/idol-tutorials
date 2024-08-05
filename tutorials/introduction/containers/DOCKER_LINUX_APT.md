# Set up your Linux system for Docker

## Install Docker Engine

> NOTE: The following steps assume a Linux system using the `apt-get` package manager. For the `yum` package manager, see the [yum steps](./DOCKER_LINUX_YUM.md). For other Linux systems, refer to the official guide https://docs.docker.com/engine/install/.

Connect to the Docker repository:

```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Verify the connection:

```
$ sudo apt-get update
Get:1 https://download.docker.com/linux/ubuntu jammy InRelease [48.8 kB]
Get:2 https://download.docker.com/linux/ubuntu jammy/stable amd64 Packages [35.6 kB]
```

Install Docker packages:

```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Test installation

Test run Docker:

```
$ sudo docker run hello-world
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

Verify that you also have Docker Compose installed:

```
$ sudo docker compose version
Docker Compose version v2.28.1
```

### Optional post-install steps

Join your user to the `docker` group:

```
sudo usermod -aG docker $USER
newgrp docker
```

Test docker access:

```
$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

Configure Docker to start on boot:

```
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

## Next steps

Return to the [`containers tutorial](./PART_I.md#log-in-to-idols-docker-repository).
