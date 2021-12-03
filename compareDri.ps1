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
        [Int16] $Line = 3
    )
    if ($Output -eq "") {
        if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
        $Output = "$curDir\FileDiff-Out.html"
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
        [Int16] $Line = 3,
        [switch] $Mode_S
    )
    $Content = ""
    $idx = 1
    $collection = (Get-Content $listFileName)
    foreach ($item in $collection) {
        # 獲取兩個資料夾原始檔
        $F1 = $dir1 + "\" + $item
        $F2 = $dir2 + "\" + $item
        # 簡化路徑輸出檔案路徑
        if ($Mode_S) {
            $MainDir = $item.Substring(0, $item.IndexOf("/"))
            $idx = $item.LastIndexOf("/") + 1
            $FileName = "$MainDir\" + $item.Substring($idx, $item.Length - $idx )
        }
        else {
            $FileName = $item.Replace("/", "\")
        }
        # 輸出比對檔案
        $outName = "$outDir\$FileName.html"
        WinMergeU_Core $F1 $F2 $outName -Line $Line
        
        # HTML項目
        $number = HTML_Tag "span" $idx -style "width: 30px;display: inline-block"
        $link = HTML_Tag "a" $FileName -href $outName
        $div = HTML_Tag "div" "`n    $number`n    $link`n" -style "height: 22px"
        $Content = $Content + "$div`n"
        $idx = $idx+1
    }
    [System.IO.File]::WriteAllLines("$outDir\index.html", (HTML_Head $Content));
}
# ==================================================================================================
if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
$diffDir  = "Z:\autoCompare\doc_develop_update"
$CM1      = "INIT"
$CM2      = "master"
$diffList = "diff-list.txt"
$outDir   = "Z:\autoCompare\doc_develop_diff"

$dir1   = "$diffDir\$CM1"
$dir2   = "$diffDir\$CM2"
$list   = "$diffDir\$diffList"
$outDir = "$outDir"

WinMergeU_Dir $dir1 $dir2 $list -outDir $outDir -Line 3
# ==================================================================================================