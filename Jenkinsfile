pipeline {
    agent any
    parameters { booleanParam(name: 'IS_DEBUG', defaultValue: false, description: 'Debug or Release build') }
    environment {
        // USER CONFIGURATION
        INPUT_FILE = "app-release.aab"; CONFIG_FILE = "bluebeetle_config.bm"
        MACOS_DOWNLOAD_URL = "https://storage.googleapis.com/masst-assets/Defender-Binary-Integrator/1.0.0/MacOS/MASSTCLI-v1.1.0-darwin-arm64.zip"
        LINUX_DOWNLOAD_URL = "https://storage.googleapis.com/masst-assets/Defender-Binary-Integrator/1.0.0/Linux/MASSTCLI-v1.1.0-linux-amd64.zip"
        ANDROID_HOME = "/home/snehal_mane/Android/Sdk"
        KEYSTORE_FILE = "Bluebeetle.jks"; KEYSTORE_PASSWORD = "bugs@1234"; KEY_ALIAS = "key0"; KEY_PASSWORD = "bugs@1234"
        IDENTITY = "Apple Distribution: Bugsmirror Research private limited (BPKUYCFJ74)"
        MASST_DIR = "MASSTCLI_EXTRACTED"; ARTIFACTS_DIR = "output"; MASST_ZIP = "MASSTCLI"
    }
    options { timestamps(); buildDiscarder(logRotator(numToKeepStr: '10')) }
    stages {
        stage('Setup') {
            steps {
                checkout scm
                script {
                    if (isUnix()) {
                        sh '''#!/bin/bash
                            set -e
                            [[ "$(uname)" == "Darwin" ]] && PLATFORM="MacOS" || PLATFORM="Linux"
                            echo "$PLATFORM" > platform.txt
                        '''
                        env.DETECTED_PLATFORM = readFile('platform.txt').trim()
                        env.DOWNLOAD_URL = env.DETECTED_PLATFORM == 'MacOS' ? env.MACOS_DOWNLOAD_URL : env.LINUX_DOWNLOAD_URL
                        sh '''#!/bin/bash
                            set -e
                            [ "${DETECTED_PLATFORM}" = "Linux" ] && export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
                            [ ! -f "${MASST_ZIP}.zip" ] && { curl -L -o "${MASST_ZIP}.zip" "${DOWNLOAD_URL}" || wget -O "${MASST_ZIP}.zip" "${DOWNLOAD_URL}"; }
                            [ -d "${MASST_DIR}" ] && rm -rf "${MASST_DIR}"
                            TEMP=$(mktemp -d) && unzip -q "${MASST_ZIP}.zip" -d "${TEMP}"
                            [ $(find "${TEMP}" -mindepth 1 -maxdepth 1 -type d | wc -l) -eq 1 ] && mv "$(find "${TEMP}" -mindepth 1 -maxdepth 1 -type d)" "${MASST_DIR}" || { mkdir -p "${MASST_DIR}" && mv "${TEMP}"/* "${MASST_DIR}/"; }
                            chmod +x "$(find "${MASST_DIR}" -type f -name "MASSTCLI*")"
                            echo "${DETECTED_PLATFORM} ready"
                        '''
                    }
                }
            }
        }
        stage('Execute') {
            steps {
                script {
                    if (isUnix()) {
                        sh """#!/bin/bash
                            set -e
                            [ "${env.DETECTED_PLATFORM}" = "Linux" ] && export PATH=\$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
                            [ -f "${INPUT_FILE}" ] || { echo "ERROR: ${INPUT_FILE} not found"; exit 1; }
                            [ -f "${CONFIG_FILE}" ] || { echo "ERROR: ${CONFIG_FILE} not found"; exit 1; }
                            MASST_EXE=\$(find "${MASST_DIR}" -type f -name "MASSTCLI*" -print -quit)
                            EXT=\$(echo "${INPUT_FILE}" | awk -F. '{print tolower(\$NF)}')
                            case "\$EXT" in
                                xcarchive|ipa) "\$MASST_EXE" -input="${INPUT_FILE}" -config="${CONFIG_FILE}" -identity="${IDENTITY}" ;;
                                aab|apk) [ "${params.IS_DEBUG}" = "true" ] && "\$MASST_EXE" -input="${INPUT_FILE}" -config="${CONFIG_FILE}" || "\$MASST_EXE" -input="${INPUT_FILE}" -config="${CONFIG_FILE}" -keystore="${KEYSTORE_FILE}" -storePassword=${KEYSTORE_PASSWORD} -alias=${KEY_ALIAS} -keyPassword=${KEY_PASSWORD} -v=true -apk ;;
                                *) echo "ERROR: Unsupported file"; exit 1 ;;
                            esac
                            echo "Build complete"
                        """
                    }
                }
            }
        }
        stage('Archive') {
            steps {
                script {
                    if (isUnix()) {
                        sh """#!/bin/bash
                            mkdir -p "${ARTIFACTS_DIR}"
                            echo "Build: ${env.DETECTED_PLATFORM} | ${params.IS_DEBUG ? 'DEBUG' : 'RELEASE'} | \$(date)" > "${ARTIFACTS_DIR}/report.txt"
                            rm -rf "${MASST_DIR}" "${MASST_ZIP}.zip"
                        """
                    }
                }
                archiveArtifacts artifacts: 'output/**', allowEmptyArchive: true
            }
        }
    }
    post {
        success { echo "${env.DETECTED_PLATFORM} ${params.IS_DEBUG ? 'DEBUG' : 'RELEASE'} - SUCCESS" }
        failure { echo 'Failed' }
    }
}