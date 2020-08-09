---
title: "Time Sync in Linux"
date: 2020-02-07T20:22:34-08:00
tags: [Linux, SRE]
---

# Case

For distribute system, sometimes the datetime on every server in the cluster, or a group of servers need to be synced. 

# Time on a Ubuntu Server

## Timekeepers in the System

*Timekeeper, who hold its own time.*

1. System time: managed by the Linux kernel
2. RTC: real-time clock, hardware clock on your motherboard CMOS
    - **Should always in the UTC timezone**. But there’s nothing in the hardware clock itself says which timezone is used. Can be adjusted by,
        - BIOS setting
        - `hwclock(8)`
    - set this clock only to a whole second
    - `hwclock --systohc` is called on server shutdown and also every 11 mins (if `11 mode` enabled), which means setting just `hwclock` make no sense (ref. `man hwclock`)

## Adjustment

> The Hardware Clock is usually not very accurate. However, much of its inaccuracy is completely predictable - it gains or loses the same amount of time every day. This is called systematic drift.


## Stock services in Ubuntu 16.04


### systemd-timesyncd.service

*`systemd-timesyncd.service` come with stock Ubuntu 16.04.*

- NTP client only

It will conflict with any other time sync daemons, ref:
  - https://www.digitalocean.com/community/tutorials/how-to-set-up-time-synchronization-on-ubuntu-16-04#switching-to-ntpd
  - https://wiki.archlinux.org/index.php/Chrony#Usage

So stop it by `sudo timedatectl set-ntp 0` before installing other service, although the stock `systemd-timesyncd` comes with the built-in confliction setting,

```conf
# /lib/systemd/system/systemd-timesyncd.service.d/disable-with-time-daemon.conf
[Unit]
# don't run timesyncd if we have another NTP daemon installed
ConditionFileIsExecutable=!/usr/sbin/ntpd
ConditionFileIsExecutable=!/usr/sbin/openntpd
ConditionFileIsExecutable=!/usr/sbin/chronyd
ConditionFileIsExecutable=!/usr/sbin/VBoxService
```

So, if we have another timesync service installed, `systemd-timesyncd` will not be operating **even** that service is enabled. For ex., With Chrony installed,

```sh
$ timedatectl
...
Network time on: yes
$ systemctl status systemd-timesyncd
  ...
  Active: inactive (dead)
  Condition: start condition failed at Thu 2020-01-09 14:07:32 MST; 2h 6min ago
```

So it's not operating. Relax.

- see `timesyncd.conf(5)`

### systemd-timedated.service

*`systemd-timedated.service` come with the stock Ubuntu 16.04.*

Useful with,
- cli-tool: `timedatectl`
- gui-tool: `unity-control-center datetime` (can open by from `System setting` -> `Time & Date`)

### `time-sync.target`

//TODO


# Sync Protocols

## NTP

Accuracy

- on a LAN: 1-1000 us
- over the Internet: 1-10 ms

Implementations

1. Chrony
2. Ntpd
3. timed

## PTP

- provides by PTP service
- Lidar trigger Cameras
- included in Octopus Manager
- Use `UDP:319`
- Implementation on Linux PPTD and [others](https://en.wikipedia.org/wiki/List_of_PTP_implementations)


# Sync Service: Chrony

https://chrony.tuxfamily.org/manual.html

> Normally chronyd will cause the system to **gradually** correct any time offset, by slowing down or speeding up the clock as required.

Such config comes with `chrony 2.1.1-1ubuntu0.1` at `/etc/chrony/chrony.conf` 

```sh
pool 2.debian.pool.ntp.org offline iburst
keyfile /etc/chrony/chrony.keys
commandkey 1
driftfile /var/lib/chrony/chrony.drift
log tracking measurements statistics
logdir /var/log/chrony
maxupdateskew 100.0
dumponexit
dumpdir /var/lib/chrony

# This directive forces `chronyd' to send a message to syslog if it
# makes a system clock adjustment larger than a threshold value in seconds.
logchange 0.5
hwclockfile /etc/adjtime
# enables kernel synchronisation (every 11 minutes)
rtcsync
```

# The Simplest Sync Model

```
POOL.NTP.ORG -ntp-> Master
                     |-ntp-> Client
                     |-ntp-> Client
                     |-ntp-> Client
                     ...
```

- Use Chrony as the NTP service for both server and clients
- Master has its own external NTP server
- Client may not find Master as its NTP authority when 
  - network is unstable
  - Master is booting


```sh
# stop the stock NTP service
timedatectl set-ntp 0
```

On Master,

```sh
sed -i '/^pool/s/$/ minpoll 1 maxpoll 2/' /etc/chrony/chrony.conf
cat <<EOT >> /etc/chrony/chrony.conf
allow CLIENT_IP
# allow makestep any time by the 2nd -1
makestep 1 -1
local stratum 8
EOT
```

On Clients,

```sh
sed -i '/^pool/s/^/# /' /etc/chrony/chrony.conf
cat <<EOT >> /etc/chrony/chrony.conf
# presend to prevent the delay on ARP request
server MASTER_IP prefer offline iburst presend 9 minpoll 1 maxpoll 2
makestep 1 -1
local stratum 10
EOT
```

`systemctl restart chrony.service` to reload the service.

# Useful Tools

- `timedatectl`
    - Local time
    - RTC time
    - `Network time on` == `systemd-timesyncd.service` is `running`
- `sudo hwclock --debug`
- `ntpq`
- `chronyc`
    - `chronyc> tracking` for status 
    - `chronyc> sources -v` for status
        - upstream sources might be `?`(unreachable) after drifting, need ~3 mins to be back to synced
        - `LastRx`: column shows how long ago (in seconds) the last sample was received from the source.
        - `Poll`: column shows the rate at which the source is being polled, as a `base-2` logarithm of the interval in seconds. E.x. `poll = 6` means sync every `2^6=64` seconds.
    - `chronyc> password` to login using key in `/etc/chrony/chrony.keys` (not including the heading integer, autogenerated key like `5fbqIloT`)
    - `chronyc> makestep` to force sync using step instead of gradually(slew)
- `timedatectl set-local-rtc 0` to set RTC to local


# Ref.

1. https://en.wikipedia.org/wiki/Orders_of_magnitude_(time)
    - `ns` 1e-9
    - `us` (micro-) 1e-6
    - `ms` (milli-) 1e-3
2. `man 8 hwclock`
3. https://www.linux.com/tutorials/keep-accurate-time-linux-ntp/
4. https://chrony.tuxfamily.org/manual.html
5.  https://www.digitalocean.com/community/tutorials/how-to-set-up-time-synchronization-on-ubuntu-16-04
6.  https://chrony.tuxfamily.org/doc/2.1/manual.html
7.  https://www.meinbergglobal.com/english/info/ntp-packet.htm
8.  https://wiki.archlinux.org/index.php/Chrony#Usage
9.  https://chrony.tuxfamily.org/faq.html
10. https://docs.fedoraproject.org/en-US/Fedora/18/html/System_Administrators_Guide/sect-Checking_if_chrony_is_synchronized.html
