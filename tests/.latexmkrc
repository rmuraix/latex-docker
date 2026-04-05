# latexmkrc for test documents
# Ensures latexmk calls biber for biblatex documents.
$pdf_mode = 1;
$biber = 'biber %O %S';
