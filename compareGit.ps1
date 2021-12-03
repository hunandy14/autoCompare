function getCommitFile {
    param (
        [Parameter(Position = 0)]
        [string] $CM1,
        [Parameter(Position = 1)]
        [string] $CM2,
        [Parameter(Position = 2)]
        [string] $gitDir,
        [Parameter(ParameterSetName = "")]
        [string] $outDir,
        [Parameter(ParameterSetName = "")]
        [string] $ListFileName,
        [switch] $Expand
    )
    if ($outDir -eq "") { $outDir = "$PSScriptRoot\CommitFiles" }
    if ($ListFileName -eq "") { $ListFileName = "diff-list.txt" }
    # 獲取差異清單
    Set-location $gitDir
    $F1 = "$outDir\$CM1.zip".Replace("\", "/")
    New-Item -ItemType File -Path $F1 -Force | Out-Null
    $F2 = "$outDir\$CM2.zip".Replace("\", "/")
    New-Item -ItemType File -Path $F2 -Force | Out-Null
    # 打包差異的檔案
    $diff_list = "`$(git diff --name-only $CM1 $CM2)"
    $cmd = "git archive -o $F1 $CM1 $diff_list"
    Invoke-Expression $cmd
    $cmd = "git archive -o $F2 $CM2 $diff_list"
    Invoke-Expression $cmd
    # 建立差異清單檔案
    $FileContent = $(git diff --name-only $CM1 $CM2)
    Set-location $outDir
    $FileContent | Out-File -Encoding ASCII $ListFileName
    # 解壓縮並刪除檔案
    if ($Expand) {
        Expand-Archive $F1 -Force; Remove-Item $F1
        Expand-Archive $F2 -Force; Remove-Item $F2
    }
    # 恢復工作目錄
    Set-location $PSScriptRoot
    return @("$outDir\$CM1", "$outDir\$CM2", "$outDir\$ListFileName")
}
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
    "A $CM1"
    "B $CM2"
    "C $gitDir"
}
# ==================================================================================================
$gitDir = "Z:\gitRepo\doc_develop"
$List = @("css/DMWD1013.css", "css/DMWZ01.css")
# 依據特定清單獲取提交點檔案
archiveCommit "INIT" $List $gitDir -outDir "Z:\Test" -Expand
archiveCommit "master" $List $gitDir -outDir "Z:\Test" -Expand


# ==================================================================================================

