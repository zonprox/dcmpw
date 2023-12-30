# DCMPW Installation Guide

This guide provides a step-by-step process for installing a web server stack on Debian 11, incorporating Caddy as the web server, MariaDB as the database server, PHP, and WordPress.

## Update OS
```shell
sudo apt update && sudo apt full-upgrade -y && sudo reboot
```

## Install DCMPW
```shell
sudo wget https://raw.githubusercontent.com/zonprox/dcmpw/main/dcmpw.sh -O dcmpw.sh && sudo chmod +x dcmpw.sh && sudo ./dcmpw.sh
```
Note: Ensure you always use the latest version of the installation script.

## Reinstall OS - Debian 11 (optional)
```shell
sudo wget --no-check-certificate -qO InstallNET.sh 'https://gitee.com/mb9e8j2/Tools/raw/master/Linux_reinstall/InstallNET.sh' && sudo chmod a+x InstallNET.sh
sudo bash InstallNET.sh -debian 11
sudo reboot
```
The installation process may take approximately 5 - 30 minutes.\
Default Root Password: `LeitboGi0ro`
