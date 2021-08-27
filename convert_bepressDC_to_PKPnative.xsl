<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">

    <!-- 
        
        This stylesheet originated as a main component of OSU Libraries Emerging Technologies 
        and Services' project to migrate the Oregon Library Association Quarterly journal from 
        Bepress Digital Commons to Open Journal Systems (OJS) version 3.1.4. 
        
        The stylesheet is yet untested on any other data set.
        
        Expected input is flat XML generated from CSV of Bepress data for one or more journal issues.
        Output is one XML file per journal issue, saved to an "import_files" directory.

        Variables depend on values added in the local_data.xml configuration file.
        
    -->

    <xsl:output method="xml" exclude-result-prefixes="#all" indent="yes"/>
    
    <!-- Enable lookup of local data values in local_data.xml config file -->
    <xsl:variable name="local_data" select="document('local_data.xml')/local_data"/>
   
    <xsl:template match="/">

        <!-- Group records by journal issue using 'issue' field value (journal ID plus volume plus issue) -->
        <xsl:for-each-group select="//row" group-by="issue">

            <!-- Create one output XML file per journal issue, with filename from 'issue' field;
                 @published="1" causes the issue to be published automatically upon import -->
            <xsl:result-document href="import_files/{replace(issue,'/','_')}.xml">
                <issue xmlns="http://pkp.sfu.ca"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:schemaLocation="http://pkp.sfu.ca native.xsd" 
                    published="1">

                    <!-- Identify the issue-level record for building the issue description -->
                    <xsl:variable name="issue_record"
                        select="current-group()[document_type = $local_data/issue_doctype]"/>

                    <!-- Derive issue ID from 'issue' field -->
                    <id type="public" advice="update">
                        <xsl:value-of
                            select="replace(substring-after($issue_record/issue, '/'[1]), '/', '_')"
                        />
                    </id>

                    <!-- Copy DOI, omitting doi.org address component if included -->
                    <id type="doi" advice="update">
                        <xsl:choose>
                            <xsl:when test="contains($issue_record/doi, '.org/')">
                                <xsl:value-of select="substring-after($issue_record/doi, '.org/')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$issue_record/doi"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </id>
                    
                    <!-- Compose issue Description from Abstract, Editor, Keywords, and Disciplines fields.
                             Insert HTML markup for readability.
                         User may remove or comment out unwanted portions of the Description.
                    -->
                    <description>
                        <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
                        
                        <!-- If the issue record has an abstract:
                             - Add bold "Abstract: " heading;
                             - If abstract_cdata has been added to source data, copy abstract_cdata (after opening paragraph tag) to keep original HTML formatting; 
                             - Otherwise, copy abstract and add closing HTML paragraph tag (pairs with opening p tag with header).
                        -->
                        <xsl:if
                            test="$issue_record/abstract/text() or $issue_record/abstract_cdata/text()">
                            <xsl:text disable-output-escaping="yes">&lt;p&gt;&lt;strong&gt;Abstract:&lt;/strong&gt;</xsl:text>
                            <xsl:choose>
                                <xsl:when test="abstract_cdata/text()">
                                    <xsl:value-of
                                        select="substring-after(abstract_cdata, '&lt;p&gt;'[1])"
                                        disable-output-escaping="yes"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="abstract"/>
                                    <xsl:text>&lt;/p&gt;</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                        
                        
                        <!-- If the issue record has one or more values in the author field, treat these as editors:
                             - Add bold "Editor: " or "Editors: " heading depending on presence of author2 name;
                             - Add the name and institution, if present, for each editor (author) value
                             - Place a semicolon delimiter between names
                        -->
                        <xsl:if test="$issue_record/*[matches(name(), '_lname')][text()]">
                            <xsl:text disable-output-escaping="yes">&lt;p&gt;&lt;strong&gt;Editor</xsl:text>
                            <xsl:if test="$issue_record/author2_lname/text()">
                                <xsl:text>s</xsl:text>
                            </xsl:if>
                            <xsl:text disable-output-escaping="yes">:&lt;/strong&gt; </xsl:text>
                            
                            <xsl:for-each
                                select="$issue_record/*[matches(name(), '_lname')][text()]">
                                <xsl:variable name="ednum" select="substring-before(name(), '_')"/>

                                <xsl:value-of select="../*[name() = concat($ednum, '_fname')]"/>
                                <xsl:for-each
                                    select="../*[name() = concat($ednum, '_mname')]/text()">
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of select="."/>
                                </xsl:for-each>
                                <xsl:text> </xsl:text>
                                <xsl:value-of select="."/>
                                <xsl:for-each select="../*[name() = concat($ednum, '_institution')]/text()">
                                    <xsl:text>, </xsl:text>
                                    <xsl:value-of select="."/>
                                </xsl:for-each>
                                <xsl:if test="position() != last()">
                                    <xsl:text>; </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:text disable-output-escaping="yes">&lt;/p&gt;</xsl:text>
                        </xsl:if>

                        <!-- If the issue record has one or more author bio fields, with or without an author name value,
                            treat those as Editor Biographies; 
                            - Add bold "Editor Biography: " heading
                            - If author_bio_cdata has been added to the source data, copy each (after the first paragraph tag) as a separate paragraph;
                            - Otherwise, copy each author_bio as a separate paragraph
                        -->
                        <xsl:if test="$issue_record/*[matches(name(), '_bio')][text()]">
                            <xsl:text disable-output-escaping="yes">&lt;p&gt;&lt;strong&gt;Editor Biography:&lt;/strong&gt; </xsl:text>
                            <xsl:for-each select="$issue_record/*[matches(name(), '_bio')][text()]">
                                <xsl:variable name="ednum" select="substring-before(name(), '_')"/>
                                <xsl:choose>
                                    <xsl:when test="../*[name() = concat($ednum, '_bio_cdata')]//text()">
                                        <xsl:value-of
                                            select="substring-after(../*[name() = concat($ednum, '_bio_cdata')], '&lt;p&gt;'[1])"
                                            disable-output-escaping="yes"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="."/>
                                        <xsl:text disable-output-escaping="yes">&lt;/p&gt;</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:if test="position() != last()">
                                    <xsl:text disable-output-escaping="yes">&lt;p&gt;</xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:if>

                        <!-- Add Keywords from the issue-level record to the Issue Description,
                                 as a new paragraph prefaced by "Keywords: " heading -->
                        <xsl:for-each select="$issue_record/keywords/text()">
                            <xsl:text disable-output-escaping="yes">&lt;p&gt;&lt;strong&gt;Keywords:&lt;/strong&gt; </xsl:text>
                            <xsl:value-of select="."/>
                            <xsl:text disable-output-escaping="yes">&lt;/p&gt;</xsl:text>
                        </xsl:for-each>

                        <!-- Add Disciplines from the issue-level record to the Issue Description,
                                 as a new paragraph prefaced by "Disciplines: " heading -->
                        <xsl:for-each select="$issue_record/disciplines/text()">
                            <xsl:text disable-output-escaping="yes">&lt;p&gt;&lt;strong&gt;Disciplines:&lt;/strong&gt; </xsl:text>
                            <xsl:value-of select="."/>
                            <xsl:text disable-output-escaping="yes">&lt;/p&gt;</xsl:text>
                        </xsl:for-each>

                        <!-- Close CDATA wrapper to complete Issue Description -->
                        <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
                    </description>

                    <issue_identification>
                        <!-- Copy volume number -->
                        <volume>
                            <xsl:value-of select="$issue_record/volnum"/>
                        </volume>
                        <!-- Copy issue number -->
                        <number>
                            <xsl:value-of select="$issue_record/issnum"/>
                        </number>
                        <!-- Parse issue year from first four characters of Publication Date -->
                        <year>
                            <xsl:value-of select="substring($issue_record/publication_date, 1, 4)"/>
                        </year>
                        <!-- Copy issue title -->
                        <title>
                            <xsl:value-of select="$issue_record/title"/>
                        </title>
                    </issue_identification>

                    <!-- Copy issue publication date; 
                         Date must be in YYYY-MM-DD format to import successfully! -->
                    <date_published>
                        <xsl:value-of select="publication_date"/>
                    </date_published>

                    <!-- Create sections based on document types; 
                         Configure values in local_data.xml helper file -->
                    <sections>
                        <xsl:for-each select="$local_data/section">
                            <section ref="{abbreviation}" seq="{sequence_number}">
                                <abbrev locale="{locale}">
                                    <xsl:value-of select="abbreviation"/>
                                </abbrev>
                                <title locale="{locale}">
                                    <xsl:value-of select="title"/>
                                </title>
                            </section>
                        </xsl:for-each>
                    </sections>

                    <articles>
                        <!-- Create an article object for each non-issue record -->
                        <xsl:for-each
                            select="current-group()[document_type != $local_data/issue_doctype]">
                            <xsl:element name="article">
                                
                                <!-- Copy publication date;
                                     Date must be in YYYY-MM-DD format to import successfully! -->
                                <xsl:attribute name="date_published">
                                    <xsl:value-of select="publication_date"/>
                                </xsl:attribute>
                                
                                <!-- Pull the appropriate section abbreviation from the local_data helper file
                                     and insert as section reference -->
                                <xsl:variable name="doctype" select="document_type"/>
                                <xsl:variable name="section"
                                    select="$local_data/section[document_type = $doctype]/abbreviation"/>
                                <xsl:attribute name="section_ref" select="$section"/>
                                
                                <!-- Set @stage value to "production" for all items by default -->
                                <xsl:attribute name="stage" select="'production'"/>

                                <!-- Copy DOI, omitting doi.org address component if included -->
                                <id type="doi" advice="update">
                                    <xsl:choose>
                                        <xsl:when test="contains(doi, '.org/')">
                                            <xsl:value-of select="substring-after(doi, '.org/')"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="doi"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </id>

                                <!-- Derive article ID from 'calc_url' field -->
                                <id type="public" advice="update">
                                    <xsl:value-of
                                        select="replace(substring-after(calc_url, concat(journal_id,'/')), '/', '_')"
                                    />
                                </id>
                                
                                <!-- Copy article title -->
                                <title>
                                    <xsl:value-of select="title"/>
                                </title>
                                
                                <!-- Either copy abstract, or, if abstract_cdata has been added to source data,
                                     wrap contents of abstract field in CDATA tags to keep original HTML formatting -->
                                <abstract>
                                    <xsl:choose>
                                        <xsl:when test="abstract_cdata/text()">
                                            <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
                                            <xsl:value-of select="abstract_cdata/text()"
                                                disable-output-escaping="yes"/>
                                            <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="abstract"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </abstract>
                                
                                <!-- Copy distribution license URL -->
                                <xsl:if test="distribution_license[contains(text(),'http')][not(contains(text(),' '))]">
                                    <licenseUrl>
                                        <xsl:value-of select="distribution_license"/>
                                    </licenseUrl>
                                </xsl:if>
                                
                                <!-- Split rights data in "© YYYY Name" pattern into copyright year and copyright holder fields -->
                                <xsl:variable name="rights" select="rights"/>
                                <xsl:analyze-string select="$rights" regex=".\s(\d{{4}})\s(.*)">
                                    <xsl:matching-substring>
                                        <copyrightHolder>
                                            <xsl:value-of select="normalize-space(regex-group(2))"/>
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

                                <!-- Create authors section:
                                     If one or more authors are present, call template below for each numbered author -->
                                <xsl:choose>
                                    <xsl:when test="*[matches(name(), '_lname')][text()]">
                                        <authors>
                                            <xsl:for-each
                                                select="*[matches(name(), '_lname')][text()]">
                                                <!-- "authnum" variable groups data for each author, author1, author2, etc -->
                                                <xsl:variable name="authnum"
                                                  select="substring-before(name(), '_')"/>
                                                <xsl:call-template name="author">
                                                  <xsl:with-param name="authnum" select="$authnum"/>
                                                </xsl:call-template>
                                            </xsl:for-each>
                                        </authors>
                                    </xsl:when>
                                    
                                    <xsl:otherwise>
                                        <!-- If there are no authors in source data, fill in a 
                                             default author value set from local_data.xml helper file.
                                             OJS requires at least one author for each article -->
                                        <authors>
                                            <author user_group_ref="Author">
                                                <givenname>
                                                    <xsl:value-of select="$local_data/default_author/givenname"/>
                                                </givenname>
                                                <familyname>
                                                    <xsl:value-of select="$local_data/default_author/familyname"/>
                                                </familyname>
                                                <affiliation>
                                                    <xsl:value-of select="$local_data/default_author/affiliation"/>
                                                </affiliation>
                                                <email>
                                                    <xsl:value-of select="$local_data/default_author/email"/>
                                                </email>
                                            </author>
                                        </authors>
                                    </xsl:otherwise>
                                </xsl:choose>
                                
                                <!-- Parse submission ID from PDF URL based on expected pattern -->
                                <xsl:variable name="submission_id" select="substring-before(substring-after(fulltext_url,'article='),'&amp;context=')"/>
                                
                                <!-- Create Submission File element and supply values for required attributes, mostly default values. 
                                     Dates and Filesize will be automatically replaced with accurate values in OJS.
                                     (Ignore import warning about filesize mismatch.)
                                     Note: Assumes PDF submission files! -->
                                <submission_file id="{$submission_id}" stage="public">
                                    <xsl:element name="revision">
                                        <xsl:attribute name="number" select="'1'"/>
                                        <xsl:attribute name="genre" select="'Article Text'"/>
                                        <xsl:attribute name="filename" select="filename"/>
                                        <xsl:attribute name="viewable" select="'true'"/>
                                        <xsl:attribute name="date_uploaded" select="current-date()"/>
                                        <xsl:attribute name="date_modified" select="current-date()"/>
                                        <xsl:attribute name="filesize" select="'100000'"/>
                                        <xsl:attribute name="filetype" select="'application/pdf'"/>
                                        <name>
                                            <xsl:value-of select="title"/>
                                        </name>

                                        <!-- Copy fulltext URL to fetch PDF from remote source on import -->
                                        <xsl:element name="href">
                                            <xsl:attribute name="src">
                                                <xsl:value-of select="fulltext_url"/>
                                            </xsl:attribute>
                                        </xsl:element>
                                    </xsl:element>
                                </submission_file>

                                <!-- Create Article Galley element and fill in default values and references to Submission File. 
                                     Note: Assumes PDF submission files! -->
                                <xsl:element name="article_galley">
                                    <xsl:attribute name="approved" select="'true'"/>
                                    <xsl:attribute name="galley_type"
                                        select="'pdfarticlegalleyplugin'"/>
                                    <id type="public" advice="update">
                                        <xsl:value-of select="$submission_id"/>
                                    </id>
                                    <name>
                                        <xsl:text>PDF</xsl:text>
                                    </name>
                                    <seq>
                                        <xsl:text>0</xsl:text>
                                    </seq>
                                    <submission_file_ref id="{$submission_id}" revision="1"/>
                                </xsl:element>

                                <!-- Copy page number(s)s -->
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
    </xsl:template>

    <!-- Template to fill in author metadata -->
    <xsl:template name="author">
        <xsl:param name="authnum" select="''"/>

        <!-- Create an 'author' element for each author number -->
        <xsl:element name="author" xmlns="http://pkp.sfu.ca">

            <!-- Assign author1 as the primary contact, and set other attributes with default values -->
            <xsl:choose>
                <xsl:when test="$authnum = 'author1'">
                    <xsl:attribute name="primary_contact" select="'true'"/>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
            <xsl:attribute name="include_in_browse">true</xsl:attribute>
            <xsl:attribute name="user_group_ref">Author</xsl:attribute>

            <!-- Concatenate fname and mname values as givenname -->
            <givenname>
                <xsl:value-of select="../*[name() = concat($authnum, '_fname')]"/>
                <xsl:for-each select="../*[name() = concat($authnum, '_mname')]/text()">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="."/>
                </xsl:for-each>
            </givenname>

            <!-- Copy lname to familyname -->
            <familyname>
                <xsl:value-of select="."/>
            </familyname>

            <!-- Copy institution to affiliation -->
            <affiliation>
                <xsl:value-of select="../*[name() = concat($authnum, '_institution')]"/>
            </affiliation>

            <!-- Copy email -->
            <email>
                <xsl:value-of select="../*[name() = concat($authnum, '_email')]"/>
            </email>

            <!-- Check for author bio; either copy author bio, or, if authorX_bio_cdata has been added to source data,
            wrap contents of author bio field in CDATA tags to keep original HTML formatting -->
            <xsl:if test="../*[contains(name(), concat($authnum, '_bio'))]//text()">
                <biography>
                    <xsl:choose>
                        <xsl:when test="../*[name() = concat($authnum, '_bio_cdata')]//text()">
                            <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
                            <xsl:value-of
                                select="../*[name() = concat($authnum, '_bio_cdata')]//text()"
                                disable-output-escaping="yes"/>
                            <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="../*[name() = concat($authnum, '_bio')]"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </biography>
            </xsl:if>

        </xsl:element>
    </xsl:template>

</xsl:stylesheet>