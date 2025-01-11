# 安裝 WinMerge
function Install-WinMerge {
  param (
      [switch] $Force
  )
  # 檢測命令是否已經存在
  $CmdName = "WinMergeU"
  if ((!$Force) -and (Get-Command $CmdName -CommandType:Application -EA:0)) { return }
  
  # 獲取設置
  $Url = "https://github.com/WinMerge/winmerge/releases/download/v2.16.24/winmerge-2.16.24-x64-exe.zip"
  $Url -match "[^/]+(?!.*/)" |Out-Null
  $ZipName = $Matches[0]
  $DLPath = $env:TEMP+"\$ZipName"
  $AppPath = $env:TEMP+"\WinMerge"
  $AppExec = $AppPath+"\WinMergeU.exe"
  
  # 檢測下載資料夾是否存在
  if (Get-Command $AppExec -CommandType:Application -EA:0) {
      if (($env:Path).IndexOf($AppPath) -eq -1) {
          if ($env:Path[-1] -ne ';') { $env:Path = $env:Path+';' }
          $env:Path = $env:Path+$AppPath
      }
  } else {
      # 下載並解壓縮
      (New-Object Net.WebClient).DownloadFile($Url, $DLPath)
      Expand-Archive $DLPath $env:TEMP -Force
      # 加到臨時變數
      if (($env:Path).IndexOf($AppPath) -eq -1) {
          if ($env:Path[-1] -ne ';') { $env:Path = $env:Path+';' }
          $env:Path = $env:Path+$AppPath
      }
  }
  
  # 驗證安裝
  if (!(Get-Command $CmdName -CommandType:Application -EA:0)) { Write-Error "Error:: WinMerge installation failed." -ForegroundColor:Yellow; return } else {
      return $AppExec
  }
} # Install-WinMerge -Force
