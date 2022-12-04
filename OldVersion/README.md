
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


