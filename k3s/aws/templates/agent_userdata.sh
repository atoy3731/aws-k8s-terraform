#!/bin/bash

export CONFIGURE_AWS_PROVIDER="${configure_aws_provider}"
export K3S_TOKEN="${k3s_token}"
export K3S_NODE_NAME="$(hostname).ec2.internal"

if [[ "$CONFIGURE_AWS_PROVIDER" == "true" ]]; then
    curl -sfL https://get.k3s.io | sh -s - agent \
      --server https://${cp_lb_host}:6443 \
      --kubelet-arg="cloud-provider=external" \
      --kubelet-arg="provider-id=aws:///$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

else
    curl -sfL https://get.k3s.io | sh -s - agent \
      --server https://${cp_lb_host}:6443
fi

echo "Installing AWS CLI"
apt-get update -y
apt-get install -y python-pip
snap install jq
pip install awscli