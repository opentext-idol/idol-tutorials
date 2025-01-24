# Miscellaneous tips

---

- [Command line response formatting](#command-line-response-formatting)
  - [XML formatting](#xml-formatting)
  - [JSON formatting](#json-formatting)
- [Monitoring Docker](#monitoring-docker)
- [File name format encoding](#file-name-format-encoding)
- [End](#end)

---

## Command line response formatting

IDOL Components offer a HTTP interface, which you will often call from the command line in a Linux (or WSL) environment.

### XML formatting

Install the following package:

```sh
sudo apt-get install libxml2-utils
```

Compare the output:

- Without:
  
  ```bsh
  $ curl $(hostname).local:20000/a=getversion
  <?xml version='1.0' encoding='UTF-8' ?><autnresponse xmlns:autn='http://schemas.autonomy.com/aci/'><action>GETVERSION</action><response>SUCCESS</response><responsedata>...
  ```

- With:
  
  ```bsh
  $ curl localhost:20000/a=getversion | xmllint --format -
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                   Dload  Upload   Total   Spent    Left  Speed
  100  1181  100  1181    0     0  1185k      0 --:--:-- --:--:-- --:--:-- 1153k
  <?xml version="1.0" encoding="UTF-8"?>
  <autnresponse xmlns:autn="http://schemas.autonomy.com/aci/">
    <action>GETVERSION</action>
    <response>SUCCESS</response>
    <responsedata>
      <autn:version>24.4.0</autn:version>
      ...
    </responsedata>
  </autnresponse>
  ```

### JSON formatting

Install the following package:

```sh
sudo apt-get install jq
```

Compare the output:

- Without:
  
  ```bsh
  $ curl $(hostname).local:20000/a=getversion -F responseformat=simplejson
  {"autnresponse":{"action":"GETVERSION","response":"SUCCESS","responsedata":{,...
  ```

- With:
  
  ```bsh
  $ curl $(hostname).local:20000/a=getversion -F responseformat=simplejson | jq
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                   Dload  Upload   Total   Spent    Left  Speed
  100   915    0   756  100   159   168k  36334 --:--:-- --:--:-- --:--:--  223k
  {
    "autnresponse": {
      "action": "GETVERSION",
      "response": "SUCCESS",
      "responsedata": {
        "version": "24.4.0",
        ...
      }
    }
  }
  ```

## Monitoring Docker

Monitor hardware resources per container, where the helper script `deploy.sh` calls `docker compose` with your collection of compose `.yml` files as described in the [introductory tutorial](../introduction/containers/DOCKER_DEPLOY.md#keeping-track-of-compose-files):

```sh
$ ./deploy.sh stats
CONTAINER ID   NAME                                          CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O   PIDS
53182ce4c214   basic-idol-httpd-reverse-proxy-1              0.01%     43.34MiB / 31.19GiB   0.14%     349kB / 295kB     0B / 0B     109
9581d8f09492   basic-idol-idol-find-1                        0.22%     1.263GiB / 31.19GiB   4.05%     1.26kB / 0B       0B / 0B     64
02867de98103   basic-idol-idol-community-1                   0.01%     26.63MiB / 31.19GiB   0.08%     53kB / 12.3kB     0B / 0B     17
16fa8be21c4c   basic-idol-idol-view-1                        0.02%     13.86MiB / 31.19GiB   0.04%     3.1kB / 835B      0B / 0B     14
8e1f3787f442   basic-idol-idol-content-1                     0.02%     108.6MiB / 31.19GiB   0.34%     362kB / 54kB      0B / 0B     22
d2e499cc349c   basic-idol-idol-nifi-1                        11.24%    6.055GiB / 31.19GiB   19.41%    123kB / 429kB     0B / 0B     215
ec10facb8935   basic-idol-idol-categorisation-agentstore-1   0.02%     19.07MiB / 31.19GiB   0.06%     4.26kB / 897B     0B / 0B     22
c81461d2fc7f   basic-idol-idol-agentstore-1                  0.02%     90.3MiB / 31.19GiB    0.28%     5.76kB / 5.13kB   0B / 0B     22
```

> NOTE: Optionally add a service name to restrict the list, for example:
>
> ```sh
> $ ./deploy.sh ps idol-content
> CONTAINER ID   NAME                        CPU %     MEM USAGE / LIMIT     MEM %     NET I/O          BLOCK I/O   PIDS
> 8e1f3787f442   basic-idol-idol-content-1   0.02%     116.1MiB / 31.19GiB   0.36%     387kB / 70.8kB   0B / 0B     22
> ```

See which container services are running:

```sh
$ ./deploy.sh ps idol-content
NAME                                          IMAGE                                                 COMMAND              SERVICE                          CREATED         STATUS                   PORTS
basic-idol-idol-content-1                     microfocusidolserver/content:24.4                     "./run_idol.sh"      idol-content                     6 minutes ago   Up 6 minutes (healthy)   0.0.0.0:9100-9102->9100-9102/tcp, :::9100-9102->9100-9102/tcp
```

See which processes are running on each container:

```sh
$ ./deploy.sh top idol-content
basic-idol-idol-content-1
UID       PID       PPID      C    STIME   TTY   TIME       CMD
cblanks   2083586   2083558   0    18:18   ?     00:00:00   /bin/bash ./run_idol.sh                              
cblanks   2083755   2083586   0    18:18   ?     00:00:00   ./content.exe -configfile /content/cfg/content.cfg 
```

## File name format encoding

When you mount a disk for ingest with the FileSystem Connector, depending on your environment you may see issues with file names containing unicode characters that stop you being able to ingest content.

1. Verify the locale of your `idol-nifi` container:

    ```sh
    $ cd /opt/idol/idol-containers-toolkit/basic-idol
    $ docker exec -it basic-idol-idol-nifi-1 bash
    [nifi@912b67752a6e nifi-current]$ locale
    LANG=C.utf8
    ...
    [nifi@912b67752a6e nifi-current]$ exit
    ```

1. If the system is not setup with a UTF-8 locale, like `C.utf8` shown above, make the following change  your docker compose file:

    ```diff
    idol-nifi:
      <<: *common-server
      image: ${IDOL_REGISTRY}/nifi-minimal:${IDOL_SERVER_VERSION} # choose > nifi-minimal or nifi-full
      environment:
    +   - LANG=C.UTF-8
    +   - LC_ALL=C.UTF-8
    ```

1. Restart your NiFi container to apply the changes:

    ```sh
    cd /opt/idol/idol-containers-toolkit/basic-idol
    ./deploy.sh down idol-nifi
    ./deploy.sh up -d
    ```

---

## End
