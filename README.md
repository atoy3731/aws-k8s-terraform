## AWS K8S Terraform

This is a project containing Terraform IaC to get a scalable Kubernetes cluster up and running in AWS with ArgoCD deployed to it.

### Prerequisites

* Terraform CLI
* An AWS account with Admin Permissions
* Your AWS credentials configured via Environment Variables or `~/.aws/credentials` file.
* Kubectl CLI

### How Do I Work It?

Right now, we only support a K3S deployment model using RDS as a backend store. Eventually we'll expand to EKS.

1. Navigate to the `k3s` directory: 
    ```bash
    cd k3s
    ```

2. Create an S3 bucket in the AWS console to persist Terraform state. This gives you a highly reliable way to maintain your state file.

3. Update the `bucket` entry in both `backends/s3.tfvars` and `main.tf` files with the name of you bucket from the previous step.

4. (Optional) If you want to maintain multiple Terraform states, you can create/select separate workspaces. This will create separate files within your S3 bucket, so you can maintain multiple environments at once:
   ```bash
   # Create a new workspace
   terraform workspace new staging

   # Or select and switch to an existing workspace
   terraform workspace select staging
   ```

5. Update the `example.tfvars`:
   * _db_username_: The master username for the RDS cluster.
   * _db_password_: The master password for the RDS cluster (you should actually not store this in a file and enter it when you apply your Terraform, but leaving it here for simplicity's sake.)
   * _public_ssh_key_: Set this to the public SSH key you're going to use to SSH to boxes. It is usually in `~/.ssh/id_rsa.pub` on your system.
   * _keypair_name_: The name of the keypair to store your public SSH key.
   * _key_s3_bucket_name_: The S3 bucket to store the K3S kubeconfig file. (**NOTE**: This needs to be GLOBALLY UNIQUE across AWS.)
   
6. Initialize Terraform with the S3 backend:
    ```bash
    terraform init -backend-config=backends/s3.tfvars
    ```

7. Apply terraform (you'll need to type 'yes'):
    ```bash
    terraform apply -var-file=example.tfvars
    ```
    
8. Wait until Terraform successfully deploys your cluster + a few minutes, then run the following to get your Kubeconfig file from S3:
    ```bash
    aws s3 cp s3://YOUR_BUCKET_NAME/k3s.yaml ~/.kube/config
    ```

9. You should now be able to interact with your cluster via:
    ```bash
    kubectl get nodes
    ```
    You should see 6 healthy nodes running (unless you've otherwised specified agent/server counts).

10. Lastly, let's check to make sure your ArgoCD pods are running:
    ```bash
    kubectl get deployments -n kube-system | grep argocd
    ```
    You should see all ArgoCD deployments as `1/1`.

### Destroying your cluster

To destroy a cluster, you need to first go to your AWS console, the EC2 service, and click on Load Balancers.  There will be an ELB that the Kubernetes cloud provider created but isn't managed by Terraform that you need to clean up. You also need to delete the Security Group that that ELB is using.   

After you've cleaned the ELB up, run the following and type "yes" when prompted:
```bash
terraform destroy -var-file=example.tfvars
```

### What Next?

If you're looking to really get into GitOps via ArgoCD, check out the [demo-app](https://github.com/atoy3731/k8s-tools-app) for adding a ton of cool tools to this cluster.
