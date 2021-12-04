Import-module .\archiveGit.ps1
Import-module .\compareDri.ps1
# ==================================================================================================
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
# ==================================================================================================
if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
    
$diffDir = "Z:\Work\doc_diff"

$dir1    = "source_after"
$dir2    = "source_before"
$list    = "diff-list.txt"
$outDir  = "source_cmp"
 
$dir1    = "$diffDir\$dir1"
$dir2    = "$diffDir\$dir2"
$list    = "$diffDir\$list"
$outDir  = "$diffDir\$outDir"
 
WinMergeU_Dir $dir1 $dir2 $list -outDir $outDir -Line 3 -Mode_S
# ==================================================================================================
