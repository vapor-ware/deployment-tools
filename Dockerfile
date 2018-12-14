# 
# Usage: docker run -ti --rm --volume $(pwd)/assets/config:/home/deploy/.config gstf:latest gsutil
# 

FROM vaporio/foundation:latest

LABEL maintainer "Chuck B <chuck@vapor.io>"

ARG TF_SEMVER=0.11.10
ARG TF_VERSION=${TF_SEMVER}_linux_amd64
ARG CLOUD_SDK_VERSION=227.0.0
ARG HELM_VERSION=v2.12.0
ARG KUBECTL_VERSION=v1.13.0

ENV PATH /google-cloud-sdk/bin:$PATH
# This is a fake path and may need to be volume mapped in.
# We'll need to test this in CI to determine if we can get
# away with CI ROLE scopes.
ENV GOOGLE_CREDENTIALS="/home/deploy/gce.json"
ENV HOME="/home/deploy"

# Add terraform
ADD https://releases.hashicorp.com/terraform/${TF_SEMVER}/terraform_${TF_VERSION}.zip /tmp
# Add google cloud sdk
ADD https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz /tmp
# Add helm
ADD https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz /tmp
# Add kubectl
ADD https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl /tmp

WORKDIR /tmp
# Thid party package management, wish they had up-to-date apt packages.
RUN adduser deploy --system --uid 112 \
    && apt-get update \
    && apt-get install -y python unzip curl \
    && unzip terraform_${TF_VERSION}.zip \
    && install terraform /usr/local/bin/terraform \
    && terraform --version  \
    && tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && ln -s /lib /lib64 \
    && mv google-cloud-sdk /google-cloud-sdk \
    && tar xzvf helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && install linux-amd64/helm /usr/local/bin/helm \
    && helm version -c \
    && install kubectl /usr/local/bin/kubectl \
    && kubectl version --client \
    && rm -rf /tmp/* /var/lib/apt/cache/*


USER deploy
WORKDIR /home/deploy

# Tune gcloud to not be all uppity about reporting on our containers actions
RUN gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image
