pipeline {
  agent any

  stages {
    stage('Atualizar Terraform') {
        steps {
            sh 'cd /var/lib/jenkins/ && git clone https://github.com/rfrezende/criar_infraestrutura.git'
        }
    }
    stage('Terraform Init') {
        steps {
            sh 'cd /var/lib/jenkins/criar_infraestrutura && terraform init'
        }
    }
    stage('Terraform Destroy') {
      steps {
          sh 'cd /var/lib/jenkins/criar_infraestrutura && terraform destroy -auto-approve'
      }
    }
    stage('Terraform Apply') {
      steps {
          sh 'cd /var/lib/jenkins/criar_infraestrutura && terraform apply -auto-approve'
      }
    }
  }
  post {
    always {
      sh 'docker logout'
      sh 'rm -r /var/lib/jenkins/criar_infraestrutura'
    }
  }
}
