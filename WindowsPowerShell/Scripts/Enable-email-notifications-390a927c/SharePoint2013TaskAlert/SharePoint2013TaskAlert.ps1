$site=Get-SPSite "http://sharepoint2013/"
$web=$site.OpenWeb()
$list=$web.Lists.TryGetList("Tasks")
if($list -ne $null)
{
   $list.EnableAssignToEmail =$true
   $list.Update()
}
