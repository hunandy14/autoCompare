function getCommitFile {
    param (
        [Parameter(Position = 0)]
        [string] $CM1,
        [Parameter(Position = 1)]
        [string] $CM2,
        [Parameter(Position = 2)]
        [string] $gitDir,
        [Parameter(ParameterSetName = "")]
        [string] $dstDir,
        [Parameter(ParameterSetName = "")]
        [string] $ListFileName,
        [switch] $Expand
    )
    if ($dstDir -eq "") { $dstDir = "$PSScriptRoot\CommitFiles" }
    if ($ListFileName -eq "") { $ListFileName = "diff-list.txt" }
    # 獲取差異清單
    Set-location $gitDir
    $F1 = "$dstDir\$CM1.zip".Replace("\", "/")
    New-Item -ItemType File -Path $F1 -Force | Out-Null
    $F2 = "$dstDir\$CM2.zip".Replace("\", "/")
    New-Item -ItemType File -Path $F2 -Force | Out-Null
    # 打包差異的檔案
    $diff_list = "`$(git diff --name-only $CM1 $CM2)"
    $cmd = "git archive -o $F1 $CM1 $diff_list"
    Invoke-Expression $cmd
    $cmd = "git archive -o $F2 $CM2 $diff_list"
    Invoke-Expression $cmd
    # 建立差異清單檔案
    $FileContent = $(git diff --name-only $CM1 $CM2)
    Set-location $dstDir
    $FileContent | Out-File -Encoding ASCII $ListFileName
    # 解壓縮並刪除檔案
    if ($Expand) {
        Expand-Archive $F1 -Force; Remove-Item $F1
        Expand-Archive $F2 -Force; Remove-Item $F2
    }
    # 恢復工作目錄
    Set-location $PSScriptRoot
    return @("$dstDir\$CM1", "$dstDir\$CM2", "$dstDir\$ListFileName")
}
# ===========================================================
function WinMergeU_Report {
    param (
        [string] $F1,
        [string] $F2,
        [string] $Output,
        [string] $line = 3
    )
    New-Item -ItemType File -Path $Output -Force | Out-Null
    WinMergeU $F1 $F2 -cfg Settings/ShowIdentical=0 -cfg Settings/DiffContextV2=$line -minimize -noninteractive -u -or $Output
}
function WinMergeU_Report2 {
    param (
        [string] $D1,
        [string] $D2,
        [System.Object] $List,
        [string] $OutDir,
        [switch] $Mode_S
    )
    if ($OutDir -eq "") { $OutDir = "$PSScriptRoot\WinMergOut" }
    foreach ($item in $List) {
        # 獲取兩個資料夾原始檔
        $_D1 = $D1 + "\" + $item
        $_D2 = $D2 + "\" + $item
        # 簡化路徑輸出檔案路徑
        if ($Mode_S) {
            $MainDir = $item.Substring(0, $item.IndexOf("/"))
            $idx=$item.LastIndexOf("/") + 1
            $FileName = $item.Substring($idx, $item.Length - $idx )
            $outName = $OutDir + "\" + $MainDir + "\" + $FileName + ".html"
        } else {
            $outName = $OutDir + "\" + $item + ".html"
        }
        # 輸出比對檔案
        WinMergeU_Report $_D1 $_D2 $outName
    }
}
function CompareDir {
    param (
        [string] $dir1,
        [string] $dir2, 
        [string] $ListFileName 
    )
    $List = (Get-Content $ListFileName)
    if ($List[0].ToString().Length -ge 20) {
        WinMergeU_Report2 $dir1 $dir2 $List -Mode_S
    } else {
        # WinMergeU_Report2 $dir1 $dir2 $List
    }
}
# ===========================================================

# ===========================================================
$gitDir = "Z:\gitRepo\doc_develop"
$CM1 = "INIT"
$CM2 = "master"

# 獲取CommitFile
# $dir = getCommitFile $CM1 $CM2 $gitDir -Expand

# 建立差異html
CompareDir $dir[0] $dir[1] $dir[2]
