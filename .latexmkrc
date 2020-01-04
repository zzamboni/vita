# Remove xdv files as well when cleaning
$clean_ext = "xdv run.xml";
# Default directory for TeX libraries
$ENV{'TEXINPUTS'}=":texinput";
# Use xelatex by default - these parameters are the same as passing -xelatex to latexmk
$pdf_mode = 5; # xelatex
$dvi_mode = $postscript_mode = 0;
