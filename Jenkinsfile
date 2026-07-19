pipeline {
    agent {
    	label 'redis-build'
    }

    options {
        skipDefaultCheckout(true)
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '10'))
    }

    parameters {
    
        string(
            name: 'GIT_BRANCH',
            defaultValue: 'unstable',
            description: 'Redis branch'
        )
    
        string(
            name: 'GIT_URL',
            defaultValue: 'https://github.com/wyidongh/redis.git'
        )

        string(
            name: 'BUILD_IMAGE_TAG',
            defaultValue: 'redis_build:1.0.1',
            description: '编译镜像标签'
        )
        
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: '是否跳过测试'
        )

    }


    environment {
        IMAGE_TAG = "${params.BUILD_IMAGE_TAG}" 
        APP_NAME = "redis"
        APP_VERSION = "1.0"
        ARTIFACT_HOST = "192.168.79.134"
        ARTIFACT_USER = "dong2"
        ARTIFACT_DIR = "/home/dong2/artifacts"
        // HOST_JENKINS_HOME = "/home/dong/devops/jenkins_home"
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
                        url: "${params.GIT_URL}",
                        branch: "${params.GIT_BRANCH}"
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
		docker run --rm \
		--user $(id -u):$(id -g) \
		-v ${WORKSPACE}:/workspace \
		-w /workspace/redis \
		${IMAGE_TAG} \
		make -j$(nproc)
		'''
	    }
	}


        stage("Test") {
            when {
                expression { !params.SKIP_TESTS }
            }
            steps {
                sh '''
                docker run --rm \
                --user $(id -u):$(id -g) \
                -v ${WORKSPACE}:/workspace \
                -w /workspace/redis \
                ${IMAGE_TAG} \
                make test
                '''
            }
            post {
                always {
                    // 收集测试报告（如果 Redis 生成 junit/xml 格式）
                    // junit 'redis/tests/test-report.xml'
                    
                    // 或者收集日志
                    archiveArtifacts artifacts: 'redis/tests/tmp/**', allowEmptyArchive: true
                }
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
		withEnv([
		    "PACKAGE_NAME=${env.PACKAGE_NAME}",
		    "ARTIFACT_DIR=${env.ARTIFACT_DIR}"
		]) {
		    retry(3) {
			sshagent(credentials: ['dong2-ssh-key']) {
			    sh '''
			    mkdir -p ~/.ssh
			    ssh-keyscan -H "${ARTIFACT_HOST}" >> ~/.ssh/known_hosts 2>/dev/null || true
			    
			    ssh "${ARTIFACT_USER}@${ARTIFACT_HOST}" "mkdir -p ${ARTIFACT_DIR}"
			    
			    scp "$PACKAGE_NAME" "$PACKAGE_NAME.md5" \
				"${ARTIFACT_USER}@${ARTIFACT_HOST}:${ARTIFACT_DIR}/"
			    
			    ssh "${ARTIFACT_USER}@${ARTIFACT_HOST}" "
				cd ${ARTIFACT_DIR} && \
				ln -sf \"$PACKAGE_NAME\" latest.tar.gz && \
				ln -sf \"$PACKAGE_NAME.md5\" latest.tar.gz.md5
			    "
			    '''
			}
		    }
		}
	    }
	}

	stage("Cleanup") {
	    steps {
		withEnv([
		    "ARTIFACT_DIR=${env.ARTIFACT_DIR}",
		    "ARTIFACT_RETENTION=${env.ARTIFACT_RETENTION}"
		]) {
		    sshagent(credentials: ['dong2-ssh-key']) {
			sh '''
			ssh "${ARTIFACT_USER}@${ARTIFACT_HOST}" "
			    cd \"${ARTIFACT_DIR}\" 2>/dev/null || exit 0
			    echo 'Before cleanup:'
			    ls -lt *.tar.gz 2>/dev/null || echo 'No packages'
			    ls -t *.tar.gz | tail -n +$(( ARTIFACT_RETENTION + 1 )) | xargs -r rm -f
			    for f in *.md5; do [ -f \"\\${f%.md5}\" ] || rm -f \"\\$f\" 2>/dev/null; done
			    echo 'After cleanup:'
			    ls -lt *.tar.gz 2>/dev/null || echo 'No packages'
			"
			'''
		    }
		}
	    }
	}


    }

    post {
        success {
            script { currentBuild.description = env.RELEASE_VERSION }
        }
        always {
            script {
                def pkg = env.PACKAGE_NAME
                archiveArtifacts artifacts: "${pkg}, ${pkg}.md5", allowEmptyArchive: true
            }
        }
    }

}
