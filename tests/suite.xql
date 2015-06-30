xquery version "3.0";
import module namespace t="http://papyri.uni-koeln.de:8080/papyri/tests"
    at "tests.xql";
import module namespace test="http://exist-db.org/xquery/xqsuite" 
	at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";

test:suite(util:list-functions("http://papyri.uni-koeln.de:8080/papyri/tests"))