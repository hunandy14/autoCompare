## 使用範例

```
irm "https://raw.githubusercontent.com/hunandy14/autoCompare/master/compareGit.ps1" | iex
$Left        = "INIT"
$Right       = "master"
$gitDir      = "Z:\gitRepo\doc_develop"
$outDir      = "Z:\work"
compareGitCommit $Left $Right $gitDir -o $outDir -p "doc_1130" -Line 2 -Com

compareGitCommit INIT master "Z:\gitRepo\doc_develop" -o "Z:\work" -p "doc_1130" -Line 2 -Com

```