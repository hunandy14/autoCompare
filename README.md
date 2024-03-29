# 比對兩個資料夾間檔案的差異

## 快速使用

比較兩個資料夾

```ps1
irm bit.ly/DiffSource|iex; DiffSource $Left $Right
```

比較 Git 提交點 [HEAD -> CURR]

```ps1
irm bit.ly/DiffGitSource|iex; acvDC |cmpSrc
```

比較 Git 提交點 [HEAD^ -> HEAD]

```ps1
irm bit.ly/DiffGitSource|iex; acvDC HEAD^ HEAD |cmpSrc
```

<br><br><br>

## 自動比對 (資料夾, 單檔, 壓縮檔)

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

<br><br><br>

## 比對 GIT 提交點

詳細使用說明

```ps1
# 載入函式
irm bit.ly/DiffGitSource|iex;

# 尚未提交的變更 [HEAD -> CURR] 的變更
irm bit.ly/DiffGitSource|iex; acvDC |cmpSrc
irm bit.ly/DiffGitSource|iex; acvDC HEAD |cmpSrc

# 指定交點的變更 [HEAD^ -> HEAD] 的變更
irm bit.ly/DiffGitSource|iex; acvDC HEAD^ HEAD |cmpSrc

# 比較節點的變更且輸出所有檔案
irm bit.ly/DiffGitSource|iex; acvDC -OutAllFile |cmpSrc
```
