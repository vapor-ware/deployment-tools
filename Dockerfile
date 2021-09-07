FROM vaporio/foundation:latest

# usage:
# docker run --rm -ti -v $HOME:/localhost deployment-tools
#


ENV NEEDED_TERRAFORM_VERSIONS="0.14.3 0.14.10"
ENV DEFAULT_TERRAFORM_VERSION=0.14.10

ENV CLAIRCTL_VERSION=v1.2.8
ENV CLOUD_SDK_VERSION=342.0.0
# ENV HELM_VERSION=v2.17.0
ENV HELM3_VERSION=v3.6.0
ENV KUBECTL_VERSION=v1.21.1
ENV HELMFILE_VERSION=v0.139.7
ENV VELERO_VERSION=v1.3.2
ENV SCTL_VERSION=1.5.0
ENV RANCHER_CLI_VERSION=v2.4.3
ENV CHARTRELEASER_VERSION="v0.2.0"
ENV TFLINT_VERSION="v0.25.0"
ENV TFSEC_VERSION="v0.39.15"
ENV KUBELINT_VERSION="0.1.6"
ENV KUBECONFORM_VERSION="v0.4.7"
# TODO (etd): deprecate - migrated to kubeconform
ENV KUBEVAL_VERSION="0.15.0"
ENV DF_PV_VERSION v0.3.0
ARG GHR_VERSION=v0.13.0
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Add google cloud sdk
ADD https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz /tmp
# Add helm
# ADD https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz /tmp
# Add helm3
ADD https://get.helm.sh/helm-${HELM3_VERSION}-linux-amd64.tar.gz /tmp
# Add kubectl
ADD https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl /tmp
# Add helmfile
ADD https://github.com/roboll/helmfile/releases/download/${HELMFILE_VERSION}/helmfile_linux_amd64 /tmp
# Add Velero
ADD https://github.com/heptio/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz /tmp
# Add Sctl
ADD https://github.com/vapor-ware/sctl/releases/download/${SCTL_VERSION}/sctl_${SCTL_VERSION}_Linux_x86_64.tar.gz /tmp
# Add rancher-cli
ADD https://github.com/rancher/cli/releases/download/${RANCHER_CLI_VERSION}/rancher-linux-amd64-${RANCHER_CLI_VERSION}.tar.gz /tmp
# Add chart-releaser
ADD https://github.com/edaniszewski/chart-releaser/releases/download/${CHARTRELEASER_VERSION}/chart-releaser_linux_amd64.tar.gz /tmp
# Add ghr github releaser
ADD https://github.com/tcnksm/ghr/releases/download/${GHR_VERSION}/ghr_${GHR_VERSION}_linux_amd64.tar.gz /tmp
# Add tflint
ADD https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip /tmp
# Add TFSec
ADD https://github.com/tfsec/tfsec/releases/download/${TFSEC_VERSION}/tfsec-linux-amd64 /tmp
# Add kubelint
ADD https://github.com/stackrox/kube-linter/releases/download/${KUBELINT_VERSION}/kube-linter-linux.tar.gz /tmp
# Add kubeval
ADD https://github.com/instrumenta/kubeval/releases/download/${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz /tmp
# Add kubeconform
ADD https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz /tmp
# Add df-pv
ADD https://github.com/yashbhutwala/kubectl-df-pv/releases/download/${DF_PV_VERSION}/kubectl-df-pv_${DF_PV_VERSION}_linux_amd64.tar.gz /tmp
# Add Clairctl
ADD https://github.com/jgsqware/clairctl/releases/download/${CLAIRCTL_VERSION}/clairctl-linux-amd64 /tmp


ENV HOME=/conf
ENV CLOUDSDK_CONFIG=/localhost/.config/gcloud/
ENV GOOGLE_APPLICATION_CREDENTIALS=/localhost/.config/gcloud/application_default_credentials.json


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
    netcat-openbsd \
    python \
    python3-yaml \
    python3-click \
    python3-requests \
    python3-pip \
    unzip \
    curl  \
    bash-completion \
    telnet \
    direnv \
    rsync \
    wget \
    # Install the GCS Fuse package to mount remote storage
    && echo "deb http://packages.cloud.google.com/apt gcsfuse-bionic main" | tee /etc/apt/sources.list.d/gcsfuse.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && apt-get update && apt-get install -y gcsfuse \
    && rm -rf /var/lib/apt/lists/*

# During transitionary releases of terraform we need multiple versions available to
# provide functionality during execution contexts. This will be required for
# ci-shared/1.2.0+ for deployment-tools based pipelines.
RUN AVAILABLE_TERRAFORM_VERSIONS="${NEEDED_TERRAFORM_VERSIONS}" && \
    rm -f /usr/local/bin/terraform && \
    for VERSION in ${AVAILABLE_TERRAFORM_VERSIONS}; do \
    curl -LOs https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip && \
    curl -LOs https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_SHA256SUMS && \
    sed -n "/terraform_${VERSION}_linux_amd64.zip/p" terraform_${VERSION}_SHA256SUMS | sha256sum -c && \
    mkdir -p /usr/local/bin/tf/versions/${VERSION} && \
    unzip -o terraform_${VERSION}_linux_amd64.zip -d /usr/local/bin/tf/versions/${VERSION} && \
    ln -fs /usr/local/bin/tf/versions/${VERSION}/terraform /usr/local/bin/terraform${VERSION} && \
    rm terraform_${VERSION}_linux_amd64.zip && \
    rm terraform_${VERSION}_SHA256SUMS; \
    done && \
    ln -s /usr/local/bin/tf/versions/${DEFAULT_TERRAFORM_VERSION}/terraform /usr/local/bin/terraform




COPY rootfs/etc/skel/bashrc /etc/skel/.bashrc
# Additional utility tooling
WORKDIR /tmp
# Thid party package management, wish they had up-to-date apt packages.
RUN adduser neo --home /conf -q \
    && adduser jenkins --home /home/jenkins -q \
    && usermod -aG jenkins neo \
    && tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && tar xzvf velero-${VELERO_VERSION}-linux-amd64.tar.gz \
    && mv velero-${VELERO_VERSION}-linux-amd64/velero . \
    && rm velero-${VELERO_VERSION}-linux-amd64.tar.gz \
    && tar xzvf sctl_${SCTL_VERSION}_Linux_x86_64.tar.gz  \
    && tar xzvf rancher-linux-amd64-${RANCHER_CLI_VERSION}.tar.gz \
    && tar xzvf chart-releaser_linux_amd64.tar.gz \
    && tar xzvf ghr_${GHR_VERSION}_linux_amd64.tar.gz \
    && tar xzvf kubectl-df-pv_${DF_PV_VERSION}_linux_amd64.tar.gz \
    && ln -s /lib /lib64 \
    && mv google-cloud-sdk /google-cloud-sdk \
    # && tar xzvf helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && mkdir -p helm3 /etc/helm \
    && chmod 775 /etc/helm \
    && chgrp jenkins /etc/helm \
    && tar xzvf helm-${HELM3_VERSION}-linux-amd64.tar.gz -C helm3 \
    && unzip -u /tmp/tflint_linux_amd64.zip -d /tmp/ \
    && tar xzvf kube-linter-linux.tar.gz \
    && tar xzvf kubeval-linux-amd64.tar.gz \
    && tar xzvf kubeconform-linux-amd64.tar.gz \
    # && install linux-amd64/helm /usr/bin/helm2 \
    && install helm3/linux-amd64/helm /usr/bin/helm \
    && install helmfile_linux_amd64 /usr/bin/helmfile \
    && install kubectl /usr/bin/kubectl \
    && install velero /usr/bin/velero \
    && install sctl /usr/bin/sctl \
    && install rancher-${RANCHER_CLI_VERSION}/rancher /usr/bin/rancher \
    && install chart-releaser /usr/bin/chart-releaser \
    && install ghr_${GHR_VERSION}_linux_amd64/ghr /usr/bin/ghr \
    && install tflint /usr/bin/tflint \
    && install tfsec-linux-amd64 /usr/bin/tfsec \
    && install kube-linter /usr/bin/kube-linter \
    && install kubeval /usr/bin/kubeval \
    && install kubeconform /usr/bin/kubeconform \
    && install df-pv /usr/bin/df-pv \
    && install clairctl-linux-amd64 /usr/local/bin/clairctl \
    && rm -rf /tmp/* /var/lib/apt/cache/* \
    && ln -s /google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud  \
    && ln -s /google-cloud-sdk/bin/gsutil /usr/local/bin/gsutil  \
    && ln -s /google-cloud-sdk/bin/bq /usr/local/bin/bq \
    && ln -s /usr/bin/helm /usr/bin/helm3
# ln -s /usr/local/google-cloud-sdk/completion.bash.inc /etc/bash_completion.d/gcloud.sh && \

RUN kubectl completion bash > /etc/bash_completion.d/kubectl.sh
ENV KUBECTX_COMPLETION_VERSION 0.6.3
ADD https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_COMPLETION_VERSION}/kubens /usr/local/bin/kubens
ADD https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_COMPLETION_VERSION}/kubectx /usr/local/bin/kubectx


ADD https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_COMPLETION_VERSION}/completion/kubens.bash /etc/bash_completion.d/kubens.sh
ADD https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_COMPLETION_VERSION}/completion/kubectx.bash /etc/bash_completion.d/kubectx.sh

ENV HELM_DIFF_VERSION 2.11.0+5

# RUN helm2 init --client-only \
#     && helm2 plugin install https://github.com/databus23/helm-diff --version v${HELM_DIFF_VERSION} \
RUN helm plugin install https://github.com/databus23/helm-diff

#
# Init Helm for CI deployment-runner
#
ENV HOME=/home/jenkins
RUN mkdir -p /home/jenkins/agent-workspace \
    # && helm2 init --client-only \
    # && helm2 plugin install https://github.com/databus23/helm-diff --version v${HELM_DIFF_VERSION} \
    && helm plugin install https://github.com/databus23/helm-diff

#
# Install fancy Kube PS1 Prompt
#
ENV HOME=/conf
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
    && chown -R neo:jenkins /home/jenkins \
    && chown -R neo /conf \
    # && chgrp -R 117 /conf/.helm \
    # && chmod -R 775 /conf/.helm \
    && chmod -R 777 /localhost \
    && rm -rf /tmp/* \
    && chmod 777 /tmp

COPY rootfs /

USER neo
WORKDIR /conf
