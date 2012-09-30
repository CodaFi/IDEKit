import urllib
import re
import string
rootURL = "http://aspn.activestate.com/ASPN/Cookbook/"

def LoadCategories(rootURL, catbase):
    baseHTML = urllib.URLopener().open(rootURL).read()
    r = re.compile(catbase+"\?kwd=([A-Za-z%0-9]+)")
    return r.findall(baseHTML)

def GrabResults(html):
    r = re.compile("/ASPN/Cookbook/[A-Za-z]+/Recipe/([0-9]+)\">([^<]*)</a>([^<]*)<br />([^<]*)<br />")
    retval = {}
    for i in r.findall(html):
	#print i # index, title, author, description
	retval[i[0]] = (i[1],i[2],i[3])
    return retval

def LoadStarts(rootURL, category):
    results = urllib.URLopener().open(rootURL + "?kwd=" + category).read()
    r = re.compile(rootURL + "?kwd=" + category +"\?query_start=([0-9]+)")
    retval = GrabResults(results)
    for i in r.findall(results):
	next = urllib.URLopener().open(rootURL + "?kwd=" + category + "&query_start=" + i).read()
	retval.update(GrabResults(results))
    return retval

def GrabCookbook(f, language, langName, urlLang = None):
    if (urlLang == None):
	urlLang = language
    print >> f, "("
    categories = LoadCategories(rootURL + urlLang,"/ASPN/Cookbook/" + urlLang)
    for i in categories:
	print "Loading category",i
	#print LoadStarts(rootURL, i)
	snips = LoadStarts(rootURL + urlLang,i)
	for num,values in snips.items():
	    name,author,desc = values
	    if not name:
		continue # blank entires
	    print "\t",name
	    print >> f, "{"
	    if langName:
		print >> f,"\tlanguage=\"%s\";" % (langName,) # limit to a specific language
	    print >> f, "\ttitle=\"%s Cookbook/%s/%s\";" % (language,i,name.replace('"','%22').replace('/','%2f'))
	    print >> f, "\ttag=\"%s\";" % (desc.strip().replace('"','\\"'))
	    print >> f, "\turl=\"%s/Recipe/%s/index_txt\";" % (rootURL + urlLang,num)
	    print >> f, "},"
    print >> f, ")"

GrabCookbook(file("phpCookbook.iksnip","w"),"php","php","PHP")
GrabCookbook(file("tclCookbook.iksnip","w"),"Tcl","tcl")
GrabCookbook(file("pyCookbook.iksnip","w"),"Python","Python")
GrabCookbook(file("rxCookbook.iksnip","w"),"perl Regular Expression","perl","Rx")















