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
    if (!(Get-Command $CmdName -CommandType:Application -EA:0)) { Write-Host "WinMerge 安裝失敗" -ForegroundColor:Yellow; Exit }
} Install-WinMerge -Force



# 比較程式碼碼差異
function DiffSource {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [String] $LeftPath,
        [Parameter(Position = 1, ParameterSetName = "", Mandatory)]
        [String] $RightPath,
        [Parameter(ParameterSetName = "")]
        [String] $Output = "$env:TEMP\DiffSource\index.html",
        [Parameter(ParameterSetName = "")]
        [Int64 ] $Line = -1,
        [Parameter(ParameterSetName = "")]
        [String] $Filter,
        [Switch] $NoOpenHTML,
        [Switch] $CompareZipSecondLayer
    )
    # 安裝WinMerge (已安裝會自動退出)
    Install-WinMerge
    
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
    -f !.git\;!.vs\;$Filter
    -r
    -u
    -or "$Output"
"@ -split("`r`n|`n") -replace("^ +") -join(" ")
    # 開始比較
    Start-Process WinMergeU $ArgumentList -Wait
    if (!$NoOpenHTML) { explorer.exe $Output }
    return "ReportPath: $Output"
} # DiffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html'
# DiffSource 'Z:\Work\INIT.zip' 'Z:\Work\master.zip' -Output 'Z:\Work\Diff\index.html' -CompareZipSecondLayer
