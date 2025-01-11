# 比較程式碼差異
function diffSource {
    [Alias("cmpSrc")]
    param (
        [Parameter(Position = 0, ParameterSetName = "A", Mandatory)]
        [String] $LeftPath,
        [Parameter(Position = 1, ParameterSetName = "A", Mandatory)]
        [String] $RightPath,
        [Parameter(ParameterSetName = "")]
        [String] $Output,
        [Parameter(ParameterSetName = "")]
        [Int64 ] $Line = -1,
        [Parameter(ParameterSetName = "")]
        [String] $Filter,
        [Parameter(ParameterSetName = "")]
        [Object] $Include,
        [String] $Argument,
        [Switch] $IgnoreSameFile,
        [Switch] $IgnoreWhite,
        [Switch] $NoOpenHTML,
        [Switch] $CompareZipSecondLayer,
        [Parameter(ValueFromPipeline, ParameterSetName = "B")]
        [Object] $InputObject
    )
    Begin { $ItemObject = @() } Process { if ($InputObject) { $ItemObject += $InputObject.FullName } } End {
    # 輸入為 InputObject 時
    if ($InputObject) { $LeftPath = $ItemObject[0]; $RightPath = $ItemObject[1]; }
    # 安裝WinMerge (已安裝會自動退出)
    Install-WinMerge|Out-Null
    # 測試路徑
    if ($LeftPath  -and !(Test-Path $LeftPath )) { Write-Host "Error:: LeftPath is not exist."  -ForegroundColor:Yellow ; return }
    if ($RightPath -and !(Test-Path $RightPath)) { Write-Host "Error:: RightPath is not exist."  -ForegroundColor:Yellow; return }
    if ($Output) {
        [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
        $Output = [System.IO.Path]::GetFullPath($Output)
        $Output = $Output -replace("^Microsoft.PowerShell.Core\\FileSystem::")
        if (!($Output -match ".html$")) { Write-Host "Error:: Output Path is not HTML file." -ForegroundColor:Yellow; return }
    } else { $Output = "$env:TEMP\diffSource\index.html" }
    
    # 比較壓縮檔中第二層資料夾(資料夾名必須與壓縮檔名一致)
    if ($CompareZipSecondLayer) {
        function Expand-ZipSecondLayer {
            param([string]$Path)
            
            $File = Get-Item $Path
            if ($File.Extension -eq '.zip') {
                $ExpandPath = Join-Path $env:TEMP $File.BaseName
                Expand-Archive $File.FullName $ExpandPath -Force
                return Join-Path $ExpandPath $File.BaseName
            }
            return $Path
        }

        $LeftPath = Expand-ZipSecondLayer $LeftPath
        $RightPath = Expand-ZipSecondLayer $RightPath
    }
    
    # 處理Incule參數，獲取FileName
    if ($Include) {
        $Filter = "$Filter;" + ($Include -replace ".*?(\\|/)" -join ";")
    }
    # 參數設定
$ArgumentList = @"
    "$LeftPath"
    "$RightPath"
    -minimize
    -noninteractive
    -noprefs
    -cfg Settings/DiffContextV2=$Line
    -cfg Settings/DirViewExpandSubdirs=1
    -cfg ReportFiles/ReportType=2
    -cfg ReportFiles/IncludeFileCmpReport=1
    -cfg Settings/ViewLineNumbers=1
    -f "!.git\;!.vs\;$Filter"
    -r
    -u
    -or "$Output"
    $Argument
"@ -split("`r`n|`n")

    # 追加參數
    if ($IgnoreSameFile){ $ArgumentList += "-cfg Settings/ShowIdentical=0" }
    if ($IgnoreWhite){ $ArgumentList += "-ignorews"; $ArgumentList += "-ignoreblanklines"; $ArgumentList += "-ignoreeol" }
    $ArgumentList = $ArgumentList -replace("^ +") -join(" ")
    # 開始比較
    Write-Host "WinMergeU $ArgumentList" -ForegroundColor DarkGray
    Start-Process WinMergeU $ArgumentList -Wait
    if (!$NoOpenHTML) { explorer.exe $Output }
    return $Output
}} # diffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html'
# diffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -NoOpenHTML -IgnoreSameFile -IgnoreWhite
# diffSource 'Z:\Work\INIT.zip' 'Z:\Work\master.zip' -Output 'Z:\Work\Diff\index.html' -CompareZipSecondLayer
# diffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -Filter ((Get-Content "Z:\Work\diff-list.txt") -replace ".*?(\\|/)" -join ";")
# diffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -Include (Get-Content "Z:\Work\diff-list.txt")
# diffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -Include @("DMWA1010.xsl", "css/DMWZ01.css")
# diffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' 
# diffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -Filter "js\"
# diffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -Filter "!js\;!xsl\"
# diffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -Include @("js/aaa/DMWA0010.js")
# diffSource 'Z:\diffSource\before' 'Z:\diffSource\after' -Output 'Z:\diffSource\Report\index.html' -Include (Get-Content "Z:\diffSource\list.txt") -Filter "!xml\"
# (Get-ChildItem 'C:\Users\hunan\AppData\Local\Temp\archiveCommit' -Directory)|diffSource
