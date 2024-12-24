# 引用模組
Import-Module "$PSScriptRoot\autoCompare.psm1"

# 封存 Git差異節點 間的變動檔案
function archiveDiffCommit {
    [Alias("acvDC")]
    param (
        [Parameter(Position = 0, ParameterSetName = "")]
        [string] $Commit1,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $Commit2,
        
        [Parameter(ParameterSetName = "")]
        [string] $Path,
        [string] $Output,
        
        [Parameter(ParameterSetName = "")]
        [switch] $OpenOutDir,
        [switch] $OutAllFile
    )
    # 檢測路徑
    [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
    if ($Path) { $Path = [System.IO.Path]::GetFullPath($Path) } else { $Path = Get-Location}
    if ($Output) { $Output = [System.IO.Path]::GetFullPath($Output) } else {
        $Output = "$Env:TEMP\archiveDiffCommit"
        if (Test-Path "$Env:TEMP\archiveDiffCommit\*") { Remove-Item "$Env:TEMP\archiveDiffCommit\*" -Recurse }
    }
    if (!(Test-Path -PathType:Container "$Path\.git")) { Write-Error "Error:: The path `"$Path`" is not a git folder" -ErrorAction:Stop }
    
    
    # 處理節點
    if (!$Commit1) { $Commit1 = 'HEAD' }
    if (!$Commit2) { $IsCurrStatusDiff=$true }
    # 節點名稱
    $CommitName1 = $Commit1
    $CommitName2 = if ($Commit2) {$Commit2} else {'CURR'}
    Write-Host "Diff Commit:: [$CommitName1 -> $CommitName2]"
    
    
    # 獲取 節點1 差異清單 (變更前)
    $List1Cmd = "diffCommit $Commit2 $Commit1 -Path $Path" -replace '\s+', ' '
    # Write-Host "  List1:: $List1Cmd" -ForegroundColor DarkGray
    $List1 = Invoke-Expression $List1Cmd; if ($List1) {
        if ($IsCurrStatusDiff) {
            # 因為git的省參數狀態只能比較[HEAD->CURR]不能比較[CURR->HEAD]，直觀的解法把A跟D反過來就好
            $List1 = ($List1|Where-Object{$_.Status -notin "A" -and $_.Status -notin "U"}) # 去除AU
            # 處理更名物件拆成AD並刪除A
            $List1|ForEach-Object{
                if (($_.Status)[0] -eq "R") {
                    $_.Name = $_.OldName
                    $_.OldName = $null
                    $_.Status = "D"
                }
            }
        } else {
            $List1 = ($List1|Where-Object{$_.Status -notin "D"})
        }
    }
    # Write-Host ($List1|Format-Table|Out-String)
    # 獲取 節點2 差異清單 (變更後)
    $List2Cmd = "diffCommit $Commit1 $Commit2 -Path $Path" -replace '\s+', ' '
    # Write-Host "  List2:: $List2Cmd" -ForegroundColor DarkGray
    $OutList = Invoke-Expression $List2Cmd; if ($OutList) {
        # 排除已經被刪除的清單
        $List2 = ($OutList|Where-Object{$_.Status -notin "D"})
    }
    # Write-Host ($List2|Format-Table|Out-String)
    
    
    # 獲取 節點 差異檔案 (變更後)
    if ($OutAllFile) { 
        # 輸出所有檔案 (List為null預設會全出)
        $Out1 = archiveCommit -Path:$Path -List:$null -Output $Output $Commit1
        $Out2 = archiveCommit -Path:$Path -List:$null -Output $Output $Commit2
    } else {
        # 獲取差異清單檔案
        if ($List1) { $Out1 = archiveCommit -Path:$Path -List:($List1.Name) -Output $Output $Commit1 }
        if ($List2) { $Out2 = archiveCommit -Path:$Path -List:($List2.Name) -Output $Output $Commit2 }
        # Zip的定義中沒辦法存在空zip，遇到List1為空做一個空檔案比較
        if (!$List1) {
            if ($Commit1) { $ZipCmt = $Commit1 } else { $ZipCmt = "CURR" }
            $emptyFile = "$Env:TEMP\_"
            $emptyZip = "$Env:TEMP\archiveDiffCommit\$($ZipCmt)_CommitIsNonDiffFile.zip"
            if (!(Test-Path $emptyFile)) { New-Item $emptyFile -ItemType:File|Out-Null }
            Compress-Archive $emptyFile $emptyZip -Force
            $Out1=$emptyZip
        }
        if (!$List2) {
            if ($Commit2) { $ZipCmt = $Commit2 } else { $ZipCmt = "CURR" }
            $emptyFile = "$Env:TEMP\_"
            $emptyZip = "$Env:TEMP\archiveDiffCommit\$($ZipCmt)_CommitIsNonDiffFile.zip"
            if (!(Test-Path $emptyFile)) { New-Item $emptyFile -ItemType:File|Out-Null }
            Compress-Archive $emptyFile $emptyZip -Force
            $Out2=$emptyZip
        }
    }
    
    
    # 輸出 差異清單表
    $OutString = ($OutList | ForEach-Object { $index; $index=1} {
        $_ | Select-Object @{Name='Index'; Expression={[string]$index}},*
        $index++
    } |Format-Table |Out-String) -split "`r`n" -notmatch "^$"
    $OutString > "$Output\diff-list.txt"
    Write-Host ''
    Write-Host ($OutString[0..1] -join "`r`n") -ForegroundColor DarkGray
    Write-Host ($OutString[2..($OutString.Length-1)] -join "`r`n")
    Write-Host ''
    
    
    # 輸出物件
    if ($Commit1 -and !$Commit2) { $Commit2 = "CURR"}
    $Obj = @()
    $Obj += [PSCustomObject]@{
        Commit   = $Commit1
        FullName = $Out1
    }
    $Obj += [PSCustomObject]@{
        Commit   = $Commit2
        FullName = $Out2
    }
    # 打開輸出資料夾
    if ($OpenOutDir) { explorer.exe $Output }
    # 回傳完整路徑
    return $Obj
}
# 輸出 [HEAD -> CURR] 差異檔案
# archiveDiffCommit -Path:"Z:\doc"
# archiveDiffCommit HEAD -Path:"Z:\doc"
# 輸出 [INIT -> HEAD] 差異檔案
# archiveDiffCommit INIT HEAD -Path:"Z:\doc"
# 輸出 [HEAD -> INIT] 差異檔案
# archiveDiffCommit HEAD INIT -Path:"Z:\doc"
# 輸出 [INIT -> HEAD] 差異檔案並過濾特定檔案
# archiveDiffCommit INIT0 HEAD -Path:"Z:\doc" -Include:@("*.css")
# DiffSource "doc-INIT0.zip" "doc-HEAD.zip"
# archiveDiffCommit INIT0 HEAD -Path:"Z:\doc"
# 空節點測試
# archiveDiffCommit -Path:"Z:\doc" -Include EAWD1100.css,EAWD1100.js
# OpenOutDir
# archiveDiffCommit -Path:"Z:\doc" -OpenOutDir
# 輸出所有檔案測試
# archiveDiffCommit -Path:"Z:\doc" -OpenOutDir -OutAllFile
# 比較git節點
# Invoke-RestMethod "raw.githubusercontent.com/hunandy14/autoCompare/master/DiffSource.ps1"|Invoke-Expression
# . ".\DiffSource.ps1"
# acvDC 'HEAD^' 'HEAD' -Path:"Z:\doc"
# acvDC 'HEAD^^' 'HEAD' -Path:"Z:\doc" |cmpSrc
# acvDC INIT0 HEAD -Path:"Z:\doc"
# acvDC INIT0 HEAD -Path:"Z:\doc"|cmpSrc
# acvDC HEAD -Path:"Z:\doc" |cmpSrc
# acvDC -Path:"Z:\doc" HEAD
# acvDC -Path:"Z:\doc" |cmpSrc
# acvDC -Path:"Z:\doc" -OutAllFile |cmpSrc
# 測試中文檔名問題
# acvDC -Path:"Z:\gitCode"
# acvDC -Path:"Z:\gitCode" |cmpSrc
# acvDC -Path:"Z:\gitCode" -OutAllFile |cmpSrc
