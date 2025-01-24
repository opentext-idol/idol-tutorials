# Set up Docker with yum

## Install Docker engine

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

## Next steps

Return to the common [docker setup steps](./DOCKER_LINUX_APT.md#test-installation).
