# ===========================================================
function WinMergeU_Core {
    param (
        [string] $F1,
        [string] $F2,
        [string] $Output,
        [string] $line = 3
    )
    New-Item -ItemType File -Path $Output -Force | Out-Null
    WinMergeU $F1 $F2 -cfg Settings/ShowIdentical=0 -cfg Settings/DiffContextV2=$line -minimize -noninteractive -u -or $Output
}
function WinMergeU_Dir {
    param (
        [string] $dir1,
        [string] $dir2,
        [System.Object] $listFileName,
        [string] $outDir,
        [switch] $Mode_S
    )
    $collection = (Get-Content $listFileName)
    foreach ($item in $collection) {
        # 獲取兩個資料夾原始檔
        $F1 = $dir1 + "\" + $item
        $F2 = $dir2 + "\" + $item
        # 簡化路徑輸出檔案路徑
        if ($Mode_S) {
            $MainDir = $item.Substring(0, $item.IndexOf("/"))
            $idx = $item.LastIndexOf("/") + 1
            $FileName = $item.Substring($idx, $item.Length - $idx )
            $outName = $outDir + "\" + $MainDir + "\" + $FileName + ".html"
        }
        else {
            $outName = $outDir + "\" + $item.Replace("/", "\") + ".html"
        }
        # 輸出比對檔案
        WinMergeU_Core $F1 $F2 $outName
    }
}
# ===========================================================
function createIndexHTML {
    param (
        [string] $site,
        [string] $Mode_S ,
        [string] $diffList,
        [string] $indexFileName
    )
    Set-Location $cmprOutDir
    $docList = Get-Content $diffList

    # 開頭
    $Content = "" +
    '<!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Document</title>
    </head>
    <body>
    '
    # 產生各個項目
    for ($i = 0; $i -lt $docList.Count; $i++) {
        $item = $docList[$i]
        if ($Mode_S) {
            $MainDir = $item.Substring(0, $item.IndexOf("/"))
            $idx = $item.LastIndexOf("/") + 1
            $FileName = $item.Substring($idx, $item.Length - $idx )
            $item2 = $MainDir + "/" + $FileName
            $address = $site + "/" + $item2 + ".html"
            $linkName = $item2
        }
        else {
            $address = $site + "/" + $item + ".html"
            $linkName = $item
        }
        
        $Number = '<span style="width: 30px;display: inline-block;">' + ($i + 1) + '</span>'

        $out = '<div style="height: 22px">' + $Number + '<a href="' + $address + '">' 
        $out = $out + '' + $linkName + ''
        $out = $out + '</a></div>'
        # Write-Host $out

        $Content = $Content + $out + "`n"
    }
    # 結尾
    $Content = $Content + '
    </body>
    </html>
    '
    # 輸出
    [System.IO.File]::WriteAllLines($indexFileName, $Content);
}
# ===========================================================
if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
$diffDir  = "Z:\autoCompare\doc_develop_update"
$outDir   = "Z:\autoCompare\doc_develop_diff"
$CM1      = "INIT"
$CM2      = "master"
$diffList = "diff-list.txt"


$dir1   = "$diffDir\$CM1"
$dir2   = "$diffDir\$CM2"
$list   = "$diffDir\$diffList"
$outDir = "$outDir"
WinMergeU_Dir $dir1 $dir2 $list $outDir


# 建立indexJTML
# $diffList = $dir[2]
# $indexFileName = "$cmprOutDir\index.html"
# createIndexHTML $cmprOutDir $Mode_S $diffList $indexFileName

# ===========================================================
