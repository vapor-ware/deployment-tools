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

## Credentials

### When being used as a repl

Terraform will by read from the environment variable `GOOGLE_CREDENTIALS`. This
can be mapped in using your service account json file:

```console
docker run -ti -v $HOME/gce.json:/home/deploy/.gce.json -e GOOGLE_CREDENTIALS=/home/deploy/gce.json vaporio/deployment-tools:latest
```

### When being used in CI

Credentials should be enlisted into jenkins as a base64 encoded secret file. This
makes the management straight forward. consider the following snippet:

```json
  environment {
    SVC_ACCOUNT_KEY = credentials('terraform-gce-credential')
  }
  stage('Terraform') {
    agent {
      docker { 
        image 'vaporio/deployment-tools:latest'
        args '-v ${SVC_ACCOUNT_KEY}:/home/deploy/gce.json'
      }
    }
    steps {
      dir('cloud/dev') {
        sh 'terraform init'
        sh 'terraform validate'
        sh 'terraform plan'
      }
    }
  }
```


## Who to contact in case of issues

You can reach out to chuck at vapor dot io in the event of issues with this image.

