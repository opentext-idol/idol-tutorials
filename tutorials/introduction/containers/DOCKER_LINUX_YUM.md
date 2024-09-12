# Set up your Linux system for Docker

## Install Docker engine

> NOTE: The following steps assume a Linux system using the `yum` package manager. For the `apt-get` package manager, see the [apt-get steps](./DOCKER_LINUX_APT.md).  For other Linux systems, please refer to the official guide <https://docs.docker.com/engine/install/>.

Connect to the Docker repository:

```sh
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

Install Docker packages:

```sh
sudo yum update
sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Test installation

Test run Docker:

```sh
$ sudo docker run hello-world
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

Verify that you also have Docker Compose installed:

```sh
$ sudo docker compose version
Docker Compose version v2.28.1
```

### Optional post-install steps

Join your user to the `docker` group:

```sh
sudo usermod -aG docker $USER
newgrp docker
```

Test Docker access:

```sh
$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

Configure Docker to start on boot:

```sh
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

## Next steps

Return to the containers [tutorial](./PART_I.md#log-in-to-the-idol-docker-repository).
