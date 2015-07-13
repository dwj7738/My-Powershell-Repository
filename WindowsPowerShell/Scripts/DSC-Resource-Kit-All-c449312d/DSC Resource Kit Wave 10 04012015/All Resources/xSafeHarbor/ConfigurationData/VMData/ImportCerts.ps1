$scriptLocation = $PSScriptRoot

$null = [Reflection.Assembly]::Load("System.Security, Version=2.0.0.0, Culture=Neutral, PublicKeyToken=b03f5f7f11d50a3a")
$flags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet

## LocalMachine\Root
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("$scriptLocation\DSCTestRootAuthority.pfx", "", $flags)
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite);
$store.Add($cert);
$store.Close();

## Personal\My
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("$scriptLocation\DSCDemo.pfx", "", $flags)
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My", [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite);
$store.Add($cert);
$store.Close();

## Personal\My
if(Test-Path $scriptLocation\PullServer.pfx)
{
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("$scriptLocation\PullServer.pfx", "", $flags)
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My", [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite);
    $store.Add($cert);
    $store.Close();
}