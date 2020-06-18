# VRChat用のUnityProjectを作成するPowershell
# - 2020/06/14 初版
# - 2020/06/15 Powershell 5.x系対応

$UNITY_VERSION = "2018.4.20f1"
$NOWDATE = (Get-Date).ToLocalTime().ToString("yyyyMMdd-HHmmss")
$DOWNLOAD_PATH = "c:\temp\unity.download"
$PROJECT_PATH = "c:\temp\unity.project"
$PREFIX_NAME = "vrchat-"
$DISPLAY_UNITYEDIER = $true 

$DebugPreference = "Continue"
Set-PSDebug -strict

### 保存先の存在チェック
if (split-path $DOWNLOAD_PATH -IsAbsolute) {
    $DOWNLOAD_PATH = (Resolve-Path $DOWNLOAD_PATH).Path
}
if (Test-Path($DOWNLOAD_PATH)) {
    Write-Debug "download path OK: $DOWNLOAD_PATH"
}
else {
    Write-Debug "download path not found: $DOWNLOAD_PATH"
    New-Item -ItemType Directory -Force -Path "$DOWNLOAD_PATH"
    Write-Debug "create download folder: $DOWNLOAD_PATH"
}

# Unity project
if (split-path $PROJECT_PATH -IsAbsolute) {
    $PROJECT_PATH = (Resolve-Path $PROJECT_PATH).Path
}
if (Test-Path($PROJECT_PATH)) {
    Write-Debug "project path OK: $PROJECT_PATH"
}
else {
    Write-Debug "project path not found: $PROJECT_PATH"
    New-Item -ItemType Directory -Force -Path "$PROJECT_PATH"
    Write-Debug "create project folder: $PROJECT_PATH"
}

$recipeInstructionsJson = Get-Content ".\test.json\vrcsdk2-dynbone-uts2-avatar.json" -Encoding UTF8 -Raw | ConvertFrom-Json
# ConvertTo-Json -InputObject $recipeInstructionsJson -Depth 100
# $recipeInstructionsJson.GetType()
# $recipeInstructionsJson | Get-Member
# Exit

###
if ($DISPLAY_UNITYEDIER) {
    $ENABLE_UNITYEDIER_OPTION = " " # スペースがないとPowershell 5.x系でエラー
}
else {
    $ENABLE_UNITYEDIER_OPTION = "-batchmode -nographics" 
}

$projectPath = (Join-Path $PROJECT_PATH $PREFIX_NAME) + $NOWDATE
Write-Debug "unity project path: $projectPath"

### UnityEditor 指定バージョンのインストールチェック
. ".\scripts\vcupUnityEditor.ps1"
$unity = New-Object vcupUnityEditor

$unityPath = $unity.getEditorPath($UNITY_VERSION)
try {
    Write-Debug "create project: begin $projectPath"
    if (Test-Path($unityPath)) {
        if ($unity.createProject($unityPath, $projectPath, $ENABLE_UNITYEDIER_OPTION)) {
            Write-Host "create project: sccuess"
        }
        else {
            throw "unity error."
        }
    }
    else {
        #インストールされてない
        throw "unity none install:$UNITY_VERSION."
    }
    Write-Debug "create project: end"
}
catch {
    Write-Host $Error[0]
    Write-Error "Error: create unity project"
    exit
}

Write-Host "-----"
$recipeInstructionsJson.PSObject.Properties | ForEach-Object {
    # ConvertTo-Json -InputObject $_ -Depth 100

    $targetItem = $_

    switch ($targetItem.Value.source) {
        "VRChat" {
            try {
                Write-Debug "download vrcsdk: begin"

                . ".\scripts\vcupVRChat.ps1"
                $vrchat = New-Object vcupVRChat
                $sdkPackage = $vrchat.getSdkVersion($targetItem.Value.url)
                Write-Debug "download vrcsdk: $sdkPackage"
                if (-not ($vrchat.getSdkFile($targetItem.Value.url, $DOWNLOAD_PATH, $sdkPackage))) {
                    throw "download vrcsdk: download error"
                }

                $sdkPath = Join-Path $DOWNLOAD_PATH $sdkPackage
                if ($unity.importPackageToProject($unityPath, $projectPath, $ENABLE_UNITYEDIER_OPTION, $sdkPath)) {
                    Write-Host " import package: $targetItem.name"
                }
                else { 
                    throw "unity package import error."
                }
                Write-Debug "download vrcsdk: end"
                Write-Host "---"
            }
            catch {
                Write-Host $Error[0]
                Write-Error "Error: download vrcsdk"
                exit
            }
        }
        "AssetStore" {
            try {
                Write-Debug "download assetstore: begin"

                $assetStorePath = Join-Path $env:APPDATA "\Unity\Asset Store-5.x"

                $tempName = $targetItem.Value.file.Replace('\\', '\')
                $packagePath = Join-Path $assetStorePath $tempName
                Write-Debug "download assetstore: $packagePath"

                if ((Test-Path($packagePath))) {
                    if ($unity.importPackageToProject($unityPath, $projectPath, $ENABLE_UNITYEDIER_OPTION, $packagePath)) {
                        Write-Host " import package: $targetItem.Name ($packagePath)"
                    }
                    else {
                        throw "unity package import error. $targetItem.Name"
                    }
                }
                else {
                    if (($targetItem.Value.RequiredCondition) -eq "required") {
                        throw "unity package not found. $targetItem.Name"
                    }
                }
                Write-Debug "download assetstore: end"
                Write-Host "---"
            }
            catch {
                Write-Host $Error[0]
                Write-Error "Error: download assetstore"
                exit
            }
        }
        "Github" {
            try {
                Write-Debug "download github: begin"
                . ".\scripts\vcupGithub.ps1"
                $github = New-Object vcupGithub
                                
                $ghFile = $github.getFileInfo($targetItem.Value)
                Write-Debug ("download github: ghFile.name {0} / {1}" -f $ghFile.name, $ghFile.url)

                if ($github.getGithubFile($ghFile, $DOWNLOAD_PATH)) {
                    $packagePath = Join-Path $DOWNLOAD_PATH $ghFile.name
                    Write-Debug "download github: $packagePath"

                    if ((Test-Path($packagePath))) {
                        if ($unity.importPackageToProject($unityPath, $projectPath, $ENABLE_UNITYEDIER_OPTION, $packagePath)) {
                            Write-Host " import package: $targetItem.Name ($packagePath)"
                        }
                        else {
                            throw "unity package import error. $targetItem.Name"
                        }
                    }
                    else {
                        if (($targetItem.Value.RequiredCondition) -eq "required") {
                            throw "unity package not found. $targetItem.Name"
                        }
                    }
                }
                Write-Debug "download github: end"
                Write-Host "---"
            }
            catch {
                Write-Host $Error[0]
                Write-Error "Error: download github"
                exit
            }

        }
        "localzip" {
            Write-Debug ("localzip: begin: " + $targetItem.Value.zipfile)
            
            # unzip
            if (Test-Path($targetItem.Value.zipfile)) {
                # $zipfilename = Split-Path $targetItem.Value.zipfile -Leaf
                Expand-Archive -Path $targetItem.Value.zipfile -DestinationPath $DOWNLOAD_PATH -Force
            }

            $packagePath = Join-Path $DOWNLOAD_PATH $targetItem.Value.packagefile
            if (Test-Path($packagePath)) {
                if ($unity.importPackageToProject($unityPath, $projectPath, $ENABLE_UNITYEDIER_OPTION, $packagePath)) {
                    Write-Host (" import package: {0}({1})" -f $targetItem.Name, $targetItem.Value.zipfile)
                }
                else {
                    throw "unity package import error. $targetItem.Value.zipfile"
                }
            }
            Write-Debug "localzip: end"
        }

        Default {
            $targetItem
        }
    }
}
Set-PSDebug -Off
Write-Host "Complete !"
exit