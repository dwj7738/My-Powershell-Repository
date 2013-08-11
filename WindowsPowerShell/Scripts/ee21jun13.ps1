$file1 = "C:\test\lista.csv"
$file2 = "C:\test\listb.csv"

 
$lista = import-csv -Path $file1
$listb = Import-Csv -Path $file2
$equals = Compare-Object  $lista.Hostname  $listb.Hostname  -IncludeEqual -ExcludeDifferent 
foreach ( $equal in $equals) {
    foreach ( $list in $lista ) 
        {
        if ($equal.InputObject -eq $list.hostname)
             {
            # write-output("$equal.InputObject,$list.location,$list.serial,$list.spec")
              $props = @{
                "Hostname"=$equal.InputObject;
                "Location" = $list.location;
                "Serial" = $list.serial;
                "Spec" = $list.spec
              }
         New-Object -TypeName PSObject -Property $props 

         }
        }
        #$props
        $props | sort-object hostname | select hostname,location,serial,spec| tee-object -variable proc  | Export-Csv -notypeinformation -Path c:\test\listc.csv
        
}
c:\test\listc.csv
