---
title: "Deploy Docker Registry"
date: 2020-02-02T19:55:40-08:00
tags: [Docker, SRE]
---

# Case

To distribute the updated docker images among a cluster, compared with
using a centralized registry, use P2P registry is more bandwidth and
speed-efficient. 

We can deploy docker image registry on any server.

# Steps

To init the server,

```bash
docker run -d -e REGISTRY_HTTP_ADDR=0.0.0.0:5000 -p 5000:5000 --name registry registry:2
docker tag original.registry.com/image-name:version my-registry:5000/image-name:version
docker push my-registry:5000/image-name:version
```

To let client connect to server,

```bash
vi /etc/docker/daemon.json
# add a line
# {
#     ...
#     "insecure-registries": ["my-registry:5000"]
#     ...
# }
systemctl restart docker
# or
# sudo killall -1 dockerd
docker pull my-registry:5000/image-name:version
docker tag my-registry:5000/image-name:version original.registry.com/image-name:version
```

# Troubleshooting

## "Server Gave Http Response To Https Client"

If the client return error,

```bash
Error response from daemon: Get https://my-registry:5000/v2/: http: server gave HTTP response to HTTPS client
```

That's because the client's dockerd doesn't has `insecure registries` set.

## "Manifest Unknown"

If the client return error,

```bash
Error response from daemon: manifest for my-registry:5000/services:octopus-manager-2.0.34.3 not found: manifest unknown: manifest unknown
```

That's because the server doesn't has the the target image, aka `my-registry:5000/image-name:version` in its own registry. Please make sure if the server has image pushed, **to itself**.


# Ref.

1. https://docs.docker.com/registry/deploying/