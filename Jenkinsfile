pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '10'))
    }

    environment {
        IMAGE_TAG = "redis_build:1.0.1"
        APP_NAME = "redis"
        APP_VERSION = "1.0"
        ARTIFACT_HOST = "192.168.79.134"
        ARTIFACT_USER = "dong2"
        ARTIFACT_DIR = "/home/dong2/artifacts"
        HOST_JENKINS_HOME = "/home/dong/devops/jenkins_home"
        ARTIFACT_RETENTION = "10"  // ← 补上
    }

    stages {
        stage("Clean Workspace") {
            steps {
                cleanWs()
            }
        }

        stage("Checkout Redis") {
            steps {
                dir("redis") {
                    git(
                        url: "https://github.com/wyidongh/redis.git",
                        branch: "unstable"
                    )
                    script {
                        // 设置到 env，确保跨 stage 可用
                        env.GIT_COMMIT_ID = sh(
                            script: "git rev-parse --short=7 HEAD",
                            returnStdout: true
                        ).trim()
                        echo "Git Commit: ${env.GIT_COMMIT_ID}"
                    }
                }
            }
        }

        stage("Generate Version") {
            steps {
                script {
                    // 必须用 env. 前缀，否则 Groovy 可能找不到
                    env.RELEASE_VERSION = "${env.APP_VERSION}.${env.BUILD_NUMBER}-${env.GIT_COMMIT_ID}"
                    env.PACKAGE_NAME = "${env.APP_NAME}-${env.RELEASE_VERSION}.tar.gz"
                    
                    echo "RELEASE_VERSION: ${env.RELEASE_VERSION}"
                    echo "PACKAGE_NAME: ${env.PACKAGE_NAME}"
                }
            }
        }

        stage("Build") {
            steps {
                sh '''
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
		script {
		    def buildInfo = """{
	    "app": "${env.APP_NAME}",
	    "version": "${env.RELEASE_VERSION}",
	    "git_commit": "${env.GIT_COMMIT_ID}",
	    "build_number": "${env.BUILD_NUMBER}",
	    "build_image": "${env.IMAGE_TAG}",
	    "build_time": "${new Date().format('yyyy-MM-dd HH:mm:ss')}",
	    "builder": "Jenkins"
	}"""
		    writeFile file: 'package/build-info.json', text: buildInfo
		}
		
		sh """
		mkdir -p package/bin
		cp redis/src/redis-server package/bin/
		cp redis/src/redis-cli package/bin/
		
		echo "Packaging: ${env.PACKAGE_NAME}"
		tar czf ${env.PACKAGE_NAME} package
		md5sum ${env.PACKAGE_NAME} > ${env.PACKAGE_NAME}.md5
		ls -lh ${env.PACKAGE_NAME}
		"""
	    }
	}

        stage("Check Artifact") {
            steps {
                sh """
                echo "Current directory: \$(pwd)"
                echo "Files:"
                ls -lh
                echo "Package:"
                ls -lh ${env.PACKAGE_NAME}
                """
            }
        }

        stage("Upload") {
            steps {
                retry(3) {
                    sshagent(credentials: ['dong2-ssh-key']) {
                        sh """
                        mkdir -p ~/.ssh
                        ssh-keyscan -H ${env.ARTIFACT_HOST} >> ~/.ssh/known_hosts 2>/dev/null || true
                        
                        remote_dir="${env.ARTIFACT_DIR}"
                        ssh ${env.ARTIFACT_USER}@${env.ARTIFACT_HOST} "mkdir -p \${remote_dir}"
                        
                        scp ${env.PACKAGE_NAME} ${env.PACKAGE_NAME}.md5 \
                            ${env.ARTIFACT_USER}@${env.ARTIFACT_HOST}:\${remote_dir}/
                        
                        ssh ${env.ARTIFACT_USER}@${env.ARTIFACT_HOST} "
                            cd \${remote_dir} && \
                            ln -sf ${env.PACKAGE_NAME} latest.tar.gz && \
                            ln -sf ${env.PACKAGE_NAME}.md5 latest.tar.gz.md5
                        "
                        """
                    }
                }
            }
        }

        stage("Cleanup") {
            steps {
                sshagent(credentials: ['dong2-ssh-key']) {
                    sh """
                    ssh ${env.ARTIFACT_USER}@${env.ARTIFACT_HOST} "
                        cd ${env.ARTIFACT_DIR} 2>/dev/null || exit 0
                        echo 'Before cleanup:'
                        ls -lt *.tar.gz 2>/dev/null || echo 'No packages'
                        ls -t *.tar.gz | tail -n +$(( ${env.ARTIFACT_RETENTION} + 1 )) | xargs -r rm -f
                        for f in *.md5; do [ -f \\\"\\${f%.md5}\\\" ] || rm -f \\\"\\$f\\\" 2>/dev/null; done
                        echo 'After cleanup:'
                        ls -lt *.tar.gz 2>/dev/null || echo 'No packages'
                    "
                    """
                }
            }
        }
    }

    post {
        success {
            script { currentBuild.description = "${env.RELEASE_VERSION}" }
        }
        always {
            archiveArtifacts artifacts: "${env.PACKAGE_NAME}, ${env.PACKAGE_NAME}.md5", allowEmptyArchive: true
        }
    }
}
