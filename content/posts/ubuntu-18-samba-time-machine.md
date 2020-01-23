---
title: Time Machine On Ubuntu 18 with samba
date: 2018-07-22 21:49:46
tags: [Gadget, Linux]
---

折腾 NAS 第二篇，配置 time machine base on smb at ubuntu 18.04

- Ref: [HowTo make time machine backups on a samba fileserver without netatalk : homelab](https://www.reddit.com/r/homelab/comments/83vkaz/howto_make_time_machine_backups_on_a_samba/)



# 安装 Samba 4.8+

If you install older version of samba, uninstall it,
```
sudo apt-get remove --purge samba
```


compile prerequisites,
```
sudo apt-get update
sudo apt-get install acl attr autoconf bind9utils bison build-essential debhelper dnsutils docbook-xml docbook-xsl flex gdb libjansson-dev krb5-user \
libacl1-dev libaio-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev \
libcap-dev libcups2-dev libgnutls28-dev libgpgme11-dev libjson-perl \
libldap2-dev libncurses5-dev libpam0g-dev libparse-yapp-perl \
libpopt-dev libreadline-dev nettle-dev perl perl-modules pkg-config \
python-all-dev python-crypto python-dbg python-dev python-dnspython \
python3-dnspython python-markdown python3-markdown python3-dev xsltproc zlib1g-dev
```

download,
```
wget https://download.samba.org/pub/samba/samba-4.8.3.tar.gz
tar -xzf samba-4.8.3.tar.gz
cd samba-4.8.3.tar.gz
```


compile,
```
./configure --with-systemd --systemd-install-services --with-systemddir=/lib/systemd/system \
  --sysconfdir=/etc/samba --jobs=`nproc --all`
make --jobs=`nproc --all` && sudo make install
```


This will install samba to /usr/local/samba, puts configs under /etc/samba and installs the systemd services to /lib/systemd/system and it will use all your cpu cores for compiling.

Fixed some issues while starting the service,
`sed -i ’s/Type=notify/Type=simple/g’ /lib/systemd/system/smb.service`

change all "Type=notify" to "Type=simple" for smb.service file.


# Samba config

```
#! /etc/samba/smb.conf

[global]
# Basic Samba configuration
server role = standalone server
passdb backend = tdbsam
obey pam restrictions = yes
security = user
printcap name = /dev/null
load printers = no
socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=524288 SO_SNDBUF=524288
server string = Samba Server %v
map to guest = bad user
dns proxy = no
wide links = yes
follow symlinks = yes
unix extensions = no
acl allow execute always = yes
log file = /var/log/samba/%m.log
max log size = 1000

# Special configuration for Apple's Time Machine
fruit:model = MacPro
fruit:advertise_fullsync = true
fruit:aapl = yes

## Definde your shares here
[TimeMachine]
path = /srv/backup/timemachine/%U
valid users = %U
writable = yes
durable handles = yes
kernel oplocks = no
kernel share modes = no
posix locking = no
vfs objects = catia fruit streams_xattr
ea support = yes
browseable = yes
read only = No
inherit acls = yes
fruit:time machine = yes
```

add smb user, "USERNAME" must be valid user name, 
`/usr/local/samba/bin/smbpasswd -a $USERNAME`

If you want to use a separate user for time machine, after add user,
```
# do again
/usr/local/samba/bin/smbpasswd -a $USERNAME

# make other people read only
chmod 744 /media/timemachine

# make this user the owner of this path
chown $USERNAME /media/timemachine
```

# 启动 samba

```
systemctl enable smb.service; systemctl start smb.service
```


# 安装 avahi

```
apt -y install avahi-daemon
```

配置文件，

```
#! /etc/avahi/services/timemachine.service
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
 <name replace-wildcards="yes">%h</name>
 <service>
   <type>_smb._tcp</type>
   <port>445</port>
 </service>
 <service>
   <type>_device-info._tcp</type>
   <port>0</port>
   <txt-record>model=RackMac</txt-record>
 </service>
 <service>
   <type>_adisk._tcp</type>
   <txt-record>sys=waMa=0,adVF=0x100</txt-record>
   <txt-record>dk0=adVN=tm,adVF=0x82</txt-record>
 </service>
</service-group>
```

其中，`<txt-record>dk0=adVN=tm,adVF=0x82</txt-record>` , "tm" is the name your mac will display.

# Trouble shooting

- Time Machine Error 13:
remember `/media` or any other father path of the target backup path must can be accessed by this user. 

- Time Machine Error:
remember to mount the disk

