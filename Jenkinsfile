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

    }


    stages {


	stage("Checkout Redis") {
	    steps {
		sh '''
		echo "SkipCheckout Redis"

		'''
	    }
	}	

	stage("Debug") {
	    steps {
		sh '''
		echo "==== workspace ===="
		pwd

		echo "==== ls ===="
		ls -al

		echo "==== find Makefile ===="
		find . -name Makefile
		'''
	    }
	}


        stage("Build") {

            steps {

                sh '''

                docker run --rm \
                -v $WORKSPACE:/workspace \
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

                sh '''

                scp ${PACKAGE_NAME} \
                ${ARTIFACT_USER}@${ARTIFACT_HOST}:${ARTIFACT_DIR}

                '''

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
