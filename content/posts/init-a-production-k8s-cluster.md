---
title: "Init a Production K8s Cluster"
date: 2020-03-16T01:52:09-07:00
tags: ['SRE', 'k8s']
---

*k8s v1.16.8, kubespray v2.12.0*

# Init a Production K8s Cluster

Kubespray works like a charm,

```sh
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
sudo pip install -r requirements.txt
cp -rfp inventory/sample inventory/mycluster

# create cluster hosts poll
declare -a IPS=(10.10.1.3 10.10.1.4 10.10.1.5)
CONFIG_FILE=inventory/mycluster/inventory.yml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
mv inventory/mycluster/inventory.ini inventory/mycluster/inventory.yml

# Review and modify the cluster config
vi inventory/mycluster/inventory.yml

ansible-playbook -i inventory/aws-test/inventory.yml --become --become-user=root --user=ubuntu --private-key=$(pwd)/.ssh/aws-ec2-test.pem cluster.yml
```

Get kubeconfig from `$1st-kube-master:/root/.kube/config`.

*One additional credentials will be available at `inventory/mycluster/credentials`.*

Create an Admin token,

> @https://medium.com/@kanrangsan/creating-admin-user-to-access-kubernetes-dashboard-723d6c9764e4
> 
> ```yaml
> apiVersion: v1
> kind: ServiceAccount
> metadata:
>   name: admin-user
>   namespace: kube-system
> ```
> 
> ```yaml
> apiVersion: rbac.authorization.k8s.io/v1
> kind: ClusterRoleBinding
> metadata:
>   name: admin-user
> roleRef:
>   apiGroup: rbac.authorization.k8s.io
>   kind: ClusterRole
>   name: cluster-admin
> subjects:
> - kind: ServiceAccount
>   name: admin-user
>   namespace: kube-system
> ```
> 
> ```sh
> kubectl apply -f {ServiceAccount, ClusterRoleBinding}.yaml
> kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | > awk '{print $1}')
> ```


Access frontend at,
`https://1st-kube-master:6443/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login`
using the generated token.

*Since kubeconfig login is [by default disabled](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/README.md).*

Troubleshooting on [Kubernetes dashboard reports that "the server could not find the requested resource"](https://github.com/kubernetes-sigs/kubespray/issues/5347),


```sh
# Delete 1.10.1 dashboard
kubectl delete deployments kubernetes-dashboard -n kube-system

# Install v2.0.0-rc2 dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended.yaml
```

## K8s API-Servers HA

Kubespray, by default, creates multiple,

- etcd nodes
- api-servers(kube-master)

### Etcd

Depends on the assigned roles of the servers, etcd cluster is coupled by default with api-server and even nodes, which something **like** [Stacked etcd topology](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/#stacked-etcd-topology). Although it's **actually still** deployed as [External etcd topology](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/#external-etcd-topology). 

### Kube-master

Kubespray deploys `localhost` reverse proxy on non-Master kube-Nodes. 

> K8s components require a loadbalancer to access the apiservers via a reverse proxy.  
> Kubespray includes support for an nginx-based proxy that resides on each non-master Kubernetes node. This is referred to as localhost loadbalancing.   
> This option is configured by the variable loadbalancer_apiserver_localhost (defaults to `True`)

So on the traffic to API-Server will be like this,

```
+- non-Master k8s Node --+       +------- k8s Master --------+
|                        |       |                           |
|  kubelet --> Nginx ----+-------+-> API-Server <-- kubelet  |---+
|         localhost:6443 |       |  0.0.0.0:6443             |   |
+----------------+-------+       +---------------------------+   |
                 +----------------->|    ...other Masters        |
                                    +----------------------------+
```

Nginx, as reverse proxy on every non-Master kube-Node will incharge of HA traffic redirecting.  
Nginx proxy deployed as Pod, `pod/nginx-proxy-nodeN`, with config sit on local `/etc/nginx/nginx.conf`,
```conf
...
stream {
  upstream kube_apiserver {
    least_conn;
    # Master IPs
    server 172.30.77.8:6443;
    server 172.30.77.126:6443;
  }

  server {
    listen        127.0.0.1:6443;
    proxy_pass    kube_apiserver;
    proxy_timeout 10m;
    proxy_connect_timeout 1s;
  }
}
...
```

kubelet has setting in `/etc/kubernetes/kubelet.conf`,

```conf
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ...
    server: https://localhost:6443
  name: default-cluster
kind: Config
...
```

For external access, there's actually only one entrypoint: `kube-master[0]`, the 1st-kube-master.

## Certificates in K8s

These certs are created by Kubespray,

- `apiserver.crt/key`
- `apiserver-kubelet-client.crt/key`
- `ca.crt/key`
- `front-proxy-ca.crt/key`
- `front-proxy-client.crt/key`
- `sa.key/pub`

### Q: Where's etcd.ca?

> "certificates are not generated in case of external etcd."

### Q: "Client certificates" is the, 

1. certificates hold by client, or
2. certificates have been signed to client's publich key, or
3. both?

**2**. Public keys for both digital signature and key encipherment.

## LB for users' services

In the case of no Pod/container in k8s cluster need to be accessed directly by users, we don't need to setup BGP edge routers.

We can just keep the internal containers as internal, make them available for clients by gateway as also the load balancer.

See [expose-service-in-k8s]({{< ref "/posts/expose-service-in-k8s" >}}) for details.


## Ref.

1. https://github.com/kubernetes-sigs/kubespray/blob/master/docs/getting-started.md#accessing-kubernetes-api
2. https://medium.com/@kanrangsan/creating-admin-user-to-access-kubernetes-dashboard-723d6c9764e4
3. https://kubernetes.io/docs/setup/best-practices/certificates/
4. https://kubespray.io/#/docs/getting-started
5. tagged playbook. https://docs.ansible.com/ansible/latest/user_guide/playbooks_tags.html
6. local reverse LB. https://kubespray.io/#/docs/ha-mode