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
    TF_VAR_region = "${AWS_REGION}"
    TF_VAR_state_bucket = "${TF_STATE_BUCKET}"
    TF_VAR_key_name = "${EC2_KEY_NAME}"
    TF_CLI_ARGS_init = "-input=false -backend-config=\"bucket=${TF_STATE_BUCKET}\" -backend-config=\"region=${AWS_REGION}\""
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
    stage('Build and Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker build -t itzboncar/carbonfire:${BUILD_NUMBER} -t itzboncar/carbonfire:latest app/
            docker push itzboncar/carbonfire:${BUILD_NUMBER}
            docker push itzboncar/carbonfire:latest
          '''
        }
      }
    }
    stage('Terraform Init & Apply') {
      steps {
        withAWS(credentials: 'canberry-aws', region: "${AWS_REGION}") {
          dir("${TF_DIR}") {
            sh 'terraform init -reconfigure'
            sh 'terraform apply -auto-approve'
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
              echo "Querying instance IDs for role: $role..."
              IDS=$(aws ec2 describe-instances \
                --region "${AWS_REGION}" \
                --filters "Name=tag:Project,Values=carbonfire" "Name=tag:Role,Values=${role}" "Name=instance-state-name,Values=running" \
                --query "Reservations[*].Instances[*].InstanceId" \
                --output text)
              
              if [ -n "$IDS" ]; then
                echo "Waiting for instance status OK for: $IDS"
                aws ec2 wait instance-status-ok \
                  --region "${AWS_REGION}" \
                  --instance-ids $IDS
              else
                echo "No running instances found for role: $role"
              fi
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
