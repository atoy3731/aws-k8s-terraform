#!/bin/bash

apt-get update -y
apt-get install -y curl python-pip

export INSTALL_K3S_EXEC="server"
export K3S_DATASTORE_ENDPOINT="${datastore_endpoint}"
export CONFIGURE_AWS_PROVIDER="${configure_aws_provider}"
export K3S_TOKEN="${k3s_token}"
export K3S_NODE_NAME="$(hostname).ec2.internal"

if [[ "$CONFIGURE_AWS_PROVIDER" == "true" ]]; then
    curl -sfL https://get.k3s.io | sh -s - server \
      --disable-cloud-controller \
      --tls-san ${cp_lb_host} \
      --no-deploy servicelb \
      --kubelet-arg="cloud-provider=external" \
      --kubelet-arg="provider-id=aws:///$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
else
    curl -sfL https://get.k3s.io | sh -s - server \
      --tls-san ${cp_lb_host}
fi

echo "Installing AWS CLI"
snap install jq
pip install awscli

echo "Waiting for k3s config file to exist.."
while [[ ! -f /etc/rancher/k3s/k3s.yaml ]]; do
  sleep 2
done

echo "Installing cloud controller RBAC"
curl https://raw.githubusercontent.com/atoy3731/aws-k8s-terraform/master/manifests/aws-cloud-provider-manifests.yaml | kubectl apply -f -

echo "Installing ArgoCD"
curl https://raw.githubusercontent.com/atoy3731/aws-k8s-terraform/master/manifests/argocd-manifests.yaml | kubectl apply -f -

#echo "Installing Helm and EBS.."
#curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
#helm --kubeconfig /etc/rancher/k3s/k3s.yaml install aws-ebs-csi-driver \
#  --set enableVolumeScheduling=true \
#  --set enableVolumeResizing=true \
#  --set enableVolumeSnapshot=true \
#  --set cloud-provider=external \
#  https://github.com/kubernetes-sigs/aws-ebs-csi-driver/releases/download/v0.5.0/helm-chart.tgz


CURRENT_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
aws configure set default.region $CURRENT_REGION
cp /etc/rancher/k3s/k3s.yaml /tmp/k3s.yaml
sed -i -e "s/127.0.0.1/${cp_lb_host}/g" /tmp/k3s.yaml

aws s3 cp /tmp/k3s.yaml s3://${s3_bucket}/k3s.yaml