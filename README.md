## 使用範例

```
irm "https://raw.githubusercontent.com/hunandy14/autoCompare/master/compareGit.ps1" | iex

$ServAddr    = "Z:\Server"
$projectName = "doc_1130"

$Left        = "INIT"
$Right       = "master"
$gitDir      = "Z:\gitRepo\doc_develop"
$outDir      = "Z:\work"

compareGitCommit $Left $Right $gitDir -o $outDir -p:projectName -Line:2 -Comp

# compareGitCommit $Left $Right $gitDir -o $outDir -p:projectName -Line:2 -S:$ServAddr -Comp

```