## WinMerge 比較報告輸出說明
### 範例代碼
```ps1
# 參數設定 (Path可接受資料夾或檔案)
$LeftPath     = "Left"
$RightPath    = "Right"
$Output       = "$env:TEMP\WinMerge\index.html"
$Line         = -1
$ArgumentList = (@"
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
"@ -split("`r`n|`n") -replace("^ +") -join(" "))
# 開始比較
Write-Output "WinMergeU $ArgumentList"
Start-Process WinMergeU $ArgumentList -Wait
explorer.exe $Output

```

<br>

### 參數說明
||參數|說明|
|-|-|-|
|1|-minimize|最小化啟動|
|2|-noninteractive|生成完畢後退出 WinMerge|
|3|-noprefs|不要讀取或寫入註冊表|
|4|-cfg Settings/DiffContextV2=$Line|報告中前後未修改的代碼行數|
|5|-cfg Settings/DirViewExpandSubdirs=1|包含所有子資料夾檔案|
|6|-cfg ReportFiles/ReportType=2|精簡的HTML格式(單檔比較時可省略)|
|7|-cfg ReportFiles/IncludeFileCmpReport=1|包含檔案清單總攬|
|7|-cfg Settings/ViewLineNumbers=1|顯示行號|
|8|-f|忽略指定檔案|
|8|-r|包含子文件的比較|
|9|-u |不要將本次比較清單加入最近使用清單|
|10|-or|生成報告的輸出路徑(.HTML)|

<br>

### 其他常用參數說明
||參數|說明|
|-|-|-|
|1|-ignorews|忽略右邊空白字元差異|
|2|-ignoreblanklines|忽略空白行差異|
|3|-ignoreeol|忽略換行 LF/CRLF 差異|
|4|-cfg Settings/ShowIdentical=0|忽略相同檔案不輸出報告|

<br>

### Filter 說明
> Filter 似乎只是針對項目名稱進行的過濾，沒有辦法使用相對路徑進行過濾
> 1. 結尾追加斜線可以僅搜尋該資料夾，但不會搜尋子資料夾
> 2. 可以疊加白名單指定第二層以上某個資料夾，但會導致比較結果包含第一層的檔案
> 3. 用黑名單禁用第一層目標以外的所有項目，可以保持搜尋子資料夾功能

<br>

### 參考
- https://qiita.com/mima_ita/items/ac21c0588080e73fc458
- https://www.c-sharpcorner.com/article/poor-man-web-monitoring-tools/
- https://manual.winmerge.org/en/Command_line.html
- https://github.com/WinMerge/winmerge
- https://github.com/WinMerge/winmerge/releases/download/v2.16.24/winmerge-2.16.24-x64-exe.zip
- https://manual.winmerge.org/en/Filters.html
- https://stackoverflow.com/questions/59682491/winmerge-filter-for-file-types-and-include-subfolders
