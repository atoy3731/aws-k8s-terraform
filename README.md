## AWS K8S Terraform

This is a project containing Terraform IaC to get a scalable Kubernetes cluster up and running in AWS with ArgoCD deployed to it.

### Prerequisites

* Terraform CLI
* An AWS account with Admin Permissions
* Your AWS credentials configured via Environment Variables or `~/.aws/credentials` file.
* Kubectl CLI

### How Do I Work It?

Right now, we only support a K3S deployment model using RDS as a backend store. Eventually we'll expand to EKS.

1. Navigate to the `k3s` directory: `cd k3s`

2. Update the `example.tfvars`:
   * _db_username_: The master username for the RDS cluster.
   * _db_password_: The master password for the RDS cluster (you should actually not store this in a file and enter it when you apply your Terraform, but leaving it here for simplicity's sake.)
   * _public_ssh_key_: Set this to the public SSH key you're going to use to SSH to boxes. It is usually in `~/.ssh/id_rsa.pub` on your system.
   * _keypair_name_: The name of the keypair to store your public SSH key.
   * _key_s3_bucket_name_: The S3 bucket to store the K3S kubeconfig file. (**NOTE**: This needs to be GLOBALLY UNIQUE across AWS.)
   
3. Initialize Terraform:
    ```bash
    terraform init
    ```

4. Apply terraform (you'll need to type 'yes'):
    ```bash
    terraform apply -var-file=example.tfvars
    ```
    
5. Wait until Terraform successfully deploys your cluster + a few minutes, then run the following to get your Kubeconfig file from S3:
    ```bash
    aws s3 cp s3://YOUR_BUCKET_NAME/k3s.yaml ~/.kube/config
    ```

6. You should now be able to interact with your cluster via:
    ```bash
    kubectl get nodes
    ```
    You should see 6 healthy nodes running (unless you've otherwised specified agent/server counts).

7. Lastly, let's check to make sure your ArgoCD pods are running:
    ```bash
    kubectl get deployments -n kube-system | grep argocd
    ```
    You should see all ArgoCD deployments as `1/1`.
    
    

### What Next?

If you're looking to really get into GitOps via ArgoCD, check out the [demo-app](https://github.com/alterus-io/demo-app) for adding a ton of cool tools to this cluster.