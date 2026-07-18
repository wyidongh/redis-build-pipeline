pipeline {

    agent any
    environment {
    	IMAGE_NAME = "redis_build"
	VERSION = "1_0_1"	
	IMAGE_TAG = "${IMAGE_NAME}:${VERSION}"
	PACKAGE_NAME = "redis_${VERSION}.tar.gz"
	ARTIFACT_HOST = "192.168.79.134"
	ARTIFACT_USER = "dong2"
	ARTIFACT_DIR = "/home/${ARTIFACT_USER}/artifacts"
    }

    stages {

        stage("Checkout") {

            steps {

                git 'https://github.com/redis/redis.git'

            }

        }

	
        stage("Build") {

            steps {
		sh '''
		docker run --rm \
		-v $WORKSPACE:/workspace \
		-w /workspace \
		${IMAGE_TAG}
		make -j$(nproc)
		'''
            }
	}


        stage("Package") {

            steps {

		sh '''
		mkdir -p package/bin \
		cp src/redis-server package/bin/
                cp src/redis-cli package/bin/
	
                tar czf $PACKAGE_NAME package
		'''
            }

        }


        stage("Archive") {

            steps {

		sh '''
                scp $PACKAGE_NAME $ARTIFACT_USER@$ARTIFACT_HOST:$ARTIFACT_DIR
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
