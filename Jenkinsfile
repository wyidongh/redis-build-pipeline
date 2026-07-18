pipeline {

    agent any

    
    // 禁止Jenkins自动拉取代码（checkout scm), 手动stage checkout
    options {
        skipDefaultCheckout(true)
	timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '10'))
    }


    environment {

        IMAGE_TAG="redis_build:1.0.1"

	APP_NAME="redis"

    	APP_VERSION="1.0"

        ARTIFACT_HOST="192.168.79.134"

        ARTIFACT_USER="dong2"

        ARTIFACT_DIR="/home/dong2/artifacts"

	HOST_JENKINS_HOME = "/home/dong/devops/jenkins_home"
    }


    stages {
	
	// 开始checkout代码之前先清除workspace
        stage("Clean Workspace") {

            steps {

                cleanWs()

            }
        }


        stage("Checkout Redis") {

            steps {

                dir("redis") {

                    git(
                      url:"https://github.com/wyidongh/redis.git",
                      branch:"unstable"
                    )

		    script {

			env.GIT_COMMIT_ID = sh(
			    script:"git rev-parse --short HEAD",
			    returnStdout:true
			).trim()


			echo "Git Commit: ${env.GIT_COMMIT_ID}"

		    }

                }
		
            }
	}



	stage("Generate Version") {

	    steps {

		script {

		    env.RELEASE_VERSION =
		    "${APP_VERSION}.${BUILD_NUMBER}-${GIT_COMMIT_ID}"


		    env.PACKAGE_NAME =
		    "${APP_NAME}-${RELEASE_VERSION}.tar.gz"


		    echo """
		    Release Version:
		    ${RELEASE_VERSION}

		    Package:
		    ${PACKAGE_NAME}
		    """

		}

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
                -w /workspace/redis \
                ${IMAGE_TAG} \
                make -j$(nproc)

                '''

            }

        }


        stage("Package") {

            steps {

                sh '''

                mkdir -p package/bin

                cp redis/src/redis-server package/bin/
                cp redis/src/redis-cli package/bin/

		cat > package/build-info.json <<EOF
		{
		    "app": "${APP_NAME}",
		    "version": "${RELEASE_VERSION}",
		    "git_commit": "${GIT_COMMIT_ID}",
		    "build_number": "${BUILD_NUMBER}",
		    "build_image": "${IMAGE_TAG}",
		    "build_time": "$(date '+%Y-%m-%d %H:%M:%S')",
		    "builder": "Jenkins"
		}
		EOF

                tar czf ${PACKAGE_NAME} package
		md5sum ${PACKAGE_NAME} > ${PACKAGE_NAME}.md5
                '''

            }

        }

        stage("Upload") {
            steps {
                retry(3) {
                    sshagent(credentials: ['dong2-ssh-key']) {
                        sh '''
                        mkdir -p ~/.ssh
                        ssh-keyscan -H ${ARTIFACT_HOST} >> ~/.ssh/known_hosts 2>/dev/null || true
                        
                        remote_dir="${ARTIFACT_DIR}/${UPSTREAM_VERSION}"
                        ssh ${ARTIFACT_USER}@${ARTIFACT_HOST} "mkdir -p ${remote_dir}"
                        
                        scp ${PACKAGE_NAME} ${PACKAGE_NAME}.md5 \
                            ${ARTIFACT_USER}@${ARTIFACT_HOST}:${remote_dir}/
                        
                        ssh ${ARTIFACT_USER}@${ARTIFACT_HOST} "
                            cd ${remote_dir} && \
                            ln -sf ${PACKAGE_NAME} latest.tar.gz && \
                            ln -sf ${PACKAGE_NAME}.md5 latest.tar.gz.md5
                        "
                        '''
                    }
                }
            }
        }

        stage("Cleanup") {
            steps {
                sshagent(credentials: ['dong2-ssh-key']) {
                    sh '''
                    ssh ${ARTIFACT_USER}@${ARTIFACT_HOST} "
                        cd ${ARTIFACT_DIR}/${UPSTREAM_VERSION} 2>/dev/null || exit 0
                        ls -t *.tar.gz | tail -n +$(( ${ARTIFACT_RETENTION} + 1 )) | xargs -r rm -f
                        for f in *.md5; do [ -f \"\${f%.md5}\" ] || rm -f \"\$f\" 2>/dev/null; done
                    "
                    '''
                }
            }
        }

    }

    post {
        success {
            script { currentBuild.description = "${VERSION}" }
        }
        always {
            archiveArtifacts artifacts: "${PACKAGE_NAME}, ${PACKAGE_NAME}.md5", allowEmptyArchive: true
        }
    }

}
