# 安裝 WinMerge
function Install-WinMerge {
    param (
        [switch] $Force
    )
    # 檢測命令是否已經存在
    $CmdName = "WinMergeU"
    if ((!$Force) -and (Get-Command $CmdName -CommandType:Application -EA:0)) { return }
    
    # 獲取設置
    $Url = "https://github.com/WinMerge/winmerge/releases/download/v2.16.24/winmerge-2.16.24-x64-exe.zip"
    $Url -match "[^/]+(?!.*/)" |Out-Null
    $ZipName = $Matches[0]
    $DLPath = $env:TEMP+"\$ZipName"
    $AppPath = $env:TEMP+"\WinMerge"
    $AppExec = $AppPath+"\WinMergeU.exe"
    
    # 檢測下載資料夾是否存在
    if (Get-Command $AppExec -CommandType:Application -EA:0) {
        if (($env:Path).IndexOf($AppPath) -eq -1) {
            if ($env:Path[-1] -ne ';') { $env:Path = $env:Path+';' }
            $env:Path = $env:Path+$AppPath
        }
    } else {
        # 下載並解壓縮
        Start-BitsTransfer $Url $DLPath
        Expand-Archive $DLPath $env:TEMP -Force
        # 加到臨時變數
        if (($env:Path).IndexOf($AppPath) -eq -1) {
            if ($env:Path[-1] -ne ';') { $env:Path = $env:Path+';' }
            $env:Path = $env:Path+$AppPath
        }
    }
    
    # 驗證安裝
    if (!(Get-Command $CmdName -CommandType:Application -EA:0)) { Write-Error "Error:: WinMerge installation failed." -ForegroundColor:Yellow; return } else {
        return $AppExec
    }
} # Install-WinMerge -Force



# 比較程式碼差異
function DiffSource {
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
    } else { $Output = "$env:TEMP\DiffSource\index.html" }
    
    # 比較壓縮檔中第二層資料夾(資料夾名必須與壓縮檔名一致)
    if ($CompareZipSecondLayer) {
        # LeftPath
        $File = Get-Item $LeftPath
        if($File.Extension -eq '.zip'){
            $ExpandPath = $env:TEMP+"\"+$File.BaseName
            Expand-Archive $File.FullName $ExpandPath -Force
        } $LeftPath = $ExpandPath+"\"+$File.BaseName
        # RightPath
        $File = Get-Item $RightPath
        if($File.Extension -eq '.zip'){
            $ExpandPath = $env:TEMP+"\"+$File.BaseName
            Expand-Archive $File.FullName $ExpandPath -Force
        } $RightPath = $ExpandPath+"\"+$File.BaseName
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
}} # DiffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html'
# DiffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -NoOpenHTML -IgnoreSameFile -IgnoreWhite
# DiffSource 'Z:\Work\INIT.zip' 'Z:\Work\master.zip' -Output 'Z:\Work\Diff\index.html' -CompareZipSecondLayer
# DiffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -Filter ((Get-Content "Z:\Work\diff-list.txt") -replace ".*?(\\|/)" -join ";")
# DiffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -Include (Get-Content "Z:\Work\diff-list.txt")
# DiffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -Include @("DMWA1010.xsl", "css/DMWZ01.css")
# DiffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' 
# DiffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -Filter "js\"
# DiffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -Filter "!js\;!xsl\"
# DiffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -Include @("js/aaa/DMWA0010.js")
# DiffSource 'Z:\DiffSource\before' 'Z:\DiffSource\after' -Output 'Z:\DiffSource\Report\index.html' -Include (Get-Content "Z:\DiffSource\list.txt") -Filter "!xml\"
# (Get-ChildItem 'C:\Users\hunan\AppData\Local\Temp\archiveCommit' -Directory)|DiffSource
