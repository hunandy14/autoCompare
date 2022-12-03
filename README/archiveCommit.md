### 獲取 Git 提交點的差異清單
快速使用
```ps1
irm bit.ly/ArchiveGitCommit|iex; archiveCommit HEAD
```

<br>

詳細說明
```ps1
# 載入函式庫
irm bit.ly/ArchiveGitCommit|iex

# HEAD節點的檔案全
archiveCommit HEAD
# 過濾取出特定檔案
archiveCommit HEAD @("A.txt", "B.txt")
archiveCommit HEAD @("*.css")

# 指定git倉庫位置
archiveCommit HEAD -Path:"Z:\doc"

# 解壓輸出縮檔案
archiveCommit HEAD -Expand
archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"$env:TEMP\archiveCommit"
```

<br><br>

關於自動解壓 -Expand
1. 指定目錄為路徑時不會輸出壓縮檔直接，取出檔案到該目錄
2. 指定目錄為壓縮檔時，原地解壓縮到壓縮旁

<br><br>

例外狀況

```ps1
# 輸出路徑與Git目錄相同可能會會覆蓋掉未提交的的檔案(程序停止)
archiveCommit -Output:(Get-Location) HEAD -Expand
archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"Z:\doc" -Expand
# 解壓縮路徑與Git目錄相同(警告)
archiveCommit HEAD @("*.css") -Path:"Z:\doc" -Output:"Z:\doc.zip" -Expand
```
