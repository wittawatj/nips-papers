
# download all the papers from 2006 to 2015. Start from 2015
6to15:
	python pnips/download_papers.py 2015
	python pnips/download_papers.py 2014
	python pnips/download_papers.py 2013
	python pnips/download_papers.py 2012
	python pnips/download_papers.py 2011
	python pnips/download_papers.py 2010
	python pnips/download_papers.py 2009
	python pnips/download_papers.py 2008
	python pnips/download_papers.py 2007
	python pnips/download_papers.py 2006

6to10:
	python pnips/download_papers.py 2010
	python pnips/download_papers.py 2009
	python pnips/download_papers.py 2008
	python pnips/download_papers.py 2007
	python pnips/download_papers.py 2006

11to15:
	python pnips/download_papers.py 2015
	python pnips/download_papers.py 2014
	python pnips/download_papers.py 2013
	python pnips/download_papers.py 2012
	python pnips/download_papers.py 2011

0to5:
	python pnips/download_papers.py 2005
	python pnips/download_papers.py 2004
	python pnips/download_papers.py 2003
	python pnips/download_papers.py 2002
	python pnips/download_papers.py 2001
	python pnips/download_papers.py 2000

88to99:
	python pnips/download_papers.py 1999
	python pnips/download_papers.py 1998
	python pnips/download_papers.py 1997
	python pnips/download_papers.py 1996
	python pnips/download_papers.py 1995
	python pnips/download_papers.py 1994
	python pnips/download_papers.py 1993
	python pnips/download_papers.py 1992
	python pnips/download_papers.py 1991
	python pnips/download_papers.py 1990
	python pnips/download_papers.py 1989
	python pnips/download_papers.py 1988


output/Papers.csv:
	mkdir -p output
	mkdir -p output/pdfs
	python pnips/download_papers.py
csv: output/Papers.csv

working/noHeader/Papers.csv: output/Papers.csv
	mkdir -p working/noHeader
	tail +2 $^ > $@

working/noHeader/Authors.csv: output/Authors.csv
	mkdir -p working/noHeader
	tail +2 $^ > $@

working/noHeader/PaperAuthors.csv: output/PaperAuthors.csv 
	mkdir -p working/noHeader
	tail +2 $^ > $@

output/database.sqlite: working/noHeader/Papers.csv working/noHeader/PaperAuthors.csv working/noHeader/Authors.csv
	-rm output/database.sqlite
	sqlite3 -echo $@ < pnips/import.sql
db: output/database.sqlite

output/hashes.txt: output/database.sqlite
	-rm output/hashes.txt
	echo "Current git commit:" >> output/hashes.txt
	git rev-parse HEAD >> output/hashes.txt
	echo "\nCurrent ouput md5 hashes:" >> output/hashes.txt
	md5 output/*.csv >> output/hashes.txt
	md5 output/*.sqlite >> output/hashes.txt
	md5 output/pdfs/*.pdf >> output/hashes.txt
hashes: output/hashes.txt

release: output/database.sqlite output/hashes.txt
	zip -r -X output/release-`date -u +'%Y-%m-%d-%H-%M-%S'` output/*

all: csv db hashes release

clean:
	rm -rf working
	rm -rf output
