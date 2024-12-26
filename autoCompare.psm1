# 引用所有函數檔案
. "$PSScriptRoot\src\ConvertFrom-OctalString.ps1"
. "$PSScriptRoot\src\archiveFiles.ps1"
. "$PSScriptRoot\src\Invoke-Git.ps1"
. "$PSScriptRoot\src\diffCommit.ps1"
. "$PSScriptRoot\src\archiveCommit.ps1"

# 導出所有公開函數
Export-ModuleMember -Function @(
    'ConvertFrom-OctalString',
    'archiveFiles',
    'Invoke-Git',
    'diffCommit',
    'archiveCommit'
) 
