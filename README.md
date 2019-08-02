# Deployment Tools

## What's Deployment Tools?

Deployment Tools provide a homegenoous environment to execute, develop, and test
your infrastructure as code. Whether in CI or on your Laptop.


### Whats in the box?

Core Tooling

 - Kubectl
 - Terraform
 - GoogleSDK
 - Helm
 - Helmfile

Helm Plugins

- Helm Diff
- Helm Git
- Helm Edit
- Helm Secrets
- Helm S3

Remote Filesystems

- fuse / gcsfuse for remote persistent state.
  *note* this requires `--privilged` on most systems.

Nice to haves

- KTX

## Usage

Basic usage example:

To use this container as a shell, launch the container with a few convention arguments:

```
    docker run -ti --rm -v $HOME:/localhost --privileged vaporio/deployment-tools:latest build-info
```

in order to launch a shell simply:

```
    docker run -ti --rm -v $HOME:/localhost --privileged vaporio/deployment-tools:latest /bin/bash
```

All your files in $HOME will be volume mapped into the container as `/localhost`
by convention.


