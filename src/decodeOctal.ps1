# 解碼八進制編碼的字串
function decodeOctal {
    param (
        [Parameter(ValueFromPipeline, Mandatory)]
        [string]$InputString,
        [Text.Encoding]$Encoding = [Text.Encoding]::UTF8
    )
    try {
        # 使用正則表達式找出所有可能的八進制序列組
        $result = $InputString
        $pattern = '(?:\\[0-7]{3})+'
        
        [regex]::Matches($InputString, $pattern) | ForEach-Object {
            Write-Host $_.Value
            $match = $_.Value
            try {
                # 收集所有連續的八進制值
                $bytes = New-Object Collections.Generic.List[byte]
                $octalGroups = [regex]::Matches($match, '\\[0-7]{3}')
                
                foreach ($group in $octalGroups) {
                    $octalValue = [convert]::ToInt32($group.Value.Substring(1), 8)
                    $bytes.Add($octalValue)
                }
                
                # 將字節數組轉換為字符
                $decodedChar = $Encoding.GetString($bytes.ToArray())
                # 替換原始字串中的八進制序列
                $result = $result.Replace($match, $decodedChar)
            } catch {
                # 如果轉換失敗，保留原始序列
                Write-Warning "Failed to decode octal sequence $match : $_"
            }
        }
        
        return $result.Trim('"')
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
'Hello\346\226\260ㄅㄆㄇ\346\226\260\346\226\260あいう\346\226\260World\777\777\777' | decodeOctal

# 不同編碼測試
# 'Test' | decodeOctal -Encoding ([Text.Encoding]::ASCII)
