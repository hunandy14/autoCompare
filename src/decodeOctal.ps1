# 解碼八進制編碼的字串
function ConvertFrom-OctalBytes {
    param (
        [Parameter(Mandatory)]
        [string]$OctalString
    )
    return [byte[]](
        [Convert]::ToByte($OctalString.Substring(1, 3), 8),
        [Convert]::ToByte($OctalString.Substring(5, 3), 8),
        [Convert]::ToByte($OctalString.Substring(9, 3), 8)
    )
}

function decodeOctal {
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        [string]$InputString,
        [Text.Encoding]$Encoding = [Text.Encoding]::UTF8
    )
    
    # 匹配三個連續的八進制序列（一個完整的中文字符）
    $pattern = '(\\[0-7]{3}){3}'
    try {
        $result = [regex]::Replace($InputString, $pattern, {
            param($m)
            try {
                # 將三個八進制序列轉換為一個字符
                $bytes = ConvertFrom-OctalBytes -OctalString $m.Value
                return $Encoding.GetString($bytes)
            }
            catch {
                # 解析失敗就原樣回傳
                return $m.Value
            }
        })

        return $result.Trim('"')
    }
    catch {
        Write-Error "Failed to decode octal string: $_" -ErrorAction Stop
    }
}



# 基本使用方式
# '"Z:/git/\346\226\260\345\242\236\350\263\207\346\226\231\345\244\276/\346\270\254\350\251\246\350\267\257\345\276\221.txt"' | decodeOctal

# 空字串測試
# '' | decodeOctal
# $null | decodeOctal

# 無效八進制測試
# '\999' | decodeOctal

# 混合內容測試
'Hello\346\226\260ㄅㄆㄇ\346\226\260\346\226\260あいう\346\226\260World\777\777\777' | decodeOctal

# 不同編碼測試
# 'Test' | decodeOctal -Encoding ([Text.Encoding]::ASCII)
