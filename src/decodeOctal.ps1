# 解碼八進制編碼的字串
function ConvertFrom-OctalString {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string]$InputString,
        [Text.Encoding]$Encoding = [Text.Encoding]::UTF8
    )
    # 匹配三個連續的八進制序列（一個完整的中文字符）
    $pattern = '(\\[0-7]{3}){3}'
    
    # 執行替換
    [regex]::Replace($InputString, $pattern, {
        param($m)
        try {
            if ($m.Value.Length -ne 12) { throw }
            return $Encoding.GetString([byte[]](
                [Convert]::ToByte($m.Value.Substring(1, 3), 8),
                [Convert]::ToByte($m.Value.Substring(5, 3), 8),
                [Convert]::ToByte($m.Value.Substring(9, 3), 8)
            ))
        }
        catch {
            return $m.Value
        }
    })
}

# 基本使用方式
# '"Z:/git/\346\226\260\345\242\236\350\263\207\346\226\231\345\244\276/\346\270\254\350\251\246\350\267\257\345\276\221.txt"' | ConvertFrom-OctalString

# 空字串測試
# '' | ConvertFrom-OctalString
# $null | ConvertFrom-OctalString

# 無效八進制測試
# '\999' | ConvertFrom-OctalString

# 混合內容測試
# 'Hello\346\226\260ㄅㄆㄇ\346\226\260\346\226\260あいう\346\226\260World\777\777\777' | ConvertFrom-OctalString

# 不同編碼測試
# 'Test' | ConvertFrom-OctalString -Encoding ([Text.Encoding]::ASCII)
