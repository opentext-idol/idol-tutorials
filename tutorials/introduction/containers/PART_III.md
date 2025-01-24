# PART III - Modify the deployment for your data

In this lesson, you will:

- Make changes to your Docker deployment, including learning how to edit a containerized IDOL component configuration file.
- Modify your NiFi flow to add an additional processor.
- Ingest some sample enterprise documents.
- Edit your IDOL Find configuration file to better explore those documents.

---

- [Modify IDOL container deployment](#modify-idol-container-deployment)
- [Ingest documents with NiFi](#ingest-documents-with-nifi)
  - [Prepare sample data for ingest](#prepare-sample-data-for-ingest)
  - [Follow the ingestion](#follow-the-ingestion)
  - [See your documents in IDOL Content](#see-your-documents-in-idol-content)
  - [Understanding ingest](#understanding-ingest)
- [Explore documents in IDOL Find](#explore-documents-in-idol-find)
  - [Filter by metadata](#filter-by-metadata)
  - [Search](#search)
- [Edit the IDOL Find configuration file](#edit-the-idol-find-configuration-file)
  - [Copy out configuration files](#copy-out-configuration-files)
  - [Mount external configuration files](#mount-external-configuration-files)
  - [Update the configuration file](#update-the-configuration-file)
  - [Redeploy and validate](#redeploy-and-validate)
- [Conclusions](#conclusions)
- [Next steps](#next-steps)

---

## Modify IDOL container deployment

Remember that, to edit files under WSL Linux, we recommend [VS Code](https://code.visualstudio.com). To open the `basic-idol` folder contents for editing, type:

```sh
cd /opt/idol/idol-containers-toolkit/basic-idol
code .
```

The default `basic-idol` system is *almost* exactly what we need now... but you can make some modifications to help you understand the system, including mounting a shared folder where you can copy sample data to index.

Follow these [docker deployment steps](./DOCKER_DEPLOY.md) to make the following instructional changes:

1. Keep track of multi-file docker configurations.
1. Open ports to make each IDOL component accessible.
1. Mount a shared folder for document ingestion.
1. Mount a containerized IDOL component configuration file to make and preserve edits.

## Ingest documents with NiFi

With your IDOL system now running and configured, you are now ready to start ingesting data.

### Prepare sample data for ingest

This repository includes a `data` folder containing some sample enterprise files to ingest. Copy the directory `Retail` into your shared folder `C:\OpenText\hotfolder`.

### Follow the ingestion

Open NiFi at <http://idol-docker-host:8080/idol-nifi/nifi/> and note that the processors are automatically started.

Monitor some of the files as they pass from processor to processor:

- To stop a processor to temporarily block some files in the queue, right-click on the processor tile, then click **Stop**:

    ![nifi-list-queue](./figs/nifi-stop-processor.png)

- Right-click the link comping in to that processor, then click **List queue**:

    ![nifi-list-queue](./figs/nifi-list-queue.png)

- Click the **eye icon** for any queued document:

    ![nifi-view-queue](./figs/nifi-view-queue.png)

- A new tab opens, showing the document metadata and content for this file, including any PII detections:

    ![nifi-view-document](./figs/nifi-view-document.png)

    > TIP: To monitor documents flowing through NiFi, you must connect to NiFi by using an explicit IP address, as instructed in this tutorial, not using `localhost`. If you are using WSL and following this tutorial to the letter, you will have no problem. You have already found your WSL (guest) IP address in the [WSL guide](./SETUP_WINDOWS_WSL.md#network-access) and possibly set a friendly host name for it (`idol-docker-host`) in your Windows `hosts` file.

If you stopped a processor, restart it (right-click, then **Start**) to allow those queued files to be processed.

### See your documents in IDOL Content

As in the first lesson, use IDOL Admin for Content to view the data index.

As in the first lesson, use [test action](http://idol-docker-host:9100/a=admin#page/console/test-action) to run a query on the data.

Use this query to search for documents related to "retail sales" and return a contextual summary of each document:

```url
action=query&text=retail%20sales&summary=context&print=none
```

![retail-sales-query](./figs/retail-sales-query.png)

### Understanding ingest

Now is a good point to pause and review what we've done for clarity. How did your files actually get from your filesystem to IDOL Content?

1. In the setup, you [configured a mounted disk](./DOCKER_DEPLOY.md#mount-a-shared-folder) that is visible to the container running NiFi at `/idol-ingest`.

   - The `docker-compose.bindmount.yml` file defines the local directory for a volume:

      ```yml
      volumes:
        idol-ingest-volume:
          driver_opts:
            device: /mnt/c/OpenText/hotfolder
      ```

   - That volume is mounted into the NiFi container in `docker-compose.yml`:

      ```yml
      services:
        idol-nifi:
          volumes:
            - idol-ingest-volume:/idol-ingest
      ```

1. In the "Basic IDOL" NiFi flow, the FileSystem Connector is pre-configured to look at this mounted folder for files.

    - Navigate to the "GetFileSystem" processor to view its configuration:
      ![nifi-get-files-config](./figs/nifi-get-files-config.png)

    - Click **ADVANCED** and go to the **BROWSE** tab to see the connector's view of that folder:
      ![nifi-get-files-browse](./figs/nifi-get-files-browse.png)

1. After flowing through the various IDOL processors in NiFi, files get to the "PutIDOL" processor, which sends them to IDOL Content (in batches) to the container with hostname `idol-content` on port `9100`.

    - The container host is defined in `docker-compose.yml`, which also points to the mounted configuration directory:

      ```yml
      services:
        idol-content: 
          volumes:
            - ./content/cfg:/content/cfg
      ```

    - The IDOL Content configuration file `content/cfg/original-content-cfg` defines the server port:

      ```ini
      [Server]
      Port=9100
      ```

    - The **PutIDOL** processor properties reference this port, as well as the target **Default** database:

      ![nifi-put-idol](./figs/nifi-put-idol.png)

## Explore documents in IDOL Find

Log in to Find on <http://idol-docker-host:8080/find/>. The default credentials are `admin` / `admin`.

> NOTE: To create your own users, go to IDOL Community <http://idol-docker-host:9030/action=admin#page/users>. Find users need one or more of the "FindAdmin", "FindBI" and "FindUser" roles. See the [Find Administration Guide](https://www.microfocus.com/documentation/idol/IDOL_24_4/Find_24.4_Documentation/admin/Content/User_Roles.htm) for details.

The initial view of the topic map shows a summary of the key terms in your document set:

![find-topic-map](./figs/find-topic-map.png)

### Filter by metadata

For example:

- application name, or

  ![find-filter-app-name](./figs/find-filter-app-name.png)

- word count
  
  ![find-filter-word-count](./figs/find-filter-word-count.png)

### Search

For example, for "sales process" to retrieve relevant documents:

![find-search](./figs/find-search.png)

In the **List** tab, click on an item in the result list to show a near-native HTML rendering of the original document. In this way, IDOL allows you to view documents directly in the Find application, without having to have the viewing software installed for each file type in your index.

You can explore some of the other tabs and filters to get a feeling for using the Find interface.

> NOTE: To learn more about Find, see the [Find Administration Guide](https://www.microfocus.com/documentation/idol/IDOL_24_4/Find_24.4_Documentation/admin/Content/Introduction.htm).

## Edit the IDOL Find configuration file

You have already modified an IDOL component configuration file. You used IDOL Content as an example and this process applies to all IDOL servers. However, IDOL Find is a bit different. Find (and other UIs you will see in later lessons) is a Java application, with a `.json` file as the primary means of modifying its behavior.

### Copy out configuration files

With the Docker system running, use the Linux command line to make a local copy of the IDOL container configuration directory:

```sh
$ cd /opt/idol/idol-containers-toolkit/basic-idol
$ mkdir find
$ docker cp basic-idol-idol-find-1:/opt/find/home/config_basic.json find/
Successfully copied 10.8kB to /opt/idol/idol-containers-toolkit/basic-idol/find/
```

### Mount external configuration files

Edit the file `basic-idol/docker-compose.yml` to mount the external config directory:

```diff
idol-find:
  image: ${IDOL_REGISTRY}/find:${IDOL_SERVER_VERSION}
  labels:
    <<: *common-labels
  environment:
    - IDOL_UI_CFG=config_basic.json # this controls the configuration of Find
+ volumes:
+   - ./find/config_basic.json:/opt/find/home/config_basic.json:ro # this mounts an external cfg file
  depends_on:
    - idol-community
    - idol-view
```

### Update the configuration file

You might have noticed that Find automatically displays any *parametric*- and *numeric*-type fields found in the source documents. To change the behavior of this display, you can edit the configuration file `fieldsInfo` section.

One common change is to provide a friendly name for a given field. For example, look at the `PII_NAME/VALUE` field, which is shown as just **VALUE** by default in Find. Use the following example to add an entry for it:

```diff
"fieldsInfo" : {
  ...
  "longitude" : {
    "type" : "number",
    "advanced" : true,
    "names" : [ "NODE_PLACE/LON", "LON" ],
    "values" : [ ]
+ },
+ "educed_person_name" : {
+   "advanced" : true,
+   "names" : [ "PII_NAME/VALUE" ]
  }
}
```

> NOTE: For full options on the `fieldsInfo` configuration section, see the [Find Administration Guide](https://www.microfocus.com/documentation/idol/IDOL_24_4/Find_24.4_Documentation/admin/Content/ConfigFile/ConfigureFriendlyNamesParametric.htm).

### Redeploy and validate

Next you stop and start the IDOL Find container to pick up these changes.

```sh
./deploy.sh stop idol-find
./deploy.sh up -d
```

Open IDOL Find and log in again to see the field name under **FILTERS** has changed to **EDUCED PERSON NAME**.

![find-filter-educed-name](./figs/find-filter-educed-name.png)

> NOTE: For details on other available configuration options, see the [Find Administration Guide](https://www.microfocus.com/documentation/idol/IDOL_24_4/Find_24.4_Documentation/admin/Content/Introduction.htm).

> NOTE: The IDOL Find source code is available on [GitHub](https://github.com/opentext-idol/find), where you can find detailed instructions to set up your own development environment to build your own custom changes into the application.

## Conclusions

You have now set up and used an end-to-end IDOL system.

You understand how to modify a containerized IDOL deployment. You can mount external volumes and update configuration files for IDOL components, including Find. You have explored a NiFi ingest chain to ingest documents and can search for your documents in Find.

> REMINDER: To stop (but not destroy) your IDOL deployment, run:
>
> ```sh
> /opt/idol/idol-containers-toolkit/basic-idol/deploy.sh stop
> ```

## Next steps

Explore some advanced IDOL configurations, in the [showcase section](../../README.md#showcase-lessons).
