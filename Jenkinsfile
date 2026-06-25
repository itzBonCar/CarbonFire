pipeline {
  agent any
  environment {
    AWS_REGION = 'us-east-1'
    TF_STATE_BUCKET = 'carbonfire-terraform-state-bucket-unique'
    EC2_KEY_NAME = 'canbor-kp'
    TF_DIR = 'terraform'
    ANSIBLE_DIR = 'ansible'
    ANSIBLE_LOCAL_TEMP = "${WORKSPACE}/.ansible/tmp"
    ANSIBLE_REMOTE_TEMP = "/tmp/.ansible/tmp"
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Bootstrap backend') {
      steps {
        withAWS(credentials: 'canberry-aws', region: "${AWS_REGION}") {
          sh 'bash scripts/bootstrap_backend.sh "${TF_STATE_BUCKET}" "${AWS_REGION}"'
        }
      }
    }
    stage('Upload App Bundle to S3') {
      steps {
        withAWS(credentials: 'canberry-aws', region: "${AWS_REGION}") {
          sh '''
            set -eu
            tar -czf app.tar.gz -C app .
            aws s3 cp app.tar.gz "s3://${TF_STATE_BUCKET}/app-bundle/app.tar.gz"
            rm app.tar.gz
          '''
        }
      }
    }
    stage('Terraform Init & Apply') {
      steps {
        withAWS(credentials: 'canberry-aws', region: "${AWS_REGION}") {
          dir("${TF_DIR}") {
            sh 'terraform init -input=false -reconfigure -backend-config="bucket=${TF_STATE_BUCKET}" -backend-config="region=${AWS_REGION}"'
            sh 'terraform apply -auto-approve -var="state_bucket=${TF_STATE_BUCKET}" -var="region=${AWS_REGION}" -var="key_name=${EC2_KEY_NAME}"'
          }
        }
      }
    }
    stage('Wait for EC2 instances') {
      steps {
        withAWS(credentials: 'canberry-aws', region: "${AWS_REGION}") {
          sh '''
            set -eu
            for role in bastion redis app; do
              aws ec2 wait instance-status-ok \
                --region "${AWS_REGION}" \
                --filters "Name=tag:Project,Values=carbonfire" "Name=tag:Role,Values=${role}" "Name=instance-state-name,Values=running"
            done
          '''
        }
      }
    }
    stage('Run Ansible') {
      steps {
        withAWS(credentials: 'canberry-aws', region: "${AWS_REGION}") {
          withCredentials([sshUserPrivateKey(credentialsId: 'canbor-ssh-key', keyFileVariable: 'ANSIBLE_KEY')]) {
            dir("${ANSIBLE_DIR}") {
              sh 'ansible-galaxy collection install amazon.aws community.docker || true'
              sh '''
                set -eu
                BASTION_PUBLIC_IP="$(terraform -chdir="../${TF_DIR}" output -raw bastion_public_ip)"
                AWS_REGION="${AWS_REGION}" \
                BASTION_PUBLIC_IP="${BASTION_PUBLIC_IP}" \
                ANSIBLE_PRIVATE_KEY_FILE="${ANSIBLE_KEY}" \
                ansible-playbook -i inventory/aws_ec2.yml playbook.yml -vv
              '''
            }
          }
        }
      }
    }
  }
  post {
    always {
      echo 'Pipeline finished'
    }
  }
}
