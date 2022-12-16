# 獲取提交點的差異清單
function diffCommit {
    param (
        [Parameter(Position = 0, ParameterSetName = "")]
        [string] $Commit1,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $Commit2,
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
    if ($Filter) { $Filter = " --diff-filter=$Filter" }
    $cmd1 = "git diff --name-status$Filter $Commit1 $Commit2".Trim()
    $cmd2 = "git diff --numstat$Filter $Commit1 $Commit2".Trim()
    # 提取差分清單
    if ($Path) { $curDir = (Get-Location).Path; Set-location $Path }
    $content1 = @(Invoke-Expression $cmd1)
    $content2 = @(Invoke-Expression $cmd2)
    # Write-Host $cmd1 -ForegroundColor:Yellow
    # Write-Host $cmd2 -ForegroundColor:Yellow
    if ($Path) { Set-location $curDir }
    # 轉換成 PSCustomObject
    $List = @()
    # $content1|ForEach-Object{
    #     $item = ($_ -split("\t"))
    #     $List += [PSCustomObject]@{ Status = $item[0]; Name = $item[1]; }
    # }
    for ($i = 0; $i -lt $content1.Count; $i++) {
        $item1 = ($content1[$i] -split("\t"))
        $item2 = ($content2[$i] -split("\t"))
        # 取出字段
        $Status = $item1[0]
        $Name   = $item1[1]
        $StepAdd = $item2[0]
        $StepDel = $item2[1]
        # 特殊狀況改名時
        if ($Status -match '^R') {
            # $Status = 'R'
            $Name   = $item1[2]
        }
        # 轉換物件
        $List += [PSCustomObject]@{
            Status  = $Status
            Name    = $Name
            StepAdd = $StepAdd
            StepDel = $StepDel
        }
    }
    return $List
} # diffCommit INIT HEAD -Path "Z:\doc" -Filter "ADMR"



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
        [switch] $OutputToTemp,
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
    if ($OutputToTemp) {
        $Output = "$env:TEMP\ArchiveOutFile"
        if (Test-Path "$env:TEMP\ArchiveOutFile\*") { Remove-Item "$env:TEMP\ArchiveOutFile\*" -Recurse }
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
            if (Test-Path "$env:TEMP\archiveCommitTemp\*") { Remove-Item "$env:TEMP\archiveCommitTemp\*" -Recurse }
        }
        # 獲取檔案清單
        if ($List) {
            $FileInfo = @()
            $List|ForEach-Object{
                $obj = [IO.Path]::GetFullPath([IO.Path]::Combine($Path, $_))
                $FileInfo += Get-Item $obj
            }
        } else { # 沒給List全輸出
            $FileInfo = (Get-ChildItem -Path:$Path -Recurse -File)
            $FileInfo = $FileInfo|Where-Object{$_.FullName -notmatch ".git\*"}
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
    } else {
        # 打包差異的檔案
        $cmd = ("git archive -o '$Output' $Commit $List").Trim()
        if ($cmd) {
            # 執行命令
            if ($Path) { $curDir = (Get-Location).Path; Set-location $Path }
            $dstDir = (Split-Path $Output -Parent)
            if (!(Test-Path $dstDir)) { New-Item -ItemType Directory $dstDir  -Force | Out-Null }
            Invoke-Expression $cmd
            # Write-Host $cmd -ForegroundColor:Yellow
            if ($Path) { Set-location $curDir }
        }
        # 解壓縮並刪除檔案
        if ($Expand) {
            if ($OutputIsDir) { # 解壓縮到目標資料夾並刪除 zip 檔案
                $ExpPath = Split-Path $Output
                $ExpPath = [System.IO.Path]::GetFullPath($ExpPath)
                if (!(Test-Path $ExpPath)) { New-Item $ExpPath -ItemType:Directory -Force |Out-Null } # 不存在則創建
                if ($ExpPath -eq $Path) { $Output=$null; Write-Error "The `$Output location is the same as the Git directory." } else { # 禁止複製到Git資料夾覆蓋
                    if ((Test-Path $ExpPath) -and (Get-ChildItem $ExpPath)) { # 禁止複製到非空目錄造成覆蓋
                        Write-Warning "Output directory is not an empty directory, the output may be overwrite with other files."
                        if ((Split-Path $Output -Leaf) -eq "archiveCommit-temp.zip") { Remove-Item $Output } # 多餘的if判斷避免砍錯檔案
                        return
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
    if ($OutputToTemp) {
        # 打開輸出到暫存的資料夾或Zip資料夾
        $OpenPath = $Output
        if (Test-Path -PathType:Leaf $OpenPath) { $OpenPath = Split-Path $OpenPath -Parent } 
        # explorer.exe $OpenPath
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
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -OutputToTemp
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -OutputToTemp -Expand
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -OutputToTemp -Expand -ConvertToSystemEncoding
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -OutputToTemp -Expand -ConvertToUTF8
# archiveCommit -List css\EAWD1100.css,js\EAWD1100.js -Path:"Z:\doc" -OutputToTemp -Expand -ConvertToUTF8BOM
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


# archiveDiffCommit 別名
Set-Alias acvDC archiveDiffCommit
# 封存 Git差異節點 間的變動檔案
function archiveDiffCommit {
    param (
        [Parameter(Position = 0, ParameterSetName = "")]
        [string] $Commit1,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $Commit2,
        [Parameter(ParameterSetName = "")]
        [string] $Path
    )
    # 檢測路徑
    if ($Path) {
        [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
        $Path = [System.IO.Path]::GetFullPath($Path)
    } else { $Path = Get-Location}
    if (!(Test-Path -PathType:Container "$Path\.git")) { Write-Error "Error:: The path `"$Path`" is not a git folder" -ErrorAction:Stop }
    # if (!$Commit1) { $Commit1 = 'HEAD' }
    if ( $Commit1 -and !$Commit2) { $Commit2 = "$Commit1"; $Commit1 = "$Commit1^" }
    if (!$Commit1 -and !$Commit2) { $Commit1 = "HEAD"; $IsCurrStatusDiff=$true}
    # Write-Host $Commit1 -> $Commit2
    
    # 獲取 節點1 差異清單 (變更前)
    $List1 = diffCommit $Commit2 $Commit1 -Path $Path
    if ($IsCurrStatusDiff) {
        # 因為git的省參數狀態只能比較[HEAD->CURR]不能比較[CURR->HEAD]，直觀的解法把A跟D反過來就好
        $List1 = ($List1|Where-Object{$_.Status -notin "A"})
    } else {
        $List1 = ($List1|Where-Object{$_.Status -notin "D"})
    }
    # 獲取 節點2 差異清單 (變更後)
    $List2 = diffCommit $Commit1 $Commit2 -Path $Path
    $List2 = ($List2|Where-Object{$_.Status -notin "D"})
    # 獲取 節點 差異檔案 (變更後)
    if ($List1) {$Out1 = archiveCommit -Path:$Path -List:($List1.Name) -Output "$Env:TEMP\archiveDiffCommit" $Commit1}
    if ($List2) {$Out2 = archiveCommit -Path:$Path -List:($List2.Name) -Output "$Env:TEMP\archiveDiffCommit" $Commit2}
    
    # Zip的定義中沒辦法存在空zip，遇到List1為空做一個空檔案比較
    if (!$List1) {
        $emptyFile = "$Env:TEMP\_"
        $emptyZip = "$Env:TEMP\archiveDiffCommit\$($Commit1)_CommitIsNonDiffFile.zip"
        if (!(Test-Path $emptyFile)) { New-Item $emptyFile -ItemType:File|Out-Null }
        Compress-Archive $emptyFile $emptyZip -Force
        $Out1=$emptyZip
    }
    if (!$List2) {
        $emptyFile = "$Env:TEMP\_"
        $emptyZip = "$Env:TEMP\archiveDiffCommit\$($Commit2)_CommitIsNonDiffFile.zip"
        if (!(Test-Path $emptyFile)) { New-Item $emptyFile -ItemType:File|Out-Null }
        Compress-Archive $emptyFile $emptyZip -Force
        $Out2=$emptyZip
    }
    
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
    return $Obj
}
# 輸出 [HEAD -> CURR] 差異檔案
# archiveDiffCommit -Path:"Z:\doc"
# 輸出 [HEAD^ -> HEAD] 差異檔案
# archiveDiffCommit HEAD -Path:"Z:\doc"
# 輸出 [INIT -> HEAD] 差異檔案
# archiveDiffCommit INIT0 HEAD -Path:"Z:\doc"
# 輸出 [INIT -> HEAD] 差異檔案並過濾特定檔案
# archiveDiffCommit INIT0 HEAD -Path:"Z:\doc" -Include:@("*.css")
# DiffSource "doc-INIT0.zip" "doc-HEAD.zip"
# archiveDiffCommit INIT0 HEAD -Path:"Z:\doc"
# 空節點測試
# archiveDiffCommit -Path:"Z:\doc" -Include EAWD1100.css,EAWD1100.js

# 
# 比較git節點
# Invoke-RestMethod "raw.githubusercontent.com/hunandy14/autoCompare/master/DiffSource.ps1"|Invoke-Expression
# acvDC INIT0 HEAD -Path:"Z:\doc"|cmpSrc
# acvDC HEAD -Path:"Z:\doc" |cmpSrc
# acvDC -Path:"Z:\doc" |cmpSrc
# (acvDC -Path:"Z:\doc")|cmpSrc
# acvDC -Path:"Z:\doc"|cmpSrc
