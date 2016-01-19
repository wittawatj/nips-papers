"""
The MIT License (MIT)
=====================

Copyright (c) 2015 Ben Hamner
Modified copyright 2016 Wittawat Jitkrittum

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""


from bs4 import BeautifulSoup
import json
import os
import pandas as pd
import re
import requests
import subprocess
import sys

def text_from_pdf(pdf_path, temp_path):
    if os.path.exists(temp_path):
        os.remove(temp_path)
    subprocess.call(["pdftotext", pdf_path, temp_path])
    f = open(temp_path)
    text = f.read()
    f.close()
    os.remove(temp_path)
    return text

def main(year):
    year = int(year)
    count = year - 1987
    base_url  = "http://papers.nips.cc"
    index_url = "http://papers.nips.cc/book/advances-in-neural-information-processing-systems-%d-%d"%(count, year)

    r = requests.get(index_url)

    soup = BeautifulSoup(r.content)
    paper_links = [link for link in soup.find_all('a') if link["href"][:7]=="/paper/"]
    print("%d Papers Found" % len(paper_links))

    nips_authors = set()
    papers = list()
    paper_authors = list()

    output_base = 'output%d'%year
    if not os.path.exists(output_base):
        os.mkdir(output_base)

    temp_path = os.path.join(output_base, "temp.txt")

    #for link in paper_links[:5]:
    pdfs_base = os.path.join(output_base, 'pdfs')
    if not os.path.exists(pdfs_base):
        os.mkdir(pdfs_base)
    for link in paper_links:
        paper_title = link.contents[0]
        info_link = base_url + link["href"]
        pdf_link = info_link + ".pdf"
        pdf_name = link["href"][7:] + ".pdf"
        paper_id = re.findall(r"^(\d+)-", pdf_name)[0]
        pdf = requests.get(pdf_link)
        pdf_path = os.path.join(output_base, "pdfs", pdf_name)
        pdf_file = open(pdf_path, "wb")
        pdf_file.write(pdf.content)
        pdf_file.close()
        paper_soup = BeautifulSoup(requests.get(info_link).content)
        abstract = paper_soup.find('p', attrs={"class": "abstract"}).contents[0]
        authors = [(re.findall(r"-(\d+)$", author.contents[0]["href"])[0],
                    author.contents[0].contents[0])
                   for author in paper_soup.find_all('li', attrs={"class": "author"})]
        for author in authors:
            nips_authors.add(author)
            paper_authors.append([len(paper_authors)+1, paper_id, author[0]])
        event_types = [h.contents[0][23:] for h in paper_soup.find_all('h3') if h.contents[0][:22]=="Conference Event Type:"]
        if len(event_types) != 1:
            print(event_types)
            print([h.contents for h in paper_soup.find_all('h3')])
            raise Exception("Bad Event Data")
        event_type = event_types[0]
        paper_text = text_from_pdf(pdf_path, temp_path)
        print(paper_title)
        papers.append([paper_id, paper_title, event_type, pdf_name, abstract, paper_text])

    pd.DataFrame(list(nips_authors),
            columns=["Id","Name"]).to_csv(os.path.join(output_base,
                "Authors.csv"), index=False)
    pd.DataFrame(papers, columns=["Id", "Title", "EventType", "PdfName",
        "Abstract", "PaperText"]).to_csv(os.path.join("Papers.csv"), index=False)
    pd.DataFrame(paper_authors, columns=["Id", "PaperId",
        "AuthorId"]).to_csv(os.path.join("PaperAuthors.csv"), index=False)

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('usage: %s year'%(sys.argv[0]) )
        print(' year is from 1988')
        sys.exit(1)

    year = sys.argv[1]
    main(year)
