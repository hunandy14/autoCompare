# ==================================================================================================
function compareGitCommit {
    param (
        [Parameter(Position = 0)]
        $CM1,
        [Parameter(Position = 1)]
        $CM2,
        [Parameter(Position = 2)]
        $gitDir,
        [Parameter(ParameterSetName = "")]
        $outDir,
        [Parameter(ParameterSetName = "")]
        $projectName
    )
    # Import-module .\archiveGit.ps1
    # Import-module .\compareDri.ps1
    irm "https://raw.githubusercontent.com/hunandy14/autoCompare/master/archiveGit.ps1" | iex
    irm "https://raw.githubusercontent.com/hunandy14/autoCompare/master/compareDri.ps1" | iex
    $listFileName = "diff-list.txt"
    # ===================================================
    # 輸出 WinMerge 比較清單
    if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
    $list = getCommitDiff $CM1 $CM2 -gitDir $gitDir
    
    if (!$outDir) {
        if (!$projectName) { $outDir = "$curDir\compare_source" } 
        else { if ($projectName) { $outDir = "$curDir\$projectName" } }
    } elseif ($projectName) { $outDir = "$outDir\$projectName" }
    
    
    # if ($projectName) { $outDir = "$outDir\$projectName" }
    # 書出檔案
    # archiveCommit $CM1 $List $gitDir -outFile "source_before.zip" -outDir $outDir -Expand
    # archiveCommit $CM2 $List $gitDir -outFile "source_after.zip"  -outDir $outDir -Expand
    # 輸出清單
    # $listFileName = "$outDir\$listFileName"
    # [System.IO.File]::WriteAllLines($listFileName, $list);
    
    # ===================================================
    $outDir
    return
    # ===================================================
    $diffDir = "Z:\Work\doc_diff"

    $dir1    = "source_after"
    $dir2    = "source_before"
    $list    = "diff-list.txt"
    $outDir  = "source_cmp"

    $dir1    = "$diffDir\$dir1"
    $dir2    = "$diffDir\$dir2"
    $list    = "$diffDir\$list"
    $outDir  = "$diffDir\$outDir"

    # WinMergeU_Dir $dir1 $dir2 $list -outDir $outDir -Line 3 -Mode_S
}
# ==================================================================================================
$CM1         = "master"
$CM2         = "INIT"
$gitDir      = "Z:\gitRepo\doc_develop"
$outDir      = "Z:\work"

# compareGitCommit $CM1 $CM2 $gitDir -outDir $outDir
compareGitCommit $CM1 $CM2 $gitDir -outDir $outDir