#Get-WindowsLicensingStatus.ps1

$cim = New-CimSession -ComputerName (get-vm).name -Credential
get-ciminstance -class SoftwareLicensingProduct -CimSession $cim |

  where {$_.name -match 'windows' -AND $_.licensefamily} |

    format-list -property Name, Description, `

             @{Label="Grace period (days)"; Expression={ $_.graceperiodremaining / 1440}}, `

             @{Label= "License Status"; Expression={switch (foreach {$_.LicenseStatus}) `

              { 0 {"Unlicensed"} `

                1 {"Licensed"} `

                2 {"Out-Of-Box Grace Period"} `

                3 {"Out-Of-Tolerance Grace Period"} `

                4 {"Non-Genuine Grace Period"} `

              } } }

