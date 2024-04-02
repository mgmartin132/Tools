$path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'

Get-ItemProperty -Path $path | Select-Object "DisplayVersion"
