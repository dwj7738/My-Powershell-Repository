<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >
  <xsl:param name="Keyword" />
  <xsl:param name="ResultsBy" />
  <xsl:param name="ViewByUrl" />
  <xsl:param name="ShowDropDown" />
  <xsl:param name="ViewByValue" />
  <xsl:param name="SortBy" />
  <xsl:param name="SortOptions" />
  <xsl:param name="Multiply" />
  <xsl:param name="PictureTaken" />
  <xsl:param name="IsNoKeyword" />
  <xsl:param name="IsFixedQuery" />
  <xsl:param name="ShowActionLinks" />
  <xsl:param name="MoreResultsText" />
  <xsl:param name="MoreResultsLink" />
  <xsl:param name="CollapsingStatusLink" />
  <xsl:param name="CollapseDuplicatesText" />
  <xsl:param name="AlertMeLink" />
  <xsl:param name="AlertMeText" />
  <xsl:param name="SrchRSSText" />
  <xsl:param name="SrchRSSLink" />
  <xsl:param name="SearchProviderText" />
  <xsl:param name="SearchProviderLink" />
  <xsl:param name="SearchProviderAlt"/>
  <xsl:param name="ShowMessage" />
  <xsl:param name="IsThisListScope" />
  <xsl:param name="DisplayDiscoveredDefinition" select="True" />
  <xsl:param name="NoFixedQuery" />
  <xsl:param name="NoKeyword" />
  <xsl:param name="ResultsNotFound" />
  <xsl:param name="NoResultsSuggestion" />
  <xsl:param name="NoResultsSuggestion1" />
  <xsl:param name="NoResultsSuggestion2" />
  <xsl:param name="NoResultsSuggestion3" />
  <xsl:param name="NoResultsSuggestion4" />
  <xsl:param name="NoResultsSuggestion5" />
  <xsl:param name="AdditionalResources" />
  <xsl:param name="AdditionalResources1" />
  <xsl:param name="AdditionalResources2" />
  <xsl:param name="Period" />
  <xsl:param name="SearchHelp" />
  <xsl:param name="Tags" />
  <xsl:param name="Authors" />
  <xsl:param name="Date" />
  <xsl:param name="Size" />
  <xsl:param name="ViewInBrowser" />
  <xsl:param name="DefinitionIntro" />
  <xsl:param name="IdPrefix" />
  <xsl:param name="FindSimilarLinkText" />
  <xsl:param name="EnableSimilarFind" />
  <xsl:param name="SimilarFindBaseURL" />
  <xsl:param name="DuplicatesLinkText" />
  <xsl:param name="PreviewScrollbarMode" />
  <xsl:param name="PreviewWindowSize" />
  <xsl:param name="EnableDocumentPreviewPowerPoint" />
  <xsl:param name="EnableDocumentPreviewWord"/>
  <xsl:param name="ViewInBrowserLink" />
  <xsl:param name="ViewInBrowserReturnUrl" />
  <xsl:param name="ThumbnailTooltip" />
  <xsl:param name="ThumbnailTooltipLoading" />
  <xsl:param name="ThumbnailTooltipLoadingFailed" />
  <xsl:param name="ConcurrentDocumentPreview" />
  <xsl:param name="TotalDocumentPreview" />
  <xsl:param name="OpenPreviewLink" />
  <xsl:param name="ClosePreviewLink" />
  <xsl:param name="LangPickerHeading" />
  <xsl:param name="LangPickerNodeSet" />
  <xsl:param name="AAMZone" />


  <!-- display document preview thumbnail-->
  <xsl:template name="DisplayPreviewThumbnail">
    <xsl:param name="width" />
    <xsl:param name="currentId" />
    <xsl:param name="className" />
    <xsl:param name="isPreviewAvailable" />
    <div _class="srch-ext-previewThumbnailDiv"
         id="{concat('FST_previewIconDiv_',$currentId)}"
         style="DISPLAY: block;">
      <xsl:choose>
        <xsl:when test="$isPreviewAvailable = true()">
          <img id="{concat('FST_previewIcon_',$currentId)}"
                   class="{$className}"
                   onclick="FST_TogglePreviewWindow('{$currentId}'); return false;"
                   onerror="FST_ThumbnailImageLoadError('{$currentId}', '{$ThumbnailTooltipLoadingFailed}');"
                   style="width: 0px;height: 0px;display:none;">
          </img>
          <div class="srch-ext-mgnfier" id="{concat('FST_magIcon_',$currentId)}" style="display:none;">
            <img src="/_layouts/images/zoomhh.png" title="{$ThumbnailTooltip}"
                 onclick="FST_TogglePreviewWindow('{$currentId}'); return false;" />
          </div>
        </xsl:when>
        <xsl:otherwise>
          <img id="{concat('FST_previewIcon_',$currentId)}"
               style="width: 0px;height: 0px;display:none;"
               onerror="FST_ThumbnailImageLoadError('{$currentId}', '{$ThumbnailTooltipLoadingFailed}');"
               class="{$className}"/>
        </xsl:otherwise>
      </xsl:choose>
    </div>

  </xsl:template>

  <!-- When there is keywory to issue the search -->
  <xsl:template name="dvt_1.noKeyword">
    <span class="srch-description2">
      <xsl:choose>
        <xsl:when test="$IsFixedQuery">
          <xsl:value-of select="$NoFixedQuery" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$NoKeyword" />
        </xsl:otherwise>
      </xsl:choose>
    </span>
  </xsl:template>


  <!-- When empty result set is returned from search -->
  <xsl:template name="dvt_1.empty">
    <div class="srch-results">

      <xsl:if test="string-length($SrchRSSLink) &gt; 0 and $ShowActionLinks">
        <a type="application/rss+xml" href ="{$SrchRSSLink}" title="{$SrchRSSText}" id="SRCHRSSL" class="srch-ext-action-margin">
          <img style="vertical-align: middle;" border="0" src="/_layouts/images/rss.gif" alt=""/>
          <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
          <xsl:value-of select="$SrchRSSText"/>
        </a>
        <xsl:if test="string-length($SearchProviderLink) &gt; 0">
          |
          <a href ="{$SearchProviderLink}" title="{$SearchProviderText}" class="srch-ext-action-margin" >
            <img style="vertical-align: middle;" border="0" src="/_layouts/images/searchfolder.png" alt=""/>
            <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
            <xsl:value-of select="$SearchProviderText"/>
          </a>
        </xsl:if>
      </xsl:if>
    </div>

    <span class="srch-description2" id="CSR_NO_RESULTS">
      <p>
        <xsl:value-of select="$ResultsNotFound" />
        <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
        <strong>
          <xsl:value-of select="$Keyword" />
        </strong>
        <xsl:value-of select="$Period" />
      </p>
      <h3>
        <xsl:value-of select="$NoResultsSuggestion" />
      </h3>
      <ul>
        <li>
          <xsl:value-of select="$NoResultsSuggestion1" />
        </li>
        <li>
          <xsl:value-of select="$NoResultsSuggestion2" />
        </li>
        <li>
          <xsl:value-of select="$NoResultsSuggestion3" />
        </li>
        <xsl:if test="string-length($NoResultsSuggestion4) &gt; 0">
          <li>
            <xsl:value-of select="$NoResultsSuggestion4" />
          </li>
        </xsl:if>
        <xsl:if test="string-length($NoResultsSuggestion5) &gt; 0">
          <li>
            <xsl:value-of select="$NoResultsSuggestion5" />
          </li>
        </xsl:if>
      </ul>
      <h3>
        <xsl:value-of select="$AdditionalResources" />
      </h3>
      <ul>
        <li>
          <xsl:value-of select="$AdditionalResources1" />
          <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
          <a href="javascript:HelpWindowKey('WSSEndUser_FindContent')" label="$SearchHelp">
            <xsl:value-of select="$SearchHelp" />
          </a>
        </li>
        <li>
          <xsl:value-of select="$AdditionalResources2" />
        </li>
      </ul>



    </span>
  </xsl:template>

  <!-- Main body template. Sets the Results view (Relevance or date) options -->
  <xsl:template name="dvt_1.body">
    <script language="javascript">
      function ToggleShowAll(id)
      {
      var selection = document.getElementById(id);
      if (selection.style.display == "none")
      {
      selection.style.display = "inline";
      }
      else
      {
      selection.style.display = "none";
      }
      }
    </script>

    <xsl:choose>
      <xsl:when test="$ShowActionLinks">
        <div class="srch-sort-right2">
          <xsl:if test="$LangPickerNodeSet and count($LangPickerNodeSet) &gt; 0">
            <xsl:value-of select="$LangPickerHeading"/>
            <select class="srch-ext-dropdown" onchange="window.location.href=this.value" id="langpickerdd">
              <xsl:for-each select="$LangPickerNodeSet">
                <xsl:element name="option">
                  <xsl:attribute name="value">
                    <xsl:value-of select="@url"/>
                  </xsl:attribute>
                  <xsl:if test="@selected = 'true'">
                    <xsl:attribute name="selected">selected</xsl:attribute>
                  </xsl:if>
                  <xsl:value-of select="@title"/>
                </xsl:element>
              </xsl:for-each>
            </select>
            <xsl:text disable-output-escaping="yes">&#8195;</xsl:text>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="All_Results/SortList/SortEntry">
              <xsl:value-of select="$SortBy" />
              <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
              <select id="dropdown" title="{$SortOptions}" onchange="PostToUrl(this.value)" class="srch-ext-dropdown srch-ext-action-margin">
                <xsl:for-each select="All_Results/SortList/SortEntry">
                  <xsl:element name="option">
                    <xsl:attribute name="value">
                      <xsl:value-of select="SelectionUrl"/>
                    </xsl:attribute>
                    <xsl:variable name="lowercasetext" select="translate(IsSelected, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')" />
                    <xsl:if test="$lowercasetext ='true'">
                      <xsl:attribute name="selected">selected</xsl:attribute>
                    </xsl:if>
                    <xsl:value-of select="DisplayName"/>
                  </xsl:element>
                </xsl:for-each>
              </select>
            </xsl:when>
          </xsl:choose>
          <xsl:if test="string-length($SrchRSSLink) &gt; 0">
            <a type="application/rss+xml" href ="{$SrchRSSLink}" title="{$SrchRSSText}" id="SRCHRSSL" class="srch-ext-action-margin">
              <img style="vertical-align: middle;" border="0" src="/_layouts/images/rss.gif" alt=""/>
            </a>
          </xsl:if>
          <xsl:if test="string-length($SearchProviderLink) &gt; 0">
            <a href ="{$SearchProviderLink}" title="{$SearchProviderAlt}" class="srch-ext-action-margin" >
              <img style="vertical-align: middle;" border="0" src="/_layouts/images/searchfolder.png" alt=""/>
            </a>
          </xsl:if>
        </div>
      </xsl:when>
      <xsl:otherwise>

        <div class="srch-results">
          <xsl:apply-templates />
          <xsl:if test="string-length($ConcurrentDocumentPreview) &gt; 0  and string-length($TotalDocumentPreview) &gt; 0">
            <script type="text/javascript">
              function __loadDocPreviewWrap() {
              FST_StartDocPreviewFetch(<xsl:value-of select="$ConcurrentDocumentPreview"/>, <xsl:value-of select="$TotalDocumentPreview"/>);
              }
              function __loadDocPreview() {
              ExecuteOrDelayUntilScriptLoaded(__loadDocPreviewWrap, 'search.js');
              }
              _spBodyOnLoadFunctionNames.push('__loadDocPreview');
            </script>
          </xsl:if>
        </div>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:call-template name="DisplayMoreResultsAnchor" />
  </xsl:template>
  <!-- Has to be in as otherwise the xml is just dumped in the action webpart -->
  <xsl:template match="All_Results/SortList">
  </xsl:template>
  <!-- This template is called for each result -->
  <xsl:template match="TotalResults">
  </xsl:template>
  <xsl:template match="NumberOfResults">
  </xsl:template>
  <xsl:template match="Result">
    <xsl:variable name="id" select="id"/>
    <xsl:variable name="currentId" select="concat($IdPrefix,$id)"/>
    <xsl:variable name="url" select="url"/>
    <!--Allowed document preview extentions -->
    <xsl:variable name="DOCPreviewSupported" select="'-DOC-DOCX-DOCM-DOTM-DOTX-'"/>
    <xsl:variable name="PPTPreviewSupported" select="'-PPT-PPTX-PPTM-PPS-PPSM-'"/>
    <xsl:variable name="pptPreview" select="contains( $PPTPreviewSupported, concat('-',fileextension,'-'))"/>
    <xsl:variable name="docPreview" select="contains( $DOCPreviewSupported, concat('-',fileextension,'-'))"/>

    <div style="clear: both;">

      <xsl:choose>
        <xsl:when test="string-length(picturethumbnailurl) &gt; 0 and contentclass[. = 'STS_ListItem_PictureLibrary']">
          <div style=" padding-top: 2px; padding-bottom: 2px;">
            <div class="srch-picture1">
              <img src="/_layouts/images/imageresult_16x16.png" />
            </div>
            <div class="srch-picture2">
              <img class="srch-picture" src="{picturethumbnailurl}" alt="" />
            </div>
            <span>
              <ul class="srch-picturetext">
                <li class="srch-Title2 srch-Title5">
                  <a href="{$url}" id="{concat('CSR_',$id)}" title="{title}">
                    <xsl:choose>
                      <xsl:when test="hithighlightedproperties/HHTitle[. != '']">
                        <xsl:call-template name="HitHighlighting">
                          <xsl:with-param name="hh" select="hithighlightedproperties/HHTitle" />
                        </xsl:call-template>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="title"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </a>
                </li>

                <li>
                  <xsl:if test="string-length(picturewidth) &gt; 0 and string-length(pictureheight) &gt; 0">
                    <xsl:value-of select="$Size" />
                    <xsl:value-of select="picturewidth" />
                    <xsl:value-of select="$Multiply" />
                    <xsl:value-of select="pictureheight" />

                    <xsl:if test="string-length(size) &gt; 0">
                      <xsl:if test="number(size) &gt; 0">
                        <xsl:text disable-output-escaping="yes">&#8195;</xsl:text>
                        <xsl:choose>
                          <xsl:when test="round(size div 1024) &lt; 1">
                            <xsl:value-of select="size" /> Bytes
                          </xsl:when>
                          <xsl:when test="round(size div (1024 *1024)) &lt; 1">
                            <xsl:value-of select="round(size div 1024)" />KB
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:value-of select="round(size div (1024 * 1024))"/>MB
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:if>
                    </xsl:if>
                  </xsl:if>

                  <xsl:if test="string-length(datepicturetaken) &gt; 0">
                    <xsl:text disable-output-escaping="yes">&#8195;</xsl:text>
                    <xsl:value-of select="$PictureTaken" />
                    <xsl:value-of select="datepicturetaken" />
                  </xsl:if>

                  <xsl:if test="string-length(author) &gt; 0">
                    <xsl:text disable-output-escaping="yes">&#8195;</xsl:text>
                    <xsl:value-of select="$Authors" />
                    <xsl:value-of select="author" />
                  </xsl:if>

                  <xsl:if test="string-length(write) &gt; 0">
                    <xsl:text disable-output-escaping="yes">&#8195;</xsl:text>
                    <xsl:value-of select="$Date" />
                    <xsl:value-of select="write" />
                  </xsl:if>

                </li>

                <li>
                  <span class="srch-URL2" id="{concat($currentId,'_Url')}">
                    <xsl:choose>
                      <xsl:when test="hithighlightedproperties/HHUrl[. != '']">
                        <xsl:call-template name="HitHighlighting">
                          <xsl:with-param name="hh" select="hithighlightedproperties/HHUrl" />
                        </xsl:call-template>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="url"/>
                      </xsl:otherwise>
                    </xsl:choose>

                  </span>
                </li>
              </ul>
            </span>
          </div>
          <div class="srch-clear">
            <img alt="" src="/_layouts/images/blank.gif" />
          </div>
        </xsl:when>
        <xsl:otherwise>
          <div class="srch-Icon" id="{concat($currentId,'_Icon')}">
            <img align="absmiddle" src="{imageurl}" border="0" alt="{imageurl/@imageurldescription}" />
          </div>
          <div class="srch-Title2">
            <div class="srch-Title3">
              <a href="{$url}" id="{concat($currentId,'_Title')}" title="{title}">
                <xsl:choose>
                  <xsl:when test="hithighlightedproperties/HHTitle[. != '']">
                    <xsl:call-template name="HitHighlighting">
                      <xsl:with-param name="hh" select="hithighlightedproperties/HHTitle" />
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="title"/>
                  </xsl:otherwise>
                </xsl:choose>
              </a>
            </div>
          </div>

          <xsl:choose>
            <xsl:when test="$IsThisListScope = 'True' and contentclass[. = 'STS_ListItem_PictureLibrary'] and picturethumbnailurl[. != '']">
              <div style="padding-top: 2px; padding-bottom: 2px;">
                <a href="{$url}" id="{concat($currentId,'_P')}" title="{title}">
                  <img src="{picturethumbnailurl}" alt="" />
                </a>
              </div>
            </xsl:when>
          </xsl:choose>

          <!-- BEGIN preview elements -->
          <xsl:variable name="hasViewInBrowser" select="serverredirectedurl"></xsl:variable>

          <xsl:choose>
            <xsl:when  test="string-length($hasViewInBrowser) &gt; 0" >
              <xsl:choose>
                <xsl:when test="$EnableDocumentPreviewPowerPoint = 'true' and $pptPreview = true()">
                  <table class="srch-ext-detail-table-docpreview srch-ext-table" >
                    <tr>
                      <td class="src-ext-tablevaligntop">
                        <xsl:variable name="pptwidth" select="100" />
                        <xsl:variable name="pptclassName"  select="'srch-ext-previewIconPptImg'" />
                        <xsl:variable name="previewAvailable" select="true()" />
                        <xsl:call-template name="DisplayPreviewThumbnail">
                          <xsl:with-param name="width" select="$pptwidth" />
                          <xsl:with-param name="currentId" select="$currentId" />
                          <xsl:with-param name="className"  select="$pptclassName" />
                          <xsl:with-param name="isPreviewAvailable" select="$previewAvailable" />
                        </xsl:call-template>
                      </td>
                      <td class="src-ext-tablevaligntop">
                        <xsl:call-template name="ResultDetail">
                          <xsl:with-param name="currentId" select="$currentId" />
                          <xsl:with-param name="hasViewInBrowser" select="$hasViewInBrowser" />
                          <xsl:with-param name="docPreviewStyle" select="'srch-ext-docpreview'" />
                          <xsl:with-param name="previewBrowser" select="true()" />
                        </xsl:call-template>
                      </td>
                    </tr>
                  </table>
                  <xsl:call-template name="PreviewFetchAndBrowser">
                    <xsl:with-param name="currentId" select="$currentId" />
                    <xsl:with-param name="docPreview" select="false()" />
                    <xsl:with-param name="pptPreview" select="$pptPreview" />
                  </xsl:call-template>
                </xsl:when>
                <xsl:when test="$EnableDocumentPreviewWord = 'true' and $docPreview = true()">
                  <table class="srch-ext-detail-table-docpreview srch-ext-table" >
                    <tr>
                      <td class="src-ext-tablevaligntop">
                        <xsl:variable name="docwidth" select="80" />
                        <xsl:variable name="docclass" select="srch-ext-docicon" />
                        <xsl:variable name="docsrc" select="_layouts/images/icdocx.gif" />
                        <xsl:variable name="previewAvailable" select="false()" />
                        <xsl:variable name="pptclassName"  select="'srch-ext-previewIconDocImg'" />
                        <xsl:call-template name="DisplayPreviewThumbnail">
                          <xsl:with-param name="width" select="$docwidth" />
                          <xsl:with-param name="currentId" select="$currentId" />
                          <xsl:with-param name="className"  select="$pptclassName" />
                          <xsl:with-param name="isPreviewAvailable" select="$previewAvailable" />
                        </xsl:call-template>
                      </td>
                      <td class="src-ext-tablevaligntop">
                        <xsl:call-template name="ResultDetail">
                          <xsl:with-param name="currentId" select="$currentId" />
                          <xsl:with-param name="hasViewInBrowser" select="$hasViewInBrowser" />
                          <xsl:with-param name="docPreviewStyle" select="'srch-ext-docpreview'" />
                          <xsl:with-param name="previewBrowser" select="false()" />
                        </xsl:call-template>
                      </td>
                    </tr>
                  </table>
                  <xsl:call-template name="PreviewFetchAndBrowser">
                    <xsl:with-param name="currentId" select="$currentId" />
                    <xsl:with-param name="docPreview" select="$docPreview" />
                    <xsl:with-param name="pptPreview" select="false()" />
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:call-template name="ResultDetail">
                    <xsl:with-param name="currentId" select="$currentId" />
                    <xsl:with-param name="hasViewInBrowser" select="$hasViewInBrowser" />
                    <xsl:with-param name="previewBrowser" select="false()" />
                    <xsl:with-param name="docPreviewStyle" select="''" />
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="ResultDetail">
                <xsl:with-param name="currentId" select="$currentId" />
                <xsl:with-param name="hasViewInBrowser" select="$hasViewInBrowser" />
                <xsl:with-param name="previewBrowser" select="false()" />
                <xsl:with-param name="docPreviewStyle" select="''" />
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>

  <xsl:template name="ResultDetail">
    <xsl:param name="currentId" />
    <xsl:param name="hasViewInBrowser" />
    <xsl:param name="docPreviewStyle" />
    <xsl:param name="previewBrowser"/>

    <div id="{concat('DOC_DETAIL_',$currentId)}" >
      <div class="{$docPreviewStyle} srch-Description2">
        <xsl:choose>
          <xsl:when test="hithighlightedsummary[. != '']">
            <xsl:call-template name="HitHighlighting">
              <xsl:with-param name="hh" select="hithighlightedsummary" />
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="description[. != '']">
            <xsl:value-of select="description"/>
          </xsl:when>
          <xsl:otherwise>
            <img alt="" src="/_layouts/images/blank.gif" height="0" width="0"/>
          </xsl:otherwise>
        </xsl:choose>
      </div >

      <div class="{$docPreviewStyle} srch-Metadata2">
        <xsl:call-template name="DisplayAuthors">
          <xsl:with-param name="author" select="author" />
        </xsl:call-template>
        <xsl:call-template name="DisplayDate">
          <xsl:with-param name="write" select="write" />
        </xsl:call-template>
        <xsl:if test="string-length(popularsocialtag0) &gt; 0">
          <xsl:text disable-output-escaping="yes">&#8195;</xsl:text>
          <xsl:value-of select="$Tags" />
          <xsl:value-of select="popularsocialtag0"/>
          <xsl:if test="string-length(popularsocialtag1) &gt; 0">
            ::
            <xsl:value-of select="popularsocialtag1"/>
          </xsl:if>
          <xsl:if test="string-length(popularsocialtag2) &gt; 0">
            ::
            <xsl:value-of select="popularsocialtag2"/>
          </xsl:if>
          <xsl:if test="string-length(popularsocialtag3) &gt; 0">
            ::
            <xsl:value-of select="popularsocialtag3"/>
          </xsl:if>
          <xsl:if test="string-length(popularsocialtag4) &gt; 0">
            ::
            <xsl:value-of select="popularsocialtag4"/>
          </xsl:if>
        </xsl:if>
        <xsl:call-template name="DisplaySize">
          <xsl:with-param name="size" select="size" />
        </xsl:call-template>
        <img style="display:none;" alt="" src="/_layouts/images/blank.gif"/>
      </div>

      <div class="{$docPreviewStyle} srch-Metadata2" style="margin-bottom:20px;">
        <span class="srch-URL2" id="{concat($currentId,'_Url')}">

          <xsl:choose>
            <xsl:when test="hithighlightedproperties/HHUrl[. != '']">
              <xsl:call-template name="HitHighlighting">
                <xsl:with-param name="hh" select="hithighlightedproperties/HHUrl" />
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="url"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:call-template name="DisplayCollapsingStatusLink">
            <xsl:with-param name="status" select="collapsingstatus"/>
            <xsl:with-param name="urlEncoded" select="urlEncoded"/>
            <xsl:with-param name="id" select="concat($currentId,'_CS')"/>
          </xsl:call-template>
        </span>

        <!-- BEGIN Additinal links -->
        <xsl:variable name="fcocount" select="fcocount"/>
        <xsl:variable name="fcoid" select="fcoid"/>
        <xsl:if test="string-length($hasViewInBrowser) &gt; 0 or $EnableSimilarFind = 'true' or $fcocount &gt; 1">
          <br/>
        </xsl:if>
        <xsl:if test="string-length($hasViewInBrowser) &gt; 0">
          <xsl:if test="$EnableDocumentPreviewPowerPoint = 'true'  or $EnableDocumentPreviewWord = 'true'">
            <xsl:if test="$EnableDocumentPreviewPowerPoint = 'true'" >
              <xsl:if test="$previewBrowser">
                <a href="." class="srch-ext-previewLinks" style="display:none;"
                   id="{concat('FST_previewLink_',$currentId)}"
                   onclick=" FST_TogglePreviewWindow('{$currentId}'); return false;">
                  <xsl:value-of select="$OpenPreviewLink" />
                </a>
                <a href="." style="display:none;" id="{concat('FST_previewLinkClose_',$currentId)}" onclick="FST_TogglePreviewWindow('{$currentId}', '{urlEncoded}', '{fileextension}'); return false;">
                  <xsl:value-of select="$ClosePreviewLink" />
                </a>
                <span id="{concat('FST_linkSep_',$currentId)}" style="display:none;">
                  <xsl:text disable-output-escaping="yes">&amp;nbsp;|&amp;nbsp;</xsl:text>
                </span>
              </xsl:if>
            </xsl:if>
            <xsl:call-template name="ViewInBrowser">
              <xsl:with-param name="browserlink" select="serverredirectedurl" />
              <xsl:with-param name="currentId" select="$currentId" />
            </xsl:call-template>
          </xsl:if>
        </xsl:if>
        <xsl:if test="string-length($hasViewInBrowser) &gt; 0 and $EnableSimilarFind = 'true'">
          <span>
            <xsl:text disable-output-escaping="yes">&amp;nbsp;|&amp;nbsp;</xsl:text>
          </span>
        </xsl:if>
        <xsl:if test="$EnableSimilarFind = 'true'" >
          <xsl:variable name="Findpostfix" xml:space="default">
            &amp;similarto&#61;<xsl:value-of select="docvector"/>&amp;similartype&#61;find
          </xsl:variable>
          <xsl:text disable-output-escaping="yes">&lt;a href="</xsl:text>
          <xsl:value-of disable-output-escaping="yes" select="$SimilarFindBaseURL" />
          <xsl:value-of disable-output-escaping="yes" select="$Findpostfix" />
          <xsl:text disable-output-escaping="yes">"&gt;</xsl:text>
          <xsl:value-of select="$FindSimilarLinkText" />
          <xsl:text disable-output-escaping="yes">&lt;/a&gt;</xsl:text>
        </xsl:if>
        <xsl:if test="$fcocount &gt; 1">
          <xsl:if test="string-length($hasViewInBrowser) &gt; 0 or $EnableSimilarFind = 'true'">
            <span>
              <xsl:text disable-output-escaping="yes">&amp;nbsp;|&amp;nbsp;</xsl:text>
            </span>
          </xsl:if>
          <span>
            <xsl:variable name="DuplicatesPostfix" xml:space="default">
              &amp;dupid&#61;<xsl:value-of select="fcoid"/>
            </xsl:variable>
            <xsl:text disable-output-escaping="yes">&lt;a href="</xsl:text>
            <xsl:value-of disable-output-escaping="yes" select="$SimilarFindBaseURL" />
            <xsl:value-of disable-output-escaping="yes" select="$DuplicatesPostfix" />
            <xsl:text disable-output-escaping="yes">"&gt;</xsl:text>
            <xsl:value-of select="$DuplicatesLinkText" />
            <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
            <span class="srch-ext-duplicate-count">
              (<xsl:value-of select="$fcocount"/>)
            </span>
            <xsl:text disable-output-escaping="yes">&lt;/a&gt;</xsl:text>
          </span>
        </xsl:if>
        <xsl:call-template name="DisplayShowAll">
          <xsl:with-param name="currentId" select="$currentId" />
        </xsl:call-template>
        <!-- END Additional links -->
      </div>
    </div>

  </xsl:template>

  <xsl:template name="PreviewFetchAndBrowser">
    <xsl:param name="pptPreview" />
    <xsl:param name="docPreview" />
    <xsl:param name="currentId" />

    <xsl:choose>
      <xsl:when test="$docPreview">
        <xsl:if test="$EnableDocumentPreviewWord = 'true'" >
          <script type="text/javascript">
            function __<xsl:value-of select="$currentId"/>_checkPrevWrap() {
            FST_CheckForPreview('<xsl:value-of select="$currentId"/>', '<xsl:value-of disable-output-escaping="yes" select="serverredirectedurl"/>', '<xsl:value-of select="fileextension"/>', <xsl:value-of select="$PreviewWindowSize"/>, '<xsl:value-of select="sitename"/>', '<xsl:value-of select="$ThumbnailTooltip" />', '<xsl:value-of select="$ThumbnailTooltipLoadingFailed" />', '<xsl:value-of select="$AAMZone" />');
            }
            function __<xsl:value-of select="$currentId"/>_checkPrev() {
            ExecuteOrDelayUntilScriptLoaded(__<xsl:value-of select="$currentId"/>_checkPrevWrap, 'search.js');
            }
            _spBodyOnLoadFunctionNames.push('__<xsl:value-of select="$currentId"/>_checkPrev');
          </script>
        </xsl:if>
      </xsl:when>

      <xsl:when test="$pptPreview">
        <xsl:if test="$EnableDocumentPreviewPowerPoint = 'true'" >

          <div class="srch-ext-previewContainer" >
            <table class="srch-ext-table">
              <tr>
                <td class="src-ext-tablevaligntop srch-ext-doc-prev-btn">
                  <div style="width:24px;height:0px;"></div>
                  <div id="{concat('FST_leftArrow_',$currentId)}" onselectstart="return false"
                       onmousedown="FST_ScrollStart('{$currentId}', -10); return false;"
                       onmouseup="FST_ScrollStop('{$currentId}', -225); return false;"
                       onmouseout="FST_ScrollStop('{$currentId}', -225); return false;"
                       style="background: url(/_layouts/images/PreviewArrowLeft.png) no-repeat 50% 50%; height:{$PreviewWindowSize - 4}px;"
                       class="srch-ext-spanleft">
                    <img src="/_layouts/images/blank.gif"/>
                  </div>
                  <div id="{concat('FST_leftArrowDis_',$currentId)}"
                       onselectstart="return false"
                       class="srch-ext-spanleftdis"
                       style="display:none;background: url(/_layouts/images/PreviewArrowLeftDis.png) no-repeat 50% 50%; height:{$PreviewWindowSize - 4}px;">
                    <img src="/_layouts/images/blank.gif"/>
                  </div>
                </td>

                <td class="src-ext-tablevaligntop">
                  <div id="{concat('FST_previewWindow_',$currentId)}" class="srch-ext-previewWindow" style="margin-buttom:0px;" >
                    <div id="{concat('FST_previewDiv_',$currentId)}" class="srch-ext-previewDiv">
                      <span></span>
                    </div>
                  </div>
                </td>

                <td class="src-ext-tablevaligntop srch-ext-doc-prev-btn">
                  <div style="width:24px;height:0px;"></div>
                  <div id="{concat('FST_rightArrow_',$currentId)}"
                       onselectstart="return false"
                       onmousedown="FST_ScrollStart('{$currentId}', 10); return false;"
                       onmouseup="FST_ScrollStop('{$currentId}', 225); return false;"
                       onmouseout="FST_ScrollStop('{$currentId}', 225); return false;"
                       class="srch-ext-spanright"
                        style="display:none;background: url(/_layouts/images/PreviewArrowRight.png) no-repeat 50% 50%; height:{$PreviewWindowSize - 4}px;">
                    <img src="/_layouts/images/blank.gif"/>
                  </div>
                  <div id="{concat('FST_rightArrowDis_',$currentId)}" onselectstart="return false" class="srch-ext-spanrightdis"
                        style='display:none; background: url(/_layouts/images/PreviewArrowRightDis.png) no-repeat 50% 50%; left:-20px; height:{$PreviewWindowSize - 4}px;'>
                    <img src="/_layouts/images/blank.gif"/>
                  </div>
                </td>
                <script type="text/javascript">
                  function __<xsl:value-of select="$currentId"/>_checkPrevWrap() {
                  FST_CheckForPreview('<xsl:value-of select="$currentId"/>', '<xsl:value-of disable-output-escaping="yes" select="serverredirectedurl"/>', '<xsl:value-of select="fileextension"/>', <xsl:value-of select="$PreviewWindowSize"/>, '<xsl:value-of select="sitename"/>', '<xsl:value-of select="$ThumbnailTooltip" />', '<xsl:value-of select="$ThumbnailTooltipLoadingFailed" />', '<xsl:value-of select="$AAMZone" />');
                  }
                  function __<xsl:value-of select="$currentId"/>_checkPrev() {
                  ExecuteOrDelayUntilScriptLoaded(__<xsl:value-of select="$currentId"/>_checkPrevWrap, 'search.js');
                  }
                  _spBodyOnLoadFunctionNames.push('__<xsl:value-of select="$currentId"/>_checkPrev');
                </script>
              </tr>
            </table>
          </div>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="HitHighlighting">
    <xsl:param name="hh" />
    <xsl:apply-templates select="$hh"/>
  </xsl:template>

  <xsl:template match="ddd">
    &#8230;
  </xsl:template>
  <xsl:template match="c0">
    <strong>
      <xsl:value-of select="."/>
    </strong>
  </xsl:template>
  <xsl:template match="c1">
    <strong>
      <xsl:value-of select="."/>
    </strong>
  </xsl:template>
  <xsl:template match="c2">
    <strong>
      <xsl:value-of select="."/>
    </strong>
  </xsl:template>
  <xsl:template match="c3">
    <strong>
      <xsl:value-of select="."/>
    </strong>
  </xsl:template>
  <xsl:template match="c4">
    <strong>
      <xsl:value-of select="."/>
    </strong>
  </xsl:template>
  <xsl:template match="c5">
    <strong>
      <xsl:value-of select="."/>
    </strong>
  </xsl:template>
  <xsl:template match="c6">
    <strong>
      <xsl:value-of select="."/>
    </strong>
  </xsl:template>
  <xsl:template match="c7">
    <strong>
      <xsl:value-of select="."/>
    </strong>
  </xsl:template>
  <xsl:template match="c8">
    <strong>
      <xsl:value-of select="."/>
    </strong>
  </xsl:template>
  <xsl:template match="c9">
    <strong>
      <xsl:value-of select="."/>
    </strong>
  </xsl:template>

  <xsl:template name="DisplayAuthors">
    <xsl:param name="author" />
    <xsl:if test="string-length($author) &gt; 0">
      <xsl:value-of select="$Authors" />
      <xsl:value-of select="author"/>
    </xsl:if>
  </xsl:template>

  <xsl:template name="DisplayDate">
    <xsl:param name="write" />
    <xsl:if test="string-length($write) &gt; 0">
      <xsl:if test="string-length(author) &gt; 0">
        <xsl:text disable-output-escaping="yes">&#8195;</xsl:text>
      </xsl:if>
      <xsl:value-of select="$Date" />
      <xsl:value-of select="$write"/>
    </xsl:if>
  </xsl:template>

  <!-- The size attribute for each result is prepared here -->
  <xsl:template name="DisplaySize">
    <xsl:param name="size" />
    <xsl:if test="string-length($size) &gt; 0">
      <xsl:if test="number($size) &gt; 0">
        <xsl:if test="string-length(write) &gt; 0 or string-length(author) &gt; 0">
          <xsl:text disable-output-escaping="yes">&#8195;</xsl:text>
        </xsl:if>
        <xsl:value-of select="$Size" />
        <xsl:choose>
          <xsl:when test="round($size div 1024) &lt; 1">
            <xsl:value-of select="$size" /> Bytes
          </xsl:when>
          <xsl:when test="round($size div (1024 *1024)) &lt; 1">
            <xsl:value-of select="round($size div 1024)" />KB
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="round($size div (1024 * 1024))"/>MB
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template name="ViewInBrowser">
    <xsl:param name="browserlink" />
    <xsl:param name="currentId" />
    <xsl:if test="string-length($browserlink) &gt; 0">
      <a href="{concat($browserlink, $ViewInBrowserReturnUrl)}" id="{concat($currentId,'_VBlink')}">
        <xsl:value-of select="$ViewInBrowser" />
      </a>
    </xsl:if>
  </xsl:template>

  <!-- A generic template to display string with non 0 string length (used for author and write time -->
  <xsl:template name="DisplayString">
    <xsl:param name="str" />
    <xsl:if test='string-length($str) &gt; 0'>
      -
      <xsl:value-of select="$str" />
    </xsl:if>
  </xsl:template>

  <!-- document collapsing link setup -->
  <xsl:template name="DisplayCollapsingStatusLink">
    <xsl:param name="status"/>
    <xsl:param name="urlEncoded"/>
    <xsl:param name="id"/>
    <xsl:if test="$CollapsingStatusLink">
      <xsl:choose>
        <xsl:when test="$status=1">
          <xsl:variable name="CollapsingStatusHref" select="concat(substring-before($CollapsingStatusLink, '$$COLLAPSE_PARAM$$'), 'duplicates:&quot;', $urlEncoded, '&quot;', substring-after($CollapsingStatusLink, '$$COLLAPSE_PARAM$$'))"/>
          <a href="{$CollapsingStatusHref}" id="$id" title="{$CollapseDuplicatesText}">
            <xsl:value-of select="$CollapseDuplicatesText"/>
          </a>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <!-- The "view more results" for fixed query -->
  <xsl:template name="DisplayMoreResultsAnchor">
    <xsl:if test="$MoreResultsLink">
      <a href="{$MoreResultsLink}" id="{concat($IdPrefix,'_MRL')}">
        <xsl:value-of select="$MoreResultsText"/>
      </a>
    </xsl:if>
  </xsl:template>

  <xsl:template match="All_Results/DiscoveredDefinitions">
    <xsl:variable name="FoundIn" select="DDFoundIn" />
    <xsl:variable name="DDSearchTerm" select="DDSearchTerm" />
    <xsl:if test="$DisplayDiscoveredDefinition = 'True' and string-length($DDSearchTerm) &gt; 0">
      <script language="javascript">
        function ToggleDefinitionSelection()
        {
        var selection = document.getElementById("definitionSelection");
        if (selection.style.display == "none")
        {
        selection.style.display = "inline";
        }
        else
        {
        selection.style.display = "none";
        }
        }
      </script>
      <div class="srch-Description">
        <a href="javascript:ToggleDefinitionSelection();" id="{concat($IdPrefix,'1_DEF')}" mss_definition="true">
          <xsl:value-of select="$DefinitionIntro" />
          <strong>
            <xsl:value-of select="$DDSearchTerm"/>
          </strong>
        </a>
        <div id="definitionSelection" class="srch-Description2" style="display:none;">
          <xsl:for-each select="DDefinitions/DDefinition">
            <br/>
            <xsl:variable name="DDUrl" select="DDUrl" />
            <img alt="" src="/_layouts/images/discovered_definitions_bullet.png" />
            <xsl:value-of select="DDStart"/>
            <strong>
              <xsl:value-of select="DDBold"/>
            </strong>
            <xsl:value-of select="DDEnd"/>
            <br/>
            <span class="srch-definition">
              <xsl:value-of select="$FoundIn"/>
              <xsl:text disable-output-escaping="yes">&#160;</xsl:text>
              <a href="{$DDUrl}">
                <xsl:value-of select="DDTitle"/>
              </a>
            </span>
          </xsl:for-each>
        </div>
      </div>
    </xsl:if>
  </xsl:template>

  <!-- XSL transformation starts here -->
  <xsl:template match="/">
    <xsl:choose>
      <xsl:when test="$IsNoKeyword = 'True'" >
        <xsl:call-template name="dvt_1.noKeyword" />
      </xsl:when>
      <xsl:when test="$ShowMessage = 'True'">
        <xsl:call-template name="dvt_1.empty" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="dvt_1.body"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- credit to Thomas Svensen http://blogs.msdn.com/b/thomsven/archive/2011/01/26/seeing-what-actual-gets-indexed.aspx -->
  <xsl:template name="DisplayShowAll">
    <xsl:param name="currentId" />
    <br/>
    <!-- <a href="javascript:ToggleShowAll()" label="Show all"> -->
    <a href="{concat('javascript:ToggleShowAll(&quot;','ALL_FIELDS_',$currentId,'&quot;)')}" label="Show all">
      <xsl:text disable-output-escaping="yes">Show all</xsl:text>
      <xsl:text disable-output-escaping="yes">&#8195;</xsl:text>
      <br/>
    </a>

    <div id="{concat('ALL_FIELDS_',$currentId)}" class="" style="display:none;">
      <xsl:for-each select="*">
        <b>
          <xsl:value-of select="name()"/>
          <xsl:text>: </xsl:text>
        </b>
        <xsl:value-of disable-output-escaping="yes" select="."/>
        <br/>
      </xsl:for-each>
    </div>

  </xsl:template>

  <!-- End of Stylesheet -->
</xsl:stylesheet>
