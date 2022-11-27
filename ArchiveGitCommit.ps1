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
    $curDir = (Get-Location).Path
    if ($Path) { Set-location $Path }
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
        if ($Status -eq 'R085') {
            $Status = 'R'
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
} # diffCommit INIT0 master -Path "Z:\doc"
# diffCommit INIT0 master -Path "Z:\doc"
# diffCommit master -Path "Z:\doc"
# diffCommit -Path "Z:\doc"
# diffCommit
# diffCommit -Path "Z:\doc" -Filter "D"
# diffCommit INIT0 -Path "Z:\doc"



# 從指定提交點取出特定清單檔案
function archiveCommit {
    param (
        [Parameter(Position = 0, ParameterSetName = "")]
        [string] $Commit,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $Destination,
        [Parameter(ParameterSetName = "")]
        [object] $List,
        [Parameter(ParameterSetName = "")]
        [string] $Path,
        [switch] $Expand
    )
    # 檢測路徑
    [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
    $curDir = (Get-Location).Path
    if (!$Path) { $Path = $curDir } else {
        $Path = [System.IO.Path]::GetFullPath($Path)
        if (!(Test-Path $Path)) {
            Write-Host "Error:: Path is not exist." -ForegroundColor:Yellow; return
        }
    }
    # 設置路徑與
    $gitDirName = (Split-Path $Path -Leaf)
    if (!$Commit) { $Commit = "HEAD" }
    $defDstName = "$gitDirName-$Commit.zip"
    if ($Destination) { # 有路徑且為資料夾
        if (!(Split-Path $Destination -Extension)) { $Destination = "$Destination\archiveCommit\$defDstName" }
    } else { # 路徑為空
        $Destination = $defDstName
    } $Destination = [System.IO.Path]::GetFullPath($Destination)
    # 設置命令
    $cmd = "git archive -o '$Destination' $Commit $List".Trim()
    # 打包差異的檔案
    if ($cmd) {
        Set-location $Path
        $dstDir = (Split-Path $Destination -Parent)
        if (!(Test-Path $dstDir)) { New-Item -ItemType Directory $dstDir  -Force | Out-Null }
        Invoke-Expression $cmd
        # Write-Host $cmd -ForegroundColor:Yellow
        Set-location $curDir
    }
    # 解壓縮並刪除檔案
    if ($Expand) {
        $ExpPath = "$(Split-Path $Destination)\$gitDirName"
        Expand-Archive $Destination $ExpPath -Force; Remove-Item
    }
    return $Destination
} # archiveCommit "Z:\doc"
# $list = (diffCommit INIT0 master -Path "Z:\doc")
# archiveCommit -Path:"Z:\doc" -List:($list.Name) master 'acvFile\doc-master.zip'
# archiveCommit -Path:"Z:\doc" -List:($list.Name) INIT0 'acvFile\doc-INIT0.zip'
# archiveCommit
# archiveCommit -Path:"Z:\doc" HEAD $env:TEMP
# archiveCommit -Path:"Z:\doc" HEAD 'archive.zip'



# 封存 Git差異節點 間的變動檔案
function archiveGitCommit {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
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
    if (!$Commit2) { $Commit2 = "$Commit1"; $Commit1 = "$Commit1^" }
    # Write-Host $Commit1 -> $Commit2
    
    # 獲取 節點1 差異檔案
    $List1 = diffCommit $Commit1 $Commit2 -Path $Path
    $List1 = ($List1|Where-Object{$_.Status -notin "D"})
    # $List1|Format-Table
    $Out1 = archiveCommit -Path:$Path -List:($List1.Name) $Commit2 $Env:TEMP
    # $Out1
    # 獲取 節點2 差異檔案
    $List2 = diffCommit $Commit2 $Commit1 -Path $Path
    $List2 = ($List2|Where-Object{$_.Status -notin "D"})
    # $List2|Format-Table
    $Out2 = archiveCommit -Path:$Path -List:($List2.Name) $Commit1 $Env:TEMP
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
# archiveGitCommit HEAD0 -Path:"Z:\doc"
# 輸出 [INIT -> HEAD] 差異檔案
# archiveGitCommit INIT0 HEAD -Path:"Z:\doc"
# 輸出 [INIT -> HEAD] 差異檔案並過濾特定檔案
# archiveGitCommit INIT0 HEAD -Path:"Z:\doc" -Include:@("*.css")
# DiffSource "doc-INIT0.zip" "doc-HEAD.zip"
# archiveGitCommit INIT0 HEAD -Path:"Z:\doc"
# 比較git節點
# Invoke-RestMethod "raw.githubusercontent.com/hunandy14/autoCompare/master/DiffSource.ps1"|Invoke-Expression
# archiveGitCommit INIT0 HEAD -Path:"Z:\doc" | DiffSource
