all: preprint reprint

# with bibliography:
#
# pdflatex - first pass reads in all references
# bibtex   - reads aux file and styles bibliography
# pdflatex - second pass links references to bibtex out
# pdflatex - third pass renders references
#
# target files only (no biblio):
#
# pdflatex - first pass reads in all references
# pdflatex - second pass renders references
#
# this will help make sure references (Sections, Figs,
# Tables, Citations) are rendered correctly in the
# final PDF output

preprint:
	pdflatex preprint
	bibtex   preprint
	pdflatex preprint
	pdflatex preprint

reprint:
	pdflatex reprint
	bibtex   reprint
	pdflatex reprint
	pdflatex reprint

clean:
	rm -f preprint.pdf
	rm -f reprint.pdf
	rm -f *.aux
	rm -f *.log
	rm -f *Notes.bib
	rm -f *.blg
	rm -f *.bbl


