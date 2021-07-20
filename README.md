# XSLT Migration from bepress Digital Commons to OJS 3.X

Contains tools for migrating journal metadata and content from Bepress Digital Commons to Open Journal Systems (OJS) 3.x

Oregon State University Libraries and Press (OSULP) developed this toolkit to migrate the _OLA Quarterly_ journal to OJS 3.1.4 in early 2020. 

Upcoming work:

* generify the XSL for 3.1 (i.e. replace all OSU- and OLAQ-specific shortcuts)
* documentation/user guide/readme development
* stretch goal = modify for more recent OJS releases

## Usage

Note that this is a somewhat hands-on process. If you're using this toolset, it's because you would rather do the cleanup work before your journal data gets into OJS, rather than afterward. (If you prefer to do it afterward, other tools are out there.)

### Mapping

This table shows the fields included in the original use case's metadata export from Digital Commons and the destination OJS 3.1 fields to which they are mapped. Objects with document type “full_issue” became OJS Issues, and all other document types were migrated as OJS Submissions.

| Bepress Field | OJS XPath - Submissions |	OJS XPath - Issues | Notes |
| ----- | ----- | ----- | ----- |
| title | article/title | issue/issue_identification/title | |
| keywords | article/keywords | issue/description | |
| disciplines | article/disciplines | issue/description | |
| document_type | article/@section_ref | _na_ | a specified document_type designates an OJS Issue; this can be updated in the local_data.xml file |
| doi | article/id[@type="doi"] | issue/id[@type="doi"] | OJS DOI Plugin must be enabled before importing, otherwise DOI is not saved upon import | 
| volnum | _na_ | issue/issue_identification/volume | | 
| issnum | _na_	| issue/issue_identification/number | | 
| fpage | article/pages	| _na_ | concatenated with `lpage` value |
| lpage | article/pages	| _na_ | concatenated with `fpage` value |
| distribution_license	| _na_ | _na_ | field included but blank in original dataset |
| abstract | article/abstract | issue/description | |
| comments | article/authors/author/biography | _na_ | field was used for author bios in original dataset |
| fulltext_url | | | field included but blank in original dataset - values added during cleanup |
| peer_reviewed	| _na_ | _na_ | no appropriate mapping destination |
| publication_date | article/@date_published | issue/date_published issue/issue_identification/year | required; must be in YYYY-MM-DD format |
| rights | article/copyrightYear article/copyrightHolder | _na_ | XSLT expects "© YYYY Name" pattern |
| license_statement | _na_ | _na_ | field included but blank in original dataset |
| filename | _na_ | _na_ |  |
| erratum | _na_ | _na_ | no appropriate mapping destination |	
| publisher | _na_ | _na_ | no appropriate mapping destination; data is included in OJS journal configuration |	
| issn | _na_ | _na_ | no appropriate mapping destination; data is included in OJS journal configuration |
| journal_id | _na_ | _na_ | no appropriate mapping destination; data is included in OJS journal configuration |	
| author1_fname | article/authors/author/givenname | _na_ | applies to additional author numbers (author2_fname, author3_fname, etc.) |
| author1_mname	| article/authors/author/givenname | _na_ | concatenated with `_fname`; applies to additional author numbers |
| author1_lname | article/authors/author/familyname	| _na_ | applies to additional author numbers |
| author1_suffix | _na_ | _na_ | no appropriate mapping destination |	
| author1_email | article/authors/author/email | _na_ | applies to additional author numbers |
| author1_institution | article/authors/author/affiliation | _na_ | applies to additional author numbers |
| calc_url | article/id[@type="public"]	| _na_ | XSLT parses final portion of URL, to be used in new URL path |
| context_key | _na_ | _na_ | Digital Commons system field |
| issue	| _na_ | _na_ | field is used to group issue contents and name output files |
| ctmtime | _na_ | _na_ | Digital Commons system field |

#### General Notes 

Because there are not many descriptive metadata elements available for Issues in OJS, multiple Bepress fields are compiled into the OJS `issue/description` element. For ease of reading, HTML markup is used to add headings and whitespace.  

- - - - - - - -

### Data Preparation

1. __Export metadata records from Digital Commons as an Excel file.__ Consult the [Digital Commons documentation](https://bepress.com/reference_guide_dc/batch-upload-export-revise/) for guidance on exporting. 

1. __Review the field set.__ The XSLT expects column headers matching the strings given in the "Bepress Field" column in the table above. If your column headers do not match those strings, either the column headers or the XSLT must be updated so that they agree.

1. __Clean up the spreadsheet metadata.__ 

    - Replace XML reserved characters with HTML entities: change `&` to `&amp;` ; `<` to `&lt;` ; `>` to `&gt;`.
        - UNLESS they are part of HTML markup that will be wrapped in CDATA tags, such as in an abstract field.
    - Ensure all items have a volume number in the `volnum` column and an issue number in the `issnum` column. These are used to group contents by issue. 
    - Verify the correct order of contents. The ordering of contents in OJS follows the order of the XML import files.
    - Ensure all items have publication dates, and ensure all publication dates use format `YYYY-MM-DD`.

1. __Export spreadsheet metadata to CSV.__
1. __Update local data configuration file.__ 

### Transformation

1. __Convert CSV metadata to flat XML.__ Python code originally from [FB36 on ActiveState](https://code.activestate.com/recipes/577423-convert-csv-to-xml/), with modifications by OSULP.

    - `python3 csv_to_xml.py {source_CSV_filename}.csv {output_XML_filename}.xml`
    - e.g. `python3 csv_to_xml.py bepress_metadata_sample.csv flat_xml_sample.xml`

1. __Transform metadata to PKP/OJS Native XML using XSLT.__ XSLT can be run using software like Oxygen XML Editor, or from the command line with Saxon. 

    - If your Digital Commons exported data has additional fields not included 

3. __Import XML to OJS using Native XML Import plugin.__ 

    - Content files are fetched using remote URLs.  
    - If DOIs are included in the import files, make sure to enable the DOI Plugin _before_ importing. 
    
6. Review; modify and repeat as needed. 
