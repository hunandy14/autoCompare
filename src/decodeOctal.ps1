# 解碼八進制編碼的字串
function ConvertFrom-OctalBytes {
    param (
        [Parameter(Mandatory)]
        [string]$OctalString
    )
    
    # 使用一個動態 List 來累積 byte
    $bytes = New-Object System.Collections.Generic.List[Byte]
    $i = 0
    
    while ($i -lt $OctalString.Length) {
        if ($OctalString[$i] -eq '\') {
            # 這裡預期接下來 3 碼都是八進制 [0-7]
            $octPart = $OctalString.Substring($i + 1, 3)
            $bytes.Add([Convert]::ToInt32($octPart, 8))
            $i += 4  # 跳過 '\NNN' 共 4 字元
        }
        else {
            # 如果遇到任何非預期字元，就視為錯誤
            throw "Invalid octal escape at position $i"
        }
    }
    
    return $bytes.ToArray()
}

function decodeOctal {
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        [string]$InputString,
        [Text.Encoding]$Encoding = [Text.Encoding]::UTF8
    )
    
    $pattern = '(\\[0-7]{3})+'
    try {
        $result = [regex]::Replace($InputString, $pattern, {
            param($m)
            try {
                # 直接將匹配到的八進制序列轉換為字節數組
                $bytes = ConvertFrom-OctalBytes -OctalString $m.Value
                # 把收集到的所有 Byte，一次用指定編碼還原成字串
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
