pipeline {

    agent any


    options {
        skipDefaultCheckout(true)
    }


    environment {

        IMAGE_TAG="redis_build:1.0.1"

        PACKAGE_NAME="redis_1_0_1.tar.gz"

        ARTIFACT_HOST="192.168.79.134"

        ARTIFACT_USER="dong2"

        ARTIFACT_DIR="/home/dong2/artifacts"

	HOST_JENKINS_HOME = "/home/dong/devops/jenkins_home"
    }


    stages {


	stage("Checkout Redis") {
	    steps {
		sh '''
		echo "SkipCheckout Redis"

		'''
	    }
	}	


        stage("Build") {

            steps {

                sh '''

		# 计算宿主机上的绝对路径
                HOST_WORKSPACE="${HOST_JENKINS_HOME}/workspace/${JOB_NAME}"
                echo "Host workspace: $HOST_WORKSPACE"

                docker run --rm \
                -v ${HOST_WORKSPACE}:/workspace \
                -w /workspace \
                ${IMAGE_TAG} \
                make -j$(nproc)

                '''

            }

        }


        stage("Package") {

            steps {

                sh '''

                mkdir -p package/bin

                cp src/redis-server package/bin/
                cp src/redis-cli package/bin/

                tar czf ${PACKAGE_NAME} package

                '''

            }

        }


        stage("Upload Artifact") {
            steps {
                sshagent(credentials: ['dong2-ssh-key']) {
                    sh '''
                    scp -o StrictHostKeyChecking=no \
                    -o UserKnownHostsFile=/dev/null \
                    ${PACKAGE_NAME} \
                    ${ARTIFACT_USER}@${ARTIFACT_HOST}:${ARTIFACT_DIR}
                    '''
                }
            }
        }

    }

    post {
       success {
           echo "CI PIPELINE SUCCESS ✅"
       }
    
       failure {
           echo "CI PIPELINE FAILED ❌"
       }
    
       always {
           echo "Always echo..."
       }
    }

}
