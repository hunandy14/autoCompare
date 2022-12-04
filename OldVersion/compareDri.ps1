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
        [Parameter(Position = 0, Mandatory=$true)]
        [string] $F1,
        [Parameter(Position = 1, Mandatory=$true)]
        [string] $F2,
        [Parameter(Position = 2, ParameterSetName = "")]
        [string] $Output,
        [Parameter(ParameterSetName = "")]
        [string] $Line,
        [switch] $OpenHTML
    )
    if (!$Line) { $Line = 3 }
    if ($Output -eq "") {
        if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
        $Output = "$curDir\FileDiff-OUT.html"
        Write-Host "    File Outout to: [ $Output ]"
    }
    New-Item -ItemType File -Path $Output -Force | Out-Null
    WinMergeU $F1 $F2 -cfg Settings/ShowIdentical=0 -cfg Settings/DiffContextV2=$Line -minimize -noninteractive -u -or $Output
    if ($OpenHTML) { Invoke-Expression $Output }
}
function WinMergeU_Dir {
    param (
        [Parameter(Position = 0, Mandatory=$true)]
        [string] $dir1,
        [Parameter(Position = 1, Mandatory=$true)]
        [string] $dir2,
        [Parameter(Position = 2, ParameterSetName = "")]
        [System.Object] $List,
        [Parameter(Position = 3, ParameterSetName = "")]
        [string] $outDir,
        [Parameter(ParameterSetName = "")]
        [string] $Line,
        [switch] $CompactPATH,
        [switch] $NotOpenIndex
    )
    $dir1 = (Resolve-Path $dir1).Path
    $dir2 = (Resolve-Path $dir2).Path
    if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
    if (!$outDir) {
        $outDir = "$curDir\COMPARE_REPORT"
        Write-Host "    File Outout to: [" -NoNewline
        Write-Host $outDir -ForegroundColor yellow -NoNewline
        Write-Host "]" 
    }
    $Content = ""
    $idx     = 1
    # 獲取項目清單
    if ($List) {
        if ( $List -is [array] ) { $collection = $List } # 直接取陣列當清單
        else { $collection = (Get-Content $List) }       # 取清單文件內容
        $collection = $collection -replace ("/", "\")
    } else {
        $tmpDir = Get-Location
        Set-Location $dir1
        $collection = ((Get-ChildItem $dir1 -Recurse -File).FullName)  | Resolve-Path -Relative
        $collection = $collection -replace ("^\.\\", "")
        Set-Location $tmpDir
    }
    # 開始比對
    foreach ($item in $collection) {
        # 獲取兩個資料夾原始檔
        $F1 = $dir1 + "\" + $item
        $F2 = $dir2 + "\" + $item
        # 簡化路徑輸出檔案路徑
        if ($CompactPATH -and ((Select-String -Input $item -Patt "\\" -A).Matches.Count -gt 1)) {
            $MainDir = $item.Substring(0, $item.IndexOf("\"))
            $idxOf = $item.LastIndexOf("\") + 1
            $FileName = "$MainDir\" + $item.Substring($idxOf, $item.Length - $idxOf )
        } else { $FileName = $item }
        # 輸出比對檔案
        $outName = "$outDir\$FileName" + ".html"
        $address = "$FileName" + ".html"
        WinMergeU_Core $F1 $F2 $outName -Line:$Line
        # HTML項目
        $number = HTML_Tag "span" $idx -style "width: 30px;display: inline-block"
        $link = HTML_Tag "a" $FileName -href $address
        $div = HTML_Tag "div" "`n    $number`n    $link`n" -style "height: 22px"
        $Content = $Content + "$div`n"
        $idx = $idx + 1
    }
    
    $index = (Resolve-Path $outDir).Path + "\index.html"
    [System.IO.File]::WriteAllLines($index, (HTML_Head $Content))
    if (!$NotOpenIndex) { Invoke-Expression "& '$index'" } 
}
# ==================================================================================================
function Test_compareDir {
    $srcDir  = "Z:\Work\doc_1130"
    
    $dir1    = "source_before"
    $dir2    = "source_after"
    # $repDir  = "COMPARE_REPORT"
    
    $dir1    = "$srcDir\$dir1"
    $dir2    = "$srcDir\$dir2"
    # $list    = @("css/DMWD1013.css", "css/DMWZ01.css")
    # $list    = "$srcDir\diff-list.txt"
    # $outDir = "$srcDir\$repDir"
    
    # WinMergeU_Dir $dir1 $dir2 -List:$list -o:$outDir -Line:2 -Com
    # WinMergeU_Dir $dir1 $dir2 -Line 3 -CompactPATH -NotOpenIndex
    
    # WinMergeU_Dir $dir1 $dir2 -Line:1 -outDir:"MMMMM"
    # WinMergeU_Dir $dir1 $dir2 -Line:1 -outDir:"MMMMM" -List:@("css/DMWD1013.css", "css/DMWZ01.css")
    # WinMergeU_Dir $dir1 $dir2 -Line:1                 -List:@("css/DMWD1013.css", "css/DMWZ01.css")
    WinMergeU_Dir $dir1 $dir2 -Line:3
}
# Test_compareDir
# ==================================================================================================
