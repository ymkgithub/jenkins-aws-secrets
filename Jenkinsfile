pipeline {
    agent any

    tools {
        terraform 'terraform' // Ensure Terraform is correctly configured in Jenkins
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'stage', 'prod'], description: 'Select the environment')
        booleanParam(name: 'DESTROY', defaultValue: false, description: 'Check to destroy resources')
    }

    environment {
        TF_ENV = "${params.ENVIRONMENT}" // Use environment variable for workspace
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/ymkgithub/jenkins-aws-secrets.git' // Your Git repository
            }
        }

        stage('Fetch Workspace Variables') {
            steps {
                withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws-cred', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        def secretId = "${TF_ENV}/drupal/secrets"
                        sh """
                            aws secretsmanager get-secret-value --secret-id ${secretId} --query SecretString --output text > terraform-${TF_ENV}.json
                        """
                    }
                }
            }
        }

        stage('Terraform Init') {
            when {
                expression {
                    return !params.DESTROY
                }
            }
            steps {
                withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws-cred', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        sh """
                            terraform init
                        """
                    }
                }
            }
        }

        stage('workspace selection') {
            steps {
                withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws-cred', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        sh """
                            terraform workspace select ${TF_ENV} || terraform workspace new ${TF_ENV}
                            terraform validate
                        """
                    }
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression {
                    return !params.DESTROY
                }
            }
            steps {
                script {
                    sh """
                        terraform plan -var-file=terraform-${TF_ENV}.json -out=tfplan
                    """
                }
            }
        }

        stage('Plan Confirmation') {
            when {
                expression {
                    return !params.DESTROY
                }
            }
            steps {
                script {
                    def userInput = input(
                        id: 'userInput', 
                        message: "Are you sure you want to execute this plan in the '${TF_ENV}' environment workspace?",
                        parameters: [[$class: 'BooleanParameterDefinition', name: 'Confirm', defaultValue: false]]
                    )

                    if (!userInput) {
                        error("User aborted the pipeline.")
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression {
                    return !params.DESTROY
                }
            }
            steps {
                script {
                    sh """
                        terraform apply -auto-approve tfplan
                    """
                }
            }
        }

        // Plan for destroy
        stage('Terraform Plan (Destroy)') {
            when {
                expression {
                    return params.DESTROY
                }
            }
            steps {
                script {
                    sh """
                        terraform plan -var-file=terraform-${TF_ENV}.json -destroy -out=tf-destroy-plan
                    """
                }
            }
        }

        stage('Destroy Confirmation') {
            when {
                expression {
                    return params.DESTROY
                }
            }
            steps {
                script {
                    input message: "Are you sure you want to destroy resources in the '${TF_ENV}' workspace?",
                          ok: "Yes, Destroy"
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression {
                    return params.DESTROY
                }
            }
            steps {
                withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws-cred', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        sh """
                            terraform apply -auto-approve tf-destroy-plan
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean up the terraform-{TF_ENV}.json file
            sh """
                rm -rf terraform-${TF_ENV}.json
            """
        }
    }
}
