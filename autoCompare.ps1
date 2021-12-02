function getCommitFile {
    param (
        [string] $CM1,
        [string] $CM2,
        [string] $gitDir,
        [switch] $Expand
    )
    $CmDir = "CommitFile"
    # 獲取差異清單
    Set-location $gitDir
    $F1 = "$PSScriptRoot\$CmDir\$CM1.zip".Replace("\", "/")
    New-Item -ItemType File -Path $F1 -Force | Out-Null
    $F2 = "$PSScriptRoot\$CmDir\$CM2.zip".Replace("\", "/")
    New-Item -ItemType File -Path $F2 -Force | Out-Null
    # 打包差異的檔案
    $diff_list = "`$(git diff --name-only $CM1 $CM2)"
    $cmd = "git archive -o $F1 $CM1 $diff_list"
    Invoke-Expression $cmd
    $cmd = "git archive -o $F2 $CM2 $diff_list"
    Invoke-Expression $cmd
    # 建立差異清單檔案
    $FileContent = $(git diff --name-only $CM1 $CM2)
    Set-location $PSScriptRoot\$CmDir
    $FileContent | Out-File -Encoding ASCII "diff-list.txt"
    # 解壓縮並刪除檔案
    if ($Expand) {
        Expand-Archive $F1 -Force; Remove-Item $F1
        Expand-Archive $F2 -Force; Remove-Item $F2
    }
    # 恢復工作目錄
    Set-location $PSScriptRoot
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
        [System.Object] $List
    )
    $OutDir = "D:/Work/WinMerg/java/WinMergOut"
    foreach ($i in $List) {
        $_D1 = $D1 + "/" + $i
        $_D2 = $D2 + "/" + $i
        
        $MainDir = $i.Substring(0, $i.IndexOf("/"))
        $idx = $i.LastIndexOf("/") + 1
        $FileName = $i.Substring($idx, $i.Length - $idx )
        
        # $_Name = $OutDir + "/" + $i + ".html"
        $_Name = $OutDir + "/" + $MainDir + "/" + $FileName + ".html"

        $MainDir + "/" + $FileName

        # WinMergeU_Report $_D1 $_D2 $_Name
        # Write-Host WinMergeU_Report $_D1 $_D2 $_Name
    }
}

# $dir1 = "D:/Work/WinMerg/java/javaINIT"
# $dir2 = "D:/Work/WinMerg/java/java1130" 
# $List = @(
#     "DMPZ01_WarProject/DMPZ01_WarProject/jsp/DMVX0050.html",
#     "DMPZ01_WarProject/DMPZ01_WarProject/jsp/DMVXC001.inc",
#     "DMPZ01_WarProject/DMPZ01_WarProject/jsp/DMVXS001.css",
#     "DMPZDB/src/jp/co/hitachi_densa/DMPZDB/DMRZ013.java",
#     "blcbatch_project/src/jp/co/Hitachi/soft/blc/wfvx/WFVX0250.java"
# )
# WinMergeU_Report2 $dir1 $dir2 $List

function compareFile {
    param (
        [string] $dir1,
        [string] $dir2
    )
    
    
}
# ===========================================================
$gitDir = "Z:\gitRepo\doc_develop"
$CM1 = "INIT"
$CM2 = "master"

# 獲取CommitFile
getCommitFile $CM1 $CM2 $gitDir -Expand

# 
