---
title: "Bridge Network in Linux"
date: 2020-02-24T05:27:21-08:00
tags: ['Networking', 'Linux']
---

# Case

We want to combine two physical Network Interfaces(NIC) on a single machine, which,

1. shares the same IP address,
2. combines routing tables supporting circuit/swithing for different NICs,
3. "extends" the upstream network(connected to NIC1) to be used by another device(connected to NIC2),
4. eventually make the machine work tranparently as a network bridge.

# Bridge in Linux

## How Linux handle net bridge in stacks

For the Linux Kernel, normal user space processes can only utilize `Socket` with `(IP, port, proto)` 3-tuple for Network connection, which means that Kernel only provide **L4** network communication interface.

- `IP` will be consumed by the Kernel routing table to determine the target device, (can be virtual or real)

Package will be handled in kernel space for lower network levels.

## `Bridge Device`

If the next destination device is a virtual bridge,

> the bridge device is a software switch, and each of its slave devices and the bridge itself are ports of the switch. (`systemd.netdev(5)`)

The target `IP` and `MAC` are belongs to this virtual eth port(name it with `veth0`) on of this bridge(name `br0`).

`veth0` should have a random virtual `MAC` when created, which will show in the `ip a` as the attributes of the `br0`.

If we further connect this to the physical interfaces(name `eth0`, `eth1`...), by,

```sh
ip link set dev eth0 master br0
ip link set dev eth1 master br0
```

these `eth*`s will become transparent in the `LAN`, just like the physical ports on a real switch(bridge). `eth*`'s MAC does not matter any more for `MAC address masking`. 

After this, the `veth0` become "real" in the `LAN` since it's now addressable and masking-able. In this case, for not conflicting with other devices on the LAN accidentally, `veth0` will choose to reuse one of the MACs of `eth*`s.

Since the `eth*`s are connected to a single bridge, theoretically, any traffic comes from `eth*` will be either broadcasted, or selectively redirected to other `eth*` base on the MAC switching table. Software side, this can be implemented with the table and pipe with no magic.


```
        Server1
           |
      +---------+
      |   br0   |
      +---------+
      /   |   \     ...
   Dev0  Dev1  Dev2
```

The above graph is just schematic. In real, it's just a server (`Server1`) with three ethernet ports and they're going to behave like above. So,

- `Dev*`, and `Server1` act like they're connected in L2.

If we assign an IP for the `br0`, i.e. the `veth0`, and make it as the default `0.0.0.0/0` gateway,

- `Server1` act like a dedicate device connected to the `br0`.

### Configs of `Bridge Device`

So how are the configs and statuses of the `br0` being maintained? Like `ARP table(s)`, `switching table(s)`, `routing table(s)`?

They are all maintained in the Kernel.

- Switch(`br0`) does not need routing table. Kernel only need the routing entry to make the `br0`(or say `veth0`) as the default first hop for all the traffics.
- Switch need switching table. It can found by `bridge fdb` (http://man7.org/linux/man-pages/man8/bridge.8.html)
- ARP table does not needed by `br0` either. Its maintained by `Server1` and it need the `ARP table` to route the `IP` package to different `MAC`s, thus different ports. Ports are, in theory, ports on the `br0`, but in real, ports on the server.


## Network Namespace and `veth`

Just for clarification, **these're unrelated**.

Network namespace is a high level abstration for process.

> `network_namespaces(7)` is isolation of the system resources associated with networking: network devices, IPv4 and IPv6 protocol stacks, IP routing tables, firewall rule.

> `veth(4)` device pair provides a pipe-like abstraction that can be used to create tunnels between network namespaces 

## Prerequisites To Build The Bridge

1. All devices should share the same maximum packet size (`MTU`). The bridge doesn't fragment packets.
2. All devices should support promiscuous operation. The bridge needs to be able to receive all network traffic, not just traffic destined for its own address.
3. All devices should allow source address spoofing.

## Build A Bridge

```sh
# clean current settings
mv /etc/network/interfaces /etc/network/interfaces.bak
/bin/echo -e "auto lo\niface lo inet loopback" > /etc/network/interfaces
systemctl restart NetworkManager
systemctl restart networking

# clean all nics' IP
nics=$(ip -o l | grep "state UP" | awk '{ gsub(/:/,""); print $2 }' | grep -v '^docker\|^br\|^lo')
for nic in $nics; do ip addr flush $nic; done

# create bridge
ip link add name br0 type bridge
ip link set dev br0 up

# connect it with two physical nics
ip link set dev eth0 master br0
ip link set dev eth1 master br0

# assume this machine has static IP
ip addr add dev br0 192.168.1.2/24

# assume the upstream router is
ip r add default via 192.168.1.1
sed -i.bak "1i nameserver 192.168.1.1" /etc/resolv.conf

# enable promiscuousm, bridge, and set MTU
nics=$(ip -o l | grep "state UP" | awk '{ gsub(/:/,""); print $2 }' | grep -v '^docker\|^lo')
for nic in $nics; do ip link set $nic promisc on; done
sysctl -w net.bridge.bridge-nf-call-iptables=0
for nic in $nics; do ip link set dev $nic mtu 1500; done

# Loose mode as defined in RFC3704 Loose Reverse Path https://access.redhat.com/solutions/53031
sysctl -w net.ipv4.conf.all.rp_filter=2
```

# Ref.

1. http://man7.org/linux/man-pages/man4/veth.4.html
1. http://man7.org/linux/man-pages/man7/network_namespaces.7.html
1. https://wiki.debian.org/BridgeNetworkConnections#Bridging_with_a_wireless_NIC
1. `man 5 systemd.netdev`
1. https://unix.stackexchange.com/questions/255484/how-can-i-bridge-two-interfaces-with-ip-iproute2
1. https://wiki.archlinux.org/index.php/Network_bridge
1. https://techdifferences.com/difference-between-bridge-and-switch.html
1. https://wiki.linuxfoundation.org/networking/bridge
1. Ubuntu 16.04 Desktop is not using Systemd-networkd, ~~https://wiki.archlinux.org/index.php/Systemd-networkd~~
1. https://jlk.fjfi.cvut.cz/arch/manpages/man/systemd.netdev.5#SUPPORTED_NETDEV_KINDS
1. https://serverfault.com/questions/117788/linux-bridging-not-forwarding-packets
1. https://wiki.debian.org/BridgeNetworkConnections
1. https://superuser.com/questions/1211852/why-linux-bridge-doesnt-work
2. Linux not answer to ARP requests from other VLANs: https://access.redhat.com/solutions/53031 
3. https://www.kernel.org/doc/Documentation/networking/bonding.txt
4. http://man7.org/linux/man-pages/man8/bridge.8.html
5. https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/
6. http://ebtables.netfilter.org/br_fw_ia/br_fw_ia.html