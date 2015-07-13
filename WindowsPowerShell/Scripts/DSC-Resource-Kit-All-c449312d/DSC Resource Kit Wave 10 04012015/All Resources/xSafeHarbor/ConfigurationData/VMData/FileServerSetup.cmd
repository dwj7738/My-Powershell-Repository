netsh advfirewall firewall set rule name=all dir=in new enable=no
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" dir=in new enable=yes
netsh advfirewall firewall add rule name="DSC HTTPS" protocol=TCP dir=out localport=8080 action=allow
powershell -c Set-ExecutionPolicy RemoteSigned -Force
Powershell -c C:\Scripts\ImportCerts.ps1 -Force
Powershell -c C:\Scripts\ConfigureFSVM.ps1 -Force
Powershell -c "Get-ChildItem C:\Scripts\ -recurse -include *.pfx -force | Remove-Item -Force -ErrorAction SilentlyContinue"