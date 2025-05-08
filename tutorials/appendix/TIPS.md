# Miscellaneous tips

---

- [Command line response formatting](#command-line-response-formatting)
  - [XML formatting](#xml-formatting)
  - [JSON formatting](#json-formatting)
- [End](#end)

---

## Command line response formatting

Knowledge Discovery Components offer a HTTP interface, which you will often call from the command line in a Linux (or WSL) environment.

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

  > TIP: If the convenience `$(hostname).local` does not resolve correctly on your machine, use the command to find your Windows machine IP address:
  >
  > ```bsh
  > $ ip route show | grep -i default | awk '{ print $3}'
  > 172.18.96.1
  > $ curl 172.18.96.1:20000/a=getversion
  > ```

- With:
  
  ```bsh
  $ curl $(hostname).local:20000/a=getversion | xmllint --format -
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                   Dload  Upload   Total   Spent    Left  Speed
  100  1181  100  1181    0     0  1185k      0 --:--:-- --:--:-- --:--:-- 1153k
  <?xml version="1.0" encoding="UTF-8"?>
  <autnresponse xmlns:autn="http://schemas.autonomy.com/aci/">
    <action>GETVERSION</action>
    <response>SUCCESS</response>
    <responsedata>
      <autn:version>25.2.0</autn:version>
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
        "version": "25.2.0",
        ...
      }
    }
  }
  ```

---

## End
