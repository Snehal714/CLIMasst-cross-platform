pipeline {
    agent any
    parameters {
        booleanParam(name: 'IS_DEBUG', defaultValue: false, description: 'Debug or Release build')
        choice(name: 'SHIELD_LEVEL', choices: ['1', '2', '3'], description: 'Protection level (1=Basic, 2=Standard, 3=Advanced)')
    }
    environment {
        INPUT_FILE = "app-release.aab"
        CONFIG_FILE = "bluebeetle_config.bm"
        MACOS_URL = "https://storage.googleapis.com/masst-assets/Defender-Binary-Integrator/1.0.0/MacOS/MASSTCLI-v1.1.0-darwin-arm64.zip"
        LINUX_URL = "https://storage.googleapis.com/masst-assets/Defender-Binary-Integrator/1.0.0/Linux/MASSTCLI-v1.1.0-linux-amd64.zip"
        ANDROID_HOME = "/home/snehal_mane/Android/Sdk"
        KEYSTORE_FILE = "Bluebeetle.jks"
        KEYSTORE_PASSWORD = "bugs@1234"
        KEY_ALIAS = "key0"
        KEY_PASSWORD = "bugs@1234"
        IDENTITY = "Apple Distribution: Bugsmirror Research private limited (BPKUYCFJ74)"
        MASST_DIR = "MASSTCLI_EXTRACTED"
        ARTIFACTS_DIR = "output"
        MASST_ZIP = "MASSTCLI"
    }
    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    stages {
        stage('Setup') {
            steps {
                checkout scm
                script {
                    sh '''#!/bin/bash
                        set -e
                        [[ "$(uname)" == "Darwin" ]] && URL="${MACOS_URL}" || URL="${LINUX_URL}"
                        [ ! -f "${MASST_ZIP}.zip" ] && { curl -fsSL -o "${MASST_ZIP}.zip" "$URL" || wget -q -O "${MASST_ZIP}.zip" "$URL"; }
                        rm -rf "${MASST_DIR}"
                        unzip -qo "${MASST_ZIP}.zip" -d tmp && mv tmp/*/* "${MASST_DIR}" 2>/dev/null || mv tmp/* "${MASST_DIR}"
                        chmod +x "${MASST_DIR}"/MASSTCLI*
                        rm -rf tmp
                    '''
                }
            }
        }
        stage('Execute') {
            steps {
                sh """#!/bin/bash
                    set -e
                    export PATH=\$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
                    [ -f "${INPUT_FILE}" ] && [ -f "${CONFIG_FILE}" ] || { echo "ERROR: Input files missing"; exit 1; }
                    MASST_EXE="${MASST_DIR}/\$(ls ${MASST_DIR} | grep MASSTCLI | head -1)"
                    EXT="\${INPUT_FILE##*.}"

                    echo "Using Shield Level: ${params.SHIELD_LEVEL}"

                    case "\${EXT,,}" in
                        xcarchive|ipa)
                            printf "%s\\n" "${params.SHIELD_LEVEL}" | "\$MASST_EXE" -input="${INPUT_FILE}" -config="${CONFIG_FILE}" -identity="${IDENTITY}" ;;
                        aab|apk)
                            if [ "${params.IS_DEBUG}" = "true" ]; then
                                printf "%s\\n" "${params.SHIELD_LEVEL}" | "\$MASST_EXE" -input="${INPUT_FILE}" -config="${CONFIG_FILE}"
                            else
                                printf "%s\\n" "${params.SHIELD_LEVEL}" | "\$MASST_EXE" -input="${INPUT_FILE}" -config="${CONFIG_FILE}" -keystore="${KEYSTORE_FILE}" -storePassword="${KEYSTORE_PASSWORD}" -alias="${KEY_ALIAS}" -keyPassword="${KEY_PASSWORD}" -v=true -apk
                            fi ;;
                        *) echo "ERROR: Unsupported file type: \${EXT}"; exit 1 ;;
                    esac
                """
            }
        }
        stage('Archive') {
            steps {
                sh '''#!/bin/bash
                    mkdir -p "${ARTIFACTS_DIR}"
                    echo "Build: $(uname) | Shield: ${SHIELD_LEVEL} | ${IS_DEBUG} | $(date '+%Y-%m-%d %H:%M:%S')" > "${ARTIFACTS_DIR}/report.txt"
                    rm -rf "${MASST_DIR}" "${MASST_ZIP}.zip"
                '''
                archiveArtifacts artifacts: 'output/**', allowEmptyArchive: true
            }
        }
    }
    post {
        success { echo "✅ Shield Level ${params.SHIELD_LEVEL} | ${params.IS_DEBUG ? 'DEBUG' : 'RELEASE'} build completed" }
        failure { echo "❌ Build failed" }
    }
}