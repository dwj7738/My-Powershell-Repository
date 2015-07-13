function Out-HTML {
    <#
    .Synopsis
        Produces HTML output from the PowerShell pipeline.
    .Description
        Produces HTML output from the PowerShell pipeline, doing the best possible to obey the formatting rules in PowerShell.
    .Example
        Get-Process | Out-HTML
    .Link
        New-Webpage
    .Link
        Write-Link
    .Link
        New-Region
    #>
    [OutputType([string])]
    param(
    # The input object
    [Parameter(ValueFromPipeline=$true)]
    [PSObject]
    $InputObject,
    
    # If set, writes the response directly
    [switch]
    $WriteResponse,
    
    # If set, escapes the output    
    [switch]
    $Escape,
    
    # The id of the table that will be created
    [string]
    $Id,

    # The vertical alignment of rows within the generated table.  By default, aligns to top
    [ValidateSet('Baseline', 'Top', 'Bottom', 'Middle')]
    $VerticalAlignment = 'Top',

    # The table width, as a percentage
    [ValidateRange(1,100)]
    [Uint32]
    $TableWidth = 100,
    
    # The CSS class to apply to the table.
    [string]
    $CssClass,        
    
    # A CSS Style 
    [Hashtable]
    $Style,        
    
    # If set, will enclose the output in a div with an itemscope and itemtype attribute
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string[]]$ItemType,
    
    # If more than one view is available, this view will be used
    [string]$ViewName,

    # If set, will use the table sorter plugin
    [Switch]
    $UseTableSorter,

    # If set, will use the datatable plugin
    [Switch]
    $UseDataTable,

    # If set, will show the output as a pie graph
    [Switch]
    $AsPieGraph,

    # If set, will show the output as a line graph
    [Switch]
    $AsBarGraph,

    
    [string[]]
    $ColorList = @("#468966", "#FFF0A5", "#FF870C", "#CA0016", "#B0A5CF", "#2B85BA", "#11147D", "#EE56A9", "#ADDC6C", "#108F34"),

    # The width of the canvas for a graph
    [Double]
    $GraphWidth = 400,

    # The height of the canvas for a graph
    [Double]
    $GraphHeight = 300
    
    )
        
    begin {
        
        $RaphaelPie = @'
Raphael.fn.pieChart = function (cx, cy, r, values, labels, stroke, colors) {
    var paper = this,
        rad = Math.PI / 180,
        chart = this.set();
    function sector(cx, cy, r, startAngle, endAngle, params) {
        var x1 = cx + r * Math.cos(-startAngle * rad),
            x2 = cx + r * Math.cos(-endAngle * rad),
            y1 = cy + r * Math.sin(-startAngle * rad),
            y2 = cy + r * Math.sin(-endAngle * rad);
        return paper.path(["M", cx, cy, "L", x1, y1, "A", r, r, 0, +(endAngle - startAngle > 180), 0, x2, y2, "z"]).attr(params);
    }
    var angle = 0,
        total = 0,
        start = 0,
        process = function (j) {
            var value = values[j],
                angleplus = 360 * value / total,
                popangle = angle + (angleplus / 2),
                color = Raphael.getRGB(colors[j]),
                ms = 500,
                delta = 30,
                bcolor = Raphael.getRGB(colors[j]),
                p = sector(cx, cy, r, angle, angle + angleplus, {fill: "90-" + bcolor + "-" + color, stroke: stroke, "stroke-width": 3}),
                txt = paper.text(cx + (r + delta + 55) * Math.cos(-popangle * rad), cy + (r + delta + 25) * Math.sin(-popangle * rad), labels[j]).attr({fill: bcolor, stroke: "none", opacity: 0, "font-size": 20});
            p.mouseover(function () {
                p.stop().animate({transform: "s1.1 1.1 " + cx + " " + cy}, ms, "elastic");
                txt.stop().animate({opacity: 1}, ms, "elastic");
            }).mouseout(function () {
                p.stop().animate({transform: ""}, ms, "elastic");
                txt.stop().animate({opacity: 0}, ms);
            });
            angle += angleplus;
            chart.push(p);
            chart.push(txt);
            start += .1;
            
        };
    for (var i = 0, ii = values.length; i < ii; i++) {
        total += values[i];
    }
    for (i = 0; i < ii; i++) {
        process(i);
    }
    return chart;
};
'@
        $tablesForTypeNames = @{}
        $tableCalculatedProperties = @{}
        $CachedformatData = @{}
        $stopLookingFor = @{}
        $CachedControls = @{}
        $loadedViewFiles= @{}
        $htmlOut = New-Object Text.StringBuilder
        $typeNamesEncountered = @()
        $net = [Reflection.Assembly]::LoadWithPartialName("System.Net")        
        $loadedFormatFiles = @(dir $psHome -Filter *.format.ps1xml | 
            Select-Object -ExpandProperty Fullname) + 
            @(Get-Module | Select-Object -ExpandProperty ExportedformatFiles)
            
        $loadedViews = $loadedFormatFiles | Select-Xml -Path {$_ } "//View"
        if ($useTableSorter) {
            if ($CssClass) {
                $CssClass+="tableSorterTable"
            } else {
                $CssClass ="tableSorterTable"
            }
        }

        if ($useDataTable) {
            if ($CssClass) {
                $CssClass+="aDataTable"
            } else {
                $CssClass ="aDataTable"
            }
        }

        $userandomSalt = $false
        if ($AsPieGraph) {
            $userandomSalt = $true
            if ($CssClass) {
                $CssClass += "raphaelPieGraph"
            } else {
                $cssClass = "raphaelPieGraph"

            }
        }

        if ($AsBarGraph) {
            $userandomSalt = $true
            if ($CssClass) {
                $CssClass += "raphaelBarGraph"
            } else {
                $CssClass += "raphaelBarGraph"
            }
        }

    }
    
    process {   
        # In case nulls come in, exit politely 
        if (-not $InputObject ) {  return }       
        $randomSalt = if ($userandomSalt) {
            "_$(Get-Random)"
        } else {
            ""
        }
        $classChunk = if ($cssClass) {            
            "class='$($cssClass -join ' ')'"        
        } else { 
            ""
        
        } 
        $cssStyleChunk = if ($psBoundParameters.Style) { 
            "style='" +(Write-CSS -Style $style -OutputAttribute) + "'"
        } else {
            "style='width:100%'"
        }
        if ($inputObject -is [string]) {
            # Strings are often simply passed thru, but could potentially be escaped.
            $trimmedString = $inputObject.TrimStart([Environment]::NewLine).TrimEnd([Environment]::NewLine).TrimStart().TrimEnd()            
            # If the string looks @ all like markup or HTML, pass it thru
            if (($trimmedString -like "*<*") -and 
                ($trimmedString -like "*>*") -and
                ($trimmedString -notlike "*<?xml*")) {
                if ($escape) { 
                $null = $htmlOut.Append("
$([Web.HttpUtility]::HtmlEncode($inputObject).Replace([Environment]::NewLine, '<BR/>').Replace('`n', '<BR/>').Replace(' ', '&nbsp;'))
")
                } else {
                $null = $htmlOut.Append("
$inputObject
")
                }
            } else {
                # Otherwise, include it within a <pre> tag
                $null= $htmlOut.Append("
<pre $classChunk>
$([Web.HttpUtility]::HtmlEncode($inputObject).Replace([Environment]::NewLine, '<BR/>').Replace('`n', '<BR/>').Replace(' ', '&nbsp;'))
</pre>
")
            }
        } elseif ([Double], [int], [uint32], [long], [byte] -contains $inputObject.GetType()) {
            # If it's a number, simply print it out
            $null= $htmlOut.Append("
<span class='Number' style='font-size:2em'>
$inputObject
</span>
")
        } elseif ([DateTime] -eq $inputObject.GetType()) {
            # If it's a date, out Out-String to print the long format
            $null= $htmlOut.Append("
<span class='DateTime'>
$($inputObject | Out-String)
</span>
")
        } elseif (($inputObject -is [Hashtable]) -or ($inputObject -is [Collections.IDictionary])) {
            $null = $psBoundParameters.Remove('InputObject')            
            $inputObjecttypeName = ""
            $inputObjectcopy = @{} + $inputObject
            if ($inputObjectcopy.PSTypeName) {
                $inputObjecttypeName = $inputObject.PSTypeName
                $inputObjectcopy.Remove('PSTypeName')
            }
            
            foreach ($kv in @($inputObjectcopy.GetEnumerator())) {
                if ($kv.Value -is [Hashtable]) {                    
                    $inputObjectcopy[$kv.Key] = Out-HTML -InputObject $kv.Value
                }
            }
            
            if ($inputObjectCopy) {
            
            
                New-Object PSObject -Property $inputObjectcopy | 
                    ForEach-Object {                
                        $_.pstypenames.clear()
                        foreach ($inTypeName in $inputObjectTypeName) {
                            if (-not $inTypeName) {continue }
                            
                            $null = $_.pstypenames.add($inTypeName)
                        }
                        if (-not $_.pstypenames) {
                            $_.pstypenames.add('PropertyBag')
                        }
                        $psBoundparameters.ItemType = $inputObjectTypeName
                        $_
                    } | Out-HTML @psboundParameters
            }
        } else {
            $matchingTypeName = $null
            #region Match TypeName to Formatter
            foreach ($typeName in $inputObject.psObject.typenames) {             
                # Skip out of 
                if ($stopLookingFor[$typeName]) { continue }                 
                if ($cachedFormatData[$typeName] ) { 
                    $matchingTypeName = $typename
                    break
                }                
                
                if (-not $CachedformatData[$typeName] -and -not $stopLookingFor[$TypeName]) {
                    
                    
                    $CachedformatData[$typeName] =  
                        if ([IO.File]::Exists("$pwd\Presenters\$typeName")) {
                            if ($loadedViewFiles[$typeName]) {                            
                                $loadedViewFiles[$typeName] = [IO.File]::ReadAllText(
                                    $ExecutionContext.SessionState.Path.GetResolvedProviderPathFromPSPath(".\Presenters\$typeName"))
                                 
                            } else {
                                $loadedViewFiles[$typeName]
                            }
                        } else {
                            Get-FormatData -TypeName $typeName -ErrorAction SilentlyContinue
                        }
                    
                    if (-not $cachedFormatData[$TypeName]) {                
                        # This covers custom action
                        $CachedformatData[$typeName] = 
                            foreach ($view in $loadedViews) {
                                 
                                if ($view.Node.ViewselectedBy.TypeName -eq $typeNAme) { 
                                    if ($ViewName -and $view.Node.Name -eq $viewNAme) {
                                        $view.Node
                                        break

                                    } else {
                                        $view.Node
                                        break

                                    }
                                }
                            }
                                
                        if ($CachedFormatData[$typeName]) {
                            # Custom Formatting or SelectionSet
                            if ($CachedFormatData[$typeName]) {
                            
                            }                           
                            $matchingTypeName = $typeName
                        } else {                           
                        
                            # At this point, we're reasonably certain that no formatter exists, so
                            # Make sure we stop looking for the typename, or else this expensive check is repeated for each item                                                        
                            if (-not $cachedFormatData[$typeName]) {                            
                                $stopLookingFor[$typeName]  = $true
                            }
                        }
                    } else {
                        $matchingTypeName = $typeName
                        break
                    }                                        
                }
            }

            $TypeName = $MatchingtypeName
            
            
            
            #endregion Match TypeName to Formatter
            if ($matchingTypeName) {
                $formatData = $CachedformatData[$typeName]
                $cssSafeTypeName =$typename.Replace('.','').Replace('#','')
                if ($cachedFormatData[$typeName] -is [string]) {
                    # If it's a string, just set $_ and expand the string, which allows subexpressions inside of HTML
                    $_ = $inputObject
                    foreach ($prop in $inputObject.psobject.properties) {
                        Set-Variable $prop.Name -Value $prop.Value -ErrorAction SilentlyContinue
                    }
                    $ExecutionContext.SessionState.InvokeCommand.ExpandString($cachedFormatData[$typeName])
                } elseif ($cachedFormatData[$typeName] -is [Xml.XmlElement]) {
                    # SelectionSet or Custom Formatting Action
                                        

                    $frame = $CachedformatData[$typeName].CustomControl.customentries.customentry.customitem.frame
                    foreach ($frameItem in $frame) {
                        $item  =$frameItem.customItem
                        foreach ($expressionItem in $item) {
                            $expressionItem | 
                                Select-Xml "ExpressionBinding|NewLine" |
                                ForEach-Object -Begin {
                                    if ($itemType) {
                                        #$null = $htmlOut.Append("<div itemscope='' itemtype='$($itemType -join "','")' class='ui-widget-content'>")
                                    }
                                } {
                                    if ($_.Node.Name -eq 'ExpressionBinding') {
                                        $finalExpr =($_.Node.SelectNodes("ScriptBlock") | 
                                            ForEach-Object {
                                                $_."#text"
                                            }) -ireplace "Write-Host", "Write-Host -AsHtml" -ireplace 
                                                "Microsoft.PowerShell.Utility\Write-Host", "Write-Host"
                                        $_ = $inputObject
                                        $null = $htmlOut.Append("$(Invoke-Expression $finalExpr)")
                                    } elseif ($_.Node.Name -eq 'Newline') {
                                        $null = $htmlOut.Append("<br/>")
                                    }
                                } -End {
                                    if ($itemType) {
                                        #$null = $htmlOut.Append("</div>")
                                    }
                                }
                                
                                Where-Object { $_.Node.Name -eq 'ExpressionBinding' }
                            if (-not $expressionBinding.firstChild.ItemSelectionCondition) {
                                
                                
                                
                            }
                            
                        }
                    }
                    
                    $null = $null
                    # Lets see what to do here
                } else {                                
                    if (-not $CachedControls[$typeName]) {
                        $control = foreach ($_ in $formatData.FormatViewDefinition) {
                            if (-not $_) { continue }
                            $result = foreach ($ctrl in $_.Control) {
                                if ($ctrl.Headers) { 
                                    $ctrl
                                    break
                                }
                            }
                            if ($result) { 
                                $result
                                break 
                            }
                        }
                        $CachedControls[$typeName]= $control
                        if (-not $cachedControls[$TypeName]) {
                            $control = foreach ($_ in $formatData.CustomControl) {
                                if (-not $_) { continue }
                                
                                
                            }
                            $CachedControls[$typeName]= $control
                        }
                    }
                    $control = $CachedControls[$typeName]
                             
                    if (-not ($tablesForTypeNames[$typeName])) {
                        $tableCalculatedProperties[$typeName] = @{}
                        if (-not $psBoundParameters.id) { 
                            $id = "TableFor$($TypeName.Replace('/', '_Slash_').Replace('.', "_").Replace(" ", '_'))" 
                        } else {
                            $id = $psBoundParameters.id
                        }

                        
                        $tableHeader = New-Object Text.StringBuilder                    
                        $null = $tableHeader.Append("
$(if ($useTableSorter) { 
    '<script>
        $(function() {
            $(".tableSorterTable").tablesorter(); 
        })
    </script>'   
})

$(if ($useDataTable) { 
    '<script>
        $(function() {
            $(".aDataTable").dataTable(); 
        })
    </script>'   
})

<table id='${id}${randomSalt}' $classChunk $cssstyleChunk>
    <thead>
    <tr>")
                        $labels = @()
                        $headerCount = $control.Headers.Count
                        $columns = @($control.Rows[0].Columns)
                        for ($i=0; $i-lt$headerCount;$i++) {                                            
                            $header = $control.Headers[$i]
                            $label = $header.Label
                            if (-not $label) {
                                $label = $columns[$i].DisplayEntry.Value
                            }
                            
                            if ($label) {
                                if ($columns[$i].DisplayEntry.ValueType -eq 'Property') {
                                    $prop = $columns[$i].DisplayEntry.Value
                                    $tableCalculatedProperties[$label] = [ScriptBlock]::Create("`$inputObject.'$prop'")
                                } elseif ($columns[$i].DisplayEntry.ValueType -eq 'ScriptBlock') {
                                    $tableCalculatedProperties[$label] = [ScriptBlock]::Create($columns[$i].DisplayEntry.Value)
                                } 
                                $labels+=$label
                            }
                            
                            $null = $tableHeader.Append("
        <th style='font-size:1.1em;text-align:left;line-height:133%'>$label<hr/></th>")
                        
                        }
                        $null = $tableHeader.Append("
    </tr>
    </thead>
    <tbody>
    ")
                        $tablesForTypeNames[$typeName] = $tableHeader
                        $typeNamesEncountered += $typeName
                    }
                
                $currentTable = $tablesForTypeNames[$typeName]
            
                # Add a row
                $null = $currentTable.Append("
    <tr itemscope='' itemtype='$($typeName)'>") 

                    foreach ($label in $labels) {                
                        $value = "&nsbp;"
                        if ($tableCalculatedProperties[$label]) {
                            $_ = $inputObject
                            $value = . $tableCalculatedProperties[$label]                      
                        }
                        $value = "$($value -join ([Environment]::NewLine))".Replace([Environment]::NewLine, '<BR/> ')                    
                        if ($value -match '^http[s]*://') {
                            $value = Write-Link -Url $value -Caption $value
                        }
                        $null = $currentTable.Append("
        <td valign='$verticalAlignment' itemprop='$($label)'>$value</td>")                
                    }
                    $null = $currentTable.Append("
    </tr>")     
                }                    
            } else {

                # Default Formatting rules
                $labels = @(foreach ($pr in $inputObject.psObject.properties)  { $pr.Name })
                if (-not $labels) { return } 
                [int]$percentPerColumn = 100 / $labels.Count            
                if ($inputObject.PSObject.Properties.Count -gt 4) {
                
                    $null = $htmlOut.Append("
<div class='${cssSafeTypeName}Item'>
")
                    foreach ($prop in $inputObject.psObject.properties) {
                        $null = $htmlOut.Append("
    <p class='${cssSafeTypeName}PropertyName'>$($prop.Name)</p>
    <blockquote>
        <pre class='${cssSafeTypeName}PropertyValue'>$($prop.Value)</pre>
    </blockquote>
")
                        
                    }
                    $null = $htmlOut.Append("
</div>
<hr class='${cssSafeTypeName}Separator' />
")              
                }  else {
                    $widthPercentage = 100 / $labels.Count
                    $typeName = $inputObject.pstypenames[0]
                    if (-not ($tablesForTypeNames[$typeName])) {
                        $tableCalculatedProperties[$typeName] = @{}
                        if (-not $psBoundParameters.id) { 
                            $id = "TableFor$($TypeName.Replace('/', '_Slash_').Replace('.', "_").Replace(" ", '_'))" 
                        } else {
                            $id = $psBoundParameters.id
                        }
                        $tableHeader = New-Object Text.StringBuilder
                        
                        $null = $tableHeader.Append("
$(if ($useTableSorter) { 
    '<script>
        $(function() {
            $(".tableSorterTable").tablesorter(); 
        })
    </script>'   
})

$(if ($useDataTable) { 
    '<script>
        $(function() {
            $(".aDataTable").dataTable(); 
        })
    </script>'   
})


<table id='${id}${randomSalt}' $cssStyleChunk $classChunk >
    <thead>
    <tr>")   


                        foreach ($label in $labels) {
                            $null = $tableHeader.Append("
        <th style='font-size:1.1em;text-align:left;line-height:133%;' width='${widthPercentage}%'>$label<hr/></th>")
                    
                            
                        }
                        $null = $tableHeader.Append("
    </tr>
    </thead>
    <tbody>")
                        $tablesForTypeNames[$typeName] = $tableHeader
                        $typeNamesEncountered += $typeName
                    }
                    
                    $currentTable = $tablesForTypeNames[$typeName]
            
                    # Add a row
                    $null = $currentTable.Append("
    <tr itemscope='' itemtype='$($typeName)'>") 

                    foreach ($label in $labels) {                
                        $value = "&nsbp;"
                        $value = $inputObject.$label
                        $value = "$($value -join ([Environment]::NewLine))".Replace([Environment]::NewLine, '<BR/> ')
                        if ($value -match '^http[s]*://') {
                            $value = Write-Link $value
                        }
                        $null = $currentTable.Append("
        <td valign='$VerticalAlignment' itemprop='$($label)'>$value</td>")                
                    }
                    $null = $currentTable.Append("
    </tr>")      
                    
                }         
            }      
        }
     
    }
    
    end {
            $htmlOut = "$htmlOut" 
            $htmlOut += if ($tablesForTypeNames.Count) {
                foreach ($table in $typeNamesEncountered) {
                    if ($AsPieGraph) {
                        $null = $tablesForTypeNames[$table].Append(@"
</tbody></table>
<div id='${id}_Holder_${RandomSalt}'>
</div>
<script>
$RaphaelPie 
`$(function () {
    var values = [],
        labels = [];
    `$("#${Id}${RandomSalt} thead tr th").each(
        function () {        
            labels.push(`$(this).text());
            
            
            
    });

    `$("#${Id}${RandomSalt} tbody tr td").each(
        function () {        
            values.push(
                parseInt(
                    `$(this).text(), 10)
                );            
            
            
            
    });
    
    
    
    
    `$("#${Id}${RandomSalt}").hide();
    colors = ["$($ColorList -join '","')"]

    
    var r = Raphael("${Id}_Holder_${RandomSalt}", $GraphWidth, $GraphHeight),
            pie = r.piechart($($GraphWidth * .4), $($GraphHeight * .33), $($GraphWidth * .16), values, { legend: labels, colors: colors, legendpos: "west", href: ["http://raphaeljs.com", "http://g.raphaeljs.com"]});
        
        pie.hover(function () {
            this.sector.stop();
            this.sector.scale(1.1, 1.1, this.cx, this.cy);

            if (this.label) {
                this.label[0].stop();
                this.label[0].attr({ r: 7.5 });
                this.label[1].attr({ "font-weight": 800 });
            }
        }, function () {
            this.sector.animate({ transform: 's1 1 ' + this.cx + ' ' + this.cy }, 500, "bounce");

            if (this.label) {
                this.label[0].animate({ r: 5 }, 500, "bounce");
                this.label[1].attr({ "font-weight": 400 });
            }
        });
    


   
    
});


</script>
"@)
                    } elseif ($AsBarGraph) {
    $null = $tablesForTypeNames[$table].Append(@"
</tbody></table>
<div id='${id}_Holder_${RandomSalt}'>
</div>
<div style='clear:both'> </div>
<script>

`$(function () {
    // Grab the data
    colors = ["$($ColorList -join '","')"]
    var data = [],
        labels = [];
    `$("#${Id}${RandomSalt} thead tr th").each(
        function () {        
            labels.push(`$(this).text());
            
            
            
    });

    `$("#${Id}${RandomSalt} tbody tr td").each(
        function () {        
            data.push(
                parseInt(
                    `$(this).text(), 10)
                );            
                                    
    });
    `$("#${Id}${RandomSalt}").hide();
    
    chartHtml = '<table valign="bottom"><tr><td valign="bottom">'
    valueTotal = 0 
    for (i =0; i< labels.length;i++) {
        chartHtml += ("<div id='${RandomSalt}_" + i + "' style='min-width:50px;float:left;ver' > <div id='${RandomSalt}_" + i + "_Rect' style='height:1px;background-color:" + colors[i] + "'> </div><br/><div class='chartLabel'>"+ labels[i] + '<br/>(' + data[i] + ")</div></div>");
        valueTotal += data[i];

        chartHtml+= '</td>'

        if (i < (labels.length - 1)) {
            chartHtml+= '<td valign="bottom">'
        }
    }
    chartHtml += '</tr></table>'

    
    `$(${id}_Holder_${RandomSalt}).html(chartHtml);
    

    for (i =0; i< labels.length;i++) {
        newRelativeHeight =  (data[i] / valueTotal) * 200;
        `$(("#${RandomSalt}_" + i + "_Rect")).animate({
                        height:newRelativeHeight
                        }, 500);
        
    }

    /*     
    var r = Raphael("${id}_Holder_${RandomSalt}",$GraphWidth, $GraphHeight),
        fin = function () {
            this.flag = r.popup(this.bar.x, this.bar.y, this.bar.value || "0").insertBefore(this);
        },
        fout = function () {
            this.flag.animate({opacity: 0}, 300, function () {this.remove();});
        },
        fin2 = function () {
            var y = [], res = [];
            for (var i = this.bars.length; i--;) {
                y.push(this.bars[i].y);
                res.push(this.bars[i].value || "0");
            }
            this.flag = r.popup(this.bars[0].x, Math.min.apply(Math, y), res.join(", ")).insertBefore(this);
        },
        fout2 = function () {
            this.flag.animate({opacity: 0}, 300, function () {this.remove();});
        },
        txtattr = { font: "12px sans-serif" };
                
            
    r.barchart(10, 10, $GraphWidth, $GraphHeight, [data], { colors: colors}).hover(fin, fout).label(labels);
    */
    
});
 
</script>
"@)
                    } else {
                        $null = $tablesForTypeNames[$table].Append("
</tbody></table>")
                    }
                    
                    if ($escape) {
                        [Web.HttpUtility]::HtmlEncode($tablesForTypeNames[$table].ToString())
                    } else {
                        $tablesForTypeNames[$table].ToString()
                                                
                    }                    
                    
                }
            }
            
            if ($itemType) {
                $htmlout = "<div itemscope='' itemtype='$($itemType -join ' ')'>
$htmlOut
</div>"
            }
            if ($WriteResponse -and $Response.Write)  {
                $Response.Write("$htmlOut")
            } else {                
                $htmlOut                                 
            }
        
    }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGpkhmC4QpO45GvsKDs7loPS5
# z+mgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLxSWFT4k/b25EEJ
# In1gU/DZ8yESMA0GCSqGSIb3DQEBAQUABIIBAE2Jpezv54mPX9dCOYPX3mVjeOZN
# 7G+bQs33dbwAbIG5AEpyMhYitjlm/OsUWAoc9w05U6vtVo0giUV0QzUNgQuuaeEM
# YlGLJ/fm7bqkqRKQTyO9vVfRZelYYvtEC5esfvKc0syqlKChPHb33d2byhVY5hee
# Md155YD7cQpxtmmbPtqwYYmJ+GCe6LMVhFBJmx17QL4l1ShzWPCTkz9CC8wU3K/T
# t5CuJzFf4MZxAZOP4v3g0fjNRPSjXNDLyR6JsAc9Bp2dFNnkaxgqJuXZqq4NlMei
# UtePooG9lnEs1l0621oLkLFWl2TpBnrYLPXH0WX8kqPXI+4TYONY7w5tSd0=
# SIG # End signature block
