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
        $Path = [System.IO.Path]::GetFullPath($Path)
        if (!(Test-Path -PathType:Container "$Path\.git")) { Write-Error "Error:: The path `"$Path`" is not a git folder" -ErrorAction:Stop }
    }
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
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [string] $Commit,
        [Parameter(Position = 1, ParameterSetName = "")]
        [object] $List,
        [Parameter(ParameterSetName = "")]
        [string] $Output, # 預設為 "$gitDirName-$Commit.zip"
                          #   1. Output為Zip: "$Output.zip"
                          #   2. Output為Dir: "$Output\$gitDirName-$Commit.zip"
        [Parameter(ParameterSetName = "")]
        [string] $Path,  # 預設為當前工作目錄
        [switch] $Expand # 1. 路徑為目錄: 直接輸出檔案到目錄
                         # 2. 路徑為Zip : 原地解壓縮Zip
    )
    # 檢測路徑
    [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
    if ($Path) {
        $Path = [System.IO.Path]::GetFullPath($Path)
        if (!(Test-Path -PathType:Container "$Path\.git")) { Write-Error "Error:: The path `"$Path`" is not a git folder" -ErrorAction:Stop }
    } else { $Path = Get-Location}
    
    # 設置路徑與
    $gitDirName = (Split-Path $Path -Leaf)
    if (!$Commit) { $Commit = "HEAD" }
    $defDstName = "$gitDirName-$Commit.zip"
    if ($Output) { # 有路徑且為資料夾時創建自動檔名
        if (!(Split-Path $Output -Extension)) {
            $OutputIsDir = $true
            $tmpDstName = "archiveCommit-temp.zip"
            if ($Expand) {
                $Output = "$Output\$tmpDstName";
            } else {
                $Output = "$Output\$defDstName"
            }
        }
    } else { # 路徑為空
        $Output = $defDstName
    } $Output = [System.IO.Path]::GetFullPath($Output)
    # 設置命令
    $cmd = ("git archive -o '$Output' $Commit $List").Trim()
    # 打包差異的檔案
    if ($cmd) {
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
            if ($ExpPath -eq $Path) { $Output=$null; Write-Error "The `$Output location is the same as the Git directory." } else {
                Expand-Archive $Output $ExpPath -Force
                if ((Split-Path $Output -Leaf) -eq "archiveCommit-temp.zip") { Remove-Item $Output } # 多餘的if判斷避免砍錯檔案
                $Output = $ExpPath
            }
        } else { # 僅解壓縮
            $ExpPath = "$(Split-Path $Output)\$(Split-Path $Output -LeafBase)"
            $ExpPath = [System.IO.Path]::GetFullPath($ExpPath)
            if ($ExpPath -eq $Path) { Write-Warning "The unzip location is the same as the Git directory, Program will not decompress." } else {
                Expand-Archive $Output $ExpPath -Force
            }
        }
    } return $Output
} # archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit"

# archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit\doc-HEAD" -Expand
# archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit\Archive.zip" -Expand
# archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit"
# archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit\Archive.zip"
# 例外測試
# archiveCommit -Output:(Get-Location) HEAD -Expand
# archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"Z:\doc" -Expand
# archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"Z:\doc.zip" -Expand



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
        [string] $Path,
        [Parameter(ParameterSetName = "")]
        [object] $Include
    )
    # 檢測路徑
    if ($Path) {
        [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
        $Path = [System.IO.Path]::GetFullPath($Path)
        if (!(Test-Path -PathType:Container "$Path\.git")) { Write-Error "Error:: The path `"$Path`" is not a git folder" -ErrorAction:Stop }
    }
    if (!$Commit1) { $Commit1 = 'HEAD' }
    if (!$Commit2) { $Commit2 = "$Commit1"; $Commit1 = "$Commit1^" }
    # Write-Host $Commit1 -> $Commit2
    
    # 獲取 節點1 差異檔案 (變更前)
    $List1 = diffCommit $Commit2 $Commit1 -Path $Path
    $List1 = ($List1|Where-Object{$_.Status -notin "D"})
    # $List1|Format-Table
    $Out1 = archiveCommit -Path:$Path -List:($List1.Name) $Commit1 $Env:TEMP
    # $Out1
    # 獲取 節點2 差異檔案 (變更後)
    $List2 = diffCommit $Commit1 $Commit2 -Path $Path
    $List2 = ($List2|Where-Object{$_.Status -notin "D"})
    # $List2|Format-Table
    $Out2 = archiveCommit -Path:$Path -List:($List2.Name) $Commit2 $Env:TEMP
    # $Out2
    # DiffSource $Out1 $Out2
    # 輸出物件
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
# 輸出 [HEAD^ -> HEAD] 差異檔案
# archiveDiffCommit HEAD -Path:"Z:\doc"
# 輸出 [INIT -> HEAD] 差異檔案
# archiveDiffCommit INIT0 HEAD -Path:"Z:\doc"
# 輸出 [INIT -> HEAD] 差異檔案並過濾特定檔案
# archiveDiffCommit INIT0 HEAD -Path:"Z:\doc" -Include:@("*.css")
# DiffSource "doc-INIT0.zip" "doc-HEAD.zip"
# archiveDiffCommit INIT0 HEAD -Path:"Z:\doc"
# 
# 比較git節點
# Invoke-RestMethod "raw.githubusercontent.com/hunandy14/autoCompare/master/DiffSource.ps1"|Invoke-Expression
# acvDC INIT0 HEAD -Path:"Z:\doc"|cmpSrc
# acvDC HEAD -Path:"Z:\doc" |cmpSrc
# acvDC -Path:"Z:\doc" |cmpSrc
