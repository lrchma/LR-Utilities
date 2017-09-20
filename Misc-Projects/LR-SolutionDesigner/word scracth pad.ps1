cd C:\Users\chris.martin\Documents\WindowsPowerShell\Modules\Open-Xml-PowerTools
Import-Module .\Open-XML-PowerTools.psm1

[System.Reflection.Assembly]::LoadFrom("C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.5\WindowsBase.dll")
[System.Reflection.Assembly]::LoadFrom("C:\Users\chris.martin\Documents\WindowsPowerShell\Modules\Open-Xml-PowerTools\OpenXmlPowerTools\bin\Debug\OpenXmlPowerTools.dll")



$data = [XML] "
    <Data>
        <CustomerName>Eric White</CustomerName>
        <PreparedBy>Chris Martin</PreparedBy>
        <DateCreated>Monday, January 1 1970 UTC</DateCreated>
        <SustainedMPSRate>1234</SustainedMPSRate>
        <LicenseRate>5678</LicenseRate>
        <PeakMPSRate>2345</PeakMPSRate>
    </Data>
"

$now = get-date 

$data = [XML] "
    <Data>
        <Customer>
            <Name>Eric White</Name>
        </Customer>
        <Document>
            <PreparedBy>Chris Martin</PreparedBy>
            <DatePrepared>$now</DatePrepared>
        </Document>
    </Data>
"

Complete-DocxTemplateFromXml -OutputPath "C:\Temp\soldesigner\1\9-out.docx" -Template "C:\Temp\soldesigner\1\1-Template.docx" -XmlData $data


$doc1 = New-Object OpenXmlPowerTools.Source("C:\Temp\soldesigner\1\9-Out.docx")
$doc2 = New-Object OpenXmlPowerTools.Source("C:\Temp\soldesigner\1\2-SectionOne.docx")
$sources = ($doc1, $doc2)


Merge-Docx -Sources $sources -OutputPath "C:\Temp\soldesigner\1\9-final.docx"
Convert-DocxToHtml -FileName "C:\Temp\soldesigner\1\9-final.docx" -OutputPath .