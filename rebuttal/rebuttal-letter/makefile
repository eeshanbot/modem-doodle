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

all:
	pdflatex trunk-rebuttal
	pdflatex trunk-rebuttal


clean:
	rm -f *.aux
	rm -f *.log
	rm -f *.out
	rm -f *.fdb_latexmk
	rm -f *.toc
	rm -f *.synctex.gz
	rm -f *.fls
