# Preserving Knowledge Discovery Container State

Here is a collection of guides and tips for reference in the main lessons, including:

- System configuration: WSL and Docker.
- Updating containerized Knowledge Discovery component configuration files.
- Using the Knowledge Discovery Admin user interface to control and monitor a component.

---

- [Preserve a Knowledge Discovery component configuration](#preserve-a-knowledge-discovery-component-configuration)
  - [Copy out configuration files](#copy-out-configuration-files)
  - [Mount external configuration files](#mount-external-configuration-files)
  - [Redeploy with mounted configuration](#redeploy-with-mounted-configuration)
- [Preserve Knowledge Discovery Content index](#preserve-knowledge-discovery-content-index)
  - [Copy out indexed data](#copy-out-indexed-data)
  - [Mount the external data](#mount-the-external-data)
  - [Redeploy with mounted index](#redeploy-with-mounted-index)
- [Preserve Find state](#preserve-find-state)
  - [Copy out the home directory](#copy-out-the-home-directory)
  - [Mount external home directory](#mount-external-home-directory)
  - [Redeploy with mounted home directory](#redeploy-with-mounted-home-directory)
- [Preserve NiFi state](#preserve-nifi-state)
- [End](#end)

---

## Preserve a Knowledge Discovery component configuration

Each Knowledge Discovery component includes a configuration file that you can modify to change how the component runs.

Knowledge Discovery containers ship with their configuration files included. In order to persist your edits to these files, you must perform some extra steps:

1. Copy the configuration files out from the running container.
1. Stop the container.
1. Mount external configuration files to be read from inside the container.
1. Restart the container.

We will use Content as an example.

### Copy out configuration files

With the Docker system running, use the Linux command line to make a local copy of the Knowledge Discovery container configuration directory.

```sh
$ cd /opt/idol/idol-containers-toolkit/basic-idol
$ docker cp basic-idol-idol-content-1:/content/cfg ./content/
Successfully copied 33.8kB to /opt/idol/idol-containers-toolkit/basic-idol/content/
```

Check for a new directory `basic-idol/content/cfg` on your WSL Linux filesystem, containing several `.cfg` files.

```sh
$ ls content/cfg/
content.cfg  idol.common.cfg  idol_ssl.cfg  original.content.cfg
```

> TIP: To explore the contents of a running container manually, you can try:
>
> ```sh
> $ docker exec -it basic-idol-idol-content-1 bash
> [idoluser@4ebbcce2b410 content]$ pwd
> /content
> [idoluser@4ebbcce2b410 content]$ ls cfg
> content.cfg  idol.common.cfg  idol_ssl.cfg  original.content.cfg
> [idoluser@4ebbcce2b410 content]$ exit
> exit
> ```

### Mount external configuration files

Edit the file `basic-idol/docker-compose.yml` to mount the external config directory:

```diff
idol-content:
  <<: *common-server
  image: ${IDOL_REGISTRY}/content:${IDOL_SERVER_VERSION}
+ volumes:
+   - ./content/cfg:/content/cfg # this mounts an external cfg folder
```

> NOTE: This mount replaces the original contents of the `/content/cfg` folder in the container with the (editable) files stored outside.

### Redeploy with mounted configuration

Next you stop and start the Knowledge Discovery Content container to pick up these changes.

```sh
./deploy.sh stop idol-content
./deploy.sh up -d
```

## Preserve Knowledge Discovery Content index

The Knowledge Discovery Content index is stateful, so you may wish to keep this outside your container to ensure it is not destroyed when redeploying your project changes.

### Copy out indexed data

With the Docker system running, use the Linux command line to make a local copy of the Knowledge Discovery container index directory.

```sh
$ cd /opt/idol/idol-containers-toolkit/basic-idol
$ docker cp basic-idol-idol-content-1:/content/index ./content/index
Successfully copied 25.6MB to /opt/idol/idol-containers-toolkit/basic-idol/content/index
```

### Mount the external data

In docker-compose

```diff
idol-content:
  volumes:
    - ./content/cfg:/content/cfg # this mounts an external cfg folder
+   - ./content/index:/content/index # this mounts an external index
```

### Redeploy with mounted index

```sh
./deploy.sh down idol-content
./deploy.sh up -d
```

## Preserve Find state

Preserve state outside of the container to keep your changes safe and allow you to modify configuration files.

Find is a Java application, with a data folder, containing `.json` configuration files used for modifying its behavior.

### Copy out the home directory

With the Docker system running, use the Linux command line to make a local copy of the Knowledge Discovery Find home directory:

```sh
$ cd /opt/idol/idol-containers-toolkit/basic-idol
$ docker cp basic-idol-idol-find-1:/opt/find/home ./find/home
Successfully copied 166kB to /opt/idol/idol-containers-toolkit/basic-idol/find/home
```

### Mount external home directory

Edit the file `basic-idol/docker-compose.yml` to mount the external home directory:

```diff
idol-find:
  image: ${IDOL_REGISTRY}/find:${IDOL_SERVER_VERSION}
  labels:
    <<: *common-labels
  environment:
    - IDOL_UI_CFG=config_basic.json # this controls the configuration of Find
+ volumes:
+   - ./find/home:/opt/find/home
```

### Redeploy with mounted home directory

Next you stop and start the Knowledge Discovery Find container to pick up these changes.

```sh
./deploy.sh down idol-find
./deploy.sh up -d
```

## Preserve NiFi state

See the following guide to [preserve NiFi state](../ingest/preserve-state/README.md).

---

## End
