# XSLT Migration from bepress Digital Commons to OJS 3.X

Contains tools for migrating journal metadata and content from Bepress Digital Commons to Open Journal Systems (OJS) 3.x

Oregon State University Libraries and Press (OSULP) developed this toolkit to migrate the _OLA Quarterly_ journal to OJS 3.1.4 in early 2020. 

Upcoming work:

* generify the XSL for 3.1 (i.e. replace all OSU- and OLAQ-specific shortcuts)
* documentation/user guide/readme development
* stretch goal = modify for more recent OJS releases

# Usage

Note that this is a somewhat hands-on process. If you're using this toolset, it's because you would rather do the cleanup work before your journal data gets into OJS, rather than afterward. (If you prefer to do it afterward, other tools are out there.)

## Steps

1. __Export metadata records from Digital Commons as an Excel file.__ Consult the [Digital Commons documentation](https://bepress.com/reference_guide_dc/batch-upload-export-revise/) for guidance on exporting. 
2. __Clean up the spreadsheet metadata and export to CSV.__ 
3. __Convert CSV metadata to flat XML.__ Python code originally from [FB36 on ActiveState](https://code.activestate.com/recipes/577423-convert-csv-to-xml/), with modifications by OSULP.

    - `python3 csv_to_xml.py {source_CSV_filename}.csv {output_XML_filename}.xml`
    - e.g. `python3 csv_to_xml.py bepress_metadata_sample.csv flat_xml_sample.xml`
    
5. __Transform metadata to PKP/OJS Native XML using XSLT.__ XSLT can be run using software like Oxygen XML Editor, or from the command line with Saxon.
6. __Import XML to OJS using Native XML Import plugin.__
7. Review; rinse and repeat as needed. 
