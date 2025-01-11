# 封存資料夾中的特定檔案 (因為git無法archive未加入的檔案寫一個補齊)
function Compress-Files {
    param (
        [string]$Path,
        [string]$Output,
        [string[]]$List,
        [ValidateSet(1, 3, 5, 7, 9)]
        [UInt16]$CompressionLevel = 5
    )
    [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
    $Path = [IO.Path]::GetFullPath($Path)
    $Output = [IO.Path]::GetFullPath($Output)
    
    # 檢查輸入路徑
    if (!($Path -and (Test-Path -PathType Container $Path))) {
        Write-Error "輸入的路徑 '$Path' 有誤, 必須是資料夾"
    }    
    
    # 檢查 7z 命令是否存在
    & { param (
        [string]$Path
    )
        $Command = [IO.Path]::GetFileName($Path)
        try { Get-Command $Command -ErrorAction Stop | Out-Null } catch {
            $env:Path += ";$(Split-Path $Path)"
            try { Get-Command $Command -ErrorAction Stop | Out-Null } catch {
                Write-Error "Error:: Command '$Command' is not recognized." -ErrorAction Stop
            }
        }
    } "C:\Program Files\7-Zip\7z.exe"
    
    # 如果提供了檔案清單，則壓縮清單中的檔案
    if ($List) {
        $filesToCompress = "'" + (($List -replace "^\.\\") -join "' '") + "'"
    } else { # 壓縮整個資料夾
        $filesToCompress = "$Path\*"
    }
    
    # 生成壓縮命令
    $tmp = "$Output.tmp"
    $cmd = "7z.exe a -tzip '$tmp' $filesToCompress -mx=$CompressionLevel -aoa"
    
    # 執行壓縮檔案
    Push-Location
        Set-Location $Path
        Write-Host $cmd -ForegroundColor DarkGray
        $result = Invoke-Expression $cmd
    Pop-Location
    
    # 覆蓋目標檔案
    if (Test-Path $Output) {
        Remove-Item $Output -Force
    }
    if (Test-Path $tmp) {
        Rename-Item $tmp $Output
    }
    
    # 回傳結果
    $result -match "Everything is Ok"
}

# 基本使用方式
# Compress-Files -Path "C:\MyFolder" -Output "C:\output.zip"

# 指定檔案清單
# Compress-Files -Path "C:\MyFolder" -Output "C:\output.zip" -List @("file1.txt", "file2.txt")

# 設定壓縮等級
# Compress-Files -Path "C:\MyFolder" -Output "C:\output.zip" -CompressionLevel 9 