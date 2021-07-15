<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">

    <!-- 
        This stylesheet originated as a main component of OSU Libraries Emerging Technologies 
        and Services' project to migrate the Oregon Library Association Quarterly journal from 
        Bepress Digital Commons to Open Journal Systems (OJS) version 3.1.4. 
        
        The stylesheet is yet untested on any other data set.
        
        
    -->

    <xsl:output method="xml" exclude-result-prefixes="#all" indent="yes"/>

    <xsl:variable name="url_home" select="'https://commons.pacificu.edu/'"/>
    
    <xsl:template match="/">
        <issues xmlns="http://pkp.sfu.ca" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://pkp.sfu.ca native.xsd">

            <xsl:for-each-group select="//row" group-by="vol_iss">
                <xsl:variable name="vol_iss"
                    select="replace(replace(replace(vol_iss,'\(','_'),'\)',''),'&amp;','-')"/>
                <xsl:result-document href="issues_output/{$vol_iss}.xml">
                    <issue xmlns="http://pkp.sfu.ca"
                        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                        xsi:schemaLocation="http://pkp.sfu.ca native.xsd" published="1">
                        <xsl:variable name="issue_record"
                            select="current-group()[document_type = 'full_issue']"/>
                        <id type="public" advice="update">
                            <xsl:value-of
                                select="replace(substring-after($issue_record/issue, 'olaq/'), '/', '_')"
                            />
                        </id>
                        <id type="internal" advice="ignore">
                            <xsl:value-of select="journal_id"/>
                        </id>
                        <id type="internal" advice="ignore">
                            <xsl:value-of select="$issue_record/olaq_id"/>
                        </id>
                        <id type="issn" advice="update">
                            <xsl:value-of select="issn"/>
                        </id>
                        <id type="doi" advice="update">
                            <xsl:value-of select="substring-after($issue_record/doi, '.org/')"/>
                        </id>
                        
                        <description>
                            <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
                            <xsl:for-each select="$issue_record/abstract_cdata/text()">
                                <xsl:text disable-output-escaping="yes">&lt;p&gt;&lt;strong&gt;Abstract:&lt;/strong&gt; </xsl:text>
                                <xsl:value-of select="substring-after(., '&lt;p&gt;'[1])"
                                    disable-output-escaping="yes"/>
                            </xsl:for-each>
                            
                            <xsl:if test="$issue_record/*[matches(name(), '_lname')][text()]">
                                <xsl:choose>
                                    <xsl:when test="$issue_record/editor2_lname/text()">
                                        <xsl:text disable-output-escaping="yes">&lt;p&gt;&lt;strong&gt;Guest Editors:&lt;/strong&gt; </xsl:text>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text disable-output-escaping="yes">&lt;p&gt;&lt;strong&gt;Guest Editor:&lt;/strong&gt; </xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:for-each
                                    select="$issue_record/*[matches(name(), '_lname')][text()]">
                                    <xsl:variable name="ednum"
                                        select="substring-before(name(), '_')"/>

                                    <xsl:value-of select="../*[name() = concat($ednum, '_fname')]"/>
                                    <xsl:for-each
                                        select="../*[name() = concat($ednum, '_mname')]/text()">
                                        <xsl:text> </xsl:text>
                                        <xsl:value-of select="."/>
                                    </xsl:for-each>
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of select="."/>
                                    <xsl:for-each
                                        select="../*[name() = concat($ednum, '_institution')]">
                                        <xsl:text>, </xsl:text>
                                        <xsl:value-of select="."/>
                                    </xsl:for-each>
                                    <xsl:if test="position() != last()">
                                        <xsl:text>; </xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                                <xsl:text disable-output-escaping="yes">&lt;/p&gt;</xsl:text>
                            </xsl:if>
                            
                            <xsl:for-each select="$issue_record/author1_bio_cdata//text()">
                                <xsl:text disable-output-escaping="yes">&lt;p&gt;&lt;strong&gt;Editor Biography:&lt;/strong&gt; </xsl:text>
                                <xsl:value-of select="substring-after(., '&lt;p&gt;'[1])"
                                    disable-output-escaping="yes"/>
                            </xsl:for-each>
                            <xsl:for-each select="$issue_record/keywords/text()">
                                <xsl:text disable-output-escaping="yes">&lt;p&gt;&lt;strong&gt;Keywords:&lt;/strong&gt; </xsl:text>
                                <xsl:value-of select="."/>
                                <xsl:text disable-output-escaping="yes">&lt;/p&gt;</xsl:text>
                            </xsl:for-each>
                            <xsl:for-each select="$issue_record/disciplines/text()">
                                <xsl:text disable-output-escaping="yes">&lt;p&gt;&lt;strong&gt;Disciplines:&lt;/strong&gt; </xsl:text>
                                <xsl:value-of select="."/>
                                <xsl:text disable-output-escaping="yes">&lt;/p&gt;</xsl:text>
                            </xsl:for-each>
                            <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
                        </description>
                        
                        <issue_identification>
                            <volume>
                                <xsl:value-of select="volnum"/>
                            </volume>
                            <number>
                                <xsl:value-of select="issnum"/>
                            </number>
                            <year>
                                <xsl:value-of select="substring(publication_date, 1, 4)"/>
                            </year>
                            <title>
                                <xsl:choose>
                                    <xsl:when
                                        test="not(starts-with($issue_record/title, 'Volume '))">
                                        <xsl:value-of select="$issue_record/title"/>
                                    </xsl:when>
                                    <xsl:when test="$issue_record/special_focus//text()">
                                        <xsl:value-of select="$issue_record/special_focus"/>
                                    </xsl:when>
                                </xsl:choose>
                            </title>
                        </issue_identification>
                        <date_published>
                            <xsl:choose>
                                <xsl:when test="string-length(publication_date) = 10">
                                    <xsl:value-of select="publication_date"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="vol_date"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </date_published>

                        <sections>
                            <xsl:if test="current-group()[document_type = 'table_of_contents']">
                                <section ref="TOC" seq="1">
                                    <abbrev locale="en_US">TOC</abbrev>
                                    <title locale="en_US">Table of Contents</title>
                                </section>
                            </xsl:if>
                            <xsl:if test="current-group()[document_type = 'introduction']">
                                <section ref="INT" seq="2">
                                    <abbrev locale="en_US">INT</abbrev>
                                    <title locale="en_US">Introduction</title>
                                </section>
                            </xsl:if>
                            <section ref="ART" seq="3">
                                <abbrev locale="en_US">ART</abbrev>
                                <title locale="en_US">Articles</title>
                            </section>
                            <xsl:if test="current-group()[document_type = 'back_matter']">
                                <section ref="BACK" seq="4">
                                    <abbrev locale="en_US">BACK</abbrev>
                                    <title locale="en_US">Back Matter</title>
                                </section>
                            </xsl:if>
                        </sections>

                        <articles>
                            <xsl:for-each select="current-group()[document_type != 'full_issue']">
                                <xsl:variable name="section">
                                    <xsl:choose>
                                        <xsl:when test="document_type = 'article'">
                                            <xsl:value-of select="'ART'"/>
                                        </xsl:when>
                                        <xsl:when test="document_type = 'table_of_contents'">
                                            <xsl:value-of select="'TOC'"/>
                                        </xsl:when>
                                        <xsl:when test="document_type = 'introduction'">
                                            <xsl:value-of select="'INT'"/>
                                        </xsl:when>
                                        <xsl:when test="document_type = 'back_matter'">
                                            <xsl:value-of select="'BACK'"/>
                                        </xsl:when>
                                    </xsl:choose>
                                </xsl:variable>
                                <xsl:element name="article">
                                    <xsl:attribute name="date_published">
                                        <xsl:choose>
                                            <xsl:when test="string-length(publication_date) = 10">
                                                <xsl:value-of select="publication_date"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="vol_date"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:attribute>
                                    <xsl:attribute name="section_ref" select="$section"/>
                                    <xsl:attribute name="stage" select="'production'"/>

                                    <id type="doi" advice="update">
                                        <xsl:value-of select="substring-after(doi, '.org/')"/>
                                    </id>
                                    <id type="public" advice="update">
                                        <xsl:value-of
                                            select="replace(substring-after(calc_url, 'olaq/'), '/', '_')"
                                        />
                                    </id>
                                    <id type="internal" advice="ignore">
                                        <xsl:value-of select="olaq_id"/>
                                    </id>
                                    <title>
                                        <xsl:value-of select="title"/>
                                    </title>
                                    <!-- wrap contents of abstract field in CDATA tags to keep original HTML formatting -->
                                    <xsl:for-each select="abstract_cdata/text()">
                                        <abstract>
                                            <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
                                            <xsl:value-of select="." disable-output-escaping="yes"/>
                                            <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
                                        </abstract>
                                    </xsl:for-each>
                                    <!-- Split rights data in "© YYYY Name" pattern into copyright year and copyright holder fields -->
                                    <xsl:variable name="rights" select="rights"/>
                                    <xsl:analyze-string select="$rights" regex=".\s(\d{{4}})\s(.*)">
                                        <xsl:matching-substring>
                                            <copyrightHolder>
                                                <xsl:value-of select="regex-group(2)"/>
                                            </copyrightHolder>
                                            <copyrightYear>
                                                <xsl:value-of select="regex-group(1)"/>
                                            </copyrightYear>
                                        </xsl:matching-substring>
                                    </xsl:analyze-string>

                                    <!-- Split keywords into separate elements using comma-space delimiter pattern -->
                                    <xsl:if test="keywords/text()">
                                        <keywords>
                                            <xsl:for-each select="tokenize(keywords, ', ')">
                                                <keyword>
                                                  <xsl:value-of select="."/>
                                                </keyword>
                                            </xsl:for-each>
                                        </keywords>
                                    </xsl:if>

                                    <!-- Split disciplines into separate elements using semicolon-space delimiter pattern -->
                                    <xsl:if test="disciplines/text()">
                                        <disciplines>
                                            <xsl:for-each select="tokenize(disciplines, '; ')">
                                                <discipline>
                                                  <xsl:value-of select="."/>
                                                </discipline>
                                            </xsl:for-each>
                                        </disciplines>
                                    </xsl:if>

                                    <xsl:choose>
                                        <xsl:when test="*[matches(name(), '_lname')][text()]">
                                            <authors>
                                                <xsl:for-each
                                                  select="*[matches(name(), '_lname')][text()]">
                                                  <xsl:variable name="authnum"
                                                  select="substring-before(name(), '_')"/>
                                                  <xsl:call-template name="author">
                                                  <xsl:with-param name="authnum" select="$authnum"/>
                                                  </xsl:call-template>
                                                </xsl:for-each>
                                            </authors>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <!-- If there are no authors in metadata, insert default author info: 
                                            because without authors, the pages field fails validation -->
                                            <authors>
                                                <author user_group_ref="Author">
                                                  <givenname>Oregon Library</givenname>
                                                  <familyname>Association</familyname>
                                                  <affiliation>OLA</affiliation>
                                                  <email/>
                                                </author>
                                            </authors>
                                        </xsl:otherwise>
                                    </xsl:choose>

                                    <xsl:variable name="submission_id" select="olaq_id"/>
                                    <submission_file id="{$submission_id}" stage="public">
                                        <xsl:element name="revision">
                                            <xsl:attribute name="number" select="'1'"/>
                                            <xsl:attribute name="genre" select="'Article Text'"/>
                                            <xsl:attribute name="filename" select="pdf_filename"/>
                                            <xsl:attribute name="viewable" select="'true'"/>
                                            <xsl:attribute name="date_uploaded"
                                                select="current-date()"/>
                                            <xsl:attribute name="date_modified"
                                                select="current-date()"/>
                                            <xsl:attribute name="filesize" select="'100000'"/>
                                            <xsl:attribute name="filetype"
                                                select="'application/pdf'"/>
                                            <name>
                                                <xsl:value-of select="title"/>
                                            </name>
                                            <xsl:element name="href">
                                                <xsl:attribute name="src">
                                                  <xsl:value-of select="pdf_url"/>
                                                </xsl:attribute>
                                            </xsl:element>
                                        </xsl:element>
                                    </submission_file>

                                    <xsl:element name="article_galley">
                                        <xsl:attribute name="approved" select="'true'"/>
                                        <xsl:attribute name="galley_type"
                                            select="'pdfarticlegalleyplugin'"/>
                                        <id type="public" advice="update">
                                            <xsl:value-of select="olaq_id"/>
                                        </id>
                                        <name>
                                            <xsl:text>PDF</xsl:text>
                                        </name>
                                        <seq>
                                            <xsl:text>0</xsl:text>
                                        </seq>
                                        <submission_file_ref id="{$submission_id}" revision="1"/>
                                    </xsl:element>

                                    <pages>
                                        <xsl:value-of select="fpage"/>
                                        <xsl:if test="lpage/text()">
                                            <xsl:value-of select="concat('-', lpage)"/>
                                        </xsl:if>
                                    </pages>

                                </xsl:element>
                            </xsl:for-each>
                        </articles>
                    </issue>
                </xsl:result-document>
            </xsl:for-each-group>


        </issues>
    </xsl:template>

    <xsl:template name="author">
        <xsl:param name="authnum" select="''"/>

        <xsl:element name="author" xmlns="http://pkp.sfu.ca">
            <xsl:choose>
                    <xsl:when test="$authnum='author1'">
                        <xsl:attribute name="primary_contact" select="'true'"/>
                    </xsl:when>
                    <xsl:otherwise/>
                </xsl:choose>
            <xsl:attribute name="include_in_browse">true</xsl:attribute>
            <xsl:attribute name="user_group_ref">Author</xsl:attribute>
            
            <givenname>
                <xsl:value-of select="../*[name() = concat($authnum, '_fname')]"/>
                <xsl:for-each select="../*[name() = concat($authnum, '_mname')]/text()">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="."/>
                </xsl:for-each>
            </givenname>
            <familyname>
                <xsl:value-of select="."/>
            </familyname>
            <affiliation>
                <xsl:value-of select="../*[name() = concat($authnum, '_institution')]"/>
            </affiliation>
            <email>
                <xsl:value-of select="../*[name() = concat($authnum, '_email')]"/>
            </email>
            
            <!-- wrap biograpy in cdata tags to preserve original HTML formatting -->
            <xsl:for-each select="../*[name() = concat($authnum, '_bio_cdata')]//text()">
                <biography>
                    <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
                    <xsl:value-of select="." disable-output-escaping="yes"/>
                    <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
                </biography>
            </xsl:for-each>
            
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>