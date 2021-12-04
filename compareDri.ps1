# ==================================================================================================
function HTML_Head ($data){
    return '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
' + $data + "`n</body>`n</html>`n"
}
function HTML_Tag {
    param (
        [Parameter(Position = 0)]
        [string] $name,
        [Parameter(Position = 1)]
        [string] $value,
        [Parameter(ParameterSetName = "")]
        [string] $style,
        [Parameter(ParameterSetName = "")]
        [string] $href,
        [Parameter(ParameterSetName = "")]
        [string] $Attributes
    )
    if($style -ne "") {$style = " style=`"$style`""}
    if($href -ne "") {$href = " href=`"$href`""}
    if($Attributes -ne "") {$Attributes = " $Attributes"}
    return "<$name$style$href$Attributes>$value</$name>"
} # (HTML_Head (HTML_Tag "div" (HTML_Tag "a" "Link" -h "https://www.google.com.tw/") -s "width: 100px"))
# ==========================================================
function WinMergeU_Core {
    param (
        [Parameter(Position = 0)]
        [string] $F1,
        [Parameter(Position = 1)]
        [string] $F2,
        [Parameter(Position = 2, ParameterSetName = "")]
        [string] $Output,
        [Parameter(ParameterSetName = "")]
        [string] $Line
    )
    if (!$Line) { $Line = 3 }
    if ($Output -eq "") {
        if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
        $Output = "$curDir\FileDiff-OUT.html"
        Write-Host "    File Outout to: [ $Output ]"
    }
    New-Item -ItemType File -Path $Output -Force | Out-Null
    WinMergeU $F1 $F2 -cfg Settings/ShowIdentical=0 -cfg Settings/DiffContextV2=$Line -minimize -noninteractive -u -or $Output
}
function WinMergeU_Dir {
    param (
        [Parameter(Position = 0)]
        [string] $dir1,
        [Parameter(Position = 1)]
        [string] $dir2,
        [Parameter(Position = 2)]
        [System.Object] $listFileName,
        [Parameter(Position = 3, ParameterSetName = "")]
        [string] $outDir,
        [Parameter(ParameterSetName = "")]
        [string] $Line,
        [Parameter(ParameterSetName = "")]
        [string] $ServAddr,
        [switch] $CompactPATH
    )
    if ($outDir -eq "") {
        if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
        $outDir = "$curDir\FileDiff-OUT"
        Write-Host "    File Outout to: [ $outDir ]"
    }
    $Content = ""
    $idx = 1
    $collection = (Get-Content $listFileName)
    foreach ($item in $collection) {
        $item = $item.Replace("/", "\")
        # 獲取兩個資料夾原始檔
        $F1 = $dir1 + "\" + $item
        $F2 = $dir2 + "\" + $item
        # 簡化路徑輸出檔案路徑
        if ($CompactPATH) {
            $MainDir = $item.Substring(0, $item.IndexOf("\"))
            $idxOf = $item.LastIndexOf("\") + 1
            $FileName = "$MainDir\" + $item.Substring($idxOf, $item.Length - $idxOf )
        } else { $FileName = $item }
        # 輸出比對檔案
        $outName = "$outDir\$FileName" + ".html"
        WinMergeU_Core $F1 $F2 $outName -Line:$Line
        
        # HTML項目
        $Addr = $outName
        if ($ServAddr) { $Addr = "$ServAddr\$FileName" + ".html" }
        $number = HTML_Tag "span" $idx -style "width: 30px;display: inline-block"
        $link = HTML_Tag "a" $FileName -href $Addr
        $div = HTML_Tag "div" "`n    $number`n    $link`n" -style "height: 22px"
        $Content = $Content + "$div`n"
        $idx = $idx + 1
    }
    $index = "$outDir\index.html"
    [System.IO.File]::WriteAllLines($index, (HTML_Head $Content))
    Invoke-Expression $index
}
# ==================================================================================================
function Test_compareDir {
    $ServAddr= "Z:\Server"
    $srcDir  = "Z:\Work\doc_1130"

    $dir1    = "source_before"
    $dir2    = "source_after"
    $list    = "diff-list.txt"
    $repDir  = "COMPARE_REPORT"

    $dir1    = "$srcDir\$dir1"
    $dir2    = "$srcDir\$dir2"
    $list    = "$srcDir\$list"
    $outDir2 = "$srcDir\$repDir"
    
    WinMergeU_Dir $dir1 $dir2 $list -o $outDir2 -Line 2 -S:$ServAddr -Com
}
# Test_compareDir
# ==================================================================================================
