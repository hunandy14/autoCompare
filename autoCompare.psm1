# 引用所有函數檔案
. "$PSScriptRoot\src\unity\ConvertFrom-OctalString.ps1"
. "$PSScriptRoot\src\unity\Install-WinMerge.ps1"
. "$PSScriptRoot\src\unity\Invoke-Git.ps1"
. "$PSScriptRoot\src\diffCommit.ps1"
. "$PSScriptRoot\src\archiveCommit.ps1"
. "$PSScriptRoot\src\archiveDiffCommit.ps1"
. "$PSScriptRoot\src\diffSource.ps1"

# 導出所有公開函數
Export-ModuleMember -Function @(
    'diffCommit',
    'archiveFiles',
    'archiveCommit',
    'archiveDiffCommit'
) -Alias @(
    'acvDC',
    'cmpSrc'
)

# 引用模組: Import-Module .\autoCompare.psm1 -Force
