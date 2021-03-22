# usage:
# docker run --rm -ti -v $HOME:/localhost vaporio/deployment-tools
#

FROM vaporio/buildpack-deps:bionic as builder

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Declare versions of tooling the image installs.
ENV CHARTRELEASER_VERSION="v0.1.4"
ENV CLOUD_SDK_VERSION="292.0.0"
ENV GHR_VERSION="v0.13.0"
ENV HELM3_VERSION="v3.5.2"
ENV HELMFILE_VERSION="v0.138.6"
ENV HELM_VERSION="v2.17.0"
ENV KUBECONFORM_VERSION="v0.4.6"
ENV KUBECTL_VERSION="v1.20.4"
ENV KUBECTX_VERSION="0.6.3"
ENV KUBELINT_VERSION="0.1.6"
# TODO (etd): deprecate - migrated to kubeconform
ENV KUBEVAL_VERSION="0.15.0"
ENV KUBE_PS1_VERSION="v0.7.0"
ENV RANCHER_CLI_VERSION="v2.4.3"
ENV SCTL_VERSION="1.5.0"
ENV TERRAFORM_VERSIONS="0.13.6 0.14.3"
ENV TFLINT_VERSION="v0.23.1"
ENV TFSEC_VERSION="v0.37.0"

# Create directories used for the build/download process.
RUN mkdir -p \
  /tmp/bin \
  /tmp/completion \
  /tmp/helm3 \
  /tmp/profile

# Add google cloud sdk
ADD https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz /tmp
# Add helm
ADD https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz /tmp
# Add helm3
ADD https://get.helm.sh/helm-${HELM3_VERSION}-linux-amd64.tar.gz /tmp
# Add kubectl
ADD https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl /tmp
# Add helmfile
ADD https://github.com/roboll/helmfile/releases/download/${HELMFILE_VERSION}/helmfile_linux_amd64 /tmp
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
# Add kubectx and kubens
ADD https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_VERSION}/kubens /usr/local/bin/kubens
ADD https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_VERSION}/kubectx /usr/local/bin/kubectx

# Bash completions
ADD https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_VERSION}/completion/kubens.bash /tmp/completion/kubens.sh
ADD https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_VERSION}/completion/kubectx.bash /tmp/completion/kubectx.sh

# Add kube-ps1
ADD https://raw.githubusercontent.com/jonmosco/kube-ps1/${KUBE_PS1_VERSION}/kube-ps1.sh /tmp/profile/kube-ps1.sh


WORKDIR /tmp

# During transitionary releases of terraform we need multiple versions available to
# provide functionality during execution contexts. This will be required for
# ci-shared/1.2.0+ for deployment-tools based pipelines.
RUN AVAILABLE_TERRAFORM_VERSIONS="${TERRAFORM_VERSIONS}" \
 && rm -f /usr/local/bin/terraform \
 && for VERSION in ${AVAILABLE_TERRAFORM_VERSIONS}; do \
    curl -LOs https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip && \
    curl -LOs https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_SHA256SUMS && \
    sed -n "/terraform_${VERSION}_linux_amd64.zip/p" terraform_${VERSION}_SHA256SUMS | sha256sum -c && \
    mkdir -p /tmp/tf/${VERSION} && \
    unzip -o terraform_${VERSION}_linux_amd64.zip -d /tmp/tf/${VERSION} && \
    mv /tmp/tf/${VERSION}/terraform /usr/local/bin/terraform${VERSION}; \
    done \
 # Unpack added packages
 && tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
 && tar xzvf sctl_${SCTL_VERSION}_Linux_x86_64.tar.gz  \
 && tar xzvf rancher-linux-amd64-${RANCHER_CLI_VERSION}.tar.gz \
 && tar xzvf chart-releaser_linux_amd64.tar.gz \
 && tar xzvf ghr_${GHR_VERSION}_linux_amd64.tar.gz \
 && tar xzvf helm-${HELM_VERSION}-linux-amd64.tar.gz \
 && tar xzvf helm-${HELM3_VERSION}-linux-amd64.tar.gz -C /tmp/helm3 \
 && unzip -u /tmp/tflint_linux_amd64.zip -d /tmp/ \
 && tar xzvf kube-linter-linux.tar.gz \
 && tar xzvf kubeval-linux-amd64.tar.gz \
 && tar xzvf kubeconform-linux-amd64.tar.gz \
 # Move installed binaries to the /tmp/bin directory
 && install linux-amd64/helm /tmp/bin/helm \
 && install /tmp/helm3/linux-amd64/helm /tmp/bin/helm3 \
 && install helmfile_linux_amd64 /tmp/bin/helmfile \
 && install kubectl /tmp/bin/kubectl \
 && install sctl /tmp/bin/sctl \
 && install rancher-${RANCHER_CLI_VERSION}/rancher /tmp/bin/rancher \
 && install chart-releaser /tmp/bin/chart-releaser \
 && install ghr_${GHR_VERSION}_linux_amd64/ghr /tmp/bin/ghr \
 && install tflint /tmp/bin/tflint \
 && install tfsec-linux-amd64 /tmp/bin/tfsec \
 && install kube-linter /tmp/bin/kube-linter \
 && install kubeval /tmp/bin/kubeval \
 && install kubeconform /tmp/bin/kubeconform



FROM vaporio/foundation:bionic

# Declare versions of tooling/dependencies installed/selected for the
# final deployment-tools image.
ENV HELM_DIFF_VERSION="v3.1.3"
ENV DEFAULT_TERRAFORM_VERSION="0.13.6"

# Set default environment variables to configure the session within the container.
ENV HOME=/conf
ENV CLOUDSDK_CONFIG=/localhost/.config/gcloud/
ENV GOOGLE_APPLICATION_CREDENTIALS=/localhost/.config/gcloud/application_default_credentials.json
ENV CACHE_PATH=/localhost/.deployment-tools
ENV HISTFILE=${CACHE_PATH}/history
ENV SHELL=/bin/bash
ENV LESS=-Xr
ENV SSH_AGENT_CONFIG=/var/tmp/.ssh-agent

# This is not a "multi-user" system, so we'll use `/etc` as the global configuration dir
# Read more: <https://wiki.archlinux.org/index.php/XDG_Base_Directory>
ENV XDG_CONFIG_HOME=/etc

# User setup.
RUN adduser neo     --home /conf -q \
 && adduser jenkins --home /home/jenkins -q \
 && usermod -aG jenkins neo \
 && mkdir -p /etc/helm

# Basics and system tools.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash-completion \
      byobu \
      ca-certificates \
      curl  \
      direnv \
      dnsutils \
      git \
      gpg-agent \
      jq \
      make \
      openssh-client \
      openssl \
      pwgen \
      python \
      python3-click \
      python3-pip \
      python3-requests \
      python3-yaml \
      rsync \
      sshpass \
      tar \
      unzip \
      vim \
      wget \
 # Install the GCS Fuse package to mount remote storage.
 && echo "deb http://packages.cloud.google.com/apt gcsfuse-bionic main" | tee /etc/apt/sources.list.d/gcsfuse.list \
 && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
 && apt-get update \
 && apt-get install -y \
      gcsfuse \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY rootfs /

# Copy the binaries/scripts installed in the builder stage. This is declared here to improve
# build times/caching, as the tool versions are more likely to change than the installed packages.
# Copying this after package install lets us cache the package install layer.
COPY --from=builder /tmp/bin/*        /usr/local/bin/
COPY --from=builder /tmp/completion/* /etc/bash_completion.d/
COPY --from=builder /tmp/profile/*    /etc/profile.d/
COPY --from=builder /tmp/google-cloud-sdk /google-cloud-sdk

# Create symlinks for various resources.
RUN ln -s /lib /lib64 \
 && ln -s /google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud \
 && ln -s /google-cloud-sdk/bin/gsutil /usr/local/bin/gsutil \
 && ln -s /google-cloud-sdk/bin/bq     /usr/local/bin/bq \
 && ln -s /usr/local/bin/terraform${DEFAULT_TERRAFORM_VERSION} /usr/local/bin/terraform

# Tool initialization and setup for CI.
ENV HOME=/home/jenkins
RUN mkdir -p /home/jenkins/agent-workspace \
 && helm init --client-only \
 && helm  plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION} \
 && helm3 plugin install https://github.com/databus23/helm-diff
ENV HOME=/conf

# Tool initialization and setup for in-container workflows.
RUN kubectl completion bash > /etc/bash_completion.d/kubectl.sh \
 # Helm
 && helm init --client-only \
 && helm  plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION} \
 && helm3 plugin install https://github.com/databus23/helm-diff \
 # Tune gcloud
 && gcloud config set core/disable_usage_reporting true --installation \
 && gcloud config set component_manager/disable_update_check true --installation \
 && gcloud config set metrics/environment github_docker_image --installation \
 # Clean up file modes for scripts. Note that 117 group is for Jenkins/CI.
 # 777 for localhost is to let CI create file paths as needed.
 && find ${XDG_CONFIG_HOME} -type f -name '*.sh' -exec chmod 755 {} \; \
 && chown -R neo:jenkins /home/jenkins \
 && chmod 775 /etc/helm \
 && chgrp jenkins /etc/helm \
 && chown -R neo /conf \
 && chgrp -R 117 /conf/.helm \
 && chmod -R 775 /conf/.helm \
 && chmod -R 777 /localhost \
 && chmod 777 /tmp

USER neo
WORKDIR /conf
