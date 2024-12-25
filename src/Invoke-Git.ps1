function Invoke-Git {
    <#
    .SYNOPSIS
        執行 Git 命令的統一接口
    .PARAMETER Command
        Git 命令及其參數
    .PARAMETER Path
        Git 倉庫的路徑
    .EXAMPLE
        Invoke-Git status
        Invoke-Git diff --name-status HEAD
        Invoke-Git -Path $repoPath status
        Invoke-Git status -Path $repoPath
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)]
        [ValidateNotNull()]
        [string[]]$Command,
        
        [Parameter()]
        [ValidateScript({
            if (!(Test-Path $_ -PathType Container)) {
                throw "Path does not exist or is not a directory: $_"
            }
            if (!(Test-Path (Join-Path $_ ".git") -PathType Container)) {
                throw "Not a valid Git repository: $_"
            }
            return $true
        })]
        [string]$Path = (Get-Location)
    )
    
    # 檢測 git 命令是否存在
    try { 
        $gitCmd = Get-Command "git" -ErrorAction Stop
        Write-Verbose "Found Git at: $($gitCmd.Path)"
    } catch {
        throw "Git is not installed on this system. Please install Git to continue."
    }
    
    try {
        # 解析並驗證路徑
        [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
        $Path = $Path -replace "^Microsoft.PowerShell.Core\\FileSystem::"
        $Path = [System.IO.Path]::GetFullPath($Path)
        if (!(Test-Path -PathType Container "$Path\.git")) { 
            Write-Error "Error:: The path `"$Path`" is not a git folder" -ErrorAction Stop 
        }
        Write-Verbose "Using Git repository at: $Path"
        Push-Location $Path
        
        # 臨時改變控制台編碼為 utf8
        $originalEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        
        # 執行 Git 命令並捕獲所有輸出
        Write-Verbose "Executing Git command: git $($Command -join ' ')"
        $output = & git -c core.quotepath=false @Command 2>&1
        
        # 分離標準輸出和錯誤輸出
        $stdOut = $output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }
        $stdErr = $output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
        
        # 檢查命令執行狀態
        if ($LASTEXITCODE -ne 0) {
            # 構建詳細的錯誤信息用於 Verbose 輸出
            $verboseError = @(
                "Git command failed with exit code: $LASTEXITCODE"
                $(if ($stdOut) { "## Standard output ##", ($stdOut -join "`n") })
                $(if ($stdErr) { "## Error output ##", ($stdErr -join "`n") })
            ) -join "`n"
            
            # 寫入詳細錯誤日誌
            Write-Verbose $verboseError
            
            # 只拋出 Git 的錯誤信息
            throw ($stdErr -join "`n")
        }
        
        # 只返回標準輸出
        return $stdOut
    } catch {
        throw $_.Exception.Message
    } finally {
        [Console]::OutputEncoding = $originalEncoding
        Pop-Location
    }
}
