$cutoff = (Get-Date) - (New-TimeSpan -Days 1)
$before = (Get-ChildItem $env:temp | Measure-Object Length -Sum).Sum
Get-ChildItem $env:temp |
Where-Object { $_.Length -ne $null } |
Where-Object { $_.LastWriteTime -lt $cutoff } |
# simulation only, no files and folders will be deleted
# replace -WhatIf with -Confirm to confirm each delete
# remove -WhatIf altogether to delete without confirmation (at your own risk)
Remove-Item -Force -ErrorAction SilentlyContinue -Recurse -confirm
$after = (Get-ChildItem $env:temp | Measure-Object Length -Sum).Sum
$freed = $before - $after
$freed
