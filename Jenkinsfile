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
        TF_WORKSPACE = "${params.ENVIRONMENT}" // Use environment variable for workspace
    }

    stages {
        stage('Terraform Init & Plan') {
            steps {
                withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws-cred', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        sh """
                            terraform init
                            terraform workspace select ${TF_WORKSPACE} || terraform workspace new ${TF_WORKSPACE}
                            terraform fmt
                            terraform validate
                        """
                    }
                }
            }
        }

        stage('Fetch Workspace Variables') {
            steps {
                withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws-cred', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        def secretId = "${TF_WORKSPACE}/drupal/secrets"
                        sh """
                            aws secretsmanager get-secret-value --secret-id ${secretId} --query SecretString --output text > terraform-${TF_WORKSPACE}.tfvars
                        """
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    sh """
                        terraform plan -var-file=terraform-${TF_WORKSPACE}.tfvars -out=tfplan
                    """
                }
            }
        }

        stage('Plan Confirmation') {
            steps {
                script {
                    def userInput = input(
                        id: 'userInput', 
                        message: "Are you sure you want to execute this plan in the '${TF_WORKSPACE}' environment workspace?",
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

        stage('Destroy Confirmation') {
            when {
                expression {
                    return params.DESTROY
                }
            }
            steps {
                script {
                    input message: "Are you sure you want to destroy resources in the '${TF_WORKSPACE}' workspace?",
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
                            terraform destroy -var-file=terraform-${TF_WORKSPACE}.tfvars -auto-approve
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
