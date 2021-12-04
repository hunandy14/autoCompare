## 使用範例
===

```
irm "https://raw.githubusercontent.com/hunandy14/autoCompare/master/compareGit.ps1" | iex
$CM1         = "master"
$CM2         = "INIT"
$gitDir      = "Z:\gitRepo\doc_develop"
$outDir      = "Z:\work"
compareGitCommit $CM1 $CM2 $gitDir -o $outDir -p "release_report" -L 5 -Co
```