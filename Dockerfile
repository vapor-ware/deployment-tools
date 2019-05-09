FROM vaporio/foundation:latest

# usage:
# docker run --rm -ti -v $HOME:/localhost deployment-tools
#

ARG TF_SEMVER=0.11.13
ENV TF_VERSION=${TF_SEMVER}_linux_amd64
ENV CLOUD_SDK_VERSION=240.0.0
ENV HELM_VERSION=v2.13.1
ENV KUBECTL_VERSION=v1.13.1
ENV HELMFILE_VERSION=v0.47.0
ENV RKE_VERSION=v0.2.0
ENV VELERO_VERSION=v0.11.0
ENV SCTL_VERSION=0.3.2

# Add terraform
ADD https://releases.hashicorp.com/terraform/${TF_SEMVER}/terraform_${TF_VERSION}.zip /tmp
# Add google cloud sdk
ADD https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz /tmp
# Add helm
ADD https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz /tmp
# Add kubectl
ADD https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl /tmp
# Add helmfile
ADD https://github.com/roboll/helmfile/releases/download/${HELMFILE_VERSION}/helmfile_linux_amd64 /tmp
# Add RKE
ADD https://github.com/rancher/rke/releases/download/${RKE_VERSION}/rke_linux-amd64 /tmp
# Add Velero
ADD https://github.com/heptio/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz /tmp
# Add Sctl
ADD https://github.com/vapor-ware/sctl/releases/download/${SCTL_VERSION}/sctl_${SCTL_VERSION}_Linux_x86_64.tar.gz /tmp

ENV HOME=/conf
ENV CLOUDSDK_CONFIG=/localhost/.config/gcloud/
ENV GOOGLE_APPLICATION_CREDENTIALS=/localhost/.config/gcloud/application_default_credentials.json
ENV KUBECONFIG=/localhost/.kube/config
ENV KUBECONFIG_DIR=/localhost/.kube/

# Basics and system tools
RUN apt-get update && \
    apt-get install -y \
    byobu \
    openssl \
    openssh-client \
    git \
    dnsutils \
    jq \
    tar \
    unzip \
    vim \
    make \
    pwgen \
    sshpass \
    gpg-agent \
    python \
    unzip \
    curl  \
    bash-completion \
    direnv \
# Install the GCS Fuse package to mount remote storage
    && echo "deb http://packages.cloud.google.com/apt gcsfuse-bionic main" | tee /etc/apt/sources.list.d/gcsfuse.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && apt-get update && apt-get install -y gcsfuse \
    && rm -rf /var/lib/apt/lists/*

COPY rootfs/etc/skel/bashrc /etc/skel/.bashrc
# Additional utility tooling
WORKDIR /tmp
# Thid party package management, wish they had up-to-date apt packages.
RUN adduser neo --home /conf -q \
    && unzip terraform_${TF_VERSION}.zip \
    && install terraform /usr/bin/terraform \
    && install rke_linux-amd64 /usr/local/bin/rke \
    && tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && tar xzvf velero-${VELERO_VERSION}-linux-amd64.tar.gz \
    && rm velero-${VELERO_VERSION}-linux-amd64.tar.gz \
    && tar xzvf sctl_${SCTL_VERSION}_Linux_x86_64.tar.gz  \
    && ln -s /lib /lib64 \
    && mv google-cloud-sdk /google-cloud-sdk \
    && tar xzvf helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && install linux-amd64/helm /usr/bin/helm \
    && install helmfile_linux_amd64 /usr/bin/helmfile \
    && install kubectl /usr/bin/kubectl \
    && install velero /usr/bin/velero \
    && install sctl /usr/bin/sctl \
    && rm -rf /tmp/* /var/lib/apt/cache/* \
    && ln -s /google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud  \
    && ln -s /google-cloud-sdk/bin/gsutil /usr/local/bin/gsutil  \
    && ln -s /google-cloud-sdk/bin/bq /usr/local/bin/bq
# ln -s /usr/local/google-cloud-sdk/completion.bash.inc /etc/bash_completion.d/gcloud.sh && \

RUN kubectl completion bash > /etc/bash_completion.d/kubectl.sh
ENV KUBECTX_COMPLETION_VERSION 0.6.2
ADD https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_COMPLETION_VERSION}/completion/kubens.bash /etc/bash_completion.d/kubens.sh
ADD https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_COMPLETION_VERSION}/completion/kubectx.bash /etc/bash_completion.d/kubectx.sh

ENV KTX_VERSION master

# Install KTX quick kube context switcher
ADD https://raw.githubusercontent.com/heptiolabs/ktx/${KTX_VERSION}/ktx /usr/bin/ktx
ADD https://raw.githubusercontent.com/heptiolabs/ktx/master/ktx-completion.sh /etc/bash_completion.d/ktx-completion.sh
RUN chmod 755 /usr/bin/ktx

ENV HELM_DIFF_VERSION 2.11.0+2
ENV HELM_GIT_VERSION 0.3.0
ENV HELM_SECRETS_VERSION 1.3.2
ENV HELM_S3_VERSION 0.7.0

RUN helm init --client-only \
    && helm plugin install https://github.com/databus23/helm-diff --version v${HELM_DIFF_VERSION} \
    && helm plugin install https://github.com/lazypower/helm-secrets --version ${HELM_SECRETS_VERSION} \
    && helm plugin install https://github.com/aslafy-z/helm-git.git --version ${HELM_GIT_VERSION} \
    && helm plugin install https://github.com/hypnoglow/helm-s3 --version v${HELM_S3_VERSION}

#
# Install fancy Kube PS1 Prompt
#
ENV KUBE_PS1_VERSION v0.7.0
ADD https://raw.githubusercontent.com/jonmosco/kube-ps1/${KUBE_PS1_VERSION}/kube-ps1.sh /etc/profile.d/kube-ps1.sh

#Tune gcloud
RUN gcloud config set core/disable_usage_reporting true --installation && \
    gcloud config set component_manager/disable_update_check true --installation && \
    gcloud config set metrics/environment github_docker_image --installation

#
# Shell
#
ENV CACHE_PATH=/localhost/.deployment-tools
ENV HISTFILE=${CACHE_PATH}/history
ENV SHELL=/bin/bash
ENV LESS=-Xr
ENV SSH_AGENT_CONFIG=/var/tmp/.ssh-agent


# This is not a "multi-user" system, so we'll use `/etc` as the global configuration dir
# Read more: <https://wiki.archlinux.org/index.php/XDG_Base_Directory>
ENV XDG_CONFIG_HOME=/etc

# Clean up file modes for scripts
# Note: 117 group is for jenkins/CI
# 777 for localhost is to let Ci create file paths as needed.
RUN find ${XDG_CONFIG_HOME} -type f -name '*.sh' -exec chmod 755 {} \; \
    && chown -R neo /conf \
    && chgrp -R 117 /conf/.helm \
    && chmod -R 775 /conf/.helm \
    && chmod -R 777 /localhost

COPY rootfs /

USER neo
WORKDIR /conf

