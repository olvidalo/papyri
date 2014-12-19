<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0" version="2.0">
    <xsl:param name="invnr"/>
    
    <!-- copy all, but... -->
    <xsl:template match="node() | @* | processing-instruction() | comment()">
        <xsl:copy>
            <xsl:apply-templates select="node() | @* | processing-instruction() | comment()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="TEI">
        <xsl:copy>
            <xsl:copy-of select="@xmlns | @sameAs"/>
            <xsl:attribute name="xml:id">
                <xsl:value-of select="concat(@xml:id, $invnr)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="msDesc">
        <xsl:copy>
            <xsl:attribute name="xml:id">
                <xsl:value-of select="concat(@xml:id, $invnr)"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>