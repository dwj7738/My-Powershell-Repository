function New-Region
{
    <#
    .Synopsis
        Creates a new web region.
    .Description             
        Creates a new web region.  Web regions are lightweight HTML controls that help you create web pages.
    .Link
        New-Webpage        
        
    .Example
        # Makes a JQueryUI tab
        New-Region -Layer @{
            "Tab1" = "Content In Tab One"
            "Tab2" = "Content in Tab Two"
        } -AsTab
    .Example
        # Makes a JQueryUI accordian
        New-Region -Layer @{
            "Accordian1" = "Content In The first Accordian"
            "Accordian1" = "Content in the second Accordian"
        } -AsAccordian
    .Example
        # Makes an empty region
        New-Region -Style @{} -Content -LayerID MyId
    .Example
        # A Centered Region containing Microdata
        New-Region -ItemType http://schema.org/Event -Style @{
            'margin-left' = '7.5%'
            'margin-right' = '7.5%'
        } -Content '
<a itemprop="url" href="nba-miami-philidelphia-game3.html">
NBA Eastern Conference First Round Playoff Tickets:
<span itemprop="name"> Miami Heat at Philadelphia 76ers - Game 3 (Home Game 1) </span>  </a> 
<meta itemprop="startDate" content="2016-04-21T20:00">    Thu, 04/21/16    8:00 p.m.  
<div itemprop="location" itemscope itemtype="http://schema.org/Place">    
    <a itemprop="url" href="wells-fargo-center.html">    Wells Fargo Center    </a>    
    <div itemprop="address" itemscope itemtype="http://schema.org/PostalAddress">      
        <span itemprop="addressLocality">Philadelphia</span>,      <span itemprop="addressRegion">PA</span>    
    </div>  
</div>  
<div itemprop="offers" itemscope itemtype="http://schema.org/AggregateOffer">
    Priced from: <span itemprop="lowPrice">$35</span>    <span itemprop="offerCount">1938</span> tickets left  
</div>'        
    #>
    [CmdletBinding(DefaultParameterSetName='Content')]
    [OutputType([string])]
    param(
    # The content within the region.  This content will be placed on an unnamed layer.
    [Parameter(ParameterSetName='Content',Position=0,ValueFromPipeline=$true)]
    [string[]]$Content,
    # A set of layer names and layer content 
    [Parameter(ParameterSetName='Layer',Position=0)]
    [Alias('Item')]
    [Hashtable]$Layer,
    # A set of layer names and layer URLs.  Any time the layer is brought up, the content will be loaded via AJAX
    [Parameter(ParameterSetName='Layer')]
    [Hashtable]$LayerUrl = @{},

    # A set of layer direct links
    [Parameter(ParameterSetName='Layer')]
    [Hashtable]$LayerLink = @{},

   
    
    # The order the layers should appear.  If this is not set, the order will
    # be the alphabetized list of layer names.
    [Parameter(ParameterSetName='Layer')]
    [Alias('LayerOrder')]
    [string[]]$Order,
    # The default layer.  If this is not set and if -DefaultToFirst is not set, a layer 
    # will be randomly chosen.
    [Parameter(ParameterSetName='Layer')]
    [string]$Default,
    # The default layer.  If this is not set and if -DefaultToFirst is not set, a layer 
    # will be randomly chosen.
    [Parameter(ParameterSetName='Layer')]
    [switch]$DefaultToFirst,
    # The Name of the the container.  The names becomes the HTML element ID of the root container.
    [Alias('Container')]
    [Alias('Id')]
    [string]$LayerID = 'Layer',
    # The percentage margin on the left.  The region will appear this % distance from the side of the screen, regardless of resolution
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=1)]
    [ValidateRange(0,100)]
    [Double]$LeftMargin = 2.5,
    # The percentage margin on the right.  The region will appear this % distance from the side of the screen, regardless of resolution
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=2)]
    [ValidateRange(0,100)]
    [Double]$RightMargin = 2.5,        
    # The percentage margin on the top.  The region will appear this % distance from the top of the screen, regardless of resolution
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=3)]
    [ValidateRange(0,100)]
    [Double]$TopMargin = 10,
    # The percentage margin on the bottom.  The region will appear this % distance from the bottom of the screen, regardless of resolution
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=4)]
    [ValidateRange(0,100)]
    [Double]$BottomMargin = 10,
    # The border for the region.  Becomes the CSS border attribute of the main container
    [string]$Border = "1px solid black",
    
    # If set, hides the forward and back buttons
    [switch]$HideDirectionButton,
    # If set, hides the more button
    [switch]$HideMoreButton,
    # If set, hides the title area
    [switch]$HideTitleArea,
    # If set, shows a horizontal rule under the title
    [switch]$HorizontalRuleUnderTitle,
    
    # If set, places the toolbar above
    [switch]$ToolbarAbove,
    # The margin of the toolbar
    [int]$ToolbarMargin,
    # URL for a logo to go on the title of each page
    [uri]$Logo,    
    
    # If set, the control will not be aware of the web request string.
    # Otherwise, a URL can provide which layer of a region to show.
    [switch]$NotRequestAware,
    
    # If set, the region will have any commands to change its content, 
    # and will only have one layer
    [switch]$IsStaticRegion,        
    
    # If set, turns off fade effects
    [switch]$NotCool,
    
    # The transition time for all fade effects.  Defaults to 200ms
    [Timespan]$TransitionTime = "0:0:0.2",
    
    # The number of keyframes in all transitions
    [ValidateRange(10, 100)]
    [Uint32]$KeyFrameCount = 10,
    
    # If set, enables a pan effect within the layers
    [Switch]$CanPan,
    
    # If set, the entire container can be dragged
    [Switch]$CanDrag,        
  
    # The scroll speed (when on iOs or webkit)
    [int]$ScrollSpeed = 25,
    
    # The CSS class to use 
    [string[]]$CssClass,
    
    # A custom CSS style.
    [Hashtable]$Style,
    
    # If set, the layer will not be automatically resized, and percentage based margins will be ignored
    [switch]$FixedSize,
    
    # If set, will not allow the contents of the layer to be switched
    [switch]$DisableLayerSwitcher,
    
    # If set, will automatically switch the contents on an interval
    [Parameter(ParameterSetName='Layer')]
    [Timespan]$AutoSwitch = "0:0:4",
    
    # If set, will create the region as an JQueryUI Accordion.
    [Parameter(ParameterSetName='Layer')]
    [Switch]$AsAccordian,
    
    # If set, will create the region as an JQueryUI Tab.
    [Parameter(ParameterSetName='Layer')]
    [Switch]$AsTab,
    
    [Parameter(ParameterSetName='Layer')]
    [Switch]$TabBelow,
    
    # If set, will open the tabs on a mouseover event
    [Switch]$OpenOnMouseOver,
    
    # If set, will create a set of popout regions.  When the tile of each layer is clicked, the layer will be shown.
    [Parameter(ParameterSetName='Layer')]
    [Switch]$AsPopout,
    
    # If set, will create a set of popdown regions.  As region is clicked, the underlying content will be shown below.
    [Parameter(ParameterSetName='Layer')]
    [Switch]$AsPopdown,

    # If set, will create a set of popdown regions.  As region is clicked, the underlying content will be shown below.
    [Parameter(ParameterSetName='Layer')]
    [Switch]$AsPopIn,
    
    # If set, will create a slide of the layers.  If a layer title is clicked, the slideshow will stop
    [Parameter(ParameterSetName='Layer')]
    [Switch]$AsSlideShow,
    
    # If set, the layer will be created as a portlet
    [Parameter(ParameterSetName='Layer')]
    [Switch]$AsPortlet,
    
    # The number of columns in a Portlet
    [Uint32]$ColumnCount = 2,
    
    # The width of a column within a Portlet
    [string]$ColumnWidth,
        
    # If set, will create a set of JQueryUI buttons which popup JQueryUI dialogs
    [Switch]$AsPopup,
    
    
    # If set, will create a set of JQueryUI simple widgets
    [Switch]$AsWidget,
    
    # If set, will create the layer as a series of resizable items
    [Switch]$AsResizable,

    # If set, will create the layer as a series of draggable items
    [Switch]$AsDraggable,
    
    # If set, the layer will be created as a left sidebar menu
    [switch]$AsLeftSidebarMenu,
    
    # If set, the layer will be created as a right sidebar menu
    [Switch]$AsRightSidebarMenu,

    # If set, the layer will be created as a grid
    [Switch]$AsGrid,

    # The width of items within a grid
    [Uint32]$GridItemWidth = 175,

    # The height of items within a grid
    [Uint32]$GridItemHeight = 112,
    
    # The width of a sidebar in a left or right sidebar menu
    [ValidateRange(1,100)]
    [Uint32]$SidebarWidth = 20,
    
    # One or more item types to apply to the region.  If set, an itemscope and itemtype will be added to the region
    [string[]]
    $ItemType,
    
    # If set, will use a vector (%percentage based layout) for the region.
    [Switch]
    $AsVectorLayout,
    
    # If set, will hide the slide name buttons (effectively creating an endless slideshow)
    [switch]
    $HideSlideNameButton,

    # If set, will use a middot instead of a slide name for a slideshow button.
    [switch]
    $UseDotInsteadOfName,
    
    # The background color in a popin
    [string]
    $MenuBackgroundColor
    )
    
    begin {
        $getSafeLayerName = {
            param($layerName) 
            
            $layerName.Replace(" ", "_space_").Replace("-", "").Replace("+", "").Replace("!", "_bang_").Replace(",", "").Replace("<", "").Replace(">","").Replace("'", "").Replace('"','').Replace('=', '').Replace('&', '').Replace('?', '').Replace("/", "").Replace(",", "_").Replace("|", "_").Replace(":","_").Replace(".", "_").Replace("@", "_at_").Replace("(", "-__").Replace(")","__-").Replace("#", "_Pound_")
        }
        
        
        $getAjaxAndPutIntoContainer = {
            param($url, $container, $UrlType)


if ($url -like "*.zip" -or 
    $url -like "*.exe" -or
    $UrlType -eq 'Button') {
@"
window.location = '$url';
"@

} else {
@"
`$.ajax({
  url: '$url',
  success: function(data){     
    `$('#${container}').html(data);
  },
  error: function(xhr, message, error) {
        alert(xhr.status + message);
  }
    
});
"@

}    

            
        }
        $layerCount = 0 
        $originalLayerId = $layerId
    }
    
    process {
        
        if ($layerCount -gt 0) {
            $layerId = $originalLayerId + $layerCount     
        }
        $layerCount++
        #region Internal changing of parameters of parameter set overlaps
        if ($psCmdlet.ParameterSetName -eq 'Content') {
            if (-not $Layer) {
                $Layer = @{}
            }
            $Layer.'Default' = $Content                        
            
            $hideTitleArea = $true
            $hideDirectionButton = $true
            $hideMoreButton = $true
            
            if (-not $asVectorLayout) {
                $DisableLayerSwitcher = $true
            } 
        }
        
        
        $layerId= & $getSafeLayerName $layerId
        if ($psBoundParameters.AutoSwitch -and (-not $AsSlideshow)) {
            $DisableLayerSwitcher = $false
            $NotRequestAware = $true            
        }
                
        
        if ($AsAccordian -or $AsTab -or $AsPopout -or $asPopin -or $AsPopdown -or $asPopup -or 
            $asSlideshow -or $AsWidget -or $AsPortlet -or $AsLeftSidebarMEnu -or $ASRightSidebarMenu -or $AsResizable -or $AsDraggable -or $AsGrid) {
            $NotRequestAware = $true            
            $IsStaticRegion = $true       
            $DisableLayerSwitcher = $true     
            $FixedSize = $true            
            
        } elseif (-not $AsVectorLayout -and -not $psboundParameters.Style) {            
            $NotRequestAware = $true            
            $IsStaticRegion = $true       
            $DisableLayerSwitcher = $true     
            $FixedSize = $true       
            # Choose for them: 1 Layer is a resizable widget. <= 5 layers is a tab.  Otherwise accordian     
            if ($layer.Count -eq 1) {
                $AsWidget = $true                
                $AsResizable = $true
            } elseif ($layer.Count -le 5) {
                $AsTab = $true
            } else {
                $AsAccordian = $true
            }
        }
                                       
        if ($Style) {
            $FixedSize = $true            
        }
        
        

        if ($FixedSize) {
            $HideDirectionButton = $true
            $HideMoreButton = $true
            # DCR  : Make -*Margin turn into styles
            if (-not $style) {
                $style=  @{}
            }
            if ($psBoundParameters.LeftMargin) {
                $style["margin-left"] = "${LeftMargin}%"                
            }
            if ($psBoundParameters.RightMargin) {
                $style["margin-right"] = "${RightMargin}%"
            }
            if ($psBoundParameters.TopMargin) {
                $style["margin-top"] = "${TopMargin}%"
            }

            if ($psBoundParameters.BottomMargin) {
                $style["margin-bottom"] = "${BottomMargin}%"
            }
            if ($psBoundParameters.Border) {                
                $style["border"] = "$border"            
            }
        }
        
        if ($isStaticRegion) {
            $hideTitleArea = $true
            $HideMoreButton = $true
            $hideDirectionButton = $true
        }
        #endregion Internal changing of parameters of parameter set overlaps
        
        

        if (-not $psBoundParameters.Default) {
            $randomOnLoad = ""

        }
        
        
        if (-not $psBoundParameters.Order) {
            $order = $layer.Keys  |Sort-Object
        }
        
        $xmlHttpVar = 'load${LayerID}'
        
        $moreButtonText = if (-not $HideMoreButton) {
            "
            <span style='padding:5px;'>
            <input type='button' id='${$LayerID}_MoreButton' onclick='show${LayerID}Morebar();' style='border:1px solid black;padding:5;font-size:medium' value='...' />
            </span>
            "
        } else {
            ""
        } 
        
        $directionButtonText = if (-not $HideDirectionButton) {
            "
            <span style='padding:5px;'>            
            <input type='button' id='${LayerID}_LastButton' onclick='moveToLast${LayerID}Item();' style='border:1px solid black;padding:5;font-size:medium' value='&lt;' /> 
            <input type='button' id='${LayerID}_NextButton' onclick='moveToNext${LayerID}Item();' style='border:1px solid black;padding:5;font-size:medium' value='&gt;' />
            </span>
            "
            
        } else {
            ""
        }                
        
        $layerTitleAreaText =if (-not $HideTitleArea) { " 
            <div style='margin-top:5px;margin-right:5px;z-index:-1' id='${LayerID}_TitleArea' NotALayer='true'>
            </div>
            "
            
        } else {
            ""
        }
        
        $fadeJavaScriptFunctions = if (-not $NotCool) {
@"
function set${LayerID}LayerOpacity(id, opacityLevel) 
{
    var eStyle = document.getElementById(id).style;
    eStyle.opacity = opacityLevel / 100;
    eStyle.filter = 'alpha(opacity='+opacityLevel+')';
    if (eStyle.filter != 'alpha(opacity=0)') {
        eStyle.visibility = 'visible'
    }
    if (opacityLevel > 0) {
        eStyle.visibility = 'visible'
    } else {
        eStyle.visibility = 'hidden'
    }
}


function fade${LayerID}Layer(eID, startOpacity, stopOpacity, duration, steps) {
    
    if (steps == null) { steps = duration } 
    var opacityStep = (stopOpacity - startOpacity) / steps;
    var timerStep = duration / steps;
    var timeStamp = 10
    var opacity = startOpacity
    for (var i=0; i < steps;i++) {
        opacity += opacityStep
        timeStamp += timerStep
        setTimeout("set${LayerID}LayerOpacity('"+eID+"',"+opacity+")", timeStamp);        
    }
    
    return        
}

"@            
        } else { ""} 
        
        $dragChunk= if ($CanDrag) { @"
    if (document.getElementById('$LayerID').addEventListener) {
        document.getElementById('$LayerID').addEventListener('touchmove', function(e) {
            e.preventDefault(); 
            curX = e.targetTouches[0].pageX; 
            curY = e.targetTouches[0].pageY;      
            document.getElementById('$LayerID').style.webkitTransform = 'translate(' + curX + 'px, ' + curY + 'px)'                    
        })
    }
"@      } else { ""} 

        $enablePanChunk = if ($CanPan) { @"
    var last${LayerID}touchX = null;
    var last${LayerID}touchY = null;
    var last${LayerID}scrollX = 0;
    var last${LayerID}scrollY = 0;
    var eventHandler = function(e) {
            e.preventDefault();
            container = document.getElementById('$LayerID')
            layer = getCurrent${LayerID}Layer()
            if (last${LayerID}touchX  && last${LayerID}touchX > e.targetTouches[0].pageX) {
                // Moving right
            }
            if (last${LayerID}touchX  && last${LayerID}touchX < e.targetTouches[0].pageX) {
                // Moving left
            }
            if (last${LayerID}touchY  && last${LayerID}touchY < e.targetTouches[0].pageY) {
                // Moving up
                last${LayerID}scrollY+= $ScrollSpeed   
                                
                if (last${LayerID}scrollY > 0) {
                    last${LayerID}scrollY = 0
                }

            }
            if (last${LayerID}touchY  && last${LayerID}touchY > e.targetTouches[0].pageY) {
                // Moving down
                last${LayerID}scrollY-= $ScrollSpeed
                
                // if less than zero, set a timeout to bounce the content back                
                if (last${LayerID}scrollY < -layer.scrollHeight) {
                    last${LayerID}scrollY = -layer.scrollHeight
                        
                }

            }
            last${LayerID}touchX = e.targetTouches[0].pageX
            last${LayerID}touchY = e.targetTouches[0].pageY
            
            layer.style.webkitTransform = 'translate(' + last${LayerID}scrollX +"px," + last${LayerID}scrollY +"px)";
            
            
            
        }
    if (document.getElementById('$LayerID').addEventListener) {
        document.getElementById('$LayerID').addEventListener('touchmove', eventHandler)
    }
    
    var layers = get${LayerID}Layer();
    while (layers[layerCount]) {
        if (layers[layerCount].addEventListener) {
            layers[layerCount].addEventListener('touchmove', eventHandler)
        }
        
        layerCount++;
    }

    
"@      } else { ""} 
        $layerSwitcherScripts = if (-not $DisableLayerSwitcher) {
@"

    $fadeJavaScriptFunctions
    
    function moveToNext${LayerID}Item() {
        var layers = get${LayerID}Layer();        
        var layerCount = 0;
        var lastLayerWasVisible = false;
        while (layers[layerCount]) {
            if (lastLayerWasVisible == true) { 
                select${LayerID}Layer(layers[layerCount].id);               
                lastLayerWasVisible = false;
                break
            }
                
            
            if (layers[layerCount].style.opacity == 1) {
                // This layer is visible.  Hide it, and make sure we know to show the next one.
                lastLayerWasVisible = true;
            }                         
            layerCount++;
        }
        
        if (lastLayerWasVisible == true) {
            select${LayerID}Layer(layers[0].id);                           
        }
    }
    
    function moveToLast${LayerID}Item() {
        var layers = get${LayerID}Layer();
        
        var layerCount = 0;
        var lastLayer = null;
        var lastLayerWasVisible = false;
        var showLastLayer =false;
        while (layers[layerCount]) {
            if (layers[layerCount].style.visibility == 'visible') {
                if (lastLayer == null) {
                    showLastLayer = true;
                } else {
                    select${LayerID}Layer(lastLayer.id);                           
                }
            }
            
            lastLayer = layers[layerCount];                                      
            layerCount++;
        }

        if (showLastLayer == true) {
            select${LayerID}Layer(lastLayer.id);                           
        }
    }             
    
    function select${LayerID}Layer(name, hideMoreBar) {
        var layers = get${LayerID}Layer();
        var layerCount = 0;
        var found = false;
        while (layers[layerCount]) {
      
            containerName = '${LayerID}_' + name
            if (layers[layerCount].id == name || 
                layers[layerCount].id == containerName || 
                layers[layerCount].id == containerName.replace("-", "_").replace(" ", "")) {                
                if (typeof fade${LayerID}Layer == "function") {
                    layers[layerCount].style.zIndex = 1
                    fade${LayerID}Layer(layers[layerCount].id, 0, 100, $($TransitionTime.TotalMilliseconds), $KeyFrameCount)
                } else {
                    layers[layerCount].style.visibility = 'visible';
                    layers[layerCount].style.opacity = 1;
                }                
                if (document.getElementById('${LayerID}_TitleArea') != null) {
                    document.getElementById('${LayerID}_TitleArea').innerHTML = get${LayerID}LayerTitleHTML(layers[layerCount]);
                }
            } else {
                if (typeof fade${LayerID}Layer == "function") {
                    if (layers[layerCount].style.opacity != 0) {
                        fade${LayerID}Layer(layers[layerCount].id, 100, 0, $($TransitionTime.TotalMilliseconds), $KeyFrameCount)
                    }
                } else {
                    layers[layerCount].style.visibility = 'hidden';
                }                
            }
            layerCount++;
        }
                       
        if (hideMoreBar == true) {
            hide${LayerID}Morebar();    
        }
    } 
    
    function add${LayerID}Layer(name, content, layerUrl, refreshInterval) 
    {
        var layers = get${LayerID}Layer();
        var safeLayerName = name.replace(' ', '').replace('-', '_');
        newHtml = "<div id='${LayerID}_" + safeLayerName +"' style='$(if ($AsTab -or -not $DisableLayerSwitcher) {'visibility:hidden;'})position:absolute;margin-top:0px;margin-left:0px;opacity:0;overflow:auto;-webkit-overflow-scrolling: touch;'>"
        newHtml += content
        newHtml += "</div><script>"
        newHtml += ("document.getElementById('${LayerID}_" + safeLayerName + "').setAttribute('friendlyName', '" + name + "');")
        if (layerUrl) {
            
            newHtml += ("document.getElementById('${LayerID}_" + safeLayerName + "').setAttribute('layerUrl', '" + layerUrl + "');")
        }
        newHtml += ("<" + "/script>")
        
        document.getElementById("${LayerID}").innerHTML += newHtml;         
        layers = get${LayerID}Layer()
        layerCount =0 
        while (layers[layerCount]) {
            if (layers[layerCount].id == "${LayerID}_" + safeLayerName) {
                layers[layerCount].setAttribute('friendlyName', name);
                if (layerUrl) {
                    layers[layerCount].setAttribute('layerUrl', layerUrl);
                }
                if (refreshInterval) {
                    layers[layerCount].setAttribute('refreshInterval', refreshInterval);
                }
                if (layerCount == 0) {
                    // first layer, show it
                    select${LayerID}Layer(layers[layerCount].id, true);
                }
            }
            layerCount++
        }                
    }    
    
    function set${LayerID}Layer(name, newHTML) 
    {
        var safeLayerName = name.replace(' ', '').replace('-', '_');
        layerId ="${LayerID}_" + safeLayerName 
        
        document.getElementById(layerId).innerHTML = newHtml;
        select${LayerID}Layer(layerId);
    }

        
    function new${LayerID}CrossLink(containerName, sectionName, displayName)
    {
        if (! displayName) {
            displayName = sectionName
        }
        "<a href='javascript:void' onclick='" + "select" +containerName + "layer(\"" + sectionName+ "\")'>" + displayName + "</a>'"        
    }                    
    
    function show${LayerID}Morebar() {        
        var morebar = document.getElementById('${LayerID}_Toolbar')                        
        var layers = get${LayerID}Layer();   
        var layerCount = layers.length;
        
            newHtml = "<span><select id='${LayerID}_ToolbarJumplist' style='font-size:large;padding:5'>"
            
            for (i =0 ;i < layerCount;i++) {
                newHtml += "<option style='font-size:large;' value='";
                newHtml += layers[i].id;
                newHtml += "'>";
                newHtml += layers[i].attributes['friendlyName'].value; 
                newHtml += "</option>"                       
            }
            newHtml += "</select> \
            <input type='button' style='border:1px solid black;padding:5;font-size:medium' value='Go' onclick='select${LayerID}Layer(document.getElementById(\"${LayerID}_ToolbarJumplist\").value, true);'>\
            </span>"
            morebar.innerHTML = newHtml;
                       
        // morebar.style.visibility = 'visible';                
    }
    
    function hide${LayerID}Morebar() {                
        document.getElementById('${LayerID}_Toolbar').innerHTML = "$($directionButtonText -split ([Environment]::NewLine) -join ('\' + [Environment]::NewLine)
            $moreButtonText -split ([Environment]::NewLine) -join ('\' + [Environment]::NewLine))";                    
    }   
"@            
        } else {
            ""
        }

        $cssStyleAttr  = if ($psBoundParameters.Style) { 
            Write-CSS -Style $style -OutputAttribute
        } else {
            ""
        }
        $cssFontAttr = if ($psBoundParameters.Style.Keys -like "font*"){
            $2ndStyle = @{}
            foreach ($k in $psBoundParameters.sTyle.keys) {
                if ($k -like "font*"){
                    $2ndStyle[$k] = $style[$k]
                }
            }
            Write-CSS -Style $2ndStyle -outputAttribute
        } else {
            ""
        }
        $cssStyleChunk = if ($psBoundParameters.Style) { 
            "style='" +$cssStyleAttr   + "'"
        } else {
            ""
        }
        
        
                
        
        $classChunk =  if ($CssClass) {
            "class='$($cssClass -join ' ')'"
        } else {
            ""
        }
        
        $itemTypeChunk = if ($itemType) {
            "itemscope='' $(if ($itemId) {'itemid="' + $itemId + '"' }) itemtype='$($itemType -join ' ')'"
        } else {
            ""
        }


        if (-not $DisableLayerSwitcher) {
            $out = @"
<div id='$LayerID' $classChunk $cssStyleChunk $itemTypeChunk>
$layerTitleAreaText      
<script type='text/javascript'>   
    function get${LayerID}LayerTitleHTML(layer) {
        var logoUrl = '$Logo'
        var fullTitle = ""
        if (logoUrl != '') {
            fullTitle = "<img style='align:left' src='" + logoUrl + "' border='0'/><span style='font-size:x-large'>" + layer.attributes['friendlyName'].value +'</span>' $(if ($HorizontalRuleUnderTitle) { '+ "<HR/>"'});
        } else {
            fullTitle= "<span style='font-size:x-large'>" + layer.attributes['friendlyName'].value +'</span>' $(if ($HorizontalRuleUnderTitle) { '+ "<HR/>"'});
        }           
                
        if (layer.attributes['layerUrl']) {
            fullTitle = "<a href='" + layer.attributes['layerUrl'].value + "'>" + fullTitle + "</a>"
        }
        
        $socialChunk
        
        return fullTitle
    }    
    
    function get${LayerID}Layer() {
        var element = document.getElementById('$LayerID');
        var layers = element.getElementsByTagName('div');
        var layersOut = new Array();
        var layerCount = 0;
        var layersOutCount = 0;
        while (layers[layerCount]) {            
            
            if (layers[layerCount].parentNode == element && layers[layerCount].attributes["NotALayer"] == null) {
                layersOut[layersOutCount] = layers[layerCount];
                layersOutCount++
            }
            layerCount++;
        }
        return layersOut;
    }    
    
    function getCurrent${LayerID}Layer() {
        var element = document.getElementById('$LayerID');
        var layers = element.getElementsByTagName('div');
        var layersOut = new Array();
        var layerCount = 0;
        var layersOutCount = 0;
        while (layers[layerCount]) {            
            
            if (layers[layerCount].parentNode == element && layers[layerCount].attributes["NotALayer"] == null) {
                if (layers[layerCount].style.visibility == 'visible') {
                    return layers[layerCount]
                }
                layersOutCount++
            }
            layerCount++;
        }        
    }
    

             
    $layerSwitcherScripts                  
</script>
"@
        } elseif ($AsResizable -or $AsWidget -or $AsDraggable) {
            $out = @"
"@            
        } else {
            $out = @"
<div id='$LayerID' $classChunk $cssStyleChunk $itemTypeChunk>
$layerTitleAreaText      
"@
        }     
        
        if ($psCmdlet.ParameterSetName -eq 'Content' -and 
            -not ($AsDraggable -or $AsWidget -or $AsResizable)) {
            $out+=$content
            $out+="</div>"
        }  else {        
        if ($AsTab) {
            $out += "<ul>" 
            $out += foreach ($layerName in $Order) {      
                if (-not $layerName) {continue }                      
                $safeLayerName = & $GetSafeLayerName $layerName
                $n = $layerName.Replace(" ", "").Replace("-", "").Replace(",", "").Replace("<", "").Replace(">","").Replace("'", "").Replace('"','').Replace('=', '').Replace('&', '').Replace('?', '').Replace("/", "")
                
                # If there's a layer URL, make use of the nifty ajax loading 
                if ($LayerUrl[$LayerName]) {
                    "<li><a $cssStyleChunk href='ajax/$($LayerUrl[$LayerName])'>${LayerName}</a></li>"
                } else {
                    "<li><a $cssStyleChunk href='#${LayerID}_$safeLayerName'>${LayerName}</a></li>"                                
                }
                
            }
            $out += "</ul>" 
            $out += foreach ($layerName in $Order) {      
                if (-not $layerName) {continue }                      
                if ($layerUrl[$layerName]) { continue }
                $putInParagraph =  $layer[$layerName] -notlike "*<*>*"
                $safeLayerName = & $GetSafeLayerName $layerName
                
                "<div id='${LayerID}_$safeLayerName' $cssStyleChunk>
                    $($(if ($putInParagraph) {'<p>'}) + $layer[$layerName] + $(if ($putInParagraph) {'</p>'}) )                
                </div>"
            }
        } elseif ($AsAccordian) { 
            $out += foreach ($layerName in $Order) {      
                if (-not $layerName) {continue }      
                $putInParagraph =  $layer[$layerName] -notlike "*<*>*"
                $safeLayerName = & $GetSafeLayerName $layerName
                "<h3><a href='#'>${LayerName}</a></h3>
                <div>
                    $($(if ($putInParagraph) {'<p>'}) + $layer[$layerName] + $(if ($putInParagraph) {'</p>'}) )                
                </div>
                "
            }
        } elseif ($AsWidget -or $AsResizable -or $AsDraggable) { 
            $out += foreach ($layerName in $Order) {      
                if (-not $layerName) {continue }      
                $putInParagraph =  $layer[$layerName] -notlike "*<*>*"
                $safeLayerName = & $GetSafeLayerName $layerName
                "
                <div id='${LayerID}_$safeLayerName' class='ui-widget-content' $cssStyleChunk $itemTypeChunk>
                    $(if ($LayerName -ne 'Default') { "<h3 class='ui-widget-header'>${LayerName}</h3>" })
                    $($(if ($putInParagraph) {'<p>'}) + $layer[$layerName] + $(if ($putInParagraph) {'</p>'}) )                
                </div>                
                "
                
                if ($AsResizable) {
@"
                <script type='text/javascript'>
                `$(function() {
		              `$('#${LayerID}_$safeLayerName').resizable();
	           });                    
                </script>
"@                
                }
                if ($AsDraggable) {
@"
                <script type='text/javascript'>
                `$(function() {
		              `$('#${LayerID}_$safeLayerName').draggable();
	           });                    
                </script>
"@                  
                }
            }
        }  elseif ($AsPopUp) {
            $out += foreach ($layerName in $Order) {      
                if (-not $layerName) {continue }      
                $putInParagraph =  $layer[$layerName] -notlike "*<*>*"
                $safeLayerName = & $GetSafeLayerName $layerName
                $popoutLayerId = "${LayerID}_$safeLayerName"
                $showButtonId = "${LayerID}_${safeLayerName}_ShowButton"
                $hideButtonId = "${LayerID}_${safeLayerName}_HideButton"
                $ajaxLoad = 
                    if ($layerUrl -and $layerUrl[$layerName]) {
                        & $getAjaxAndPutIntoContainer $layerUrl[$layerName] $popoutLayerId
                    } elseif ($LayerLink -and $LayerLink[$layerName]) {
                        & $getAjaxAndPutIntoContainer $LayerLink[$layerName] $popoutLayerId "Button"
                    } else {
                        ""
                    }
                # Carefully intermixed JQuery and PowerShell Variable Embedding.  Do Not Touch
@"
<div>
<script>
	`$(function() {
    `$( "#${ShowButtonId}").button()   
    `$( "#$ShowButtonId" ).click(function(){
        var options = {}; 
        $ajaxLoad            
        `$( "#$popoutLayerId" ).dialog({modal:true, title:"$($layerName -replace '"','\"')"});        
     });
    		
	});
</script>
<a id='$ShowButtonId' $cssStyleChunk class='ui-widget-header ui-corner-all' href='javascript:void'>${LayerName}</a>
<div id='$popoutLayerId' class='ui-widget-content ui-corner-all' style="display:none;">    
    <p>$($layer[$layerName])</p>
</div>
</div>
"@                
                                                
            }
        } elseif ($AsPopout) {
            $out += foreach ($layerName in $Order) {      
                if (-not $layerName) {continue }      
                $putInParagraph =  $layer[$layerName] -notlike "*<*>*"
                $safeLayerName = & $GetSafeLayerName $layerName
                
                $popoutLayerId = "${LayerID}_$safeLayerName"
                $showButtonId = "${LayerID}_${safeLayerName}_ShowButton"
                $hideButtonId = "${LayerID}_${safeLayerName}_HideButton"
                $ajaxLoad = 
                    if ($layerUrl -and $layerUrl[$layerName]) {
                        & $getAjaxAndPutIntoContainer $layerUrl[$layerName] $popoutLayerId
                    } elseif ($LayerLink -and $LayerLink[$layerName]) {
                        & $getAjaxAndPutIntoContainer $LayerLink[$layerName] $popoutLayerId "Button"
                    } else {
                        ""
                    }

                # Carefully intermixed JQuery and PowerShell Variable Embedding.  Do Not Touch
@"
<div>
<script>
	`$(function() {
    `$( "#${ShowButtonId}").button();  
    `$( "#$ShowButtonId" ).click(function(){        
        if (`$( "#$popoutLayerId" )[0].style.visibility == 'hidden') {
            `$( "#$popoutLayerId" )[0].style.visibility = 'visible'
            $ajaxLoad
        } else {
            `$( "#$popoutLayerId" )[0].style.visibility = 'hidden'
        }
        
        `$( "#$popoutLayerId" ).toggle( "fold", {}, 200);			                       
     });
    		
	});
</script>
<a id='$ShowButtonId'  class='ui-widget-header ui-corner-all' href='javascript:void' style='width:100%;$cssStyleAttr'>${LayerName}</a>
<div id='$popoutLayerId' class='ui-widget-content ui-corner-all' style="display:none;visibility:hidden;$cssStyleAttr">    
    <p>$($layer[$layerName])</p>
</div>
</div>
"@                
                                                
            }
        } elseif ($AsPopdown) {
            $out += foreach ($layerName in $Order) {      
                if (-not $layerName) {continue }      
                $safeLayerName = & $GetSafeLayerName $layerName
                $popoutLayerId = "${LayerID}_$safeLayerName"
                $showButtonId = "${LayerID}_${safeLayerName}_ShowButton"
                $hideButtonId = "${LayerID}_${safeLayerName}_HideButton"
                # Carefully intermixed JQuery and PowerShell Variable Embedding.  Do Not Touch
                $ajaxLoad = 
                    if ($layerUrl -and $layerUrl[$layerName]) {
                        & $getAjaxAndPutIntoContainer $layerUrl[$layerName] $popoutLayerId
                    } elseif ($LayerLink -and $LayerLink[$layerName]) {
                        & $getAjaxAndPutIntoContainer $LayerLink[$layerName] $popoutLayerId "Button"
                    } else {
                        ""
                    }


@"
<script>
	`$(function() {
        `$( "#${ShowButtonId}").button();  
        `$( "#$ShowButtonId" ).click(function(){
            
            if (`$( "#$popoutLayerId" )[0].style.visibility == 'hidden') {
                `$( "#$popoutLayerId" )[0].style.visibility = 'visible'
                $ajaxLoad 
            } else {
                `$( "#$popoutLayerId" )[0].style.visibility = 'hidden'
            }
            
            `$( "#$popoutLayerId" ).toggle( "fold", {}, 200);			                           
        });    		
	});
</script>
<a id='$ShowButtonId'  class='ui-widget-header ui-corner-all' $cssStyleChunk href='javascript:void'>${LayerName}</a> 
"@                
                                                
            }
            $nlc = 0
            $out += foreach ($layerName in $Order) {      
                $showIfDefault = if (($defaultToFirst -or ((-not $Default)) -and ($nlc -eq 0))) {
                    $defaultSlide = $popOutLayerId
                    ""                     
                } elseif ($default -eq $layerName.Trim()) {
                    $defaultSlide = $popOutLayerId
                    ""
                } else {
                    ""                
                }
                $nlc++
                if (-not $layerName) {continue }      
                $putInParagraph =  $layer[$layerName] -notlike "*<*>*"
                $safeLayerName = & $GetSafeLayerName $layerName
                $popoutLayerId = "${LayerID}_$safeLayerName"
            
@"
<div id='$popoutLayerId' class='ui-widget-content ui-corner-all' style="display:none;visibility:hidden;$cssStyleAttr">    
    <p>$($layer[$layerName])</p>
</div>
"@            
            }
        } elseif ($AsGrid) {
            $out += foreach ($layerName in $Order) {      
                if (-not $layerName) {continue }      
                $safeLayerName = & $GetSafeLayerName $layerName
                $popoutLayerId = "${LayerID}_$safeLayerName"
                $showButtonId = "${LayerID}_${safeLayerName}_ShowButton"
                
                # Carefully intermixed JQuery and PowerShell Variable Embedding.  Do Not Touch
                $ajaxLoad = 
                    if ($layerUrl -and $layerUrl[$layerName]) {
                        & $getAjaxAndPutIntoContainer $layerUrl[$layerName] $popoutLayerId
                    } elseif ($LayerLink -and $LayerLink[$layerName]) {
                        & $getAjaxAndPutIntoContainer $LayerLink[$layerName] $popoutLayerId "Button"
                    } else {
                        ""
                    }


                if (-not $cssFontAttr -and $Request.UserAgent -like "*MSIE 7.0*") {
                    # compatibility view
                    $cssFontAttr = 'font-size:medium'
                }
@"
<script>
	`$(function() {
        `$( "#${ShowButtonId}").button();  
        `$( "#$ShowButtonId" ).click(function(){
            
            if ((${LayerId}_CurrentSlide != '$popoutLayerId') || (`$( "#$popoutLayerId" ).css('display') == 'none')) {
                if (`$( "#$popoutLayerId" ).css('display') == 'none') {
                    `$( "#$popoutLayerId" ).css('visibility', 'visible')
                    $ajaxLoad 
                } 
                else 
                {
                    `$( "#$popoutLayerId" ).css('visibility', 'hidden')
                    //`$( "#$popoutLayerId" )[0].style.visibility = 'hidden'
                }
            
                if (${LayerId}_ActiveButtonId != '') {
                    `$('#' + ${LayerId}_ActiveButtonId).removeClass('ui-state-active')
                    `$('#' + ${LayerId}_ActiveButtonId).addClass('ui-state-default')
                }
                if (${LayerId}_CurrentSlide != '$popoutLayerId') {
                    `$( "#" + ${LayerId}_CurrentSlide).hide( "fold", {}, 200);
                }
                `$( "#$popoutLayerId" ).show( "fold", {}, 200);			                       
                `$('html, body').scrollTop(0);
                `$('html, body').animate({scrollTop: `$(`"#$popoutLayerId`").offset().top - ($GridItemHeight * 1.05)}, 400);    
                ${LayerId}_ActiveButtonId = '$ShowButtonId'
                `$('#' + ${LayerId}_ActiveButtonId).addClass('ui-state-active')
            }
            
            ${LayerId}_CurrentSlide = '$popoutLayerId'
        });    		
	});
</script>
<a id='$ShowButtonId'  class='ui-state-default ui-corner-all' href='javascript:void' style='float:left;width:${GridItemWidth}px;height:${GridItemHeight}px;padding:2px;margin:5px;$cssFontAttr'>${LayerName}</a> 
"@                
                       
            }
            $nlc = 0
            $out += "<div style='clear:both'></div>"
            $out += foreach ($layerName in $Order) {      
                $showIfDefault = if (($defaultToFirst -or ((-not $Default)) -and ($nlc -eq 0))) {
                    $defaultSlide = $popOutLayerId
                    ""                     
                } elseif ($default -eq $layerName.Trim()) {
                    $defaultSlide = $popOutLayerId
                    ""
                } else {
                    ""                
                }
                $nlc++
                if (-not $layerName) {continue }      
                $putInParagraph =  $layer[$layerName] -notlike "*<*>*"
                $safeLayerName = & $GetSafeLayerName $layerName
                $popoutLayerId = "${LayerID}_$safeLayerName"
            
@"
<div id='$popoutLayerId' style="display:none;$cssStyleAttr">    
    <p>$($layer[$layerName])</p>
</div>
"@            
            }
            $out += 
@"
<script>
${LayerId}_ActiveButtonId = ''
var ${LayerId}_CurrentSlide = '$defaultSlide'
</script>
"@

        } elseif ($AsLeftSidebarMenu -or $AsRightSidebarMenu) {
            $out += "
<div id='$layerId' style='margin-left:0px;margin-right:0px;border:blank'>
"
            $n = 0
            $layerCount = 0
            
            $allButtonContent = ""
            foreach ($layerName in $order) {
                $safeLayerName = & $GetSafeLayerName $layerName
                $popoutLayerId = "${LayerID}_$safeLayerName"
                $slideNames += $popoutLayerId
                $showButtonId = "${LayerID}_${safeLayerName}_ShowButton"
                
                $layerCount++
                $allButtonContent +=  @"
<script>
    $setIfDefault
	`$(function() {
        `$( "#${ShowButtonId}").button();
        `$( "#$ShowButtonId" ).click(
            function() {
                $stopSlideShowIfNeeded
                l = document.getElementById('$popoutLayerId');
                if (l.style.visibility == 'hidden') {
                    l.style.visibility = 'visible';
                }
                if (document.getElementById(${LayerId}_CurrentSlide)) {
                    `$( ("#" + ${LayerId}_CurrentSlide) ).hide( "clip", {}, 200);            
                    document.getElementById(${LayerId}_CurrentSlide).style.visibility = 'hidden';
                    document.getElementById(${LayerId}_CurrentSlide).style.display = 'none';	               

                }

                `$( "#$popoutLayerId" ).show("clip", {}, 200);
                document.getElementById("$popoutLayerId").style.visibility = 'visible';          
                document.getElementById("$popoutLayerId").style.display = 'inline'       
                ${LayerId}_CurrentSlide = '$popoutLayerId';
                
            });    		
        
	});
</script>
<a id='$ShowButtonId' style='width:100%;$cssStyleAttr' class='ui-widget-header ui-corner-all' href='javascript:void'>${LayerName}</a>
<br />
"@
            }
            #if ($n -eq 0) {
                
                if ($AsLeftSidebarMenu) {
                    # Sidebar first
                    $out += "<div style='width:${sidebarWidth}%;text-align:center;float:left' valign='top'>$allbuttonContent</div>"
                    $floatDirection = "right"                    
                } else {
                    $floatDirection = "left"
                }
                
                # Make sure we put int the content column
                $out += "<div style='width:$(99 - $sidebarWidth)%;border:0px;float:$floatDirection;$cssStyleAttr' >"
                
                $nlc = 0
                $out += foreach ($2ndlayerName in $Order) {      
                    
                    if (-not $2ndlayerName) {continue }                              
                    $safeLayerName = & $GetSafeLayerName $2ndlayerName 
                    $popoutLayerId = "${LayerID}_$safeLayerName"                    
                    $setIfDefault = if (($defaultToFirst -or (-not $Default)) -and ($nlc -eq 0)) {                        
                        $defaultSlideId = $popoutLayerId 
                        "display:inline;visibility:visible;"
                    } elseif ($default -eq $layerName) {                        
                        $defaultSlideId = $popoutLayerId 
                        "display:inline;visibility:visible;"
                    } else {
                        "display:none;visibility:hidden;"                
                    }
                    $nlc++    
                    
@"
    <div id='$popoutLayerId' style="${setIfDefault}text-align:left">    
        $($layer[$2ndlayerName])
    </div>
"@            
                }
                
                
                $out += "</div>"
                if ($AsRightSidebarMenu) {
                     # Sidebar second
                     $out += "<div style='width:${sidebarWidth}%;text-align:center;float:right'>$allbuttonContent</div>"
                }
                #$out += "</tr>"
            #} else {                
            #   $out += "<tr><th valign='top'>$buttonContent</th></tr>"
            #}
            #$n++
                            
            # $defaultSlide  = $LayerID + "_" + (& $getSafeLayerName $default)
            $out += 
@"
</div>
<script>
    var ${LayerId}_CurrentSlide = '$defaultSlideId'
</script>

"@
        } elseif ($AsPortlet) {
            if (-not $ColumnWidth) { $ColumnWidth = (100 / $ColumnCount).ToString() + "%" } 
            $out += 
            "
            <style>
                .column { width: ${ColumnWidth}; float:left; padding-bottom:100px } 
                .portlet-header { margin: 0.3em; padding-bottom: 4px; padding-left: 0.2em; }
            	.portlet-header .ui-icon { float: right; }
            	.portlet-content { padding: 0.4em; }
            	.ui-sortable-placeholder { border: 1px dotted black; visibility: visible !important; height: 50px !important; }
            	.ui-sortable-placeholder * { visibility: hidden; }

            </style>
            "
            $itemsPerColumn = @($order).Count / $ColumnCount
                $portlets = foreach ($layerName in $Order) { 
                         
                    if (-not $layerName) {continue }      
                    $putInParagraph =  $layer[$layerName] -notlike "*<*>*"
                    $safeLayerName = & $GetSafeLayerName $layerName
                    "
                    <div class='portlet' $cssStyleChunk>
                        <div class='portlet-header'>${LayerName}</div>
                        <div class='portlet-content'>$($layer[$layerName])</div>
                    </div>                
                    "
                                        
                }            
                
            $columns = for ($i =0;$i-lt@($order).Count;$i+=$itemsPerColumn) {
                "<div class='column'>" + ($portlets[$i..($I + ($itemsPerColumn - 1))]) + "</div>"
            }
            
            $out += $columns
            $out += @'
<script>
	$(function() {
		$( ".column" ).sortable({
			connectWith: ".column"
		});

		$( ".portlet" ).addClass( "ui-widget ui-widget-content ui-helper-clearfix ui-corner-all" )
			.find( ".portlet-header" )
				.addClass( "ui-widget-header ui-corner-all" )
				.prepend( '<span class="ui-icon ui-icon-minusthick"></span>')
				.end()
			.find( ".portlet-content" );

		$( ".portlet-header .ui-icon" ).click(function() {
			$( this ).toggleClass( "ui-icon-minusthick" ).toggleClass( "ui-icon-plusthick" );
			$( this ).parents( ".portlet:first" ).find( ".portlet-content" ).toggle();
		});

		$( ".column" ).disableSelection();
	});
</script>
'@            
            
        } elseif ($AsPopIn -or $AsSlideShow) {
            $slideNames  = @()
            $layerCount = 0 
            $slideButtons = ""
            if (-not ($AsSlideShow -and $HideSlideNameButton)) {
                $slideButtons += "<div id='${LayerId}_MenuContainer' style='$(if ($MenuBackgroundColor) {"background-color:$MenuBackgroundColor" });text-align:center;margin-left:0%;margin-right:0%;padding-top:0%;padding-bottom:0%' >
                    "
            }            
            $slideButtons += foreach ($layerName in $Order) {      
                if (-not $layerName) {continue }      
                $safeLayerName = & $GetSafeLayerName $layerName
                
                $popoutLayerId = "${LayerID}_$safeLayerName"
                $slideNames += $popoutLayerId
                $showButtonId = "${LayerID}_${safeLayerName}_ShowButton"
                $hideButtonId = "${LayerID}_${safeLayerName}_HideButton"
                $setIfDefault = if (($defaultToFirst -or ((-not $Default)) -and ($layerCount -eq 0))) {
                    $defaultSlide = $popOutLayerId
                    "${LayerId}_CurrentSlide = '$popOutLayerId'"                     
                } elseif ($default -eq $layerName.Trim()) {
                    $defaultSlide = $popOutLayerId
                    "${LayerId}_CurrentSlide = '$popOutLayerId'"
                } else {
                    ""                
                }
                $stopSlideShowIfNeeded = if ($ASSlideshow) {
                    "clearInterval(${LayerId}_SlideshowTimer);"
                } else {
                    ""
                }
                $layerCount++
                # Carefully intermixed JQuery and PowerShell Variable Embedding.  Do Not Touch
                if (-not ($AsSlideShow -and $HideSlideNameButton)) {
                
                                    
                    if ($layerUrl[$layerName]) {

$SlidebuttonText = if ($UseDotInsteadOfName) {
    "<a style='$cssFontAttr;text-decoration:none' id='$ShowButtonId' href='$($layerUrl[$layerName])'><span style='font-size:6em'>&middot;</span></a>"
} else {
    "<a style='padding:5px;$cssFontAttr' id='$ShowButtonId' class='ui-widget-header ui-corner-all' href='$($layerUrl[$layerName])'>${LayerName}</a>"
}

@"
$SlidebuttonText
<script>`$( "#${ShowButtonId}").button();</script>
"@                    
                    } else {

$SlidebuttonText= 
    if ($UseDotInsteadOfName) {
        "<a style='$cssFontAttr;text-decoration:none' id='$ShowButtonId' href='#'><span style='font-size:6em'>&middot;</span></a>"
    } else {
        "<a style='padding:5px;$cssFontAttr' id='$ShowButtonId' href='#'>${LayerName}</a>"
    }
                
@"
<script>
	`$(function() {
        $setIfDefault
        $(if (-not $UseDotInsteadOfName) { "`$( `"#${ShowButtonId}`").button();" })
        `$( "#$ShowButtonId" ).click(
            function() {
                $stopSlideShowIfNeeded
                l = document.getElementById('$popoutLayerId');
                
                
                if (l.style.visibility == 'hidden') {
                    l.style.visibility = 'visible';
                }
                if (${LayerId}_CurrentSlide != '$popOutLayerId') {
                    if (document.getElementById(${LayerId}_CurrentSlide)) {
                        `$( ("#" + ${LayerId}_CurrentSlide) ).hide(200);            
                        document.getElementById(${LayerId}_CurrentSlide).style.visibility = 'hidden';
                        document.getElementById(${LayerId}_CurrentSlide).style.display = 'none';	               

                    }

                }
                
                `$( "#$popoutLayerId" ).show(200);
                document.getElementById("$popoutLayerId").style.visibility = 'visible';          
                document.getElementById("$popoutLayerId").style.display = 'inline'       
                ${LayerId}_CurrentSlide = '$popoutLayerId';
                
            });    		
        
	});
</script>
$SlidebuttonText
"@                
                    }
                }
                                                          
            }
            $slideButtons += "</div>"

            if (-not $AsSlideShow) {
                $out += $slideButtons
            }
            $out += foreach ($layerName in $Order) {      
                if (-not $layerName) {continue }      
                $putInParagraph =  $layer[$layerName] -notlike "*<*>*"
                $safeLayerName = & $GetSafeLayerName $layerName
                $popoutLayerId = "${LayerID}_$safeLayerName"
            
@"
<div id='$popoutLayerId' class='ui-widget-content clickable' style="display:none;visibility:hidden;border:0px">    
    <p>$($layer[$layerName])</p>
</div>
"@            
            }
            if ($AsSlideShow) {
$out += @"
    <div style='float:right'>
        $slideButtons
    </div>
    <script>
        function showNext${LayerId}Slide() {
            
            c = 0 
            do {
                if (${LayerId}_SlideNames[c] == ${LayerId}_CurrentSlide) {
                    break;
                }
                c++
            } while (${LayerId}_SlideNames[c])
            if (c == ${LayerId}_SlideNames.length) {
                return;
            }
            
            slideIndex = c
            `$( ("#" + ${LayerId}_CurrentSlide) ).hide( "drop", {}, 200);            
            document.getElementById(${LayerId}_CurrentSlide).style.visibility = 'hidden'			               
            document.getElementById(${LayerId}_CurrentSlide).style.display = 'none'			               
            if ((slideIndex + 1) == ${LayerId}_SlideNames.length) {
                nextSlideHtml = document.getElementById(${LayerId}_SlideNames[0]).innerHTML;                
                ${LayerId}_CurrentSlide = ${LayerId}_SlideNames[0]
            } else {
                nextSlideHtml = document.getElementById(${LayerId}_SlideNames[slideIndex + 1]).innerHTML
                ${LayerId}_CurrentSlide = ${LayerId}_SlideNames[slideIndex + 1]
            }
            document.getElementById(${LayerId}_CurrentSlide).style.visibility = 'visible'			           
            document.getElementById(${LayerId}_CurrentSlide).style.display = 'inline'			                   
            `$( ("#" + ${LayerId}_CurrentSlide) ).show( "drop", {}, 200);			               
            
        }
        var ${LayerId}_SlideNames = new Array('$($slidenames -join "','")');
        var ${LayerId}_CurrentSlide = '$defaultSlide'
        document.getElementById(${LayerId}_CurrentSlide).style.visibility = 'visible'			           
        document.getElementById(${LayerId}_CurrentSlide).style.display = 'inline'			                   
        var ${LayerId}_SlideshowTimer = setInterval('showNext${LayerId}Slide()', $($autoSwitch.TotalMilliseconds))
    </script>
"@                
            }

            $out +=
@"
<div id='${LayerId}_InnerContainer' style='margin-left:auto;margin-right:auto;border:0px' class='ui-widget-content'>

</div>
"@          
            if ($default) {
                $defaultSlide = $LayerID + "_" + (& $getSafeLayerName $default)
                $out += 
@"
<script>
`$(function() {
`$( `"#$defaultSlide`" ).show('drop', {}, 200)
if (document.getElementById('$defaultSlide')) {
    document.getElementById('$defaultSlide').style.visibility = 'visible'
    document.getElementById('$defaultSlide').style.display = 'inline'
}
})
var ${LayerId}_CurrentSlide = '$defaultSlide'
</script>
"@
            }
        } else {
            $out += foreach ($layerName in $Order) {      
                if (-not $layerName) {continue }      
                
                $safeLayerName = & $GetSafeLayerName $layerName
@"
            $(if (-not $DisableLayerSwitcher) {"<script type='text/javascript'>
            
            function switchTo${LayerID}${safeLayerName}() {
                select${LayerID}Layer('${LayerID}_$safeLayerName', true);                                
            }
            
            </script>
            "})
            <div id='${LayerID}_$safeLayerName' style='visibility:hidden;opacity=0;position:absolute;margin-top:0px;margin-left:0px;margin-bottom:0px;margin-right:0px;'>                
                $($layer[$layerName])                
            </div>
            $(if (-not $FixedSize) { "
            <script>
                document.getElementById('${LayerID}_${safeLayerName}').setAttribute('friendlyName', '$layerName');
                $(if ($layerUrl -and $layerUrl[$layerName]) { "document.getElementById('${LayerID}_${safeLayerName}').setAttribute('layerUrl', '$($layerUrl[$layerName])')" })
                layer = document.getElementById('${LayerID}_${safeLayerName}')
                if (layer.addEventListener) {
                    layer.addEventListener('onscroll', function(e) {
                        reset${LayerID}Size();
                    });
                } else {
                    if (layer.attachEvent) {
                        layer.attachEvent('onscroll', function(e) {
                            reset${LayerID}Size();
                        });
                    }
                }
                
            </script>
            "})
"@            
            }
        }
              
        
        $requestHandler = if (-not $NotRequestAware) {
            "
            var queryParameters = new Array();
            var query = window.location.search.substring(1);
            var parms = query.split('&');
            for (var i=0; i<parms.length; i++) {
                var pos = parms[i].indexOf('=');
                if (pos > 0) {
                    var key = parms[i].substring(0,pos);
                    var val = parms[i].substring(pos+1);
                    queryParameters[key] = val;
                }
            }
            
            if (queryParameters['$LayerID'] != null) {
                var realLayerName = '${LayerID}_' + queryParameters['$LayerID'];
                if (document.getElementById(realLayerName)) {
                    select${LayerID}Layer(realLayerName, false);
                }
            }
            "
        } else {
            ""
        }
        
        $resizeChunk =if (-not $FixedSize) {
@"
            function isIPad() {  
                return !!(navigator.userAgent.match(/iPad/));  
            }  

            function isIPhone() {  
                return !!(navigator.userAgent.match(/iPhone/));  
            }  

            function reset${LayerID}Size() {
                var element = document.getElementById('$LayerID');            
                // Late bound centering by absolute position.                  
                 
                leftMargin = document.body.clientWidth * $($LeftMargin / 100);
                rightMargin = document.body.clientWidth * $((100 -$RightMargin) / 100);
                topMargin = document.body.clientHeight  * $($TopMargin / 100);            
                bottomMargin = document.body.clientHeight * $($BottomMargin / 100);
                layerwidth = Math.abs(rightMargin - leftMargin);
                layerheight = Math.abs(bottomMargin - topMargin);
                element.style.position = 'absolute';
                element.style.marginLeft = leftMargin + 'px';
                element.style.marginRight = rightMargin + 'px';
                element.style.width = layerwidth + 'px';
                element.style.marginTop = topMargin + 'px';
                element.style.marginBottom = bottomMargin + 'px';                                                
                element.style.height = (document.body.clientHeight -(topMargin + bottomMargin)) + 'px';
                element.style.border = '$Border';
                element.style.borderRadius = '1em';
                element.style.MozBorderRadius = '1em';
                element.style.WebkitBorderRadius = '1em;'
                //element.style.borderRadius = 1em;
                //element.style.borderTopLeftRadius = 1em;
                //element.style.borderTopRightRadius = 1em;
                //element.style.borderBottomLeftRadius = 1em;
                //element.style.borderBottomRightRadius = 1em;
                element.style.clip = 'rect(auto, auto, ' + (element.style.height - 10) + 'px, ' + (element.style.width - 10) + 'px)'
                if (isIPhone() || isIPad()) {
                    element.style.overflow = 'scroll'          
                } else {
                    element.style.overflow = 'auto'                                  
                }
                element.style.webkitoverflowscrolling = 'touch'
                    
                var toolbar = document.getElementById('${LayerID}_Toolbar')
                if (toolbar != null) {
                    toolbar.style.position = 'absolute'
                    toolbar.style.zIndex= '5'                    
                    toolbar.style.width = (layerwidth - 15) + 'px';
                    $(if (-not $ToolbarAbove) {
                        "toolbar.style.bottom =  0  +'px';"
                        "toolbar.style.marginBottom =  0  +'px';"
                    } else {
                        'toolbar.style.marginTop = ${ToolbarMargin} + "px";'
                    })
                    toolbar.style.textAlign = 'right';
                    toolbar.style.marginLeft = '${ToolbarMargin}px';
                    toolbar.style.marginRight = '${ToolbarMargin}5px';
                    toolbar.style.marginBottom = '${ToolbarMargin}5px';
                }                
            }
            
            if (window.addEventListener) {
                window.addEventListener("onresize", function() {
                    reset${LayerID}Size();
                });
                
                window.addEventListener("onorientationchange", function() {
                    reset${LayerID}Size();
                });   
            } else {
                if (window.attachEvent) {
                    window.attachEvent("onresize", function(e) {                        
                        reset${LayerID}Size();
                    });
                }
            }
            
            $enablePanChunk 
            $dragChunk
            
            var original${LayerID}ClientWidth = document.body.clientWidth;
            var original${LayerID}Orientation = window.orientation;
            function checkAndReset${LayerID}Size() {
                if (original${LayerID}ClientWidth != document.body.clientWidth) { 
                    original${LayerID}ClientWidth = document.body.clientWidth
                    reset${LayerID}Size(); 
                }
                if (original${LayerID}Orientation != window.orientation) {
                    original${LayerID}Orientation = window.orientation
                    reset${LayerID}Size(); 
                }
            }
            setInterval("checkAndReset${LayerID}Size();", 100);
            reset${LayerID}Size();
"@            
        } else {
""
        }
        
        $autoSwitcherChunk = if ($psBoundParameters.AutoSwitch -and (-not $asslideshow)) {
            "
            setInterval('moveToNext${LayerID}Item()', $([int]$autoSwitch.TotalMilliseconds)); 
"
        } else {
            ""
        }
        
        $selectDefaultChunk = if (-not $disableLayerSwitcher) {
@"
            var layers = get${LayerID}Layer();
            var layerCount = 0;
            while (layers[layerCount]) {
                layerCount++;
            }

            var defaultValue = '${LayerID}_$("$default".Replace(' ','_').Replace('-', '_'))'
            if (defaultValue != '${LayerID}_') {
                select${LayerID}Layer(defaultValue);
            } else {
                $(if ($DefaultToFirst) { 
                    "var whichLayer = 0" 
                } else {"var whichLayer=Math.round(Math.random()*(layerCount - 1));"})                	                
                if (layers[whichLayer] != null) {
                    if (typeof select${LayerID}Layer == "function") {
                        select${LayerID}Layer(layers[whichLayer].id);
                    } else {
                        layers[whichLayer].style.visibility = 'visible'
                        layers[whichLayer].style.opacity = '1'
                    }
                }                
            }
"@        
        } else {
            ""
        }
        $MouseOverEvent = if ($OpenOnMouseOver) {
            "event: `"mouseover`""
        } else {
            $null
        }
        


        $AccordianChunk = if ($AsAccordian) {
            # Join all settings that exists with newlines.  
            # Powershell list operator magic filters out settings that are null.
            $settings = 
                $MouseOverEvent, 'autoHeight: false', 'navigation: true' -ne $null
            $settingString = $settings -join ",$([Environment]::NewLine)"
            "`$(function() {
		`$( `"#${LayerID}`" ).accordion({
            $settingString             
        });
	})"
        } else { "" }
        
        
        $TabChunk = if ($AsTab) {
            $settings = 
                $MouseOverEvent, 'autoHeight: false', 'navigation: true' -ne $null
                
            $tabsBelowChunk = if ($tabBelow) {
                "                
                `$( `".tabs-bottom .ui-tabs-nav, .tabs-bottom .ui-tabs-nav > *`" )
			.removeClass( `"ui-corner-all ui-corner-top`" )
			.addClass( `"ui-corner-bottom`" );
                "
            } else {
                ""
            }
            $settingString = $settings -join ",$([Environment]::NewLine)"
            "`$(function() {
		`$( `"#${LayerID}`" ).tabs({
            $mouseOverEvent
            
        });
        $tabsBelowChunk

	})"

        } else { "" }

        $javaScriptChunk = if ($SelectDefaultChunk -or 
            $ResizeChunk -or 
            $AutoSwitcherChunk -or             
            $Requesthandler -or 
            $tabChunk -or 
            $AccordianChunk) { @"
        <script type='text/javascript'>
            $selectDefaultChunk                           
            $resizeChunk                         
            $autoSwitcherChunk            
            $requestHandler                                                       
            $TabChunk
            $AccordianChunk
        </script> 
"@ 
        } else {
            ""
        }       
        
        if ($tabBelow) {
            $out += @"
<style>
    .tabs-bottom { position: relative; } 
	.tabs-bottom .ui-tabs-panel { height: 140px; overflow: auto; } 
	.tabs-bottom .ui-tabs-nav { position: absolute !important; left: 0; bottom: 0; right:0; padding: 0 0.2em 0.2em 0; } 
	.tabs-bottom .ui-tabs-nav li { margin-top: -2px !important; margin-bottom: 1px !important; border-top: none; border-bottom-width: 1px; }
	.ui-tabs-selected { margin-top: -3px !important; }
</style>            
"@            
        }                
        $out += @"
        $(if (-not $IsStaticRegion) {
        "
        <div id='${LayerID}_Toolbar' style='margin-top:${ToolbarMargin}px;margin-right:${ToolbarMargin}px;margin-bottom:${ToolbarMargin}px;z-index:-1' NotALayer='true'>            
            $directionButtonText 
            $moreButtonText                   
        </div>"
        })       
               
        $(if (-not ($AsResizable -or $AsDraggable -or $asWidget)) {'</div>'})
        $javaScriptChunk


"@
        }
    $pageAsXml = $out         -as [xml]
    
    if ($pageAsXml -and 
        $out -notlike "*<pre*") {
        $strWrite = New-Object IO.StringWriter
        $pageAsXml.Save($strWrite)
        $strOut = "$strWrite"
        $strOut.Substring($strOut.IndexOf(">") + 3)
    } else {
        $out        
    }
        
        
        
    }
}
