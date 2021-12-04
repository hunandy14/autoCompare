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
    if ($gitDir -ne "") { Set-location "$gitDir\" }
    $F1 = "$outDir\$outFile".Replace("\", "/")
    New-Item -ItemType File -Path $F1 -Force | Out-Null
    Invoke-Expression "git archive -o $F1 $CM1 $List"
    # 解壓縮並刪除檔案
    if ($Expand) {
        Set-location "$outDir\"
        Expand-Archive $F1 -Force; Remove-Item $F1
    }
    if ($gitDir -ne "") { Set-location "$curDir\" }
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
    if ($CM2 -eq "") { $CM2 = "$CM1^1" }
    if ($gitDir -ne "") { Set-location "$gitDir\" }
    $diff_list = git diff --name-only $CM1 $CM2
    if ($gitDir -ne "") { Set-location "$curDir\" }
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
function Test_compareGit {
    # 依據特定清單獲取提交點檔案
    # $List = @("css/DMWD1013.css", "css/DMWZ01.css")
    # archiveCommit $CM2 $List $gitDir -outDir $outDir -Expand
    # archiveCommit $CM1 $List $gitDir -outDir $outDir -Expand
    # 獲取兩個差一點間的檔案修改
    # archiveCommitDiff $CM1 $CM2 $gitDir -outDir $outDir -Expand

    $projectName = "doc_diff"
    $listFileName = "diff-list.txt"
    
    $gitDir = "Z:\gitRepo\doc_develop"
    $CM1 = "master"
    $CM2 = "INIT"
    $outDir = "Z:\work"
    
    # 輸出 WinMerge 比較清單
    $list = getCommitDiff $CM1 $CM2 -gitDir $gitDir
    $listFileName = "$outDir\$projectName\$listFileName"
    $outDir = "$outDir\$projectName"
    $Expand = $true
    archiveCommit $CM1 $List $gitDir -outFile "source_before.zip" -outDir $outDir -Expand:$Expand
    archiveCommit $CM2 $List $gitDir -outFile "source_after.zip"  -outDir $outDir -Expand:$Expand
    [System.IO.File]::WriteAllLines($listFileName, $list);
}
# Test_compareGit
# ==================================================================================================
