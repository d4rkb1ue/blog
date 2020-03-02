---
title: "Expose Service in K8s"
date: 2020-03-01T23:41:46-08:00
tags: ['k8s', 'sre']
---



# Publishing Services

**We want the service in k8s cluster to be accessed from outside.**

Depending on either the Pod inside the cluster can communication with each other **directly** or not, there're three different approaches,

1. Global Gateway.  
    No direct communication between Pods. All traffic will be routed by the gateway. 
    ```
    +- k8s cluster --+
    |           ***********
    | Pod <---> *  global *
    | Pod <---> * gateway * <---> Clients
    | Pod <---> * "entry" *
    |           ***********
    +---------------+
   ```
2. Service Mesh.  
    Pods can talk directly with each others. Only external access will pass the edge gateway.
    ``` 
    +-- k8s cluster --------+
    |                   ***********
    |     Pod <-------> *         *
    |    /   \          *  edge   * <---> Clients
    | Pod    Pod <----> * gateway *
    |    \   /          *         *
    |     Pod <-------> *         *
    |                   ***********
    | (Powered by internal  |
    |  infras like Istio.)  |
    +-----------------------+
   ```

   **Of course, service mesh has way more features and components. We're only focusing on the communication plane in a single cluster.*

   > You use a gateway to manage inbound and outbound traffic for your mesh, letting you specify which traffic you want to enter or leave the mesh. Gateway configurations are applied to standalone Envoy proxies that are running at the edge of the mesh, rather than sidecar Envoy proxies running alongside your service workloads. [^istio](https://istio.io/docs/concepts/traffic-management/#gateways)

3. Just Expose.  
   Implementations like,
   - Calico in BGP mode
   - Bare MetalLB w/o Gateway

   ```
   +-- k8s cluster --------
   |                        
   |     Pod <------------------------------+
   |    /   \                               |
   | Pod    Pod <-----------------------> Clients
   |    \   /                               |
   |     Pod <------------------------------+
   |                         
   | (Cluster and outside networks *merged* with
   |  protocals like BGP, or
   |  techs like macvlan, ipvlan, MetalLB in L2)
   +-----------------------
   ```
   just as no "k8s cluster boundary" any more.


## API Gateway

The API gateway can combines,

- load balancing in L4
- security
- rate limiting
- monitoring
- ...other cross-cutting concerns for API services [^1](https://www.haproxy.com/blog/using-haproxy-as-an-api-gateway-part-1/)

# Service In K8s

*k8s v1.17*

## k8s.Service

> In theory, you could talk to these pods directly, but what happens when a node dies? The `pod`s die with it, and the `Deployment` will create new ones, with different `IP`s. This is the problem a `Service` solves.

[Service](https://kubernetes.io/docs/concepts/services-networking/service/) is an overlay of Pod's `IP:Port` for **exposing**, with dynamic config and LB.

> ```yaml
> apiVersion: v1
> kind: Service
> metadata:
>   name: my-service
> spec:
>   selector:
>     app: MyApp
>   ports:
>     - protocol: TCP
>       port: 80
>       targetPort: 9376
> ```
> This specification creates a new `Service` object, which targets TCP port `9376` on any `Pod` with the `app=MyApp` label.  

As the backend, k8s assigns this `Service` an Virtual IP (known as `clusterIP`), which is used by the service proxies (known as `kube-proxy`).

### k8s.Endpoint, DNS, kube-proxy

All the services with `clusterIP` **only routable within the cluster network**.

```
-----------------------------k8s cluster-----------------------------

 +--------------+
 | Pod          |-+
 |           Endpoint----> +----------------+
 |            IP:Port      | Service        |  +--------------------+
 +--------------+ | ^      |  - clusterIP  ----> coreDNS            |
   +--------------+ |      |  - Port        |  | (SRV.NS,clusterIP) |
  (Pods selected    |      |                |  +--------------------+
   by `Selector`)   |      +----------------+      ^
                    |                       ^      |
                    *-------------------*   |      #1
                                        |   #2     |           
                                        #3  |      |
                                        |   |      |
 +---k8s.Node(Host)-------------------- | - | ---- | ----------+
 |                                      |   |      |           |
 |  +-------------+        Request      *-------------------+  |-+
 |  | client Pods |-+  -------------->  | kube-proxy        |  | |
 |  +-------------+ |      service      | [ user space ]    |  | |
 |    +-------------+ (IP, Port, Proto) | [ proxy mode ]    |  | |
 |                                      +-------------------+  | |
 |                                                             | |
 +-------------------------------------------------------------+ |
   +-------------------------------------------------------------+

-----------------------------k8s cluster-----------------------------

"^": path regarding workload service request

kube-proxy works as,

- Step #1: get clusterIP
- Step #2: get LB-ed PodIP
- Step #3: proxy request to server
```

`kube-proxy` runs on every `k8s.Node`, which translate `Service.clusterIP` to `Pod's IP:Port` with load balancing options.

In `user space proxy mode`: works as a transparent reverse proxy. 

[More on DNS](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/).

Environment Variables will be created **during the creation** of the pod, which means it's not dynamic. Refer to [an ordering problem](https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/#environment-variables). I don't think it's a good idea of using `env`.

### Headless Services

`service` w/o LB.

> For headless Services, a cluster IP is not allocated, kube-proxy does not handle these Services, and there is no load balancing or proxying done by the platform for them.

## k8s.Service.type

Using k8s built-in [ServiceTypes](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) is not ideal, as mode of,

- `ClusterIP`: why even call this as "Publish". Since this's just the default behavior handled by [`kube-proxy`](#k8sendpoint-dns-kube-proxy).
- `NodePort`: NAT. `HostIP:Port -> (Service.clusterIP:Port ->) Pod(Container)IP:Port`
- `LoadBalancer`: Must use cloud provider? Yes. [^1](https://kubernetes.io/docs/tasks/administer-cluster/developing-cloud-controller-manager/), [^issue](https://github.com/kubernetes/kubernetes/issues/36220), [^2](https://stackoverflow.com/questions/55162890/loadbalancing-for-kubernetes-in-non-cloud-environment)
- `externalName`: just add the FQDN CNAME support, which translate FQDN CNAME to services.
- `externalIPs`: works like `externalName`, **mask** (like `MASQUERADE` in `iptables` ) user-defined destination `IP` to `clusterIP`.

## k8s.Ingress

> `Ingress` exposes `HTTP` and `HTTPS` routes from outside the cluster to services within the cluster. Traffic routing is controlled by rules defined on the `Ingress` resource.

Ingress is a set of `HTTP` **router-rules** and **firewall-rules** for `k8s.Service`.

> In order for the `Ingress` resource to work, the cluster must have an [`ingress controller`](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) running.

Since `Ingress` only describes rules and connect to `k8s.Service`, we need `Ingress Controllers` to do the heavy-lifting and "stand before" the cluster.

```
       User & Clients
            |
    Ingress Controllers
            |
 +-- k8s cluster ----------------------+
 |          |                          |
 |      Ingress -> Services -> Pods    |
 |                                     |
 | (Powered by internal Network infra, |
 |  like Calico.)                      |
 +-------------------------------------+
```

Since we're aiming at creating L4 LB, we can't use `Ingress`.

# Implementations

## Concerns

1. Sticky sessions
2. Keeping real source IP address 

## Implementation 1: NAT

```
           User & Clients
                |
 +---------+---Host.Port---+---+---Host.Port---+--+
 | k8s     |Host(k8s.Node) |   |Host(k8s.Node) |  |
 | cluster | - Pod(Ngnix)  |   | - Pod(HAProxy)|  |
 |         +---------------+   +---------------+  |
 |                      |      |                  |
 |                      +      +                  |
 |                      Services -> Pods          |
 |                                                |
 |(Powered by internal Network infra, like Calico)|
 |                                                |
 +------------------------------------------------+
```

- *`k8s.Service.type[NodePort]`*

The easiest way, is to make API gateway running as Pod on a **static** host(`k8s.Node`), having,

- all exposed ports on the host bind to the Pod directly, like `N:N, M:M`
- gateway forwarding the traffic to internal services utilizating k8s network infra

### Cons

1. Besides HTTP(S) services that can ultize HTTP headers to determine the destination, other L4 services can't share the same ports. 

2. Also, by default,
   > Kubernetes master will allocate a port from a flag-configured range (default: `30000–32767`), and each Node will proxy that port

    So we can only publish service on such ports to external users. This can be solved either by setting the available port to the Pods or use `network=host` (`k8s.DaemonSet.template.spec.hostNetwork`)

### Load Balancing Of The API Gateway Itself

1. Deploy DNS-level LB to LB multiple hosts.
2. Use BGP protocal to let upstream routers know the the nexthop of `Service.ClusterIP`, which are the hosts of the API Gateways.

## Implementation 1.2: Ambassador

Ambassador provide a turnkey solution.

https://www.getambassador.io/user-guide/bare-metal/


## Implementation 2: MetalLB

> MetalLB is a young project. You should treat it as a beta system. The project maturity page explains what that implies. [MetalLB PROJECT MATURITY](https://metallb.universe.tf/concepts/maturity/).

> Kubernetes does not currently allow multiprotocol LoadBalancer services. This would normally make it impossible to run services like DNS, because they have to listen on both TCP and UDP. 
 https://metallb.universe.tf/usage/#ip-address-sharing **This problem is shared by all the solutions.**

MetalLB responds to ARP requests for IPv4 services. So it just use [**IP aliasing**](https://en.wikipedia.org/wiki/IP_aliasing) to allow multiple IP address for a single MAC address. Like **ipvlan**.

- Layer 2 (ipvlan) mode need static IP allocation.


# Ref.

0. https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/
1. https://www.digitalocean.com/community/tutorials/an-introduction-to-haproxy-and-load-balancing-concepts
2. https://kubernetes.io/docs/concepts/services-networking/service/ (Covered in this note)
3. https://kubernetes.io/docs/concepts/services-networking/ingress/
4. https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/
5. https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
6. https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0
7. https://github.com/kubernetes/kubernetes/issues/36220
8. https://medium.com/@maniankara/kubernetes-tcp-load-balancer-service-on-premise-non-cloud-f85c9fd8f43c
9. https://www.weave.works/blog/kubernetes-faq-how-can-i-route-traffic-for-kubernetes-on-bare-metal
10. https://collabnix.com/3-node-kubernetes-cluster-on-bare-metal-system-in-5-minutes/
11. https://sreeninet.wordpress.com/2016/05/29/macvlan-and-ipvlan/
12. https://kubernetes.github.io/ingress-nginx/deploy/baremetal/
13. [Chinese] https://vqiu.cn/metallb-si-you-ji-qun-loadbalancer/
14. https://www.getambassador.io/user-guide/bare-metal/
15. https://istio.io/docs/ops/deployment/deployment-models/
16. https://istio.io/docs/concepts/traffic-management/#gateways
17. https://www.getambassador.io/about/alternatives/