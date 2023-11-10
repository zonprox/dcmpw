# DCMPW Installation Script
Debian - Caddy - MariaDB - PHP - Wordpress

## Update OS
```shell
sudo apt update && sudo apt full-upgrade -y && sudo reboot
```

## Install
```shell
sudo wget https://raw.githubusercontent.com/zonprox/dcmpw/main/dcmpw.sh -O dcmpw.sh && sudo chmod +x dcmpw.sh && sudo ./dcmpw.sh
```

## Reinstall OS - Debian 11
```shell
wget --no-check-certificate -qO InstallNET.sh 'https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh
```

```shell
bash InstallNET.sh -debian 11
```

Default Root Password: `LeitboGi0ro`
