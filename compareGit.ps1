# ==================================================================================================
function compareGitCommit {
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
        [string] $projectName,
        [Parameter(ParameterSetName = "")]
        [string] $Line,
        [Parameter(ParameterSetName = "")]
        [string] $ServAddr,
        [switch] $CompactPATH
        
    )
    # ===================================================
    # 載入函式
    # Import-module .\archiveGit.ps1
    # Import-module .\compareDri.ps1
    irm "https://raw.githubusercontent.com/hunandy14/autoCompare/master/archiveGit.ps1" | iex
    irm "https://raw.githubusercontent.com/hunandy14/autoCompare/master/compareDri.ps1" | iex
    # ===================================================
    # 初始化設定
    $listFileName = "diff-list.txt"
    # 決定 outDir 子資料夾增加與否的邏輯
    if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
    if ($projectName) {
        if (!$outDir) { $outDir = $curDir }
        $outDir = "$outDir\$projectName"
    } elseif (!$outDir) { $outDir = "$curDir\compare_source" }
    # ===================================================
    # 從git提交點中獲取檔案
    $list = getCommitDiff $CM1 $CM2 -gitDir $gitDir
    archiveCommit $CM1 $List $gitDir -outFile "source_before.zip" -outDir $outDir -Expand
    archiveCommit $CM2 $List $gitDir -outFile "source_after.zip"  -outDir $outDir -Expand
    [System.IO.File]::WriteAllLines("$outDir\$listFileName", $list);
    # ===================================================
    $srcDir  = $outDir

    $dir1    = "source_before"
    $dir2    = "source_after"
    $list    = $listFileName
    $repDir  = "COMPARE_REPORT"

    $dir1    = "$srcDir\$dir1"
    $dir2    = "$srcDir\$dir2"
    $list    = "$srcDir\$list"
    $outDir2 = "$srcDir\$repDir"
    
    WinMergeU_Dir $dir1 $dir2 $list -o $outDir2 -Line:$Line -Serv:$ServAddr -Comp:$CompactPATH
}
# ==================================================================================================
# 使用範例
function test_compareGit {
    $ServAddr    = "Z:\Server"
    $projectName = "doc_1130"
    
    $Left        = "INIT"
    $Right       = "master"
    $gitDir      = "Z:\gitRepo\doc_develop"
    $outDir      = "Z:\work"
    
    # compareGitCommit $CM1 $CM2 $gitDir -outDir $outDir -projectName "doc_1130"
    # compareGitCommit $CM1 $CM2 $gitDir -outDir $outDir
    # compareGitCommit $CM1 $CM2 $gitDir                 -projectName "doc_1130"
    # compareGitCommit $CM1 $CM2 $gitDir 
    
    compareGitCommit $Left $Right $gitDir -o $outDir -p:projectName -Line:2 -Comp
    # compareGitCommit $Left $Right $gitDir -o $outDir -p:projectName -Line:2 -S:$ServAddr -Comp
}
# test_compareGit
# ==================================================================================================
