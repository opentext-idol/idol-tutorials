# PART I - IDOL containers with Docker

In this lesson, you will:

- Set up your machine for Docker.
- Download the [IDOL Containers Toolkit](https://github.com/opentext-idol/idol-containers-toolkit).
- Log in to gain access to IDOL containers.

---

- [Third-party dependencies](#third-party-dependencies)
- [IDOL containers toolkit](#idol-containers-toolkit)
  - [Obtain a copy of the toolkit](#obtain-a-copy-of-the-toolkit)
  - [Log in to the IDOL Docker repository](#log-in-to-the-idol-docker-repository)
- [Conclusions](#conclusions)
- [Next step](#next-step)

---

## Third-party dependencies

A containerized deployment of IDOL has a few prerequisites:

- Docker: A tool used to automate the deployment of applications. Docker uses virtualization to package applications with their dependencies and configuration files into self-contained units called *containers*. You can easily deploy groups of containers connect them to bring up more complex systems, which is great for more advanced IDOL use cases where multiple IDOL components work together.

- Git: The version control system required to download the IDOL configuration tool for use with Docker.

Docker has both free and premium tiers. To run the free tier requires a Linux system. If you work on Windows, you have a few other options, including:
- Set up a cloud virtual environment, for example, using AWS.
- Set up a local virtual environment, for example, using VirtualBox.
- Set up WSL, a feature of Microsoft Windows that allows developers to run a Linux environment without the need for a separate virtual machine or dual booting.

For this guide, we recommend that you follow [these steps](./SETUP_WINDOWS_WSL.md) to configure WSL to set up a local Linux environment. This option is the quickest and easiest setup to support your own learning.

Next, follow [these steps](./DOCKER_LINUX_APT.md) to install Docker on your WSL system.

Finally, to install Git on your WSL system, run `sudo apt-get install git`.

## IDOL containers toolkit

### Obtain a copy of the toolkit

Prepare a working directory from the Linux command line:

```
sudo mkdir /opt/idol
sudo chown $USER /opt/idol
cd /opt/idol
```

Pull the repository from GitHub:

```
git clone https://github.com/opentext-idol/idol-containers-toolkit.git
```

### Log in to the IDOL Docker repository

Official IDOL software containers are distributed in a Docker repository.  A personal key is required to access them.  To request a key, contact OpenText support with the [Software Entitlements Portal](https://sld.microfocus.com/mysoftware/index).

Store your API key in a text file in your Linux home directory, for example `idol_docker_key.txt`, then log in with:

```
$ cat ~/idol_docker_key.txt | docker login --username microfocusidolreadonly --password-stdin

Login Succeeded
```

## Conclusions

You now understand how to set up a system to Docker and IDOL components in containers.

## Next step

You are now ready to go to [Part II](./PART_II.md).
