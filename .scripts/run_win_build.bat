:: PLEASE NOTE: This script has been automatically generated by conda-smithy. Any changes here
:: will be lost next time ``conda smithy rerender`` is run. If you would like to make permanent
:: changes to this script, consider a proposal to conda-smithy so that other feedstocks can also
:: benefit from the improvement.

:: INPUTS (required environment variables)
:: CONFIG: name of the .ci_support/*.yaml file for this job
:: CI: azure, github_actions, or unset
:: MINIFORGE_HOME: where to install the base conda environment
:: UPLOAD_PACKAGES: true or false
:: UPLOAD_ON_BRANCH: true or false

setlocal enableextensions enabledelayedexpansion
if "%MINIFORGE_HOME%"=="" (
    FOR %%A IN ("%~dp0.") DO SET "MINIFORGE_HOME=%%~dpA"
)
:: Remove trailing backslash, if present
if "%MINIFORGE_HOME:~-1%"=="\" set "MINIFORGE_HOME=%MINIFORGE_HOME:~0,-1%"
call :start_group "Provisioning base env with pixi"
echo Installing pixi
powershell -NoProfile -ExecutionPolicy unrestricted -Command "iwr -useb https://pixi.sh/install.ps1 | iex"
if !errorlevel! neq 0 exit /b !errorlevel!
set "PATH=%USERPROFILE%\.pixi\bin;%PATH%"
echo Installing environment
mkdir "%MINIFORGE_HOME%"
copy pixi.toml "%MINIFORGE_HOME%"
pushd "%MINIFORGE_HOME%"
set "PIXI_CACHE_DIR=%MINIFORGE_HOME%"
pixi install
if !errorlevel! neq 0 exit /b !errorlevel!
pixi list
if !errorlevel! neq 0 exit /b !errorlevel!
popd
call :end_group

call :start_group "Configuring conda"

:: Activate the base conda environment
echo Activating environment
set "ACTIVATE_PIXI=%TMP%\pixi-activate-%RANDOM%.bat"
pixi shell-hook --manifest-path "%MINIFORGE_HOME%\pixi.toml" > "%ACTIVATE_PIXI%"
call "%ACTIVATE_PIXI%"
:: Configure the solver
set "CONDA_SOLVER=libmamba"
if !errorlevel! neq 0 exit /b !errorlevel!
set "CONDA_LIBMAMBA_SOLVER_NO_CHANNELS_FROM_INSTALLED=1"

:: Set basic configuration
echo Setting up configuration
setup_conda_rc .\ ".\recipe" .\.ci_support\%CONFIG%.yaml
if !errorlevel! neq 0 exit /b !errorlevel!
echo Running build setup
CALL run_conda_forge_build_setup


if !errorlevel! neq 0 exit /b !errorlevel!

if EXIST LICENSE.txt (
    echo Copying feedstock license
    copy LICENSE.txt "recipe\\recipe-scripts-license.txt"
)
if NOT [%HOST_PLATFORM%] == [%BUILD_PLATFORM%] (
    if [%CROSSCOMPILING_EMULATOR%] == [] (
        set "EXTRA_CB_OPTIONS=%EXTRA_CB_OPTIONS% --no-test"
    )
)

if NOT [%flow_run_id%] == [] (
        set "EXTRA_CB_OPTIONS=%EXTRA_CB_OPTIONS% --extra-meta flow_run_id=%flow_run_id% remote_url=%remote_url% sha=%sha%"
)

call :end_group

:: Build the recipe
echo Building recipe
conda-build.exe "recipe" -m .ci_support\%CONFIG%.yaml --suppress-variables %EXTRA_CB_OPTIONS%
if !errorlevel! neq 0 exit /b !errorlevel!

call :start_group "Inspecting artifacts"
:: inspect_artifacts was only added in conda-forge-ci-setup 4.9.4
WHERE inspect_artifacts >nul 2>nul && inspect_artifacts --recipe-dir ".\recipe" -m .ci_support\%CONFIG%.yaml || echo "inspect_artifacts needs conda-forge-ci-setup >=4.9.4"
call :end_group

:: Prepare some environment variables for the upload step
if /i "%CI%" == "github_actions" (
    set "FEEDSTOCK_NAME=%GITHUB_REPOSITORY:*/=%"
    set "GIT_BRANCH=%GITHUB_REF:refs/heads/=%"
    if /i "%GITHUB_EVENT_NAME%" == "pull_request" (
        set "IS_PR_BUILD=True"
    ) else (
        set "IS_PR_BUILD=False"
    )
    set "TEMP=%RUNNER_TEMP%"
)
if /i "%CI%" == "azure" (
    set "FEEDSTOCK_NAME=%BUILD_REPOSITORY_NAME:*/=%"
    set "GIT_BRANCH=%BUILD_SOURCEBRANCHNAME%"
    if /i "%BUILD_REASON%" == "PullRequest" (
        set "IS_PR_BUILD=True"
    ) else (
        set "IS_PR_BUILD=False"
    )
    set "TEMP=%UPLOAD_TEMP%"
)

:: Validate
call :start_group "Validating outputs"
validate_recipe_outputs "%FEEDSTOCK_NAME%"
if !errorlevel! neq 0 exit /b !errorlevel!
call :end_group

if /i "%UPLOAD_PACKAGES%" == "true" (
    if /i "%IS_PR_BUILD%" == "false" (
        call :start_group "Uploading packages"
        if not exist "%TEMP%\" md "%TEMP%"
        set "TMP=%TEMP%"
        upload_package --validate --feedstock-name="%FEEDSTOCK_NAME%" .\ ".\recipe" .ci_support\%CONFIG%.yaml
        if !errorlevel! neq 0 exit /b !errorlevel!
        call :end_group
    )
)

exit

:: Logging subroutines

:start_group
if /i "%CI%" == "github_actions" (
    echo ::group::%~1
    exit /b
)
if /i "%CI%" == "azure" (
    echo ##[group]%~1
    exit /b
)
echo %~1
exit /b

:end_group
if /i "%CI%" == "github_actions" (
    echo ::endgroup::
    exit /b
)
if /i "%CI%" == "azure" (
    echo ##[endgroup]
    exit /b
)
exit /b