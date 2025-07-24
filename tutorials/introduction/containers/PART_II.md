# PART II - Configure and run the `basic-idol` deployment

In this lesson, you will:

- Reconfigure Knowledge Discovery License Server for remote access.
- Deploy your first end-to-end Knowledge Discovery system, from ingest with NiFi to search with Knowledge Discovery Find.

---

- [Reconfigure Knowledge Discovery License Server](#reconfigure-knowledge-discovery-license-server)
  - [Allow remote access](#allow-remote-access)
  - [Verify remote access](#verify-remote-access)
    - [Troubleshooting](#troubleshooting)
- [Deploy Knowledge Discovery containers](#deploy-knowledge-discovery-containers)
  - ["Basic" Knowledge Discovery](#basic-knowledge-discovery)
  - [What is NiFi?](#what-is-nifi)
  - [Setup](#setup)
  - [Deploy](#deploy)
- [First look at NiFi](#first-look-at-nifi)
- [First look at Find](#first-look-at-find)
- [Conclusions](#conclusions)
- [Next step](#next-step)

---

## Reconfigure Knowledge Discovery License Server

Knowledge Discovery components running in Docker containers need access to an external License Server in exactly the same way as natively-running Knowledge Discovery components. You can use the instance you set up in the previous lesson.

### Allow remote access

In a containerized deployment, Knowledge Discovery License Server receives requests from external machines. The default configuration locks the server down to accept requests from `localhost` only, so you need to modify it to add additional host names as required. The following configuration assumes you use the host name `idol-docker-host` for your WSL environment.

Edit the file `idol.common.cfg` under `C:\OpenText\LicenseServer_25.2.0_WINDOWS_X86_64`:

```diff
[AdminRole]
StandardRoles=admin,servicecontrol,query,servicestatus
- Clients=localhost
+ Clients=localhost,idol-docker-host

[QueryRole]
StandardRoles=query,servicestatus
- Clients=localhost
+ Clients=localhost,idol-docker-host
```

> NOTE: For full details on setting client access, please read the [License Server Reference](https://www.microfocus.com/documentation/idol/knowledge-discovery-25.2/LicenseServer_25.2_Documentation/Help/Content/Configuration/AuthorizationRoles/_ACI_Clients.htm).

Now, restart License Server.

> TIP: To manage Windows Services, run the **Services** system tool. Look for the service you created, named "OpenText Knowledge Discovery License Server 25.2.0".

### Verify remote access

The system running Knowledge Discovery License Server must be accessible (on port `20000`, by default) from the system running Docker. In your WSL environment, test access from the Linux command line, as follows.

```bsh
$ curl $(hostname).local:20000/a=getversion
<?xml version='1.0' encoding='UTF-8' ?><autnresponse xmlns:autn='http://schemas.autonomy.com/aci/'><action>GETVERSION</action><response>SUCCESS</response><responsedata>...
```

> TIP: Install an XML formatter to better display the server responses. See this [tip](../../appendix/TIPS.md#xml-formatting) for details.

#### Troubleshooting

If the convenience `$(hostname).local` does not resolve correctly on your machine, use the following command to find your Windows machine IP address:

```bsh
$ ip route show | grep -i default | awk '{ print $3}'
172.18.96.1
$ curl 172.18.96.1:20000/a=getversion
```

## Deploy Knowledge Discovery containers

Go to your toolkit location from your Linux command line. For example, type `cd /opt/idol/idol-containers-toolkit`.

This repository contains an official collection of tools to allow you to set up and use Knowledge Discovery Docker systems. It consists of directories of Docker *compose* files, plus (where required) build contexts for the servers used in the systems.

> NOTE: To read more about Knowledge Discovery containerized deployments using Docker (and Kubernetes), please see the project on [GitHub](https://github.com/opentext-idol/idol-containers-toolkit).

### "Basic" Knowledge Discovery

The `basic-idol` directory includes files to define a minimal end-to-end Knowledge Discovery system with a single Content engine available for indexing, a Knowledge Discovery-enabled NiFi instance for file ingest, and a Knowledge Discovery Find for queries, as well as some supporting components, including Knowledge Discovery Community for access control.

```mermaid
flowchart TB

  subgraph external[External]
    direction LR
    users([Users])
    files([Documents])
  end

  subgraph internal[Docker Containers]
    direction LR
    ingest[NiFi Ingest]
    dre[Content]
    view[View]
    find[Find]
    comm[Community]
    agent[AgentStore]
    catagent[Categorization AgentStore]
    proxy[Reverse Proxy]
  end

  files --- ingest
  users --- proxy --- find
  proxy --- ingest
  ingest -- Index Docs--- dre 
  find -- Credentials --- comm --- agent
  find -- Query Docs --- dre
  ingest -- Get File --- view
  ingest --- catagent
  find -- Get HTML --- view
  view -- Highlight --- agent
```

> NOTE: This deployment includes just a subset of the available Knowledge Discovery containers. See the [documentation](https://www.microfocus.com/documentation/idol/knowledge-discovery-25.2/IDOLServer_25.2_Documentation/Guides/html/gettingstarted/Content/Install_Run_IDOL/Containers/Docker/AvailableContainers.htm) for a full list.

### What is NiFi?

Apache NiFi is an open source tool built to automate the flow of data between systems. NiFi was originally developed as "NiagaraFiles" by the United States National Security Agency and was open-sourced in [2014](https://web.archive.org/web/20171207172647/https://www.nsa.gov/news-features/press-room/press-releases/2014/nifi-announcement.shtml).

With Knowledge Discovery, NiFi is used primarily for ingestion (ETL = Extraction, Transform and Loading). NiFi has an intuitive drag & drop interface for configuration and is highly scalable. Knowledge Discovery ships components that are easily embedded into a NiFi flow as modular processors. For full details read the [documentation](https://www.microfocus.com/documentation/idol/knowledge-discovery-25.2/NiFiIngest_25.2_Documentation/Help/Content/_FT_SideNav_Startup.htm).

### Setup

Before you continue, you need to edit some of the container toolkit files.

To edit files under WSL Linux, we recommend [VS Code](https://code.visualstudio.com). To open the `basic-idol` folder contents for editing, type:

```sh
cd /opt/idol/idol-containers-toolkit/basic-idol
code .
```

Make the following changes:

1. Edit the `.env` file in `/opt/idol/idol-containers-toolkit/basic-idol` to set the IP address of your Knowledge Discovery License Server. For example:

    ```diff
    # External licenserver host
    - LICENSESERVER_IP=
    + LICENSESERVER_IP=172.18.96.1
    ```

    > NOTE: You must set this configuration to the IP address and not the host name. If you are using WSL, you already found your Windows (host) IP address in the [WSL guide](../../introduction/containers/SETUP_UBUNTU_WSL.md#access-windows-host-from-wsl-guest).

1. Check the target Knowledge Discovery version. The same `.env` file is used to specify the Knowledge Discovery version, currently 25.2:

    ```ini
    # Version of Knowledge Discovery images to use
    IDOL_SERVER_VERSION=25.2
    ```

    > NOTE: If you upgrade in the future, you must ensure that the version of your external Knowledge Discovery License Server matches the version of your containers.

1. Starting from Knowledge Discovery 25.2, you can now select between NiFi 1 or NiFi 2 images.  Edit the file `basic-idol/docker-compose.yml` to select your preferred version:

    ```diff
    idol-nifi:
    - image: ${IDOL_REGISTRY}/nifi-minimal:${IDOL_SERVER_VERSION} # choose nifi-minimal or nifi-full
    + image: ${IDOL_REGISTRY}/nifi-ver2-minimal:${IDOL_SERVER_VERSION} # choose nifi-ver{1,2}-{minimal,full}
    ```

    > NOTE: To continue using NiFi 1, you must change the image name from `nifi-minimal` to `nifi-ver1-minimal`. See the [documentation](https://www.microfocus.com/documentation/idol/knowledge-discovery-25.2/IDOLServer_25.2_Documentation/Guides/html/gettingstarted/Content/Install_Run_IDOL/Containers/Docker/AvailableContainers.htm) for a full list of available containers.

### Deploy

To launch the system, run the following commands from Ubuntu:

```sh
cd /opt/idol/idol-containers-toolkit/basic-idol
docker compose up -d
```

![docker-up](./figs/docker-up.png)

> NOTE: Ignore the deprecation warnings about the `version` attribute.

Monitor the start of the NiFi container with:

```sh
docker compose logs -f idol-nifi
```

Wait for the log message "NiFi has started".

> NOTE: For more details read the [`docker compose logs` documentation](https://docs.docker.com/reference/cli/docker/compose/logs/).
>
> For more examples of monitoring docker containers, see the [monitoring guide](../../admin/DOCKER_MONITORING.md) of this tutorial.

## First look at NiFi

When the system is running, open NiFi on <http://idol-docker-host:8080/idol-nifi/nifi/> (via the reverse proxy).

![nifi-basic-idol-group](./figs/nifi-basic-idol-group.png)

Double-click the "Basic IDOL" tile to enter the processor group, which contains two sub-groups:

1. **Connectors** contains the processors necessary to connect to our source repositories. In the `basic-idol` example, this means ingesting files from disk.
1. **Document Processing** encapsulates the steps needed to extract and enrich ingested files before indexing into Knowledge Discovery Content.

Double-click the **Document Processing** tile:

![nifi-document-processing-group](./figs/nifi-document-processing-group.png)

> NOTE: The breadcrumbs in the footer of the NiFi window help you keep track on where you are in the process group hierarchy.

The document processing flow will:

1. Iteratively extract any sub-files using *KeyViewExtractFiles*.
1. Filter (that is, extract) content (that is, text) from files using *KeyViewFilterDocument*.
1. Normalize field names from different repository types, with *StandardizeMetadata*.
1. Identify possible PII from that text using *Eduction*.
1. Index the documents into Knowledge Discovery Content using *PutIDOL*.

![nifi-flow-enrich](./figs/nifi-flow-enrich.png)

Below this in the flow are clean-up processors, which will be discussed in another lesson.

## First look at Find

Log in to Find on <http://idol-docker-host:8080/find/> (via the reverse proxy). The default credentials are `admin` / `admin`.

It is empty for now, so you can move on to the next section.

## Conclusions

You now understand how to deploy and run Knowledge Discovery components in containers. You have an initial understanding of a NiFi ingest flow and you have Knowledge Discovery Find running.

Now is a good time to commit your changes to the `idol-containers-toolkit` environment file:

![vscode-git](./figs/vscode-git.png)

> TIP: Continue to commit your changes as you step through the tutorial.

## Next step

Next, you are ready to customize your deployment for your data. Go to [Part III](./PART_III.md).
