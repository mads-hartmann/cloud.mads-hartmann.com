
FROM ubuntu:21.10

RUN apt update \
    && apt install -y \
        curl \
        zip \
        sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# Gitpod user
# Taken from https://github.com/gitpod-io/workspace-images/blob/master/base/Dockerfile
RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod \
    # passwordless sudo for users in the 'sudo' group
    && sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers
ENV HOME=/home/gitpod
WORKDIR $HOME
USER gitpod

# Install Terraform
ARG TERRAFORM_VERSION=1.0.1
RUN mkdir -p ~/.terraform \
    && cd ~/.terraform \
    && curl -fsSL -o terraform_linux_amd64.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && unzip *.zip \
    && rm -f *.zip \
    && printf "terraform -install-autocomplete\n" >>~/.bashrc

ENV PATH=$PATH:$HOME/.aws-iam:$HOME/.terraform