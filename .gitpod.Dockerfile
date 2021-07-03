
FROM gitpod/workspace-full-vnc:commit-3cb2f5c0c4722604a0919c9e1fc7d611d3c6a05b

USER gitpod

# Install Terraform
ARG RELEASE_URL="https://releases.hashicorp.com/terraform/0.15.4/terraform_0.15.4_linux_amd64.zip"
RUN mkdir -p ~/.terraform \
    && cd ~/.terraform \
    && curl -fsSL -o terraform_linux_amd64.zip ${RELEASE_URL} \
    && unzip *.zip \
    && rm -f *.zip \
    && printf "terraform -install-autocomplete\n" >>~/.bashrc

ENV PATH=$PATH:$HOME/.aws-iam:$HOME/.terraform