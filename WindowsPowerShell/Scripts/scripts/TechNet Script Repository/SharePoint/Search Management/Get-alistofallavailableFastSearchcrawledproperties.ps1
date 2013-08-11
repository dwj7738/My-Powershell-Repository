$cps = Get-FASTSearchMetadataCrawledProperty
#$cps.Count
$outstr=""
foreach ($cp in $cps)
{
        #$cp
        $thename=$cp.Name
        $isnum = $thename.ToLower().equals($thename.ToUpper())
        $cp.VariantType
        if ( $cp.VariantType.equals(31))
        {
                if ($isnum)
                {
                        $outstr+="<CrawledProperty propertySet="""+$cp.Propset + """ varType=""" + $cp.VariantType + """ propertyId="""+$cp.Name+"""/>`n"
                }
                else
                {
                        $outstr+="<CrawledProperty propertySet="""+$cp.Propset + """ varType=""" + $cp.VariantType + """ propertyName="""+$cp.Name+"""/>`n"
                }
        }
        #<CrawledProperty propertySet="d1b5d3f0-c0b3-11cf-9a92-00a0c908dbf1" varType="31" propertyName="search.mnp.template" />
}
$outstr | Out-File pipelineextensibilityxml.txt
