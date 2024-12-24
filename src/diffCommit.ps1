# 獲取提交點的差異清單
function diffCommit {
    param (
        [Parameter(Position = 0, ParameterSetName = "")]
        [string] $Commit1, # Commit 兩者皆未輸入時輸出 [暫存 -> 當前工作目錄] 的變更
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $Commit2, # Commit2 未輸入時輸出 [Commit1 -> 當前工作目錄] 的變更
        [switch] $Cached,  # 剔除未提交檔案 (也可以解釋成將 Commit2 設置成 Stage [Commit2 必須為空])
        [switch] $Tracked, # 剔除未追蹤的清單 (git diff 是不包含未追蹤檔案的我修改了這個特性改成預設是有的 [只有在 Commit2 與 Cached 為空時才有效])
        [Parameter(ParameterSetName = "")]
        [string] $Path = (Get-Location),
        [Parameter(ParameterSetName = "")]
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
                Write-Warning "The '-Cached' parameter will not take effect because it is only valid when 'Commit2' is empty."
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
# diffCommit INIT HEAD -Path "Z:\doc" -Filter "ADMR"
# diffCommit -Path "Z:\doc" HEAD        # [HEAD  -> WorkDir]:: 未提交的變更
# diffCommit -Path "Z:\doc" -Cached     # [HEAD  -> Stage]  :: 已暫存的變更
# diffCommit -Path "Z:\doc"             # [Stage -> WorkDir]:: 未暫存的變更
# diffCommit -Path "Z:\doc" -Tracked    # [Stage -> WorkDir]:: 未暫存的變更(不含未追蹤的檔案)
# (diffCommit -Path "Z:\doc" HEAD^^ HEAD^) |Select-Object * |Format-Table
# diffCommit -Path "Z:\doc" HEAD^ HEAD -Cached
