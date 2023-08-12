# 獲取 Git 倉庫的差異清單

## 快速使用

```ps1
irm bit.ly/ArchiveGitCommit|iex; diffCommit HEAD
```

<br><br>

## 詳細說明

```ps1
# 載入函式庫
irm bit.ly/ArchiveGitCommit|iex

# 1. 未暫存變更:: [Staged -> WorkDir] (使用 -Tracked 可剔除未追蹤檔案)
irm bit.ly/ArchiveGitCommit|iex; diffCommit
# 2. 未提交變更:: [HEAD -> WorkDir] (使用 -Tracked 可剔除未追蹤檔案)
irm bit.ly/ArchiveGitCommit|iex; diffCommit HEAD
# 3. 提交點間的變更 [HEAD^ -> HEAD]
irm bit.ly/ArchiveGitCommit|iex; diffCommit HEAD^ HEAD
# 4. 僅已暫存變更:: [HEAD -> Staged] (HEAD可省略或指定其他起點)
irm bit.ly/ArchiveGitCommit|iex; diffCommit HEAD -Cached

# 指定git倉庫位置
irm bit.ly/ArchiveGitCommit|iex; diffCommit -Path "Z:\doc"
# 過濾僅輸出變動的清單
irm bit.ly/ArchiveGitCommit|iex; diffCommit -Filter "ADMR"
```


<br><br><br>

## 關於 Filter 的詳細說明:: [連結](https://explainshell.com/explain?cmd=git+diff+--name-only+--cached+--diff-filter%3DACMR+--ignore-space-at-eol+-M100%25)

```txt
--diff-filter=[(A|C|D|M|R|T|U|X|B)...[*]]
    Select only files that are Added (A), Copied (C), Deleted (D), Modified (M), Renamed (R), have their
    type (i.e. regular file, symlink, submodule, ...) changed (T), are Unmerged (U), are Unknown (X), or
    have had their pairing Broken (B). Any combination of the filter characters (including none) can be
    used. When * (All-or-none) is added to the combination, all paths are selected if there is any file
    that matches other criteria in the comparison; if there is no file that matches other criteria,
    nothing is selected.
```
