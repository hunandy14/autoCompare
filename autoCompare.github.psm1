$PSJwtModuleHome = 'https://raw.githubusercontent.com/hunandy14/autoCompare/refs/heads/dev/2.0/src'

$scriptPaths = @(
    "unity/ConvertFrom-OctalString.ps1",
    "unity/Invoke-Git.ps1",
    "diffCommit.ps1",
    "archiveFiles.ps1",
    "archiveCommit.ps1",
    "archiveDiffCommit.ps1"
)

foreach ($scriptPath in $scriptPaths) {
    try {
        # Loding function in memory
        $irmParams = @{
            Uri = "$PSJwtModuleHome/$scriptPath"
        }; if (![string]::IsNullOrWhiteSpace($env:HTTP_PROXY)) {
            $irmParams['Proxy'] = $env:HTTP_PROXY
        }; Invoke-RestMethod @irmParams | Invoke-Expression -EA Stop
    } catch {
        Write-Error "$($_.Exception.Message)" -ea 1
    }
}

# 引用模組: irm raw.githubusercontent.com/hunandy14/autoCompare/refs/heads/dev/2.0/autoCompare.github.psm1|iex
