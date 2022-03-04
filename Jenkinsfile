pipeline {
    agent any
        environment {
            DEV_URL     = 'https://dev.ericpereyra.com/'
            QA_URL  = 'https://qa.ericpereyra.com/'
            STAGE_URL    = 'https://prod.ericpereyra.com/'
            DEV_PORT    = '8181'
            QA_PORT = '8182'
            STAGE_PORT   = '8183'
            JEN_TEST_URL= 'https://agile-qk.com/jenkins/generic-webhook-trigger/invoke'
            COMMKEY = credentials('commtok')
        }
    stages {
        stage('Clean env') {
            steps{
                script{
                    def names = ['ena-dev','ena-qa','ena-stage']
                    for (int i = 0; i < names.size(); i++){
                        containers = sh(script: "docker container ls -q -f name=\"${names[i]}\"", returnStdout: true).trim()
                        if (containers != ''){
                        echo "Container for ${names[i]} found with the ID: ${containers}, removing..."
                        sh "docker stop ${names[i]}"
                        }else{
                        echo "No running container for ${names[i]}."
                        }
                    }
                    //sh "docker builder prune -a -f"
                    sh "docker system prune -a -f"
                    sh "rm -f -R allure-results"
                    sh "mkdir allure-results"
                }
            }
        }
        stage('Lint Test') {
            steps {
                echo 'LTEST'
            }
        }
        stage('Unit Test') {
            steps {
                echo 'ITEST'
            }
        }
        stage('Integration Test'){
            steps{
                sh 'echo $PATH'
            }
        }
        stage('Dev e2e Test'){
            steps{
                parallel(
                    a: {
                        sh "npm install"
                        sh "npm run start:dev -- --port ${DEV_PORT}"
                    },
                    b: {
                        script {
                            hook = registerWebhook()
                                def response = httpRequest url:"${env.JEN_TEST_URL}?token=${env.COMMKEY}",
                                    customHeaders:[
                                        [ name:'Returnurl', value:"${hook.getURL()}"],
                                        [ name:'Testurl', value:"${env.DEV_URL}"],
                                        [ name:'Buildurl', value:"${env.BUILD_URL}"],
                                        [ name:'Buildid', value:"${env.BUILD_ID}"],
                                        [ name:'Buildnumber', value:"${env.BUILD_NUMBER}"]
                                    ],
                                    httpMode: 'POST'
                            data = waitForWebhook webhookToken:hook
                            retry(3) {
                                sleep 10
                                def quit = httpRequest url:"${env.DEV_URL}/quit", httpMode: 'POST'
                            }
                            timeout(time: 1, unit: 'MINUTES') {
                                println("Pimed-out...")
                            }
                        }
                    }
                )
            }
        }
        stage('QA e2e Test'){
            steps{
                parallel(
                    a: {
                        sh "npm install"
                        sh "npm run start:dev -- --port ${QA_PORT}"
                    },
                    b: {
                        script {
                            hook = registerWebhook()
                                def response = httpRequest url:"${env.JEN_TEST_URL}?token=${env.COMMKEY}",
                                    customHeaders:[
                                        [ name:'Returnurl', value:"${hook.getURL()}"],
                                        [ name:'Testurl', value:"${env.QA_URL}"],
                                        [ name:'Buildurl', value:"${env.BUILD_URL}"],
                                        [ name:'Buildid', value:"${env.BUILD_ID}"],
                                        [ name:'Buildnumber', value:"${env.BUILD_NUMBER}"]
                                    ],
                                    httpMode: 'POST'
                                data = waitForWebhook hook
                            retry(3) {
                                sleep 10
                                def quit = httpRequest url:"${env.QA_URL}/quit", httpMode: 'POST'
                                println("${quit.status}")
                            }
                            timeout(time: 1, unit: 'MINUTES') {
                                println("Pimed-out...")
                            }
                        }
                    }
                )
            }
        }
        stage('Stage e2e Test'){
            steps{
                parallel(
                    a: {
                        sh "npm install"
                        sh "npm run start:dev -- --port ${STAGE_PORT}"
                    },
                    b: {
                        script {
                            hook = registerWebhook()
                                def response = httpRequest url:"${env.JEN_TEST_URL}?token=${env.COMMKEY}",
                                    customHeaders:[
                                        [ name:'Returnurl', value:"${hook.getURL()}"],
                                        [ name:'Testurl', value:"${env.STAGE_URL}"],
                                        [ name:'Buildurl', value:"${env.BUILD_URL}"],
                                        [ name:'Buildid', value:"${env.BUILD_ID}"],
                                        [ name:'Buildnumber', value:"${env.BUILD_NUMBER}"]
                                    ],
                                    httpMode: 'POST'
                                data = waitForWebhook hook
                            retry(3) {
                                sleep 10
                                def quit = httpRequest url:"${env.STAGE_URL}/quit", httpMode: 'POST'
                                println("${quit.status}")
                            }
                            timeout(time: 1, unit: 'MINUTES') {
                                println("Pimed-out...")
                            }
                        }
                    }
                )
            }
        }
        stage('Build docker images'){
            steps{
                sh "docker build -t ena-dev-build ."
                sh "docker build -t ena-qa-build ."
                sh "docker build -t ena-stage-build ."
            }
        }
        stage('DEV docker deploy'){
            steps{
                sh "docker run --name ena-dev -p ${DEV_PORT}:8080 -d ena-dev-build"
            }
        }
        stage('QA docker deploy'){
            steps{
                sh "docker run --name ena-qa -p ${QA_PORT}:8080 -d ena-qa-build"
            }
        }
        stage('STAGE / PROD docker deploy'){
            steps{
                sh "docker run --name ena-stage -p ${STAGE_PORT}:8080 -d ena-stage-build"
            }
        }
    }
}
