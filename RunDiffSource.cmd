@echo off

set "0=%~f0"& set "1=%~dp0"& set PwshScript=([Io.File]::ReadAllText($env:0,[Text.Encoding]::Default) -split '[:]PwshScript')
powershell -nop -c "(%PwshScript%[2]+%PwshScript%[1])|iex; Exit $LastExitCode"

echo ExitCode: %errorlevel%& pause
Exit %errorlevel%


:PwshScript#:: script1
#:: --------------------------------------------------------------------------------------------------------------------------------
Write-Host "by PSVersion::" $PSVersionTable.PSVersion "`n"

# 設定
$LeftPath  = "before"
$RightPath = "after"
$OutPath   = "Report\index.html"
$List      = "list.txt"
$Filter    = ""
$IgSame    = $true

# 比較
DiffSource $LeftPath $RightPath -Output $OutPath -Include (Get-Content $List) -Filter $Filter -IgnoreSameFile:$IgSame



:PwshScript#:: script2
#:: --------------------------------------------------------------------------------------------------------------------------------
Set-Location ($env:1); [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
irm raw.githubusercontent.com/hunandy14/autoCompare/master/DiffSource.ps1|iex
