# Run Knowledge Discovery License Server as a service

In this tip, you can optionally set up Knowledge Discovery License Server as a service under Windows or Linux.

---

- [Windows](#windows)
  - [Add service](#add-service)
  - [Remove](#remove)
- [Linux](#linux)
  - [Configure](#configure)
  - [Add `systemd` service](#add-systemd-service)
  - [Manage](#manage)
- [End](#end)

---

## Windows

### Add service

On Windows, open Windows Command Prompt in administrator mode by right-clicking and selecting **Run as administrator**. Type the following commands:

```cmd
> cd C:\OpenText\LicenseServer_25.2.0_WINDOWS_X86_64
> licenseserver.exe -install -servicename OT_KD_License_Server -displayname "OpenText Knowledge Discovery License Server 25.2.0"
Successfully installed "licenseserver.exe" as a service.
```

> TIP: To manage Windows Services, run the **Services** system tool.

Check the service is running. Click <http://localhost:20000/action=getversion> to see an XML response in your web browser:

```xml
<autnresponse xmlns:autn="http://schemas.autonomy.com/aci/">
  <action>GETVERSION</action>
  <response>SUCCESS</response>
  <responsedata>
    <autn:version>25.2.0</autn:version>
    ...
  </responsedata>
</autnresponse>
```

### Remove

To remove the service, run the following command in administrator mode:

```cmd
> sc delete OT_KD_License_Server
[SC] DeleteService SUCCESS
```

> NOTE: For more details on Windows service setup for Knowledge Discovery components, see the [documentation](https://www.microfocus.com/documentation/idol/knowledge-discovery-25.2/LicenseServer_25.2_Documentation/Help/Content/Shared_Admin/Installation/_ADM_Install_WindowsServices.htm).

## Linux

### Configure

Edit the example systemd init file `/opt/idol/licenseserver/init/systemd/licenseserver.service`:

```diff
- ExecStart=__COMPONENT_INSTALL_DIR__/licenseserver.exe -configfile __COMPONENT_INSTALL_DIR__/licenseserver.cfg
+ ExecStart=/opt/idol/licenseserver/licenseserver.exe -configfile /opt/idol/licenseserver/licenseserver.cfg
- User=__USER__
+ User=azureuser
- Group=__GROUP__
+ Group=azureuser

- WorkingDirectory=__COMPONENT_INSTALL_DIR__
+ WorkingDirectory=/opt/idol/licenseserver
```

> NOTE: Replace the example `azureuser` user and group with your own.

### Add `systemd` service

Set up the service:

```sh
sudo cp /opt/idol/licenseserver/init/systemd/licenseserver.service /lib/systemd/system/
sudo chmod 755 /lib/systemd/system/licenseserver.service
sudo chown root /lib/systemd/system/licenseserver.service
sudo chgrp root /lib/systemd/system/licenseserver.service
sudo systemctl enable licenseserver
```

### Manage

Use `systemctl` to manage the service, for example:

```sh
sudo systemctl stop licenseserver
sudo systemctl start licenseserver
```

Check the service is running:

```sh
$ sudo systemctl status licenseserver
● licenseserver.service - Knowledge Discovery License Server
     Loaded: loaded (/lib/systemd/system/licenseserver.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2024-08-20 14:44:43 UTC; 2s ago
   Main PID: 14542 (licenseserver.e)
      Tasks: 9 (limit: 38432)
     Memory: 7.6M
        CPU: 33ms
     CGroup: /system.slice/licenseserver.service
             └─14542 /opt/idol/licenseserver/licenseserver.exe -configfile /opt/idol/licenseserver/licenseserver.cfg

Aug 20 14:44:43 td-idol-enterprise systemd[1]: Started Knowledge Discovery License Server.
```

Check License Server is contactable on port `20000`:

```bsh
$ curl localhost:20000/a=getversion | xmllint --format -
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1181  100  1181    0     0  1185k      0 --:--:-- --:--:-- --:--:-- 1153k
<?xml version="1.0" encoding="UTF-8"?>
<autnresponse xmlns:autn="http://schemas.autonomy.com/aci/">
  <action>GETVERSION</action>
  <response>SUCCESS</response>
```

> NOTE: For more details on Linux service setup for Knowledge Discovery components, see the [documentation](https://www.microfocus.com/documentation/idol/knowledge-discovery-25.2/LicenseServer_25.2_Documentation/Help/Content/Shared_Admin/Installation/_ADM_Install_LinuxStartup.htm).

---

## End
