## 使用範例

### 自動比對 GIT 提交點
```ps1
irm "https://raw.githubusercontent.com/hunandy14/autoCompare/master/compareGit.ps1"|iex

$projectName = "doc_1130"
$Left        = "INIT"
$Right       = "master"
$gitDir      = "Z:\gitRepo\doc_develop"
$outDir      = "Z:\work"

compareGitCommit $Left $Right $gitDir -o $outDir -p:projectName -Line:2 -Comp

```

<br>

### 自動比對資料夾
```ps1
irm "https://raw.githubusercontent.com/hunandy14/autoCompare/master/compareDri.ps1"|iex

$srcDir  = "Z:\Work\doc_1130"
$dir1    = "$srcDir\source_before"
$dir2    = "$srcDir\source_after"

WinMergeU_Dir $dir1 $dir2 -Line 3 -CompactPATH -NotOpenIndex

```

```ps1
irm "https://raw.githubusercontent.com/hunandy14/autoCompare/master/compareDri.ps1"|iex
WinMergeU_Dir "source_before" "source_after" -Line:1
```

<br>

### 自動比對資料夾2
```ps1
# 設定
$LeftPath  = "Z:\Work\INIT"
$RightPath = "Z:\Work\master"
$OutPath   = "Z:\Work\Diff\index.html"

# 比較並自動打開報告 (輸出到暫存資料夾)
irm bit.ly/3UXp1Mp|iex; DiffSource $LeftPath $RightPath

# 比較並輸出到特定資料夾
irm bit.ly/3UXp1Mp|iex; DiffSource $LeftPath $RightPath -Output $OutPath

# 比較並輸出到特定資料夾但不打開網頁
irm bit.ly/3UXp1Mp|iex; DiffSource $LeftPath $RightPath -Output $OutPath -NoOpenHTML
```



<br><br><br>

## WinMerge 比較報告輸出說明
### 範例代碼
```ps1
# 參數設定 (Path可接受資料夾或檔案)
$LeftPath     = 'doc_develop_update\INIT'
$RightPath    = 'doc_develop_update\master'
$Output       = 'Z:\Work\Diff\FileLis-Diff.html'
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
    -r
    -u
    -or "$Output"
"@ -split("`r`n|`n") -replace("^ +") -join(" "))
# 開始比較
Start-Process WinMergeU $ArgumentList
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
|8|-r|包含子文件的比較|
|9|-u |不要將本次比較清單加入最近使用清單|
|10|-or|生成報告的輸出路徑(.HTML)|

<br>

### 其他常用參數說明
||參數|說明|
|-|-|-|
|1|-ignorews|忽略空白字元差異|
|2|-ignoreblanklines|忽略空白行差異|
|3|-ignoreeol|忽略換行 LF/CRLF 差異|
|4|-cfg Settings/ShowIdentical=0|忽略相同檔案不輸出報告|

<br>

### 參考
- https://qiita.com/mima_ita/items/ac21c0588080e73fc458
- https://www.c-sharpcorner.com/article/poor-man-web-monitoring-tools/
- https://manual.winmerge.org/en/Command_line.html
- https://github.com/WinMerge/winmerge





