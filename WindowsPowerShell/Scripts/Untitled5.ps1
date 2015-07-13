$user = $env:USERNAME
$Group = @()
$info = @{
    'Group' = "ADGroup1"
    "Source" = "\\DOMAIN\netlogon\bg\file1"
    }
$Group = New-Object -TypeName psobject -Property $Info
$info = @{
    'Group' = "ADGroup2"
    "Source" = "\\DOMAIN\netlogon\bg\file2"
    }
$Group2 = New-Object -TypeName psobject -Property $Info
$Group = [array]$Group + $Group2
$tocopy = "\\DOMAIN\netlogon\bg\BGFILEDefault"
foreach($group in $Groups){
if ((Get-ADUser $User -Properties memberof).memberof -like "CN=" + $group.Group)
    {
    $tocopy = $group.source
    break
    }
}
$bgFolder = "C:\BG\"
if (!(test-path $bgFolder)) {
    md $bgFolder
    }
copy-item $tocopy -Container $bgFolder -Include $tocopy -Force
rename-item $tocopy bginfo.bmp
