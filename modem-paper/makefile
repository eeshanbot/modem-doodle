all: preprint reprint

# for the target files, call pdflatex twice to make
# sure references (Sections, Figs, Tables, Citations)
# are rendered correctly – read in on first pass, and
# rendered at ref targets on second pass

preprint:
	pdflatex preprint.tex
	pdflatex preprint.tex

reprint:
	pdflatex reprint.tex
	pdflatex reprint.tex

clean:
	rm -f preprint.tex
	rm -f reprint.tex
	rm -f *.aux
	rm -f *.log
	rm -f *Notes.bib


