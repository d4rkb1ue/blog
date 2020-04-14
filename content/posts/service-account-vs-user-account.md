---
title: "Service Account vs. User Account"
date: 2020-04-13T17:16:38-07:00
tags: ["Linux", "SRE"]
---

Firstly, we need to clarify where are we talking at,

- Linux system
- K8s service orchestration
- Directory service
- Services with API

## In Linux System

User accounts are used by real users, service accounts are used by system services such as web servers, mail transport agents, databases etc. **The kernel doesn't care, besides UID 0.**

- By convention, service accounts have user IDs in the low range, e.g. 100-999 or so
- Service accounts may own specific resources, even device special files, but they don't have superuser-like privileges
- Service accounts can be created like ordinary user accounts
- Service accounts shouldn't have a login shell, i.e. they have `/usr/sbin/nologin` as login shell 
- Service accounts are typically locked, i.e. it is not possible to login (for traditional `/etc/passwd` and `/etc/shadow` this can be achieved by setting the password hash to arbitrary values such as `*` or `x`)

Benefits of adopting Service accounts,

- reduce the impact in case of an incident with one service
- track down what resources belong to which service

## In K8s & Services

User accounts are for humans. Service accounts are for processes, which run in pods.

- User accounts are intended to be global. Names must be unique across all namespaces of a cluster, future user resource will not be namespaced. Service accounts are namespaced
- User accounts might be synced from a corporate Directory service
- Auditing considerations for humans and service accounts may differ
- Service account needs more automation, like password and token updating and expiring


## Related

### NSS and PAM

> `/etc/nsswitch.conf`. NSS (which stands for Name Service Switch) is a system mechanism to configure different sources for common configuration databases. For example, `/etc/passwd` is a file type source for the passwd database.
> 
> `/etc/pam.d`, `/etc/pam.conf`. PAM (which stands for Pluggable Authentication Modules) is a mechanism used by Linux (and most *nixes) to extend its authentication schemes based on different plugins.
>
> So to summarize, we need to configure NSS to use the OpenLDAP server as a source for the passwd, shadow and other configuration databases and then configure PAM to use these sources to authenticate its users.

## Refs.

- https://wiki.archlinux.org/index.php/LDAP_authentication
- https://unix.stackexchange.com/questions/314725/what-is-the-difference-between-user-and-service-account
- https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/