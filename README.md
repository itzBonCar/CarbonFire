**Repo Structure**

- ansible/
  - ansible.cfg
  - inventory/aws_ec2.yml
  - playbook.yml
  - roles/
    - app/
      - tasks/main.yml
    - redis/
      - tasks/main.yml
- scripts/
  - bootstrap_backend.sh
- terraform/
  - backend.tf
  - main.tf
  - modules/
  - variables.tf
  - outputs.tf
  - terraform.tfvars
- Jenkinsfile

Overview

- This repository provides a one-click pipeline (Jenkins) that:
- Bootstraps Terraform remote state (S3 native lockfile)
- Runs `terraform apply` to create VPC, subnets (2 public, 2 app private, 2 middleware private), NAT Gateway(s), ALB, a bastion host, and Auto Scaling Groups for app and redis in `us-east-1`
- Uses Ansible (AWS dynamic inventory `aws_ec2` plugin) to configure application and Redis (Redis + Sentinels)

High-level execution workflow (one click)

1. Jenkins job triggers pipeline (Jenkinsfile).
2. Pipeline runs `scripts/bootstrap_backend.sh` to create the S3 bucket if missing.
3. Terraform init/plan/apply creates infra (state stored in S3, using S3 native lockfile).
4. Pipeline reads the bastion public IP from Terraform output.
5. Pipeline runs Ansible through the bastion over SSH to configure `Role=redis` hosts first (install Redis, start), then `Role=app` hosts (deploy test app that demonstrates Redis connectivity).
6. Demo: curl ALB DNS name to exercise app which uses Redis.

Prerequisites
- Jenkins with agents that have Terraform, Ansible, Python, AWS CLI installed (or run Jenkins controller with those tools).
- AWS CLI configured with credentials allowed to create VPC, EC2, S3, ALB, IAM, AutoScaling, etc.
- An existing AWS EC2 key pair named `carbonfire-key`, or update `EC2_KEY_NAME` in `Jenkinsfile`.
- Matching private key available on the Jenkins agent at `${WORKSPACE}/carbonfire-key.pem`, or update `ANSIBLE_PRIVATE_KEY_FILE` in `Jenkinsfile`.
- GitHub repo connected to Jenkins or Jenkins can checkout this repository.

Security / Best practice notes
- For production, run Jenkins agents in cloud (shared runners with IAM roles). For a local quick demo, a local Jenkins with AWS credentials works.
- Secure S3 bucket via least-privilege IAM in real deployments.
- Restrict `ssh_ingress_cidr` to your public IP instead of leaving the demo default `0.0.0.0/0`.

Quick demo commands (local)

1. Bootstrap backend (creates S3 bucket):

```bash
./scripts/bootstrap_backend.sh my-tf-state-bucket-name us-east-1
```

2. From `terraform/` run:

```bash
terraform init
terraform apply -auto-approve \
  -var="state_bucket=my-tf-state-bucket-name" \
  -var="key_name=carbonfire-key" \
  -var="ssh_ingress_cidr=<your-public-ip>/32"
```

3. Run Ansible from repo root:

```bash
BASTION_PUBLIC_IP="$(terraform -chdir=terraform output -raw bastion_public_ip)"
AWS_REGION=us-east-1 \
BASTION_PUBLIC_IP="${BASTION_PUBLIC_IP}" \
ANSIBLE_PRIVATE_KEY_FILE=/path/to/carbonfire-key.pem \
ansible-playbook -i ansible/inventory/aws_ec2.yml ansible/playbook.yml
```

4. Grab ALB DNS from Terraform outputs and curl it to test.
# CarbonFire
Node Application focused on highlighting Redis wonders
