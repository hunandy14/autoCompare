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
        [Switch] $NoOpenHTML
    )
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
    -r
    -u
    -or "$Output"
"@ -split("`r`n|`n") -replace("^ +") -join(" ")
    # 開始比較
    Start-Process WinMergeU $ArgumentList -Wait
    if (!$NoOpenHTML) { explorer.exe $Output }
    return "ReportPath: $Output"
} # DiffSource 'Z:\Work\INIT' 'Z:\Work\master' -Output 'Z:\Work\Diff\index.html' -NoOpenHTML
