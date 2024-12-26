# 獲取提交點的差異清單
function diffCommit {
    <#
    .SYNOPSIS
        獲取 Git 提交點的差異清單
    .PARAMETER Commit1
        起始提交點。若未指定，則使用 Stage (當使用 Cached 時會變更成 HEAD)
    .PARAMETER Commit2
        結束提交點。若未指定，則使用工作目錄  (當使用 Cached 時會變更成 Stage)
    .PARAMETER Cached
        只顯示已暫存的變更 (不可指定 Commit2)
    .PARAMETER Tracked
        只顯示已追蹤的檔案變更 (不可指定 Commit2, Cached)
    .EXAMPLE
        diffCommit -Cached         # [HEAD   -> Stage  ] 已暫存的變更 (可指定 Commit1 更改起點)
        diffCommit                 # [Stage  -> WorkDir] 未暫存的變更 (可指定 Tracked 剔除未追蹤的檔案)
        diffCommit HEAD            # [Commit -> WorkDir] 未提交的變更 (可指定 Tracked 剔除未追蹤的檔案)
        diffCommit HEAD^ HEAD      # [Commit -> Commit ] 指定 Commit 的範圍
    #>
    
    [CmdletBinding(DefaultParameterSetName = 'WorkDir')]
    param (
        # 比較兩個 Commit 的變更
        [Parameter(Position = 0, ParameterSetName = 'WorkDir')]
        [Parameter(Position = 0, ParameterSetName = 'Staged')]
        [Parameter(Position = 0, ParameterSetName = 'Commits', Mandatory = $true)]
        [string] $Commit1,
        
        [Parameter(Position = 1, ParameterSetName = 'Commits')]
        [string] $Commit2,
        
        # 已暫存的變更 (已經 git add 但尚未提交)
        [Parameter(ParameterSetName = 'Staged')]
        [switch] $Cached,
        
        # 剔除未追蹤的檔案 (原生 git diff 是不包含未追蹤檔案的, 我修改了這個特性改成預設是有的)
        [Parameter(ParameterSetName = 'WorkDir')]
        [switch] $Tracked,
        
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
    
    # 獲取差異資訊
    try {
        # 準備 git 命令參數
        $gitParams = @(
            if ($Filter) { "--diff-filter=$Filter" }
            if ($Cached) { "--cached" }
            if ($Commit1) { $Commit1 }
            if ($Commit2) { $Commit2 }
        )
        # 執行命令獲取差異資訊
        Push-Location $Path
        $results = @{
            Status    = @(Invoke-Git diff --name-status @gitParams)
            NumStat   = @(Invoke-Git diff --numstat @gitParams)
            Untracked = @(if (!$Tracked -and (!$Cached -and !$Commit2)) { 
                @(Invoke-Git ls-files --others --exclude-standard) | 
                ForEach-Object { "U`t$_" }
            })
        }
    } catch { throw } finally {
        Pop-Location
    }
    
    # 設定預設顯示屬性
    $PSStandardMembers = [Management.Automation.PSMemberInfo[]]@(
        New-Object Management.Automation.PSPropertySet(
            'DefaultDisplayPropertySet',
            [string[]]@('Status', 'Name', 'StepAdd', 'StepDel')
        )
    )
    
    # 處理已追蹤的檔案變更
    $changes = for ($i = 0; $i -lt $results.Status.Count; $i++) {
        $statusParts = $results.Status[$i] -split "`t"
        $numStatParts = $results.NumStat[$i] -split "`t"
        
        $change = [PSCustomObject]@{
            Status  = $statusParts[0]
            Name    = ConvertFrom-OctalString $statusParts[1]
            OldName = if ($statusParts[0] -match '^R') { $statusParts[1] }
            StepAdd = $numStatParts[0]
            StepDel = $numStatParts[1]
        }
        
        # 處理重命名情況
        if ($change.Status -match '^R') {
            $change.Name = ConvertFrom-OctalString $statusParts[2]
        }
        
        Add-Member -InputObject $change -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers
        $change
    }
    
    # 處理未追蹤的檔案 (git 原生未追蹤的檔案不會有 Status 與 NumStat)
    $untrackedChanges = $results.Untracked | ForEach-Object {
        $parts = $_ -split "`t"
        $filePath = Join-Path $Path $parts[1]
        
        # 計算未追蹤檔案的行數
        $stepAdd = if (Test-Path $filePath -PathType Leaf) {
            try {
                (Get-Content $filePath -Raw).Split("`n").Length
            } catch { $null }
        } else { $null }
        
        $change = [PSCustomObject]@{
            Status  = $parts[0]
            Name    = ConvertFrom-OctalString $parts[1]
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

# Import-Module ".\src\ConvertFrom-OctalString.ps1"
# Import-Module ".\src\Invoke-Git.ps1"

# diffCommit -Path "Z:\doc" -Cached           # [HEAD  -> Stage  ]:: 已暫存的變更
# diffCommit -Path "Z:\doc" HEAD -Cached      # [HEAD  -> Stage  ]:: 已暫存的變更
# diffCommit -Path "Z:\doc" HEAD^ -Cached     # [HEAD^ -> Stage  ]:: 已暫存的變更

# diffCommit -Path "Z:\doc"                   # [Stage -> WorkDir]:: 未暫存的變更
# diffCommit -Path "Z:\doc" HEAD              # [HEAD  -> WorkDir]:: 未提交的變更
# diffCommit -Path "Z:\doc" HEAD^ HEAD        # [HEAD^ -> HEAD   ]:: 指定範圍的變更

# diffCommit -Path "Z:\doc" -Tracked          # [Stage -> WorkDir]:: 未暫存的變更(不含未追蹤的檔案)
# diffCommit -Path "Z:\doc" HEAD -Tracked     # [HEAD  -> WorkDir]:: 未提交的變更(不含未追蹤的檔案)
# diffCommit -Path "Z:\doc" HEAD^ -Tracked    # [HEAD  -> WorkDir]:: 未提交的變更(不含未追蹤的檔案)

# diffCommit INIT HEAD -Path "Z:\doc" -Filter "ADMR"    # 僅顯示已暫存、未暫存、已提交、未提交的檔案
# (diffCommit -Path "Z:\doc" HEAD^^ HEAD^) |Select-Object * |Format-Table

# diffCommit -Path "Z:\doc" HEAD^ HEAD -Cached      # Cached 不可指定 Commit2
# diffCommit -Path "Z:\doc" HEAD^ HEAD -Tracked     # Tracked 不可指定 Commit2
# diffCommit -Path "Z:\doc" HEAD -Tracked -Cached   # Tracked 不可指定 Cached
# diffCommit -Path "Z:\doc" -Tracked -Cached        # Tracked 不可指定 Cached
