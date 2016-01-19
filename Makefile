
# download all the papers from 2006 to 2015. Start from 2015
6to15:
	python src/download_papers.py 2015
	python src/download_papers.py 2014
	python src/download_papers.py 2013
	python src/download_papers.py 2012
	python src/download_papers.py 2011
	python src/download_papers.py 2010
	python src/download_papers.py 2009
	python src/download_papers.py 2008
	python src/download_papers.py 2007
	python src/download_papers.py 2006

6to14:
	python src/download_papers.py 2014
	python src/download_papers.py 2013
	python src/download_papers.py 2012
	python src/download_papers.py 2011
	python src/download_papers.py 2010
	python src/download_papers.py 2009
	python src/download_papers.py 2008
	python src/download_papers.py 2007
	python src/download_papers.py 2006

output/Papers.csv:
	mkdir -p output
	mkdir -p output/pdfs
	python src/download_papers.py
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
	sqlite3 -echo $@ < src/import.sql
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
