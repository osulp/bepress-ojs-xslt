# XSLT Migration from bepress Digital Commons to OJS 3.X

Contains tools for migrating journal metadata and content from Bepress Digital Commons to Open Journal Systems (OJS) 3.x.

Oregon State University Libraries and Press (OSULP) developed this toolkit to migrate the _OLA Quarterly_ journal to OJS 3.1.4 in early 2020. The XML generated by the main XSLT adheres to the OJS 3.1 version of the [PKP Native Schema](https://github.com/pkp/pkp-lib/blob/main/plugins/importexport/native/pkp-native.xsd) and [OJS Native Schema](https://github.com/pkp/ojs/blob/main/plugins/importexport/native/native.xsd). The XML can be imported to OJS using the [Native XML Plugin](https://docs.pkp.sfu.ca/admin-guide/en/data-import-and-export#native-xml-plugin). 

Upcoming work:

* generify the XSL for 3.1 (i.e. replace all OSU- and OLAQ-specific shortcuts)
* add common/standard bepress fields to XSLT that were not part of OLAQ dataset and thus not included in original script
* documentation/user guide/readme development
* stretch goal = modify for more recent OJS releases

## Usage

Note that this is a somewhat hands-on process. If you're using this toolset, it's because you would rather do the cleanup work before your journal data gets into OJS, rather than afterward. (If you prefer to do it afterward, other tools are out there.)

Note that article galleys (full text PDF files) are fetched remotely from Digital Commons and added to OJS using their live URL in this workflow. However, issue galleys cannot be pulled from a remote location via the Native XML Plugin. In the original migration project that this work is based on, staff downloaded issue galleys locally and uploaded them to each issue in the user interface post-import. The schema allows both issue and article galley files to be embedded in XML import files using base64 encoding, so converting and embedding those is an area of potential future development for this toolset.  

### Metadata Mapping

This table shows the fields included in the original use case's metadata export from Digital Commons and the destination OJS 3.1 fields to which they are mapped. Objects with document type “full_issue” became OJS Issues, and all other document types were migrated as OJS Submissions.

| Bepress Field | OJS XPath - Submissions |	OJS XPath - Issues | Notes |
| ----- | ----- | ----- | ----- |
| title | article/title | issue/issue_identification/title | |
| keywords | article/keywords | issue/description | XSLT expects comma delimiter |
| disciplines | article/disciplines | issue/description | XSLT expects semicolon delimiter |
| document_type | article/@section_ref | _na_ | a specified document_type designates an OJS Issue; this can be updated in the local_data.xml file |
| doi | article/id[@type="doi"] | issue/id[@type="doi"] | OJS DOI Plugin must be enabled before importing, otherwise DOI is not saved upon import | 
| volnum | _na_ | issue/issue_identification/volume | OJS requires an integer | 
| issnum | _na_	| issue/issue_identification/number | | 
| fpage | article/pages	| _na_ | concatenated with `lpage` value |
| lpage | article/pages	| _na_ | concatenated with `fpage` value |
| distribution_license	| article/licenseUrl | _na_ | must be a URL with no additional text |
| abstract | article/abstract | issue/description | if abstract text has HTML then see Added Fields below |
| comments | _na_ | _na_ | unpredictable values; field was used for author bios in original dataset, see Added Fields below |
| fulltext_url | | | field included but blank in original dataset - values added during cleanup |
| peer_reviewed	| _na_ | _na_ | no appropriate mapping destination |
| publication_date | article/@date_published | issue/date_published issue/issue_identification/year | REQUIRED for all records; OJS requires YYYY-MM-DD format |
| rights | article/copyrightYear article/copyrightHolder | _na_ | XSLT expects "© YYYY Name" pattern |
| license_statement | _na_ | _na_ | field included but blank in original dataset |
| filename | _na_ | _na_ |  |
| erratum | _na_ | _na_ | no appropriate mapping destination |	
| publisher | _na_ | _na_ | no appropriate mapping destination; data is included in OJS journal configuration |	
| issn | _na_ | _na_ | no appropriate mapping destination; data is included in OJS journal configuration |
| journal_id | _na_ | _na_ | no appropriate mapping destination; data is included in OJS journal configuration |	
| author1_fname | article/authors/author/givenname | _na_ | applies to additional author numbers (author2_fname, author3_fname, etc.); all included authors must have fname |
| author1_mname	| article/authors/author/givenname | _na_ | concatenated with `_fname`; applies to additional author numbers |
| author1_lname | article/authors/author/familyname	| _na_ | applies to additional author numbers; all included authors must have lname |
| author1_suffix | _na_ | _na_ | no appropriate mapping destination |	
| author1_email | article/authors/author/email | _na_ | applies to additional author numbers |
| author1_institution | article/authors/author/affiliation | _na_ | applies to additional author numbers; all included authors must have institution |
| calc_url | article/id[@type="public"]	| _na_ | XSLT parses URL for substring after the {journal_id} and replaces `/` with `_`; the result is used in new URL path |
| context_key | _na_ | _na_ | Digital Commons system field |
| issue	| _na_ | issue/id[@type="public"] | XSLT parses for issue ID from field value. expected format is `{journal_id}/{vol#}/{iss#}`. field is also used to group issue contents and name output files |
| ctmtime | _na_ | _na_ | Digital Commons system field |

#### General Notes 

Because there are not many descriptive metadata elements available for Issues in OJS, multiple Bepress fields are compiled into the OJS `issue/description` element. For ease of reading, HTML markup is used to add headings and whitespace.  

### Added Fields

The following fields should or may be added to the exported data, and are included in the XSLT. 

- __abstract_cdata__: Use to preserve HTML markup in abstract text. Maps to `article/abstract` or `issue/description`. Optional; XSLT will use the abstract field if abstract_cdata is not present, but ignore abstract if abstract_cdata is present. For values in the abstract_cdata field, concatenate the string `<![CDATA[` + text of abstract field + the string `]]>`. 
    - Google Sheets formula: `=IF(NOT(K2=""),CONCATENATE("<![CDATA[",K2,"]]>"),"")` where K is the "abstract" column 
- __author1_bio, author2_bio, etc__: Use for biographical information associated with respective authors. Maps to `article/authors/author/biography`. Optional. In original project dataset, this information was found in the comments field and cut/pasted to an authorX_bio column. 
- __author1_bio_cdata, author2_bio_cdata, etc__: If HTML markup is present in the `author1_bio` field text, use `author1_bio_cdata` etc. as in `abstract_cdata` above. Optional.


- - - - - - - -

### Data Preparation

1. __Export metadata records from Digital Commons as an Excel file.__ Consult the [Digital Commons documentation](https://bepress.com/reference_guide_dc/batch-upload-export-revise/) for guidance on exporting. 

2. __Review the field set.__ 

- The XSLT expects column headers matching the strings given in the "Bepress Field" column in the metadata mapping table above, which align with Bepress's documentation. If your column headers do not match those strings, either the column headers or the XSLT must be updated so that they agree.
    - If your Digital Commons exported data has additional fields not included in the metadata mapping above, the XSLT may be updated to accommodate them. Consult the appropriate versions of the [PKP Native Schema](https://github.com/pkp/pkp-lib/blob/main/plugins/importexport/native/pkp-native.xsd) and [OJS Native Schema](https://github.com/pkp/ojs/blob/main/plugins/importexport/native/native.xsd).
- Some fields have required or expected formatting. In case of disagreement, either the data or the XSLT will need updating for accurate results. _Some assumptions about expected formatting were made based on the original project dataset._
    - keywords: expected delimiter is comma, consistent with Bepress documentation (XSLT requirement)
    - disciplines: expected delimiter is semicolon, consistent with Bepress documentation (XSLT requirement)
    - volnum: must be an integer (OJS requirement)
    - distribution_license: must be a URL (OJS + XSLT requirement, if included)
    - fulltext_url: must be a URL (XSLT requirement)
    - publication_date: must be `YYYY-MM-DD` (OJS requirement)
    - rights: expected to use `© YYYY Name` pattern (XSLT requirement, if included)
    - calc_url: expected to use `{base URL}/{journal_id}/{unique path to item}`, XSLT parses using the `journal_id` (XSLT requirement)
    - issue: expected to use `{journal_id}/{vol#}/{iss#}` (XSLT requirement)

3. __Clean up the spreadsheet metadata.__ 

- Replace XML reserved characters with HTML entities: change `&` to `&amp;` ; `<` to `&lt;` ; `>` to `&gt;`;
    - __UNLESS__ they are part of HTML markup that will be wrapped in CDATA tags, such as in an abstract field.
- Verify the correct order of contents. The ordering of contents in OJS follows the order of the XML import files.
- Ensure all items have publication dates, and ensure all publication dates use format `YYYY-MM-DD`.
- Ensure all items other than issue-level items have the URL for the full text (e.g. PDF file) in the fulltext_url column. These are used to fetch the full text remotely and add it as an article galley to OJS. __Note that issue galleys cannot be fetched remotely using the OJS Native XML Plugin._
    - The original project data did not have values in the fulltext_url field, and we used a Google Sheets IMPORTXML function to add them to the dataset. 
    - YMMV but our function looked like 

4. __Export spreadsheet metadata to CSV.__

5. __Update local data configuration file.__ 

- - - - -

### Transformation

1. __Convert CSV metadata to flat XML.__ Python code originally from [FB36 on ActiveState](https://code.activestate.com/recipes/577423-convert-csv-to-xml/), with modifications by OSULP.

- `python3 csv_to_xml.py {source_CSV_filename}.csv {output_XML_filename}.xml`
- e.g. `python3 csv_to_xml.py bepress_metadata_sample.csv flat_xml_sample.xml`

2. __Transform metadata to PKP/OJS Native XML using XSLT.__ XSLT can be run using software like Oxygen XML Editor, or from the command line with Saxon. 

- Output will be one XML file per journal issue, saved to a directory called `import_files`.

3. __Import XML to OJS using Native XML Import plugin.__ 

- Content files are fetched using remote URLs.  
- If DOIs are included in the import files, make sure to enable the DOI Plugin _before_ importing. 
    
4. Review; modify and repeat as needed. 
