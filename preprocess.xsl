<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="str"
    xmlns:prosody="http://www.prosody.org" xmlns:TEI="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.w3.org/1999/xhtml" version="1.0">

    <xsl:output indent="no" method="xml" omit-xml-declaration="yes"/>
    <xsl:strip-space elements="TEI:*"/>
    <xsl:preserve-space elements="seg"/>
    <xsl:variable name="scheme">
      <xsl:for-each select="//TEI:lg/@rhyme">
        <xsl:value-of select="."/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:template match="/">
			<xsl:if test="/TEI:TEI/TEI:text/TEI:body/TEI:lg[1]/@rhyme">
        <div id="rhyme" style="display:none;">
            <div id="rhymespacer"><xsl:text> </xsl:text></div>
            <form name="{$scheme}" id="rhymeform" autocomplete="off">
            <xsl:for-each select="/TEI:TEI/TEI:text/TEI:body/TEI:lg">
                <xsl:variable name="lgPos"><xsl:value-of select="position()"/></xsl:variable>
                <p><br/></p>
                <xsl:for-each select="TEI:l">
                    <div class="lrhyme">
                        <input size="1" maxlength="1" value="" name="lrhyme-{$lgPos}-{position()}" type="text" onFocus="this.value='';this.style['color'] = '#44FFFF';"/>
                    </div>
                </xsl:for-each>
            </xsl:for-each>
                <div class="lrhyme check"><input type="submit" value="&#x2713;" size="1" maxlength="1" id="rhymecheck"/></div>
            </form>
        </div>
        <div id="rhymebar">
            <xsl:text> </xsl:text>
        </div>
			</xsl:if>
        
        <!-- front matter -->
        <xsl:apply-templates select="/TEI:TEI/TEI:text/TEI:front"/>
        <!-- body -->
        
        <!-- header material -->
        <div id="poem">
            <div id="poemtitle">
                <h2>
                    <xsl:apply-templates
                        select="/TEI:TEI/TEI:teiHeader/TEI:fileDesc/TEI:titleStmt/TEI:title"/>
                    <xsl:apply-templates
                        select="/TEI:TEI/TEI:teiHeader/TEI:fileDesc/TEI:publicationStmt/TEI:date"/>
                </h2>
                <xsl:if test="/TEI:TEI/TEI:teiHeader/TEI:fileDesc/TEI:titleStmt/TEI:author">
                    <h4>
                        <xsl:apply-templates
                            select="/TEI:TEI/TEI:teiHeader/TEI:fileDesc/TEI:titleStmt/TEI:author"/>
                    </h4>
                </xsl:if>
            </div>
            <xsl:apply-templates select="TEI:TEI/TEI:text/TEI:body/*"/>
        </div>
				<xsl:if test="/TEI:TEI/TEI:text/TEI:body/TEI:lg[1]/@rhyme">
        	<div id="rhymeflag">Rhyme</div>
				</xsl:if>
        
        

        <!-- JQuery cleanup script -->
        <script type="text/javascript">
            jQuery(document).ready( function () {
              jQuery('span.tooltips').next('br:not(.tei-line-break)').remove();
            });
        </script>
    </xsl:template>

    <xsl:template match="TEI:space">
        <!-- <span class="space_{@quantity}" /> -->
    </xsl:template>

		<xsl:template match="TEI:date">
			<small class="date">
				<xsl:text>(</xsl:text>
					<xsl:value-of select="."/>
				<xsl:text>)</xsl:text>
			</small>
		</xsl:template>

    <xsl:template match="TEI:lg">
        <xsl:apply-templates select="TEI:space" />
        <xsl:for-each select="TEI:l">
            <xsl:apply-templates select=".">
                <xsl:with-param name="linegroupindex" select="position()"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>



    <xsl:template match="TEI:l">
        <xsl:param name="linegroupindex"/>
        <xsl:variable name="line-number" select="@n"/>
        <xsl:variable name="indent" select="@rend" />

        <div class="prosody-line {$indent}">
            <!-- first cycle through the segments, constructing shadow syllables -->
            

            <div class="TEI-l" id="prosody-real-{$line-number}">
<!--                 <xsl:if test="exists(TEI:space)"> -->
                    <xsl:apply-templates select="TEI:space" />
<!--                 </xsl:if> -->

                
                

                


                
                <xsl:apply-templates />
            </div>
            <div class="buttons">
                  <xsl:if test="TEI:note">
                    
                </xsl:if>
                
                
                
            </div>

        </div>
    </xsl:template>
    
    <!-- Matt's additions hereafter -->
    <xsl:template xml:space="default" match="/TEI:TEI/TEI:text/TEI:front">
        
        <div class="frontmatter">
            <xsl:apply-templates xml:space="default"/>
        </div>
    </xsl:template>
    
    <!-- bold text -->
    <xsl:template xml:space="default" match="TEI:hi[not(@corresp)][not(@id)][not(@rend='italic')]">
        <b><xsl:apply-templates/></b>
    </xsl:template>
    
    <!-- italics -->
    <xsl:template xml:space="default" match="TEI:hi[not(@corresp)][not(@id)][@rend='italic']">
        <i><xsl:apply-templates/></i>
    </xsl:template>
    
    <!-- build a Tool Tip from a matching ref/note element set -->
    <xsl:template match="TEI:hi[@target] | TEI:span[@target] | TEI:ref[@target]">
        <xsl:variable name="nodeId" select="current()/@target"/>
        <xsl:variable name="toolTipContent" select="//TEI:note[@target=$nodeId][1]"/>
        
        <xsl:element name="span">
          <xsl:attribute name="class">tooltips</xsl:attribute>
          <xsl:attribute name="title">
            <xsl:call-template name="createToolTipContent">
              <xsl:with-param name="node" select="$toolTipContent"></xsl:with-param>
            </xsl:call-template>
          </xsl:attribute>
          <xsl:choose>
            <xsl:when test="current()[@rend='italic']">
              <i><span style="color: #3366ff;"><xsl:apply-templates/></span></i>
            </xsl:when>
            <xsl:otherwise>
              <span style="color: #3366ff;"><xsl:apply-templates/></span>
            </xsl:otherwise>
          </xsl:choose> 
        </xsl:element>
        
    </xsl:template>
    
    <!-- this template copies text and links to media into a tooltip -->
    <xsl:template name="createToolTipContent">
        <xsl:param name="node"/>
        <xsl:for-each select="$node//TEI:media | $node//text()">
            <xsl:choose>
                <xsl:when test="local-name() = 'media'">
                    <xsl:variable name="mediaTag">&lt;img src=&quot;<xsl:value-of select="@url"/>&quot;/ &gt;</xsl:variable>
                    <xsl:text> </xsl:text><xsl:value-of select="normalize-space($mediaTag)"/><xsl:text> </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space(current())"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
	<xsl:template match="TEI:pb"><span style="color:#999999;" class="pagebreak">[page break]</span></xsl:template>
    
    <xsl:template match="TEI:note[@target]"></xsl:template>
    
    <!-- render media as images -->
    <xsl:template match="TEI:media">
        <xsl:element name="img">
            <xsl:attribute name="src"><xsl:value-of select="@url"/></xsl:attribute>
        </xsl:element>
    </xsl:template>
    
    <!-- render explicitly tagged line breaks -->
    <xsl:template match="TEI:lb">
        <br class="tei-line-break"/>
    </xsl:template>
    
    <!-- ignore line breaks not explicitly encoded as such -->
    <xsl:template match=
        "text()[not(string-length(normalize-space()))]"/>
    
    <xsl:template match=
        "text()[string-length(normalize-space()) > 0]">
        <xsl:value-of select="translate(.,'&#xA;&#xD;', '  ')"/>
    </xsl:template>
</xsl:stylesheet>
