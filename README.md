# XSLT Migration from bepress Digital Commons to OJS 3.X

Contains tools for migrating journal metadata and content from Bepress Digital Commons to Open Journal Systems (OJS) 3.x.

Oregon State University Libraries and Press (OSULP) developed this toolkit to migrate the _OLA Quarterly_ journal to OJS 3.1.4 in early 2020. The XML generated by the main XSLT adheres to the OJS 3.1 version of the [PKP Native Schema](https://github.com/pkp/pkp-lib/blob/main/plugins/importexport/native/pkp-native.xsd) and [OJS Native Schema](https://github.com/pkp/ojs/blob/main/plugins/importexport/native/native.xsd). The XML can be imported to OJS using the [Native XML Plugin](https://docs.pkp.sfu.ca/admin-guide/en/data-import-and-export#native-xml-plugin). 

Based on the shape of the data in our project, the current toolset was built to handle a content structure where, in Digital Commons:

- a "journal" contains one or more "issues", each with a volume and number
- issues contain one or more "articles" (translating to OJS "submissions")
- each article has one and only one "document type" assigned (translating to an OJS "section")
- each article has a single content file associated with it, and all content files are full text PDFs (translating to an OJS "article galley")

Upcoming work:

* generify the XSL for 3.1 (i.e. replace all OSU- and OLAQ-specific shortcuts)
* add common/standard bepress fields to XSLT that were not part of OLAQ dataset and thus not included in original script
* documentation/user guide/readme development
* stretch goal = modify for more recent OJS releases

## Usage

Note that this is a somewhat hands-on process. If you're using this toolset, it's because you would rather do the cleanup work before your journal data gets into OJS, rather than afterward. (If you prefer to do it afterward, other tools are out there.)

Note that article galleys (full text PDF files) are fetched remotely from Digital Commons and added to OJS using their live URL in this workflow. However, issue galleys cannot be pulled from a remote location via the Native XML Plugin. In the original migration project that this work is based on, staff downloaded issue galleys locally and uploaded them to each issue in the user interface post-import. The schema allows both issue and article galley files to be embedded in XML import files using base64 encoding, so converting and embedding those is an area of potential future development for this toolset.  

- - - - - - - -

### Data Preparation

1. __Export metadata records from Digital Commons as an Excel file.__ Consult the [Digital Commons documentation](https://bepress.com/reference_guide_dc/batch-upload-export-revise/) for guidance on exporting. 

2. __Review the field set.__ 

- Compare the fields in the [Metadata Mapping](https://github.com/osulp/bepress-ojs-xslt/wiki/Metadata-Mapping) with the exported metadata.
- The XSLT expects column headers matching the strings given in the "Bepress Field" column in the mapping table, which align with Bepress's documentation. If your column headers do not match those strings, either the column headers or the XSLT must be updated so that they agree.
    - If your Digital Commons exported data has additional fields not included in the mapping, the XSLT may be updated to accommodate them. Consult the appropriate versions of the [PKP Native Schema](https://github.com/pkp/pkp-lib/blob/main/plugins/importexport/native/pkp-native.xsd) and [OJS Native Schema](https://github.com/pkp/ojs/blob/main/plugins/importexport/native/native.xsd).
- Some fields have required or expected formatting. In case of disagreement, either the data or the XSLT will need updating for accurate results. _Some assumptions about expected formatting were made based on the original project dataset. Unless it is an OJS schema requirement, the user may edit the XSLT as needed to accommodate their data._
    - keywords: expected delimiter is comma, consistent with Bepress documentation (XSLT requirement)
    - disciplines: expected delimiter is semicolon, consistent with Bepress documentation (XSLT requirement)
    - volnum: must be an integer (OJS requirement)
    - distribution_license: must be a URL (OJS + XSLT requirement, if included)
    - fulltext_url: must be a URL (XSLT requirement); expected to use `{base URL}/cgi/viewcontent.cgi?article={article ID}&amp;context={journal_id}`, XSLT parses for the article ID (XSLT requirement)
    - publication_date: must be `YYYY-MM-DD` (OJS requirement)
    - rights: expected to use `© YYYY Name` pattern (XSLT requirement, if included)
    - calc_url: expected to use `{base URL}/{journal_id}/{unique path to item}`, XSLT parses using the `journal_id` (XSLT requirement)
    - issue: expected to use `{journal_id}/{vol#}/{iss#}` (XSLT requirement)

3. __Clean up the spreadsheet metadata.__ 

- Replace XML reserved characters with HTML entities: change `&` to `&amp;` ; `<` to `&lt;` ; `>` to `&gt;`;
    - __UNLESS__ they are part of HTML markup that will be wrapped in CDATA tags, such as in an abstract field.
- Verify the correct order of contents. The ordering of contents in OJS follows the order of the XML import files.
- Ensure all items have publication dates, and ensure all publication dates use format `YYYY-MM-DD`.
- Ensure all items other than issue-level items have the URL for the full text (e.g. PDF file) in the fulltext_url column. These are used to fetch the full text remotely and add it as an article galley to OJS. _Note that issue galleys cannot be fetched remotely using the OJS Native XML Plugin, as of the creation of this toolset._
    - The original project data did not have values in the fulltext_url field, and we used a Google Sheets IMPORTXML function to add them to the dataset. 
    - YMMV but our function looked like: `=IMPORTXML({calc_url cell},"html/body/div[@id='olaq']/div[@id='container']/div[@id='wrapper']/div[@id='content']/div[@id='main']/div[@id='display-pdf']/object/@data`
    - Ampersands in the URL must be replaced with the `&amp;` entity

4. __Export spreadsheet metadata to CSV.__

- For instance in Google Sheets, `File > Download > Comma-separated values` 
- For ease of execution, it is recommended to save the CSV to the same directory as the Python csv_to_xml.py script.

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
