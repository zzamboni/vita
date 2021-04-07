# Remove xdv files as well when cleaning
$clean_ext = "xdv run.xml";
# Default directory for TeX libraries
$ENV{'TEXINPUTS'}=":texinput";
# Use lualatex or xelatex by default depending on $pdf_mode - these parameters are the same as passing -xelatex or -lualatex to latexmk
$pdf_mode = 4; # 4=lualatex; 5=xelatex
$dvi_mode = $postscript_mode = 0;
