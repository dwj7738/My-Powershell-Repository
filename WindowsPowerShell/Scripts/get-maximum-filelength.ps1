
Get-ChildItem -r * |? {$_.GetType().Name -match "File"  } |? {$_.fullname.length -ge 200} |%{$_.fullname}