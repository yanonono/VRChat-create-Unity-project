class vcupUnityEditor {

    $TIMEOUT = 180

    [string] getEditorPath($version) {
        Write-Debug "vcupUnityEditor.getEditorPath: begin"
        $unityPath = Join-Path $env:ProgramFiles "Unity\Hub\Editor\$version\Editor\Unity.exe"
        Write-Debug "vcupUnityEditor.getEditorPath: end"
        return $unityPath
    }

    # 新規プロジェクト作成
    [bool] createProject($unityPath, $projectPath, $unityOptions) {
        Write-Debug "vcupUnityEditor.createProject: begin"
        Write-Debug ("vcupUnityEditor.createProject: timeout: " + $this.TIMEOUT)

        Write-Debug "vcupUnityEditor.createProject: unity path: $unityPath"

        $unityOptionParameters = @(
            "-createProject `"$projectPath`" ",
            "-quit",
            $unityOptions
        )
        Write-Debug "vcupUnityEditor.createProject: unity options: $unityOptionParameters"

        try {
            $proc = begin-Process `"$unityPath`" -ArgumentList $unityOptionParameters -PassThru

            $timeouted = $null 
            Wait-Process -InputObject $proc -Timeout $this.TIMEOUT -ErrorAction SilentlyContinue -ErrorVariable timeouted
            if ($timeouted) {
                Write-Debug "vcupUnityEditor.createProject: timeout"
                return $false
            }
            if ($proc.ExitCode -ne 0) {
                Write-Debug "vcupUnityEditor.createProject: unityeditor runtime error"
                return $false
            }
        }
        catch {
            Write-Error $Error
            return $false
        }

        Write-Debug "vcupUnityEditor.createProject: end"
        return $true
    }

    [bool] importPackageToProject($unityPath, $projectPath, $unityOptions, $packagePath) {
        Write-Debug "vcupUnityEditor.importPackageToProject: begin"
        Write-Debug ("vcupUnityEditor.importPackageToProject: timeout: " + $this.TIMEOUT)

        Write-Debug "vcupUnityEditor.importPackageToProject: packagePath: $packagePath"
        if (-not (Test-Path($packagePath))) {
            return $false
        }

        $unityOptionParameters = @(
            "-projectPath `"$projectPath`" ",
            "-importPackage `"$packagePath`" ",
            "-quit",
            $unityOptions
        )
        Write-Debug "vcupUnityEditor.importPackageToProject: unity options: $unityOptionParameters"

        try {
            $proc = begin-Process `"$unityPath`" -ArgumentList $unityOptionParameters -PassThru

            $timeouted = $null 
            Wait-Process -InputObject $proc -Timeout $this.TIMEOUT -ErrorAction SilentlyContinue -ErrorVariable timeouted
            if ($timeouted) {
                Write-Debug "vcupUnityEditor.importPackageToProject: timeout"
                return $false
            }
            if ($proc.ExitCode -ne 0) {
                Write-Debug "vcupUnityEditor.importPackageToProject: unityeditor runtime error"
                return $false
            }
        }
        catch {
            Write-Error $Error
            return $false
        }

        Write-Debug "vcupUnityEditor.importPackageToProject: end"
        return $true
    }
}