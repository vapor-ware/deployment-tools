# Deployment Tools

## What's this?

The range of tooling we need to perform cloud deployments at vapor, in a
consistent, homogeneous environment. What will you find in here?

- Google Cloud SDK
- Helm
- Terraform


In order to tweak the versions installed, they are exposed as simple ARG's with
sane defaults at the time of writing.


```shell
docker build -t vaporio/deployment-tools --build-arg HELM_VERSION=v12.1.0 .
```

## Use as a local runtime

This container not only warehouses our tooling for CI based deployments, but
also may be used as a local homogeneous environment. 

```
docker run --rm -ti -v $HOME/.config:/home/deploy/.config vaporio/deployment-tools:latest
```

## Who to contact in case of issues

You can reach out to chuck at vapor dot io in the event of issues with this image.

