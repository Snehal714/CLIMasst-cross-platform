pipeline {
    agent any

    environment {
        MASST_DIR = "MASSTCLI_EXTRACTED"
        ARTIFACTS_DIR = "."
        CONFIG_FILE = "config.bm"
        MASST_ZIP = "MASSTCLI"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Extract MASSTCLI') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    echo 'Extracting MASSTCLI from workspace...'
                    bat '''
                        if not exist "%MASST_DIR%" (
                            echo Extracting MASSTCLI.zip from workspace...

                            if not exist "%WORKSPACE%\\%MASST_ZIP%.zip" (
                                echo ERROR: MASSTCLI.zip not found in workspace!
                                echo Contents of workspace:
                                dir /b "%WORKSPACE%"
                                exit /b 1
                            )

                            echo Extracting to temporary location to avoid path length issues...
                            powershell -Command "$ProgressPreference = 'SilentlyContinue'; if (Test-Path 'C:\\temp\\masstcli_extract') { Remove-Item 'C:\\temp\\masstcli_extract' -Recurse -Force -ErrorAction SilentlyContinue }; New-Item -ItemType Directory -Path 'C:\\temp\\masstcli_extract' -Force | Out-Null; Expand-Archive -LiteralPath '%WORKSPACE%\\%MASST_ZIP%.zip' -DestinationPath 'C:\\temp\\masstcli_extract' -Force"

                            echo Moving extracted files to workspace...
                            powershell -Command "$extractedFolder = Get-ChildItem -Path 'C:\\temp\\masstcli_extract' -Directory | Select-Object -First 1; if ($extractedFolder) { Move-Item -Path $extractedFolder.FullName -Destination '%WORKSPACE%\\%MASST_DIR%' -Force } else { echo 'ERROR: No folder found in extracted archive'; exit 1 }"

                            echo Cleaning up temporary files...
                            powershell -Command "if (Test-Path 'C:\\temp\\masstcli_extract') { Remove-Item 'C:\\temp\\masstcli_extract' -Recurse -Force -ErrorAction SilentlyContinue }"

                        ) else (
                            echo MASSTCLI already extracted, skipping extraction
                        )
                    '''
                }
            }
        }

        stage('Verify MASSTCLI') {
            steps {
                echo 'Verifying MASSTCLI installation...'
                bat '''
                    echo Searching for MASSTCLI executable...

                    set MASST_EXE=
                    for %%f in ("%MASST_DIR%\\MASSTCLI*.exe") do (
                        set MASST_EXE=%%~nxf
                        echo Found executable: %%~nxf
                        goto :found_exe
                    )

                    :found_exe
                    if not defined MASST_EXE (
                        echo ERROR: No MASSTCLI executable found in %MASST_DIR%!
                        echo Contents of extraction directory:
                        dir /s /b "%MASST_DIR%"
                        exit /b 1
                    )

                    REM Verify executable exists and is accessible
                    if exist "%MASST_DIR%\\%MASST_EXE%" (
                        echo.
                        echo ========================================
                        echo ✅ MASSTCLI extracted and verified successfully
                        echo Executable: %MASST_EXE%
                        echo Location: %MASST_DIR%
                        echo ========================================
                    ) else (
                        echo ERROR: MASSTCLI executable file not accessible!
                        exit /b 1
                    )
                '''
            }
        }

        stage('Run MASSTCLI') {
            steps {
                powershell 'pwsh scripts/masst-scan.ps1'
                echo 'Running MASSTCLI with configuration and input file...'
                bat '''
                    setlocal EnableDelayedExpansion
                    set "MASST_EXE="
                    for %%f in ("%MASST_DIR%\\MASSTCLI*.exe") do (
                        set "MASST_EXE=%%~nxf"
                        goto :found_exe
                    )

                    :found_exe
                    if "!MASST_EXE!"=="" (
                        echo ERROR: No MASSTCLI executable found in %MASST_DIR%!
                        endlocal
                        exit /b 1
                    )

                    if not exist "%WORKSPACE%\\MyApp.aab" (
                        echo ERROR: Input file MyApp.aab not found in workspace!
                        echo Contents of workspace:
                        dir /b "%WORKSPACE%"
                        endlocal
                        exit /b 1
                    )

                    echo Running MASSTCLI with input and config...
                    "%MASST_DIR%\\!MASST_EXE!" -input "%WORKSPACE%\\MyApp.aab" -config "%WORKSPACE%\\%CONFIG_FILE%"

                    endlocal
                '''
            }
        }
    }
    post {
        success {
            echo 'MASSTCLI pipeline completed successfully!'
        }
        failure {
            echo 'MASSTCLI pipeline failed. Please check the logs above.'
        }
        always {
            echo 'Cleaning up temporary files...'
            bat '''
                powershell -Command "if (Test-Path 'C:\\temp\\masstcli_extract') { Remove-Item 'C:\\temp\\masstcli_extract' -Recurse -Force -ErrorAction SilentlyContinue }"
            '''
        }
    }
}