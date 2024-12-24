# 解碼八進制編碼的字串
function decodeOctal {
    param (
        [Parameter(ValueFromPipeline, Mandatory)]
        [string]$InputString,
        [Text.Encoding]$Encoding = [Text.Encoding]::UTF8
    )
    try {
        # 使用正則表達式一次性處理所有字符
        $bytes = New-Object Collections.Generic.List[byte]
        $pattern = '\\[0-7]{3}|.'
        
        [regex]::Matches($InputString, $pattern) | ForEach-Object {
            $match = $_.Value
            if ($match[0] -eq '\') {
                try {
                    # 處理八進制序列
                    $bytes.Add([convert]::ToInt32($match.Substring(1), 8))
                } catch {
                    # 如果轉換失敗，保留原始字符
                    $bytes.Add([byte][char]'\')
                    $match.Substring(1).ToCharArray() | ForEach-Object {
                        $bytes.Add([byte][char]$_)
                    }
                }
            } else {
                # 處理普通字符
                $bytes.Add([byte][char]$match)
            }
        }
        
        return $Encoding.GetString($bytes.ToArray()).Trim('"')
    } catch {
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
# 'Hello\346\226\260World' | decodeOctal

# 不同編碼測試
# 'Test' | decodeOctal -Encoding ([Text.Encoding]::ASCII)
