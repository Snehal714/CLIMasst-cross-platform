pipeline {
    agent any

    parameters {
        booleanParam(
            name: 'IS_DEBUG',
            defaultValue: false,
            description: 'Check for debug build (simple command), uncheck for release build (with keystore signing)'
        )
    }

    environment {
        MASST_DIR = "MASSTCLI_EXTRACTED"
        ARTIFACTS_DIR = "output"
        CONFIG_FILE = "masst_config.bm"
        MASST_ZIP = "MASSTCLI"
        DOWNLOAD_URL = "https://storage.googleapis.com/masst-assets/Defender-Binary-Integrator/1.0.0/Linux/MASSTCLI-v1.1.0-linux-amd64.zip"
        INPUT_FILE = "demoApp.aab"
        KEYSTORE_FILE = "shruti-key.jks"
        KEYSTORE_PASSWORD = "Bugsmirror@123"
        KEY_ALIAS = "key0"
        KEY_PASSWORD = "Bugsmirror@123"

        // Android SDK paths
        ANDROID_HOME = "/home/snehal_mane/Android/Sdk"
        ANDROID_SDK_ROOT = "/home/snehal_mane/Android/Sdk"
    }

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout & Prepare') {
            steps {
                checkout scm
                script {
                    if (isUnix()) {
                        sh '''#!/bin/bash
                            set -e

                            # Source environment
                            export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

                            # Download MASSTCLI if not present
                            if [ ! -f "${WORKSPACE}/${MASST_ZIP}.zip" ]; then
                                echo "Downloading MASSTCLI..."
                                curl -L --progress-bar -o "${WORKSPACE}/${MASST_ZIP}.zip" "${DOWNLOAD_URL}" || \
                                wget -O "${WORKSPACE}/${MASST_ZIP}.zip" "${DOWNLOAD_URL}" || exit 1
                            fi
                            echo "✅ MASSTCLI.zip ready"
                        '''
                    } else {
                        bat '''
                            if not exist "%WORKSPACE%\\%MASST_ZIP%.zip" (
                                powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%WORKSPACE%\\%MASST_ZIP%.zip' -ErrorAction Stop"
                            )
                            echo ✅ MASSTCLI.zip ready
                        '''
                    }
                }
            }
        }

        stage('Extract & Verify') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        if (isUnix()) {
                            sh '''#!/bin/bash
                                set -e

                                [ -d "${WORKSPACE}/${MASST_DIR}" ] && exit 0

                                TEMP=$(mktemp -d)
                                unzip -q "${WORKSPACE}/${MASST_ZIP}.zip" -d "${TEMP}"

                                if [ $(find "${TEMP}" -mindepth 1 -maxdepth 1 -type d | wc -l) -eq 1 ]; then
                                    mv "$(find "${TEMP}" -mindepth 1 -maxdepth 1 -type d | head -1)" "${WORKSPACE}/${MASST_DIR}"
                                else
                                    mkdir -p "${WORKSPACE}/${MASST_DIR}"
                                    mv "${TEMP}"/* "${WORKSPACE}/${MASST_DIR}/" 2>/dev/null || true
                                fi

                                chmod +x "$(find "${MASST_DIR}" -type f -name "MASSTCLI*" | head -1)"
                                echo "✅ MASSTCLI extracted and verified"
                            '''
                        } else {
                            bat '''
                                if exist "%MASST_DIR%" exit /b 0

                                set "TEMP=C:\\temp\\masst_%RANDOM%"
                                powershell -Command "New-Item -ItemType Directory -Path '!TEMP!' -Force | Out-Null; Expand-Archive -LiteralPath '%WORKSPACE%\\%MASST_ZIP%.zip' -DestinationPath '!TEMP!' -Force"

                                for /d %%%%d in ("!TEMP!\\*") do move "%%%%d" "%WORKSPACE%\\%MASST_DIR%"
                                echo ✅ MASSTCLI extracted and verified
                            '''
                        }
                    }
                }
            }
        }

        stage('Validate & Execute') {
            steps {
                script {
                    def isDebug = params.IS_DEBUG

                    if (isUnix()) {
                        sh """#!/bin/bash
                            set -e

                            # Set Android environment
                            export PATH=\$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

                            # Validate input files exist
                            [ -f "${WORKSPACE}/${INPUT_FILE}" ] || { echo "ERROR: ${INPUT_FILE} not found"; exit 1; }
                            [ -f "${WORKSPACE}/${CONFIG_FILE}" ] || { echo "ERROR: ${CONFIG_FILE} not found"; exit 1; }

                            # Find MASSTCLI executable
                            MASST_EXE=\$(find "${MASST_DIR}" -type f -name "MASSTCLI*" -print -quit)
                            [ -x "\${MASST_EXE}" ] || { echo "ERROR: MASSTCLI executable not found or not executable"; exit 1; }

                            INPUT_PATH="${WORKSPACE}/${INPUT_FILE}"
                            CONFIG_PATH="${WORKSPACE}/${CONFIG_FILE}"

                            # Detect input extension (case-insensitive)
                            case "\$(echo "${INPUT_FILE}" | awk -F. '{print tolower(\$NF)}')" in
                                xcarchive|ipa)
                                    echo "=========================================="
                                    echo "MASSTCLI Execution Configuration (IDENTITY)"
                                    echo "=========================================="
                                    echo "  Input: \${INPUT_PATH}"
                                    echo "  Config: \${CONFIG_PATH}"
                                    echo ""
                                    echo "🔐 Using Apple identity for both DEBUG and RELEASE"
                                    echo ""
                                    "\${MASST_EXE}" -input="\${INPUT_PATH}" -config="\${CONFIG_PATH}" -identity="Apple Distribution: My Company" || exit 1
                                    ;;
                                *)
                                    echo "=========================================="
                                    echo "MASSTCLI Execution Configuration"
                                    echo "=========================================="
                                    echo "  Build Mode: ${isDebug ? 'DEBUG' : 'RELEASE'}"
                                    echo "  Input: \${INPUT_PATH}"
                                    echo "  Config: \${CONFIG_PATH}"
                                    echo ""

                                    if [ "${isDebug}" = "true" ]; then
                                        echo "🔧 Running in DEBUG mode (simple command)..."
                                        echo ""
                                        "\${MASST_EXE}" -input="\${INPUT_PATH}" -config="\${CONFIG_PATH}" || exit 1
                                    else
                                        echo "🚀 Running in RELEASE mode (with keystore signing)..."
                                        echo ""
                                        KEYSTORE_PATH="${WORKSPACE}/${KEYSTORE_FILE}"
                                        [ -f "\${KEYSTORE_PATH}" ] || { echo "ERROR: Keystore file not found at \${KEYSTORE_PATH}"; exit 1; }

                                        echo "  Keystore: \${KEYSTORE_PATH}"
                                        echo "  Alias: ${KEY_ALIAS}"
                                        echo ""

                                        "\${MASST_EXE}" -input="\${INPUT_PATH}" \
                                            -config="\${CONFIG_PATH}" \
                                            -keystore="\${KEYSTORE_PATH}" \
                                            -storePassword=${KEYSTORE_PASSWORD} \
                                            -alias=${KEY_ALIAS} \
                                            -keyPassword=${KEY_PASSWORD} \
                                            -v=true -apk || exit 1
                                    fi
                                    ;;
                            esac

                            echo ""
                            echo "✅ MASSTCLI completed successfully"
                        """
                    } else {
                        bat """
                            setlocal enabledelayedexpansion

                            if not exist "%WORKSPACE%\\%INPUT_FILE%" (
                                echo ERROR: %INPUT_FILE% not found
                                exit /b 1
                            )
                            if not exist "%WORKSPACE%\\%CONFIG_FILE%" (
                                echo ERROR: %CONFIG_FILE% not found
                                exit /b 1
                            )

                            for /r "%MASST_DIR%" %%%%f in (MASSTCLI*.exe) do (
                                set "MASST_EXE=%%%%f"
                                set "INPUT_PATH=%WORKSPACE%\\%INPUT_FILE%"
                                set "CONFIG_PATH=%WORKSPACE%\\%CONFIG_FILE%"

                                for %%A in ("!INPUT_PATH!") do set "EXT=%%~xA"
                                if /I "!EXT!"==".xcarchive" (
                                    echo ==========================================
                                    echo MASSTCLI Execution Configuration (IDENTITY)
                                    echo ==========================================
                                    echo   Input: !INPUT_PATH!
                                    echo   Config: !CONFIG_PATH!
                                    echo.
                                    echo 🔐 Using Apple identity for both DEBUG and RELEASE
                                    echo.
                                    "!MASST_EXE!" -input="!INPUT_PATH!" -config="!CONFIG_PATH!" -identity="Apple Distribution: My Company" || exit /b 1
                                    endlocal
                                    exit /b 0
                                ) else if /I "!EXT!"==".ipa" (
                                    echo ==========================================
                                    echo MASSTCLI Execution Configuration (IDENTITY)
                                    echo ==========================================
                                    echo   Input: !INPUT_PATH!
                                    echo   Config: !CONFIG_PATH!
                                    echo.
                                    echo 🔐 Using Apple identity for both DEBUG and RELEASE
                                    echo.
                                    "!MASST_EXE!" -input="!INPUT_PATH!" -config="!CONFIG_PATH!" -identity="Apple Distribution: My Company" || exit /b 1
                                    endlocal
                                    exit /b 0
                                ) else (
                                    echo ==========================================
                                    echo MASSTCLI Execution Configuration
                                    echo ==========================================
                                    echo   Build Mode: ${isDebug ? 'DEBUG' : 'RELEASE'}
                                    echo   Input: !INPUT_PATH!
                                    echo   Config: !CONFIG_PATH!
                                    echo.

                                    if "${isDebug}"=="true" (
                                        echo 🔧 Running in DEBUG mode (simple command)...
                                        echo.
                                        "!MASST_EXE!" -input=!INPUT_PATH! -config=!CONFIG_PATH! || exit /b 1
                                        endlocal
                                        exit /b 0
                                    ) else (
                                        echo 🚀 Running in RELEASE mode (with keystore signing)...
                                        echo.
                                        set "KEYSTORE_PATH=%WORKSPACE%\\%KEYSTORE_FILE%"

                                        if not exist "!KEYSTORE_PATH!" (
                                            echo ERROR: Keystore file not found at !KEYSTORE_PATH!
                                            exit /b 1
                                        )

                                        echo   Keystore: !KEYSTORE_PATH!
                                        echo   Alias: %KEY_ALIAS%
                                        echo.

                                        "!MASST_EXE!" -input=!INPUT_PATH! ^
                                            -config=!CONFIG_PATH! ^
                                            -keystore=!KEYSTORE_PATH! ^
                                            -storePassword=%KEYSTORE_PASSWORD% ^
                                            -alias=%KEY_ALIAS% ^
                                            -keyPassword=%KEY_PASSWORD% ^
                                            -v=true || exit /b 1
                                        endlocal
                                        exit /b 0
                                    )
                                )
                            )
                            echo ERROR: MASSTCLI executable not found
                            exit /b 1
                        """
                    }
                }
            }
        }

        stage('Archive & Report') {
            steps {
                script {
                    def buildMode = params.IS_DEBUG ? 'DEBUG' : 'RELEASE'

                    if (isUnix()) {
                        sh """#!/bin/bash
                            REPORT="${WORKSPACE}/${ARTIFACTS_DIR}/build_report.txt"

                            {
                                echo "MASSTCLI Build Report"
                                echo "===================================================="
                                echo "Job: ${JOB_NAME} | Build: ${BUILD_NUMBER}"
                                echo "Build Mode: ${buildMode}"
                                echo "Timestamp: \$(date '+%Y-%m-%d %H:%M:%S')"
                                echo ""
                                echo "Input Files:"
                                [ -f "${WORKSPACE}/${INPUT_FILE}" ] && echo "  ${INPUT_FILE}: \$(stat -f%z "${WORKSPACE}/${INPUT_FILE}" 2>/dev/null || stat -c%s "${WORKSPACE}/${INPUT_FILE}") bytes"
                                [ -f "${WORKSPACE}/${CONFIG_FILE}" ] && echo "  ${CONFIG_FILE}: \$(stat -f%z "${WORKSPACE}/${CONFIG_FILE}" 2>/dev/null || stat -c%s "${WORKSPACE}/${CONFIG_FILE}") bytes"
                                echo ""
                                echo "Output Files:"
                                find "${WORKSPACE}/${ARTIFACTS_DIR}" -type f ! -name "build_report.txt" | while read file; do
                                    echo "  \$(basename "\$file"): \$(stat -f%z "\$file" 2>/dev/null || stat -c%s "\$file") bytes"
                                done
                                echo ""
                                echo "Status: SUCCESS"
                                echo "===================================================="
                            } > "\${REPORT}"

                            cat "\${REPORT}"
                        """
                    } else {
                        bat """
                            setlocal enabledelayedexpansion
                            set "REPORT=%WORKSPACE%\\%ARTIFACTS_DIR%\\build_report.txt"

                            (
                                echo MASSTCLI Build Report
                                echo ====================================================
                                echo Job: %JOB_NAME% - Build: %BUILD_NUMBER%
                                echo Build Mode: ${buildMode}
                                echo Timestamp: %DATE% %TIME%
                                echo.
                                echo Input Files:
                                echo   %INPUT_FILE%
                                echo   %CONFIG_FILE%
                                echo.
                                echo Output Files:
                                for %%%%f in (%WORKSPACE%\\%ARTIFACTS_DIR%\\*) do (
                                    if not "%%%%~nxf"=="build_report.txt" echo   %%%%~nxf: %%%%~zf bytes
                                )
                                echo.
                                echo Status: SUCCESS
                                echo ====================================================
                            ) > "!REPORT!"

                            type "!REPORT!"
                            endlocal
                        """
                    }
                }
                archiveArtifacts artifacts: 'output/**', allowEmptyArchive: false, fingerprint: true, onlyIfSuccessful: true
            }
        }

        stage('Cleanup MASSTCLI') {
            steps {
                script {
                    if (isUnix()) {
                        sh '''#!/bin/bash
                            set -e
                            echo "Cleaning up MASSTCLI..."

                            # Delete extracted directory
                            if [ -d "${WORKSPACE}/${MASST_DIR}" ]; then
                                echo "Deleting ${MASST_DIR}..."
                                rm -rf "${WORKSPACE}/${MASST_DIR}"
                            fi

                            # Delete zip file
                            if [ -f "${WORKSPACE}/${MASST_ZIP}.zip" ]; then
                                echo "Deleting ${MASST_ZIP}.zip..."
                                rm -f "${WORKSPACE}/${MASST_ZIP}.zip"
                            fi

                            echo "✅ Cleanup completed - MASSTCLI zip and extracted directory removed"
                        '''
                    } else {
                        bat '''
                            echo Cleaning up MASSTCLI...

                            REM Delete extracted directory
                            if exist "%WORKSPACE%\\%MASST_DIR%" (
                                echo Deleting %MASST_DIR%...
                                rmdir /s /q "%WORKSPACE%\\%MASST_DIR%"
                            )

                            REM Delete zip file
                            if exist "%WORKSPACE%\\%MASST_ZIP%.zip" (
                                echo Deleting %MASST_ZIP%.zip...
                                del /q "%WORKSPACE%\\%MASST_ZIP%.zip"
                            )

                            echo ✅ Cleanup completed - MASSTCLI zip and extracted directory removed
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                def buildMode = params.IS_DEBUG ? 'DEBUG' : 'RELEASE'
                echo "✅ Pipeline completed successfully - ${buildMode} build"
            }
        }
        failure {
            echo '❌ Pipeline failed - check logs above'
        }
        always {
            echo 'Build finished. Artifacts available in Jenkins.'
        }
    }
}