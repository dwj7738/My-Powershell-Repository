       Function Out-Excel {

        param ($path="$pwd")     

        if( -Not (Test-Path $path) ) {
                    throw "Cannot find path [$path]"

        }
        Get-ChildItem $path | Select-Object FullName, Length, LastWriteTime | Sort Length -Descending | Export-Csv -NoTypeInformation $pwd\test.csv
                Invoke-Item $pwd\test.csv
                }