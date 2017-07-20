	
$Word = New-Object -ComObject Word.Application
$Document = $Word.Documents.Add()
$Selection = $Word.Selection
$Selection.Style = 'Title'
$Selection.TypeText("Hello")
$Selection.TypeParagraph()
$Selection.Style = 'Heading 1'
$Selection.TypeText("Report compiled at $(Get-Date).")
$Selection.TypeParagraph()
$Report = 'C:\temp\test111.doc'
$Document.SaveAs([ref]$Report,[ref]$SaveFormat::wdFormatDocument)
$word.Quit()
