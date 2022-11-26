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
    $cmd = "git diff --name-status$Filter $Commit1 $Commit2".Trim()
    # 提取差分清單
    $curDir = (Get-Location).Path
    if ($Path) { Set-location $Path }
    $content = Invoke-Expression $cmd
    if ($Path) { Set-location $curDir }
    # 轉換成 PSCustomObject
    $List = @()
    $content|ForEach-Object{
        $item = ($_ -split("\t"))
        $List += [PSCustomObject]@{ Status = $item[0]; Name = $item[1]; }
    }
    return $List
} # diffCommit INIT0 master -Path "Z:\doc"
# diffCommit INIT0 master -Path "Z:\doc"
# diffCommit master -Path "Z:\doc"
# diffCommit -Path "Z:\doc"
# diffCommit
# diffCommit -Path "Z:\doc" -Filter "D"



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
    $curDir = (Get-Location).Path
    if (!$Path) { $Path = $curDir } else {
        [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
        $Path = [System.IO.Path]::GetFullPath($Path)
        if (!(Test-Path $Path)) {
            Write-Host "Error:: Path is not exist." -ForegroundColor:Yellow; return
        }
    }
    # 設置路徑與命令
    $gitDirName = (Split-Path $Path -Leaf)
    if (!$Commit) { $Commit = "HEAD" }
    if (!$Destination) {
        $Destination = "$gitDirName-$Commit.zip"
    }
    $Destination = [System.IO.Path]::GetFullPath($Destination)
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
    Write-Output "Output:: $Destination"
} # archiveCommit "Z:\doc"
# $list = (diffCommit INIT0 master -Path "Z:\doc")
# archiveCommit -Path:"Z:\doc" -List:($list.Name) master 'acvFile\doc-master.zip'
# archiveCommit
# archiveCommit -Path:"Z:\doc"



