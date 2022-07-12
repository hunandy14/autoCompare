# ==================================================================================================
# 載入函式
# Import-module .\archiveGit.ps1
# Import-module .\compareDri.ps1
irm "https://raw.githubusercontent.com/hunandy14/autoCompare/master/archiveGit.ps1" | iex
irm "https://raw.githubusercontent.com/hunandy14/autoCompare/master/compareDri.ps1" | iex
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
        [switch] $CompactPATH
        
    )
    # 初始化設定
    $listFileName = "diff-list.txt"
    # 決定 outDir 子資料夾增加與否的邏輯
    if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
    if ($projectName) {
        if (!$outDir) { $outDir = $curDir }
        $outDir = "$outDir\$projectName"
    } elseif (!$outDir) { $outDir = "$curDir\compare_source" }
    if (!$gitDir) {$gitDir = $curDir}
    Set-Location $gitDir
    # ===================================================
    # 從git提交點中獲取檔案
    $List = getCommitDiff $CM1 $CM2 -gitDir $gitDir
    $List_Cm1 = $(git ls-tree --name-only -r $CM1)|Where-Object { $a=$_; $List|ForEach-Object{$_ -contains $a} }
    archiveCommit $CM1 $List_Cm1 $gitDir -outFile "source_before.zip" -outDir $outDir -Expand
    archiveCommit $CM2 $List $gitDir -outFile "source_after.zip"  -outDir $outDir -Expand
    [IO.File]::WriteAllLines("$outDir\$listFileName", $List)
    # 左清單缺少的檔案補上空檔
    $List|ForEach-Object{
        $F="$outDir\source_before\$_"
        if (!(Test-Path $F -PathType:Leaf)) { New-Item $F -Force|Out-Null }
    }
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
    
    WinMergeU_Dir $dir1 $dir2 $list -o $outDir2 -Line:$Line -Comp:$CompactPATH
    Set-Location $curDir
}
# ==================================================================================================
# 使用範例
function test_compareGit {
    # irm "https://raw.githubusercontent.com/hunandy14/autoCompare/master/compareGit.ps1" | iex

    $ProjectName = "YAG0"
    
    $Left        = "INIT"
    $Right       = "dev"
    $gitDir      = "W:\MyDocument\マイドキュメント\gitRepo\YAG0\app"
    $outDir      = "W:\compare"
    
    compareGitCommit $Left $Right $gitDir -o $outDir -P:$ProjectName -Line:9999 -Comp
} # test_compareGit
# ==================================================================================================