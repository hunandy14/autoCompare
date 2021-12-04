# ==================================================================================================
function archiveCommit {
    param (
        [Parameter(Position = 0)]
        [string] $CM1,
        [Parameter(Position = 1)]
        [System.Object] $List,
        [Parameter(Position = 2, ParameterSetName = "")]
        [string] $gitDir,
        [Parameter(ParameterSetName = "")]
        [string] $outFile,
        [Parameter(ParameterSetName = "")]
        [string] $outDir,
        [switch] $Expand
    )
    if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
    
    if ($outDir -eq "") { $outDir = $curDir }
    if ($ListFileName -eq "") { $ListFileName = "diff-list.txt" }
    if ($outFile -eq "") { $outFile = "$CM1.zip" }
    # 打包差異的檔案
    Set-location "$gitDir\"
    $F1 = "$outDir\$outFile".Replace("\", "/")
    New-Item -ItemType File -Path $F1 -Force | Out-Null
    Invoke-Expression "git archive -o $F1 $CM1 $List"
    # 解壓縮並刪除檔案
    if ($Expand) {
        Set-location "$outDir\"
        Expand-Archive $F1 -Force; Remove-Item $F1
    }
    Set-location "$curDir\"
}
function getCommitDiff {
    param (
        [Parameter(Position = 0)]
        [string] $CM1,
        [Parameter(Position = 1)]
        [string] $CM2,
        [Parameter(Position = 2, ParameterSetName = "")]
        [string] $gitDir
    )
    if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
    Set-location "$gitDir\"
    $diff_list = git diff --name-only $CM1 $CM2
    Set-location "$curDir\"
    return $diff_list
}
function archiveCommitDiff {
    param (
        [Parameter(Position = 0)]
        [string] $CM1,
        [Parameter(Position = 1)]
        [string] $CM2,
        [Parameter(Position = 2, ParameterSetName = "")]
        [string] $gitDir,
        [Parameter(ParameterSetName = "")]
        [string] $outDir,
        [switch] $Expand
    )
    # 獲取差異清單
    $diff_list = getCommitDiff $CM1 $CM2 $gitDir
    archiveCommit $CM1 $diff_list $gitDir -outDir $outDir -Expand:$Expand
}
# ==================================================================================================
$gitDir = "Z:\gitRepo\doc_develop"
$List = @("css/DMWD1013.css", "css/DMWZ01.css")
$CM1 = "master"
$CM2 = "INIT"
$outDir = "Z:\Test"

# 依據特定清單獲取提交點檔案
# archiveCommit $CM2 $List $gitDir -outDir $outDir -Expand
# archiveCommit $CM1 $List $gitDir -outDir $outDir -Expand
# 獲取兩個差一點間的檔案修改
# archiveCommitDiff $CM1 $CM2 $gitDir -outDir $outDir -Expand




# ==================================================================================================

