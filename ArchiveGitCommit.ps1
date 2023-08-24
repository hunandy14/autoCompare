# 解碼八禁制字串
function DecodeOctal {
    param (
        [Parameter(ValueFromPipeline)]
        [string]$InputString,
        [Text.Encoding]$Encoding = [Text.Encoding]::UTF8
    )
    $bytesList = @()
    for ($i = 0; $i -lt $InputString.Length; $i++) {
        # 檢查當前字符是否是反斜線，並且是否有足夠的字符來解析八進制值
        if (($InputString[$i] -eq "\") -and ($i+3 -lt $InputString.Length)) {
            $octalCandidate = $InputString.Substring($i+1, 3)
            # 檢查接下來的三個字符是否為有效的八進制數字
            if ($octalCandidate -match "^[0-7]{3}$") {
                $bytesList += ,[convert]::ToInt32($octalCandidate, 8)
                $i += 3 # 移動到下一個字符，跳過八進制編碼
                continue
            }
        }
        # 如果當前字符不是八進制編碼，直接添加到結果列表
        $bytesList += ,[int][char]$InputString[$i]
    } return $Encoding.GetString([byte[]]$bytesList).Trim('"')
} # '"Z:/git/\346\226\260\345\242\236\350\263\207\346\226\231\345\244\276/\346\270\254\350\251\246\350\267\257\345\276\221.txt"'|DecodeOctal



# 獲取提交點的差異清單
function diffCommit {
    param (
        [Parameter(Position = 0, ParameterSetName = "")]
        [string] $Commit1, # Commit 兩者皆未輸入時輸出 [暫存 -> 當前工作目錄] 的變更
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $Commit2, # Commit2 未輸入時輸出 [Commit1 -> 當前工作目錄] 的變更
        [switch] $Cached,  # 剔除未提交檔案 (也可以解釋成將 Commit2 設置成 Stage [Commit2 必須為空])
        [switch] $Tracked, # 剔除未追蹤的清單 (git diff 是不包含未追蹤檔案的我修改了這個特性改成預設是有的 [只有在 Commit2 與 Cached 為空時才有效])
        [Parameter(ParameterSetName = "")]
        [string] $Path,
        [Parameter(ParameterSetName = "")]
        [string] $Filter
    )
    
    # 檢測路徑
    if ($Path) {
        [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
        $Path = $Path -replace("^Microsoft.PowerShell.Core\\FileSystem::")
        $Path = [System.IO.Path]::GetFullPath($Path)
    } else { $Path = Get-Location}
    $Path = $Path -replace("^Microsoft.PowerShell.Core\\FileSystem::")
    if (!(Test-Path -PathType:Container "$Path\.git")) { Write-Error "Error:: The path `"$Path`" is not a git folder" -ErrorAction:Stop }
    
    
    
    # 命令
    $Filter = $Stage = $null
    if ($Filter) { $Filter = "--diff-filter=$Filter" }
    if ($Cached) {
        if (!$Commit2) {
            $Stage = "--cached"
        } else { Write-Warning "The '-Cached' parameter will not take effect because it is only valid when 'Commit2' is empty." }
    }
    $cmd1 = "git diff --name-status $Filter $Stage $Commit1 $Commit2".TrimEnd() -replace "\s{2,}", " "
    $cmd2 = "git diff --numstat $Filter $Stage $Commit1 $Commit2".TrimEnd() -replace "\s{2,}", " "
    $cmd3 = "(git ls-files --others --exclude-standard) -replace('^', `"U`t`")"
    
    # 提取差分清單
    if ($Path) { $curDir = (Get-Location).Path; Set-location $Path }
    $content1 = @(Invoke-Expression $cmd1)
    $content2 = @(Invoke-Expression $cmd2)
    $content3 = @(Invoke-Expression $cmd3)
    if ($Path) { Set-location $curDir }
    
    
    
    # 自訂顯示屬性
    $displayProperties = 'Status', 'Name', 'StepAdd', 'StepDel'
    $defaultDisplaySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', [string[]]($displayProperties))
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplaySet)
    
    # 轉換成 PSCustomObject
    $PsObj = @()
    for ($i = 0; $i -lt $content1.Count; $i++) {
        $item1 = ($content1[$i] -split("\t"))
        $item2 = ($content2[$i] -split("\t"))
        # 取出字段
        $Status, $Name     = $item1[0], (DecodeOctal $item1[1])
        $StepAdd, $StepDel = $item2[0], $item2[1]
        # 特殊狀況改名時
        if ($Status -match '^R') {
            # $Status = 'R'
            $OldName = $Name
            $Name    = $item1[2]
        } else { $OldName = $null }
        # 轉換物件
        $PsObj += [PSCustomObject]@{
            Status  = $Status
            Name    = $Name
            OldName = $OldName
            StepAdd = $StepAdd
            StepDel = $StepDel
        } | Add-Member MemberSet PSStandardMembers $PSStandardMembers -PassThru
    }
    # 未追蹤檔案
    if (!$Tracked -and (!$Cached -and !$Commit2)) {
        for ($i = 0; $i -lt $content3.Count; $i++) {
            $item1 = ($content3[$i] -split("\t"))
            # # 取出字段
            $Status, $Name = $item1[0], (DecodeOctal $item1[1])
            # 轉換物件
            $PsObj += [PSCustomObject]@{
                Status  = $Status
                Name    = $Name
                OldName = $null
                StepAdd = $null
                StepDel = $null
            } | Add-Member MemberSet PSStandardMembers $PSStandardMembers -PassThru
        }
    }
    return $PsObj|Sort-Object Name
} # diffCommit INIT HEAD -Path "Z:\doc" -Filter "ADMR"
# diffCommit -Path "Z:\doc" -Tracked
# diffCommit -Path "Z:\doc" HEAD        # [HEAD  -> WorkDir]:: 未提交的變更
# diffCommit -Path "Z:\doc" -Cached     # [HEAD  -> Stage]  :: 已暫存的變更
# diffCommit -Path "Z:\doc"             # [Stage -> WorkDir]:: 未暫存的變更
# (diffCommit -Path "Z:\doc" HEAD^^ HEAD^) |Select-Object * |Format-Table
# diffCommit -Path "Z:\doc" HEAD^ HEAD -Cached



# 封存資料夾中的特定檔案
function archiveFiles {
    param (
        [string]$Path,
        [string]$Output,
        [string[]]$List,
        [ValidateSet(1, 3, 5, 7, 9)]
        [UInt16]$CompressionLevel = 5
    )
    [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
    $Path = [IO.Path]::GetFullPath($Path)
    $Output = [IO.Path]::GetFullPath($Output)
    
    # 檢查輸入路徑
    if (!($Path -and (Test-Path -PathType Container $Path))) {
        Write-Error "輸入的路徑 '$Path' 有誤, 必須是資料夾"
    }    
    
    # 檢查 7z 命令是否存在
    & { param (
        [string]$Path
    )
        $Command = [IO.Path]::GetFileName($Path)
        try { Get-Command $Command -ErrorAction Stop | Out-Null } catch {
            $env:Path += ";$(Split-Path $Path)"
            try { Get-Command $Command -ErrorAction Stop | Out-Null } catch {
                Write-Error "Error:: Command '$Command' is not recognized." -ErrorAction Stop
            }
        }
    } "C:\Program Files\7-Zip\7z.exe"
    
    # 如果提供了檔案清單，則壓縮清單中的檔案
    if ($List) {
        $filesToCompress = "'" + (($List -replace "^\.\\") -join "' '") + "'"
    } else { # 壓縮整個資料夾
        $filesToCompress = "$Path\*"
    }
    
    # 生成壓縮命令
    $tmp = "$Output.tmp"
    $cmd = "7z.exe a -tzip '$tmp' $filesToCompress -mx=$CompressionLevel -aoa"
    
    # 執行壓縮檔案
    Push-Location
        Set-Location $Path
        Write-Host $cmd -ForegroundColor DarkGray
        $result = Invoke-Expression $cmd
    Pop-Location
    
    # 覆蓋目標檔案
    if (Test-Path $Output) {
        Remove-Item $Output -Force
    }
    if (Test-Path $tmp) {
        Rename-Item $tmp $Output
    }
    
    # 回傳結果
    $result -match "Everything is Ok"
}




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
                        if ((Split-Path $Output -Leaf) -eq "archiveCommit-temp.zip") { Remove-Item $Output } # 多餘的if判斷避免砍錯檔案
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
} # archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit"
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

# 封存 Git差異節點 間的變動檔案
function archiveDiffCommit {
    [Alias("acvDC")]
    param (
        [Parameter(Position = 0, ParameterSetName = "")]
        [string] $Commit1,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $Commit2,
        
        [Parameter(ParameterSetName = "")]
        [string] $Path,
        [string] $Output,
        
        [Parameter(ParameterSetName = "")]
        [switch] $OpenOutDir,
        [switch] $OutAllFile
    )
    # 檢測路徑
    [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
    if ($Path) { $Path = [System.IO.Path]::GetFullPath($Path) } else { $Path = Get-Location}
    if ($Output) { $Output = [System.IO.Path]::GetFullPath($Output) } else {
        $Output = "$Env:TEMP\archiveDiffCommit"
        if (Test-Path "$Env:TEMP\archiveDiffCommit\*") { Remove-Item "$Env:TEMP\archiveDiffCommit\*" -Recurse }
    }
    if (!(Test-Path -PathType:Container "$Path\.git")) { Write-Error "Error:: The path `"$Path`" is not a git folder" -ErrorAction:Stop }
    
    
    # 處理節點
    if (!$Commit1) { $Commit1 = 'HEAD' }
    if (!$Commit2) { $IsCurrStatusDiff=$true }
    # 節點名稱
    $CommitName1 = $Commit1
    $CommitName2 = if ($Commit2) {$Commit2} else {'CURR'}
    Write-Host "Diff Commit:: [$CommitName1 -> $CommitName2]"
    
    
    # 獲取 節點1 差異清單 (變更前)
    $List1Cmd = "diffCommit $Commit2 $Commit1 -Path $Path" -replace '\s+', ' '
    # Write-Host "  List1:: $List1Cmd" -ForegroundColor DarkGray
    $List1 = Invoke-Expression $List1Cmd; if ($List1) {
        if ($IsCurrStatusDiff) {
            # 因為git的省參數狀態只能比較[HEAD->CURR]不能比較[CURR->HEAD]，直觀的解法把A跟D反過來就好
            $List1 = ($List1|Where-Object{$_.Status -notin "A" -and $_.Status -notin "U"}) # 去除AU
            # 處理更名物件拆成AD並刪除A
            $List1|ForEach-Object{
                if (($_.Status)[0] -eq "R") {
                    $_.Name = $_.OldName
                    $_.OldName = $null
                    $_.Status = "D"
                }
            }
        } else {
            $List1 = ($List1|Where-Object{$_.Status -notin "D"})
        }
    }
    # Write-Host ($List1|Format-Table|Out-String)
    # 獲取 節點2 差異清單 (變更後)
    $List2Cmd = "diffCommit $Commit1 $Commit2 -Path $Path" -replace '\s+', ' '
    # Write-Host "  List2:: $List2Cmd" -ForegroundColor DarkGray
    $OutList = Invoke-Expression $List2Cmd; if ($OutList) {
        # 排除已經被刪除的清單
        $List2 = ($OutList|Where-Object{$_.Status -notin "D"})
    }
    # Write-Host ($List2|Format-Table|Out-String)
    
    
    # 獲取 節點 差異檔案 (變更後)
    if ($OutAllFile) { 
        # 輸出所有檔案 (List為null預設會全出)
        $Out1 = archiveCommit -Path:$Path -List:$null -Output $Output $Commit1
        $Out2 = archiveCommit -Path:$Path -List:$null -Output $Output $Commit2
    } else {
        # 獲取差異清單檔案
        if ($List1) { $Out1 = archiveCommit -Path:$Path -List:($List1.Name) -Output $Output $Commit1 }
        if ($List2) { $Out2 = archiveCommit -Path:$Path -List:($List2.Name) -Output $Output $Commit2 }
        # Zip的定義中沒辦法存在空zip，遇到List1為空做一個空檔案比較
        if (!$List1) {
            if ($Commit1) { $ZipCmt = $Commit1 } else { $ZipCmt = "CURR" }
            $emptyFile = "$Env:TEMP\_"
            $emptyZip = "$Env:TEMP\archiveDiffCommit\$($ZipCmt)_CommitIsNonDiffFile.zip"
            if (!(Test-Path $emptyFile)) { New-Item $emptyFile -ItemType:File|Out-Null }
            Compress-Archive $emptyFile $emptyZip -Force
            $Out1=$emptyZip
        }
        if (!$List2) {
            if ($Commit2) { $ZipCmt = $Commit2 } else { $ZipCmt = "CURR" }
            $emptyFile = "$Env:TEMP\_"
            $emptyZip = "$Env:TEMP\archiveDiffCommit\$($ZipCmt)_CommitIsNonDiffFile.zip"
            if (!(Test-Path $emptyFile)) { New-Item $emptyFile -ItemType:File|Out-Null }
            Compress-Archive $emptyFile $emptyZip -Force
            $Out2=$emptyZip
        }
    }
    
    
    # 輸出 差異清單表
    $OutString = ($OutList | ForEach-Object { $index; $index=1} {
        $_ | Select-Object @{Name='Index'; Expression={[string]$index}},*
        $index++
    } |Format-Table |Out-String) -split "`r`n" -notmatch "^$"
    $OutString > "$Output\diff-list.txt"
    Write-Host ''
    Write-Host ($OutString[0..1] -join "`r`n") -ForegroundColor DarkGray
    Write-Host ($OutString[2..($OutString.Length-1)] -join "`r`n")
    Write-Host ''
    
    
    # 輸出物件
    if ($Commit1 -and !$Commit2) { $Commit2 = "CURR"}
    $Obj = @()
    $Obj += [PSCustomObject]@{
        Commit   = $Commit1
        FullName = $Out1
    }
    $Obj += [PSCustomObject]@{
        Commit   = $Commit2
        FullName = $Out2
    }
    # 打開輸出資料夾
    if ($OpenOutDir) { explorer.exe $Output }
    # 回傳完整路徑
    return $Obj
}
# 輸出 [HEAD -> CURR] 差異檔案
# archiveDiffCommit -Path:"Z:\doc"
# archiveDiffCommit HEAD -Path:"Z:\doc"
# 輸出 [INIT -> HEAD] 差異檔案
# archiveDiffCommit INIT HEAD -Path:"Z:\doc"
# 輸出 [HEAD -> INIT] 差異檔案
# archiveDiffCommit HEAD INIT -Path:"Z:\doc"
# 輸出 [INIT -> HEAD] 差異檔案並過濾特定檔案
# archiveDiffCommit INIT0 HEAD -Path:"Z:\doc" -Include:@("*.css")
# DiffSource "doc-INIT0.zip" "doc-HEAD.zip"
# archiveDiffCommit INIT0 HEAD -Path:"Z:\doc"
# 空節點測試
# archiveDiffCommit -Path:"Z:\doc" -Include EAWD1100.css,EAWD1100.js
# OpenOutDir
# archiveDiffCommit -Path:"Z:\doc" -OpenOutDir
# 輸出所有檔案測試
# archiveDiffCommit -Path:"Z:\doc" -OpenOutDir -OutAllFile
# 比較git節點
# Invoke-RestMethod "raw.githubusercontent.com/hunandy14/autoCompare/master/DiffSource.ps1"|Invoke-Expression
# . ".\DiffSource.ps1"
# acvDC 'HEAD^' 'HEAD' -Path:"Z:\doc"
# acvDC 'HEAD^^' 'HEAD' -Path:"Z:\doc" |cmpSrc
# acvDC INIT0 HEAD -Path:"Z:\doc"
# acvDC INIT0 HEAD -Path:"Z:\doc"|cmpSrc
# acvDC HEAD -Path:"Z:\doc" |cmpSrc
# acvDC -Path:"Z:\doc" HEAD
# acvDC -Path:"Z:\doc" |cmpSrc
# acvDC -Path:"Z:\doc" -OutAllFile |cmpSrc
# 測試中文檔名問題
# acvDC -Path:"Z:\gitCode"
# acvDC -Path:"Z:\gitCode" |cmpSrc
# acvDC -Path:"Z:\gitCode" -OutAllFile |cmpSrc
