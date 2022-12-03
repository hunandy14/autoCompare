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
# 比較兩個提交點
irm bit.ly/ArchiveGitCommit|iex; irm bit.ly/DiffSource|iex; acvDC INIT HEAD |cmpSrc

# 比較尚未儲存的變更
irm bit.ly/ArchiveGitCommit|iex; irm bit.ly/DiffSource|iex; acvDC |cmpSrc
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

