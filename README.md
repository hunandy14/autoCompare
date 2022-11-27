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






<br><br><br><br><br><br>

## 自動比對 GIT 提交點
```ps1
irm bit.ly/ArchiveGitCommit|iex; irm bit.ly/DiffSource|iex; acvDC INIT HEAD |cmpSrc
```






<br><br><br><br><br><br>

## 自動比對 (資料夾, 單檔, 壓縮檔)
快速使用
```ps1
irm bit.ly/DiffSource|iex; DiffSource 
```

詳細說明
```ps1
# 設定
$LeftPath  = "Z:\Work\INIT"
$RightPath = "Z:\Work\master"
$OutPath   = "Z:\Work\Diff\index.html"

# 比較並自動打開報告 (輸出到暫存資料夾)
irm bit.ly/DiffSource|iex; DiffSource $LeftPath $RightPath
# 比較並輸出到特定資料夾
irm bit.ly/DiffSource|iex; DiffSource $LeftPath $RightPath -Output $OutPath
# 比較並輸出到特定資料夾但不打開網頁
irm bit.ly/DiffSource|iex; DiffSource $LeftPath $RightPath -Output $OutPath -NoOpenHTML

# 忽略相同檔案輸出到檔案總攬
irm bit.ly/DiffSource|iex; DiffSource $LeftPath $RightPath -IgnoreSameFile
# 忽略白色 (右端空白, 跳行, 結尾符號)
irm bit.ly/DiffSource|iex; DiffSource $LeftPath $RightPath -IgnoreWhite

# 比較壓縮檔中第二層資料夾(資料夾名必須與壓縮檔名一致)
irm bit.ly/DiffSource|iex; DiffSource $LeftPath $RightPath -CompareZipSecondLayer

# 排除特定資料夾
irm bit.ly/DiffSource|iex; DiffSource $LeftPath $RightPath -Filter "!.git\;!.vs\"
# 過濾特定檔名
irm bit.ly/DiffSource|iex; DiffSource $LeftPath $RightPath -Filter "*.css;*.js;"

# 檔案名稱過濾與排除: 物件清單(會刪除的資料夾路徑僅取結尾檔名輸入Filter)
irm bit.ly/DiffSource|iex; DiffSource $LeftPath $RightPath -Include @("css/DMWA1010.xsl", "css/DMWZ01.css")
irm bit.ly/DiffSource|iex; DiffSource $LeftPath $RightPath -Include (Get-Content "Z:\Work\diff-list.txt")
```

> 原生參數的 Filter 似乎只是針對項目名稱進行的過濾, 沒有辦法使用相對路徑進行過濾
> 1. 在參數結尾追加斜線可以把該資料夾當項目名稱過濾, 但是會導致過濾條件限縮到那個資料夾不會搜尋子資料夾
> 2. 想要指定第二層以上某個資料夾，要疊加白名單才可以，但會導致比較結果包含第一層的檔案
>     (反過來先搜出第一層全部的項目用黑名單全BAN掉，可以保持自動搜尋子資料夾功能)

<br>

### 獲取 Git 倉庫的差異清單
```ps1
irm bit.ly/ArchiveGitCommit|iex; diffCommit 

# [HEAD -> 當前狀態] 的檔案比較 (不包含尚未提交的新增)
irm bit.ly/ArchiveGitCommit|iex; diffCommit 
irm bit.ly/ArchiveGitCommit|iex; diffCommit HEAD
# [HEAD^ -> 當前狀態] 的檔案比較 (不包含尚未提交的新增)
irm bit.ly/ArchiveGitCommit|iex; diffCommit HEAD^
# [HEAD^ -> HEAD] 的檔案比較 (全)
irm bit.ly/ArchiveGitCommit|iex; diffCommit HEAD^ HEAD

# 指定git倉庫位置
irm bit.ly/ArchiveGitCommit|iex; diffCommit -Path "Z:\doc"
# 過濾僅輸出變動的清單
irm bit.ly/ArchiveGitCommit|iex; diffCommit -Filter "M"
```

### 獲取 Git 提交點的差異清單
```ps1
# HEAD節點的檔案全
irm bit.ly/ArchiveGitCommit|iex; archiveCommit
irm bit.ly/ArchiveGitCommit|iex; archiveCommit HEAD
# 指定git倉庫位置
irm bit.ly/ArchiveGitCommit|iex; archiveCommit -Path:"Z:\doc"
# 過濾僅取出特定檔案
irm bit.ly/ArchiveGitCommit|iex; archiveCommit -List:@("A.txt", "B.txt")
irm bit.ly/ArchiveGitCommit|iex; archiveCommit -List:@("*.css")
```






<br><br><br><br><br><br>

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
    -f !.git\;!.vs\
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

### 參考
- https://qiita.com/mima_ita/items/ac21c0588080e73fc458
- https://www.c-sharpcorner.com/article/poor-man-web-monitoring-tools/
- https://manual.winmerge.org/en/Command_line.html
- https://github.com/WinMerge/winmerge
- https://github.com/WinMerge/winmerge/releases/download/v2.16.24/winmerge-2.16.24-x64-exe.zip
- https://manual.winmerge.org/en/Filters.html
- https://stackoverflow.com/questions/59682491/winmerge-filter-for-file-types-and-include-subfolders



