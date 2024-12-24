# 獲取提交點的差異清單
function diffCommit {
    <#
    .SYNOPSIS
        獲取 Git 提交點的差異清單
    .PARAMETER Commit1
        起始提交點。若未指定，則使用HEAD
    .PARAMETER Commit2
        結束提交點。若未指定，則使用工作目錄
    .PARAMETER Cached
        只顯示已暫存的變更 (不能與 Commit2 同時使用)
    .PARAMETER Tracked
        只顯示已追蹤的檔案變更 (不能與 Commit2, Cached 同時使用)
    .EXAMPLE
        diffCommit                 # [Stage  -> WorkDir] 未暫存的變更 (可指定 Tracked 剔除未追蹤的檔案)
        diffCommit HEAD            # [Commit -> WorkDir] 未提交的變更 (可指定 Tracked 剔除未追蹤的檔案)
        diffCommit -Cached         # [Commit -> Stage  ] 已暫存的變更 (不能指定 Commit2, 可指定 Commit1 更改起點)
        diffCommit HEAD^ HEAD      # [Commit -> Commit ] 指定兩個 Commit 的變更
    #>
    
    [CmdletBinding(DefaultParameterSetName = 'WorkDir')]
    param (
        # 一般比較模式
        [Parameter(Position = 0, ParameterSetName = 'WorkDir')]
        [Parameter(Position = 0, ParameterSetName = 'Staged')]
        [Parameter(Position = 0, ParameterSetName = 'Commits')]
        [string] $Commit1, # Commit 兩者皆未輸入時輸出 [暫存 -> 當前工作目錄] 的變更
        
        [Parameter(Position = 1, ParameterSetName = 'Commits')]
        [string] $Commit2, # Commit2 未輸入時輸出 [Commit1 -> 當前工作目錄] 的變更
        
        # 將 Commit2 設為 Stage 點(已經 add 但尚未提交的範圍)
        [Parameter(ParameterSetName = 'Staged')]
        [switch] $Cached, # 剔除未提交檔案 (也可以解釋成將 Commit2 設置成 Stage [Commit2 必須為空])
        
        # 將被設置成 WorkDir 範疇的 Commit2 擴展增加 Untracked 的檔案
        [Parameter(ParameterSetName = 'WorkDir')]
        [switch] $Tracked, # 剔除未追蹤的清單 [只有在 Commit2 與 Cached 為空時才有效]
        # (git diff 是不包含未追蹤檔案的, 我修改了這個特性改成預設是有的)
        
        # 路徑參數
        [string] $Path = (Get-Location),
        
        # 過濾參數
        [ValidatePattern('^[ADMRCUT]+$')]
        [string] $Filter
    )
    
    # 檢測路徑
    [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
    $Path = $Path -replace "^Microsoft.PowerShell.Core\\FileSystem::"
    $Path = [System.IO.Path]::GetFullPath($Path)
    if (!(Test-Path -PathType Container "$Path\.git")) { 
        Write-Error "Error:: The path `"$Path`" is not a git folder" -ErrorAction Stop 
    }
    
    # 檢測 git 命令
    try { 
        Get-Command "git" -ErrorAction Stop | Out-Null 
    } catch {
        Write-Error "Command 'git' is not installed on this system. Please install Git to continue." -ErrorAction Stop
    }
    
    # 準備 git 命令參數
    $gitParams = @{
        Filter = if ($Filter) { "--diff-filter=$Filter" }
        Stage  = if ($Cached) {
            if (!$Commit2) {
                "--cached"
            } else { 
              Write-Error "Cannot use -Cached with Commit2" -ErrorAction Stop
            }
        }
    }
    
    # 生成命令
    $commands = @{
        Status  = "git diff --name-status $($gitParams.Filter) $($gitParams.Stage) $Commit1 $Commit2".Trim() -replace "\s{2,}", " "
        NumStat = "git diff --numstat $($gitParams.Filter) $($gitParams.Stage) $Commit1 $Commit2".Trim() -replace "\s{2,}", " "
        Untracked = "(git ls-files --others --exclude-standard) -replace('^', `"U`t`")"
    }
    
    # 執行命令獲取差異資訊
    try {
        Push-Location $Path
        $results = @{
            Status    = @(Invoke-Expression $commands.Status)
            NumStat   = @(Invoke-Expression $commands.NumStat)
            Untracked = @(if (!$Tracked -and (!$Cached -and !$Commit2)) { 
                Invoke-Expression $commands.Untracked 
            })
        }
    } finally {
        Pop-Location
    }
    
    # 設定預設顯示屬性
    $defaultProperties = @('Status', 'Name', 'StepAdd', 'StepDel')
    $defaultDisplaySet = New-Object System.Management.Automation.PSPropertySet(
        'DefaultDisplayPropertySet', [string[]]$defaultProperties
    )
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplaySet)
    
    # 處理已追蹤的檔案變更
    $changes = for ($i = 0; $i -lt $results.Status.Count; $i++) {
        $statusParts = $results.Status[$i] -split "`t"
        $numStatParts = $results.NumStat[$i] -split "`t"
        
        $change = [PSCustomObject]@{
            Status  = $statusParts[0]
            Name    = decodeOctal $statusParts[1]
            OldName = if ($statusParts[0] -match '^R') { $statusParts[1] }
            StepAdd = $numStatParts[0]
            StepDel = $numStatParts[1]
        }
        
        # 處理重命名情況
        if ($change.Status -match '^R') {
            $change.Name = decodeOctal $statusParts[2]
        }
        
        Add-Member -InputObject $change -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers
        $change
    }
    
    # 處理未追蹤的檔案
    $untrackedChanges = $results.Untracked | ForEach-Object {
        $parts = $_ -split "`t"
        $filePath = Join-Path $Path $parts[1]
        
        # 計算未追蹤檔案的行數
        $stepAdd = if (Test-Path $filePath -PathType Leaf) {
            try {
                (Get-Content $filePath -Raw).Split("`n").Length
            } catch {
                $null  # 如果檔案無法讀取，返回 null
            }
        } else { $null }
        
        $change = [PSCustomObject]@{
            Status  = $parts[0]
            Name    = decodeOctal $parts[1]
            OldName = $null
            StepAdd = $stepAdd
            StepDel = 0
        }
        Add-Member -InputObject $change -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers
        $change
    }
    
    # 合併並排序結果
    @($changes) + @($untrackedChanges) | Sort-Object Name
}

# Import-Module .\src\decodeOctal.ps1 -Force
# diffCommit -Path "Z:\doc"                   # [Stage -> WorkDir]:: 未暫存的變更
# diffCommit -Path "Z:\doc" -Cached           # [HEAD  -> Stage]  :: 已暫存的變更
# diffCommit -Path "Z:\doc" HEAD -Cached      # [HEAD  -> Stage]  :: 已暫存的變更
# diffCommit -Path "Z:\doc" HEAD              # [HEAD  -> WorkDir]:: 未提交的變更
# diffCommit -Path "Z:\doc" -Tracked          # [Stage -> WorkDir]:: 未暫存的變更(不含未追蹤的檔案)
# diffCommit -Path "Z:\doc" HEAD -Tracked     # [HEAD  -> WorkDir]:: 未提交的變更(不含未追蹤的檔案)
# diffCommit INIT HEAD -Path "Z:\doc" -Filter "ADMR"
# (diffCommit -Path "Z:\doc" HEAD^^ HEAD^) |Select-Object * |Format-Table

# diffCommit -Path "Z:\doc" HEAD^ HEAD -Cached
# diffCommit -Path "Z:\doc" HEAD^ HEAD -Tracked
# diffCommit -Path "Z:\doc" -Tracked -Cached
