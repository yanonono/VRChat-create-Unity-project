class vcupGithub {

    # GitHub上のバージョンやファイル情報を取得。
    [PSCustomObject[]] getFileInfo($repoTarget) {
        try {
            Write-Debug "vcupGithub.getFileInfo: begin"
            Write-Debug "vcupGithub.getFileInfo: repoTarget, $repoTarget"
            
            $url = "https://api.github.com/repos/{0}/{1}/contents" -f $repoTarget.project, $repoTarget.repository
            Write-Debug "vcupGithub.getFileInfo: url, $url"
    
            $r = Invoke-WebRequest -Headers @{"Content-type" = "application/json" } $url | ConvertFrom-Json
            $githubFileInfo = $r | Where-Object { $_.name -like $repoTarget.file }
            Write-Debug "vcupGithub.getFileInfo: githubFileInfo, $githubFileInfo"
    
            Write-Debug "vcupGithub.getFileInfo: end"
            return $githubFileInfo
        }
        catch {
            Write-Error "vcupGithub.getFileInfo. $repoTarget"
        }
        return $null
    }

    [bool] getGithubFile($githubFileInfo, $savePath) {
        Write-Debug "vcupGithub.getGithubFile: begin"
        Write-Debug "vcupGithub.getGithubFile: githubFileInfo, $githubFileInfo"
        Write-Debug "vcupGithub.getGithubFile: savePath, $savePath"

        if (-not (Test-Path($savePath))) {
            Write-Error "vcupGithub.getGithubFile: error not found ""$savePath"" "
            return $false
        }

        $filename = Join-Path $savePath $githubFileInfo.name
        if (Test-Path($filename)) {
            Write-Information "vcupGithub.getGithubFile: already file: $githubFileInfo.name"
        }
        else {
            Invoke-WebRequest -OutFile $filename $githubFileInfo.download_url 
            Write-Information "vcupGithub.getGithubFile: download $filename from $githubFileInfo.url"
        }

        Write-Debug "vcupGithub.getGithubFile: end"
        return $true
    }

}
