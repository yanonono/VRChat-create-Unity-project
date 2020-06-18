class vcupVRChat {

    # VRCSDK2のバージョン取得
    [string] getSdkVersion ($url) {
        try {
            Write-Debug "vcupVRChat.getSdkVersion: begin"

            $curlResult = curl.exe -si $url
            $temp_name = ""
            foreach ($str in $curlResult.Split(" ")) {
                if ($str -like "https://files.vrchat.cloud/sdk/*_Public.unitypackage") {
                    $temp_name = $str.Split('/')
                }
            }
            $targetSdk = $temp_name[-1]
            Write-Debug "vcupVRChat.getSdkVersion: $targetSdk"
            Write-Debug "vcupVRChat.getSdkVersion: end"
            return  $targetSdk
        }
        catch {
            Write-Error $Error[0]
        }
        return $null
    }

    # VRCSDK2 ダウンロード処理
    [bool] getSdkFile ($url, $downloadPath, $sdkPackage) {
        Write-Debug "vcupVRChat.getSdkFile: begin"
        # 保存先の確認
        if (-not (Test-Path($downloadPath))) {
            Write-Error " Error download path: $downloadPath"
            return $false
        }

        try {
            $filepath = Join-Path $downloadPath $sdkPackage
            if (Test-Path($filepath)) {
                Write-Debug "skip vrchat sdk2 download."
            }
            else {
                Invoke-WebRequest $url -OutFile $filepath
                Write-Debug " vrchat sdk2 download complete."
            }
            Write-Debug "vcupVRChat.getSdkFile: end"
            return $true
        }
        catch {
            Write-Error " error: vrchat sdk2 download."
            Write-Error $error[0]
        }
        return $false
    }
}