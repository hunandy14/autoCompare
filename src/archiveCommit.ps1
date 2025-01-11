
# 從指定提交點取出特定清單檔案
function archiveCommit {
    param (
        [Parameter(Position = 0, ParameterSetName = "")]
        [string] $Commit,
        [Parameter(Position = 1, ParameterSetName = "")]
        [object] $List,
        [Parameter(ParameterSetName = "")]
        [string] $Output, # 預設為 "$gitDirName-$Commit.zip"
                            #   A. Output為Zip: 保持手動"$Output.zip"
                            #   B. Output為Dir: 檔名自動"$Output\$gitDirName-$Commit.zip"
        [switch] $OutToTemp,
        [Parameter(ParameterSetName = "")] # 只有當Output為資料夾且Expand有啟用才有作用
        [switch] $ConvertToSystemEncoding,
        [switch] $ConvertToUTF8,
        [switch] $ConvertToUTF8BOM,
        [Parameter(ParameterSetName = "")]
        [string] $Path,  # 預設為當前工作目錄
        [switch] $Expand # A. 路徑為目錄:
                        #     1. 輸出檔案到    [指定路徑] (            )
                        #     0. 輸出Zip       [        ] (自動檔名.zip)
                        # B. 路徑為Zip : 
                        #     1. 原地解壓縮Zip [指定路徑] (自訂檔名.Zip)
                        #     0. 輸出Zip       [        ] (自訂檔名.Zip)
    )
    # 檢測路徑
    [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
    if ($Path) {
        $Path = $Path -replace("^Microsoft.PowerShell.Core\\FileSystem::")
        $Path = [System.IO.Path]::GetFullPath($Path)
    } else { $Path = Get-Location}
    $Path = $Path -replace("^Microsoft.PowerShell.Core\\FileSystem::")
    if (!(Test-Path -PathType:Container "$Path\.git")) { Write-Error "Error:: The path `"$Path`" is not a git folder" -ErrorAction:Stop }
    
    # 檢測git命令是否可用
    try { Get-Command "git" -ErrorAction Stop | Out-Null } catch {
        Write-Error "Command 'git' is not installed on this system. Please install Git to continue." -ErrorAction Stop
    }
    
    # 輸出到暫存
    if ($OutToTemp) {
        $Output = "$env:TEMP\ArchiveOutFile\ReleaseSrc"
        $Expand = $true
        if (Test-Path "$env:TEMP\ArchiveOutFile\ReleaseSrc\*") { Remove-Item "$env:TEMP\ArchiveOutFile\ReleaseSrc\*" -Recurse }
    }
    
    
    # 設置路徑
    $gitDirName = (Split-Path $Path -Leaf)
    if (!$Commit) {
        $Commit = ""; $CommitIsNull=$true
        $defDstName = "$gitDirName-CurrStatus.zip"
    } else {
        $defDstName = "$gitDirName-$Commit.zip"
    }
    # 設置輸出
    if ($Output) { # 有路徑且為資料夾時創建自動檔名
        $Output -match "[^\\]+(?!.*\\)" |Out-Null
        $Path_FileName = $Matches[0]
        if ($Path_FileName -notmatch "\.") {
            $OutputIsDir = $true
            $tmpDstName = "archiveCommit-temp.zip"
            if ($Expand) {
                $Output = "$Output\$tmpDstName";
            } else {
                $Output = "$Output\$defDstName"
            }
        } else { $OutputIsDir = $false }
    } else { # 路徑為空
        $Output = $defDstName
    } $Output = [System.IO.Path]::GetFullPath($Output)
    
    
    # 從git目錄壓縮特定檔案成壓縮包 (git不支援從當前狀態取檔)
    if ($CommitIsNull) {
        # 設定目錄
        if ($Expand) { # 複製到指定路徑
            if ($OutputIsDir) {
                $CopyTemp = Split-Path $Output -Parent
            } else { # 複製到指定路徑(包含zip檔名)
                $CopyTemp = [IO.Path]::Combine((Split-Path $Output -Parent), (Split-Path $Output -LeafBase))
                $CopyTemp = [IO.Path]::GetFullPath($CopyTemp)
            }
            if ($CopyTemp -eq $Path) { # 禁止複製到Git資料夾覆蓋
                Write-Error "The `$Output location is the same as the Git directory."; return
            }
            if ((Test-Path $CopyTemp) -and (Get-ChildItem $CopyTemp)) { # 禁止複製到非空目錄造成覆蓋
                Write-Warning "Copy directory `"$CopyTemp`" is not an empty directory, may be overwrite with other files."; return
            }
        } else { # 複製到暫存路徑
            $CopyTemp = "$env:TEMP\archiveCommitTemp"
            if (Test-Path "$env:TEMP\archiveCommitTemp\*") { Remove-Item "$env:TEMP\archiveCommitTemp\*" -Recurse -Force }
        }
        # 獲取檔案清單
        if ($List) {
            $FileInfo = @()
            $List|ForEach-Object{
                $obj = [IO.Path]::GetFullPath([IO.Path]::Combine($Path, $_))
                $FileInfo += Get-Item $obj
            }
        } else {
            # 沒提交點也沒給List:: 全輸出
            # $FileInfo = (Get-ChildItem -Path:$Path -Recurse -File)
            # $FileInfo = $FileInfo|Where-Object{$_.FullName -notmatch ".git\*"}
            # 輸出當前狀況
            $FileInfo = @()
            $List = (diffCommit -Path $Path|Where-Object{$_.Status -notin "D"}).Name
            $List|ForEach-Object{
                $obj = [IO.Path]::GetFullPath([IO.Path]::Combine($Path, $_))
                $FileInfo += Get-Item $obj
            }
        }
        # 複製差異檔案到暫存目錄
        $curDir_tmp = Get-Location
        Set-Location $Path;
        ($FileInfo.FullName)|ForEach-Object{
            # $RelPath = [IO.Path]::GetRelativePath($Path, $_) # 舊版Pwsh不支援
            $RelPath = ($_|Resolve-Path -Relative) -replace("\.\\")
            $F1 = $_; $F2 = "$CopyTemp\$RelPath"
            $ParentPath = (Split-Path $F2 -Parent)
            if (!(Test-Path $ParentPath)) { New-Item $ParentPath -ItemType:Directory -Force |Out-Null }
            # Write-Host $F1; Write-Host "  ->" $F2
            Copy-Item $F1 $F2
        }
        Set-Location $curDir_tmp
        # 壓縮檔案
        if ($OutputIsDir) {
            if (!$Expand) {             # [複製到暫存路徑, 壓縮在指定路徑(自動檔名.Zip)]
                if (!(Test-Path (Split-Path $Output -Parent))) { New-Item (Split-Path $Output -Parent) -ItemType:Directory -Force |Out-Null }
                Compress-Archive -Path "$CopyTemp\*" -DestinationPath "$Output" -Force
                $Output = $Output
            }else {                     # [複製到指定路徑]
                $Output = $CopyTemp
            }
        } else {
            if (!$Expand) {             # [複製到暫存路徑, 壓縮在指定路徑(自定檔名.Zip)]
                if (!(Test-Path (Split-Path $Output -Parent))) { New-Item (Split-Path $Output -Parent) -ItemType:Directory -Force |Out-Null }
                Compress-Archive "$CopyTemp\*" $Output -Force
                $Output = $Output
            } else {                    # [複製到指定路徑2, 壓縮在指定路徑(自定檔名.Zip)]
                if (!(Test-Path (Split-Path $Output -Parent))) { New-Item (Split-Path $Output -Parent) -ItemType:Directory -Force |Out-Null }
                Compress-Archive "$CopyTemp\*" $Output -Force
                $Output = $CopyTemp
            }
        }
        
    # 從git倉庫獲取檔案壓縮包
    } elseif (!$CommitIsNull) {
        # 打包差異的檔案
        $cmd = ("git archive -o '$Output' $Commit $List").Trim()
        if ($cmd) {
            # 執行命令
            if ($Path) { $curDir = (Get-Location).Path; Set-location $Path }
            $dstDir = (Split-Path $Output -Parent)
            if (!(Test-Path $dstDir)) { New-Item -ItemType Directory $dstDir  -Force | Out-Null }
            # Write-Host $cmd -ForegroundColor DarkGray
            Invoke-Expression $cmd
            if ($Path) { Set-location $curDir }
            if ($LASTEXITCODE -ne 0) { Write-Error "Git Command failed with exit code: $LASTEXITCODE" -ErrorAction Stop }
        }
        # 解壓縮並刪除檔案
        if ($Expand) {
            if ($OutputIsDir) { # 解壓縮到目標資料夾並刪除 zip 檔案
                $ExpPath = Split-Path $Output
                $ExpPath = [System.IO.Path]::GetFullPath($ExpPath)
                if (!(Test-Path $ExpPath)) { New-Item $ExpPath -ItemType:Directory -Force |Out-Null } # 不存在則創建
                if ($ExpPath -eq $Path) { $Output=$null; Write-Error "The `$Output location is the same as the Git directory." } else { # 禁止複製到Git資料夾覆蓋
                    $FileList = (Get-ChildItem $ExpPath -Exclude (Split-Path $Output -Leaf))
                    if ((Test-Path $ExpPath) -and $FileList) { # 禁止複製到非空目錄造成覆蓋
                        Write-Warning "Output directory `"$ExpPath`" is not an empty directory, the output may be overwrite with other files."
                        if ((Split-Path $Output -Leaf) -eq "archiveCommit-temp.zip") { Remove-Item $Output } # 多餘的if判斷避免砍錯檔案
                    } else {
                        Expand-Archive $Output $ExpPath
                        if ((Split-Path $Output -Leaf) -eq "archiveCommit-temp.zip") { Remove-Item $Output } # 多的if判斷避免砍錯檔案
                        $Output = $ExpPath
                    }
                }
            } else { # 僅解壓縮
                $ExpPath = "$(Split-Path $Output)\$(Split-Path $Output -LeafBase)"
                $ExpPath = [System.IO.Path]::GetFullPath($ExpPath)
                if ($ExpPath -eq $Path) { $Output=$null; Write-Error "The unzip location is the same as the Git directory." } else { # 禁止複製到Git資料夾覆蓋
                    if ($ExpPath -eq $Path) { Write-Warning "The unzip location is the same as the Git directory, Program will not decompress." } else { # 禁止複製到非空目錄造成覆蓋
                        Expand-Archive $Output $ExpPath -Force
                    }
                }
            }
        }
    }
    
    
    # 編碼轉換 (Output為資料夾且Expand有啟用)
    if ((Test-Path -PathType:Container $Output) -and $Expand) {
        # 獲取系統編碼
        if (!$__SysEnc__) { $Script:__SysEnc__ = [Text.Encoding]::GetEncoding((powershell -nop "([Text.Encoding]::Default).WebName")) }
        $ReadEnc=$WriteEnc=$null
        # 編碼設置 (UTF8->System)
        if ($ConvertToSystemEncoding) {
            $ReadEnc  = New-Object System.Text.UTF8Encoding $False
            $WriteEnc = $__SysEnc__
        }
        # 編碼設置 (System->UTF8)
        if ($ConvertToUTF8) {
            $ReadEnc  = $__SysEnc__
            $WriteEnc = New-Object System.Text.UTF8Encoding $False
        }
        # 編碼設置 (System->UTF8BOM)
        if ($ConvertToUTF8BOM) {
            $ReadEnc  = $__SysEnc__
            $WriteEnc = New-Object System.Text.UTF8Encoding $True
        }
        # 轉換檔案編碼
        if ($ReadEnc -and $WriteEnc) {
            (Get-ChildItem $Output -File -Recurse).FullName|ForEach-Object{
                $Content = [IO.File]::ReadAllLines($_, $ReadEnc)
                $Content = $Content -replace("`r`n","`n") -replace("`n","`r`n") -join("`r`n")
                [IO.File]::WriteAllText($_, $Content, $WriteEnc)
            }
        }
    }
    
    # 輸出到暫存資料夾
    if ($OutToTemp) {
        # 打開輸出到暫存的資料夾或Zip資料夾
        $OpenPath = $Output
        if (Test-Path -PathType:Leaf $OpenPath) { $OpenPath = Split-Path $OpenPath -Parent } 
        explorer.exe $OpenPath
    }
    return $Output
}

# Import-Module autoCompare.psm1
# archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit"
# archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit\doc-HEAD" -Expand
# archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit\Archive.zip" -Expand
# archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit"
# archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit\Archive.zip"
# 空Comit測試
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit\Archive.zip"
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit"
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc"
# Expand測試
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc"
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -Output:"archiveCommit"
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -Output:"archiveCommit.zip"
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit"
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit\doc" -Expand
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit\Archive.zip"
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit\Archive.zip" -Expand
# 暫存測試
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -OutToTemp
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -OutToTemp -Expand
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -OutToTemp -Expand -ConvertToSystemEncoding
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -OutToTemp -Expand -ConvertToUTF8
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -OutToTemp -Expand -ConvertToUTF8BOM
# 例外測試
# archiveCommit HEAD -Output:(Get-Location) -Expand
# archiveCommit HEAD *.css -Path:"Z:\doc" -Output:"Z:\doc" -Expand
# archiveCommit HEAD *.css -Path:"Z:\doc" -Output:"Z:\doc.zip" -Expand
# 例外測試2
# archiveCommit -Output:(Get-Location) -Expand
# archiveCommit -Path:"Z:\doc" -Output:"Z:\doc" -Expand
# archiveCommit -Path:"Z:\doc" -Output:"Z:\doc.zip" -Expand
# 空節點與結合測試
# archiveCommit -Path:"Z:\doc" -Output:"Z:\Archives" -List:((diffCommit -Path "Z:\doc").Name)
# archiveCommit -List ((diffCommit INIT).Name) -OutToTemp -ConvertToSystemEncoding
# 輸出節點所有檔案
# archiveCommit -List $null -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit\doc" -Expand
# 無提交點與清單自動獲取當前狀態
# archiveCommit -Path "Z:\doc" -Output:"$env:TEMP\archiveCommit\doc" -Expand
