# PART III - Modify the deployment for your data

In this lesson, you will:

- Learn how to keep track of multi-file docker configurations.
- Open ports to make each Knowledge Discovery component accessible.
- Mount a shared folder for document ingestion.
- Mount a containerized Knowledge Discovery component configuration file to make and preserve edits.

---

- [Modify Knowledge Discovery container deployment](#modify-knowledge-discovery-container-deployment)
- [Keeping track of compose files](#keeping-track-of-compose-files)
- [Make selected Knowledge Discovery component ports accessible](#make-selected-knowledge-discovery-component-ports-accessible)
- [Mount a shared folder for ingest](#mount-a-shared-folder-for-ingest)
- [Modify Knowledge Discovery component configurations](#modify-knowledge-discovery-component-configurations)
  - [Updating configuration files](#updating-configuration-files)
    - [Update to include file metadata](#update-to-include-file-metadata)
  - [Redeploy and validate](#redeploy-and-validate)
- [Conclusions](#conclusions)
- [Next steps](#next-steps)

---

## Modify Knowledge Discovery container deployment

Remember that, to edit files under WSL Linux, we recommend [VS Code](https://code.visualstudio.com). To open the `basic-idol` folder contents for editing, type:

```sh
cd /opt/idol/idol-containers-toolkit/basic-idol
code .
```

The default `basic-idol` system is *almost* exactly what we need now... but you can make some modifications to help you understand the system, including mounting a shared folder where you can copy sample data to index.

## Keeping track of compose files

You will find that you need to reference your list of `.yml` files whenever you run commands for your system with `docker compose`, which can be a source of confusion. To simplify things, I recommend creating a `deploy.sh` script, for example:

```sh
touch deploy.sh
chmod +x deploy.sh
```

Add the following content:

```sh
docker compose \
  -f docker-compose.yml \
  "$@"
```

Now, you can use this to conveniently control your deployment with the standard `docker compose` options, for example:

- Start all containers (and rebuild any changes): `./deploy.sh up -d`
- Stop all containers (without destroying anything): `./deploy.sh stop`
- Stop one containers: `./deploy.sh stop idol-content`
- Take down all containers: `./deploy.sh down`

> NOTE: For full details on the verbs available for `docker compose`, see the [docker documentation](https://docs.docker.com/compose/reference/).

## Make selected Knowledge Discovery component ports accessible

By default, in the `basic-idol` deployment, only the NiFi and Knowledge Discovery Find use interfaces are accessible. The following modification exposes all component ports, for example allowing you to see the admin interface for Content as you did in the first lesson.

- First, stop the current system with:

    ```sh
    ./deploy.sh stop
    ```

- This modification has already been made for us and can be used by referencing a second `.yml` file in the `deploy.sh` script:

    ```diff
    docker compose \
      -f docker-compose.yml \
    + -f docker-compose.expose-ports.yml \
      "$@"
    ```

    > NOTE: Docker compose allows server configurations to be slit across files. This can be done group together optional functionality for easy enabling and disabling. This additional file includes modifiers to expose ports, *e.g.*:
    >
    > ```yml
    > idol-content:
    > ports:
    >   - 9100-9102:9100-9102
    > ```

- Restart your system with:

    ```sh
    ./deploy.sh up -d
    ```

When the containers start, you can point to the admin interface for Content on <http://idol-docker-host:9100/a=admin>.

## Mount a shared folder for ingest

Next, you can run another system modification to configure a shared folder where you can place documents for ingest.

- First, stop and destroy the current system with:

    ```sh
    ./deploy.sh down
    ```

- Next, create a shared folder location in your Windows system: `C:\OpenText\hotfolder`.

- Now edit the file `docker-compose.bindmount.yml` to define your own folder location:

    ```diff
    volumes:
      idol-ingest-volume:
    - # driver: local
    +   driver: local
        driver_opts:
          type: none
    -     device: /path/to/idol-ingest/bind
    +     device: /mnt/c/OpenText/hotfolder
          o: bind
    ```

    > NOTE: If you are using WSL, you already know that your Windows paths are accessible from WSL via the `/mnt/` parent directory from the [WSL guide](./SETUP_UBUNTU_WSL.md#file-system-access).

- To run with these changes to the Docker volume `idol-ingest-volume`, you must first remove the existing volume:

    ```sh
    docker volume rm basic-idol_idol-ingest-volume
    ```

- Modify your `deploy.sh` script to make use of the additional `.yml` file:
  
    ```diff
    docker compose \
      -f docker-compose.yml \
      -f docker-compose.expose-ports.yml \
    + -f docker-compose.bindmount.yml \
      "$@"
    ```

- Finally, launch the modified system with:

    ```sh
    ./deploy.sh up -d
    ```

- You can now check the mounted volume with:

    ```sh
    $ docker volume inspect basic-idol_idol-ingest-volume
    [
        {
            ...
            "Name": "basic-idol_idol-ingest-volume",
            "Options": {
                "device": "/mnt/c/OpenText/hotfolder",
                "o": "bind",
                "type": "none"
            },
            "Scope": "local"
        }
    ]
    ```

## Modify Knowledge Discovery component configurations

Each Knowledge Discovery component includes a configuration file that you can modify to change how the component runs.

> NOTE: For Knowledge Discovery Content, read the [documentation](https://www.microfocus.com/documentation/idol/knowledge-discovery-25.4/Content_25.4_Documentation/Help/Content/Configuration/_ACI_Config.htm) for full details. These include setting authorization, encryption, caching for efficiency savings and scheduling for maintenance task, to name a few.

Knowledge Discovery containers ship with their configuration files included. In order to persist any edits to these files, you must extract the files outside the container. Let's do that now.

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

### Mount external configuration files

Edit the file `basic-idol/docker-compose.yml` to mount the external config directory, by uncommenting the following lines:

```diff
idol-content:
  <<: *common-server
  image: ${IDOL_REGISTRY}/content:${IDOL_SERVER_VERSION}
+ volumes:
+   - ./content/cfg:/content/cfg
```

> NOTE: This mount replaces the original contents of the `/content/cfg` folder in the container with the (editable) files stored outside.

### Updating configuration files

An important area of configuration change relates to how you index your data. The Knowledge Discovery index includes specialized field type definitions to optimize query speed and/or to allow convenient filtering, such as filtering on labels ("parametrics" or "facets"), numeric ranges, dates, *etc.*

> NOTE: For full details on Knowledge Discovery index field types, see the [Expert](https://www.microfocus.com/documentation/idol/knowledge-discovery-25.4/IDOLServer_25.4_Documentation/Guides/html/expert/Content/IDOLExpert/Fields/Field_Properties.htm) documentation.

#### Update to include file metadata

Depending on your data, enrichment setup and use cases, you can expect to have different metadata properties on your documents.

The sample files we are using in this tutorial are Microsoft Office formats, which have some useful metadata fields baked in.  One is **APPNAME**, which we would like to be able to filter on. To enable this, add an additional pattern to the *parametric*-type field list.

Edit the file `basic-idol/content/cfg/original.content.cfg`:

```diff
[SetParametricFields]
- PropertyFieldCSVs=*/PII_*/VALUE,...
+ PropertyFieldCSVs=*/APPNAME,*/PII_*/VALUE,...
```

### Redeploy and validate

Next you stop and start the Knowledge Discovery Content container to pick up these changes.

```sh
./deploy.sh stop idol-content
./deploy.sh up -d
```

Open the admin interface for Content onto the [configuration view](http://idol-docker-host:9100/a=admin#page/config/SetParametricFields) to see that your change has been applied:

![content-config-param](./figs/content-config-param.png)

## Conclusions

You are now familiar with key concepts of deploying Knowledge Discovery containers with modifications, including the key steps to extract, modify and apply Knowledge Discovery component configuration file changes.

## Next steps

Next, you are ready to ingest your data. Go to [Part IV](./PART_IV.md).
