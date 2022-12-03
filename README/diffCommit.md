## 獲取 Git 倉庫的差異清單
```ps1
# 載入函式庫
irm bit.ly/ArchiveGitCommit|iex

# [Staged -> 當前狀態] 的檔案比較 (當前狀態: 無Staged時會已HEAD為主, 當前狀態: 不包含新增的檔案)
irm bit.ly/ArchiveGitCommit|iex; diffCommit
# [HEAD -> Staged] 的檔案比較  (Staged: 無Staged時會已當前狀態為主, 當前狀態: 不包含新增的檔案)
irm bit.ly/ArchiveGitCommit|iex; diffCommit HEAD
# [HEAD^ -> HEAD] 的檔案比較 (全)
irm bit.ly/ArchiveGitCommit|iex; diffCommit HEAD^ HEAD

# 指定git倉庫位置
irm bit.ly/ArchiveGitCommit|iex; diffCommit -Path "Z:\doc"
# 過濾僅輸出變動的清單
irm bit.ly/ArchiveGitCommit|iex; diffCommit -Filter "ADMR"
```

<br><br>

> 1. 關於節點參數的省略，這是跟著 git diff 的標準僅轉發命令而已
> 2. 關於比較尚未提交的檔案清單
>    1. 如果省略兩個參數的會缺少新增的檔案
>    2. 正確的作法是Stage後指定起點為HEAD(終點留空)
> 3. 在沒有Staged的情況下起點指定HEAD與省略是完全一樣的結果 [HEAD -> 當前狀態]

<br><br>

> [關於 Filter 的詳細說明](https://explainshell.com/explain?cmd=git+diff+--name-only+--cached+--diff-filter%3DACMR+--ignore-space-at-eol+-M100%25)
```txt
--diff-filter=[(A|C|D|M|R|T|U|X|B)...[*]]
    Select only files that are Added (A), Copied (C), Deleted (D), Modified (M), Renamed (R), have their
    type (i.e. regular file, symlink, submodule, ...) changed (T), are Unmerged (U), are Unknown (X), or
    have had their pairing Broken (B). Any combination of the filter characters (including none) can be
    used. When * (All-or-none) is added to the combination, all paths are selected if there is any file
    that matches other criteria in the comparison; if there is no file that matches other criteria,
    nothing is selected.
```

