powershell -c Set-ExecutionPolicy RemoteSigned -Force
Powershell -c C:\Scripts\ImportCerts.ps1 -Force
Powershell -c C:\Scripts\ConfigureVM.ps1 -Force
netsh advfirewall firewall set rule group=@FirewallAPI.dll,-28502 new enable=yes
Powershell -c "Get-ChildItem C:\Scripts\ -recurse -include *.pfx -force | Remove-Item -Force -ErrorAction SilentlyContinue"

