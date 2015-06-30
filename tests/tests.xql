xquery version "3.0";
module namespace t="http://papyri.uni-koeln.de:8080/papyri/tests";
import module namespace test="http://exist-db.org/xquery/xqsuite" 
	at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
	
import module namespace date="http://papyri.uni-koeln.de:8080/papyri/date"
	at "../modules/date.xqm";

(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ date.xqm ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ :)

declare
	%test:args("0418-03-30")
	%test:assertEquals("0418-03-30")
	%test:args("-0233-03-30")
	%test:assertEquals("-0233-03-30")
	%test:args("0800")
	%test:assertEquals("0800-01-01")
	%test:args("-0800")
	%test:assertEquals("-0800-01-01")
function t:date-parse-tei-date($dateString as xs:string?) {
	date:parse-tei-date($dateString)
};


declare 
	%test:args("215", "integer")
	%test:assertEquals("3")
	%test:args("-0800-01-01", "string")
	%test:assertEquals("-8")
	%test:args("1988-03-29", "date")
	%test:assertEquals("20")
function t:date-get-century($input, $argtype as xs:string) as xs:integer {
	if ($argtype = "integer") 			then 	date:get-century(xs:integer($input))
	else if ($argtype = "date") 		then 	date:get-century(xs:date($input))
	else 										date:get-century($input)
};


declare 
	%test:args("-799", "integer")
	%test:assertEquals("8. Jhdt. v. Chr.")
	%test:args("-0001-01-01", "string")
	%test:assertEquals("1. Jhdt. v. Chr.")
	%test:args("1988-03-29", "date")
	%test:assertEquals("20. Jhdt. n. Chr.")	
function t:date-format-century($input, $argtype as xs:string) as xs:string {
	if ($argtype = "integer") 			then 	date:format-century(xs:integer($input))
	else if ($argtype = "date") 		then 	date:format-century(xs:date($input))
	else 										date:format-century($input)

};

declare 
	%test:args("-1234-01-12", "1988-12-31")
	%test:assertEquals("-1234-01-12 to 1988-12-31")
function t:date-dateRange($from as xs:string, $to as xs:string) {
	let $range := date:dateRange($from, $to)
	return xs:string($range("from")) || " to " || xs:string($range("to"))
};

declare
	%test:args("6", "4", "integer")
	%test:assertEquals("0006")
	%test:args("-77", "2", "string")
	%test:assertEquals("-77")
	%test:args("-800", "4", "integer")
	%test:assertEquals("-0800")
function t:date-pad0($value, $length as xs:integer, $argtype ) {
	if ($argtype = "integer")			then  	date:pad0(xs:integer($value), $length)
	else 										date:pad0($value, $length)
};


declare 
	%test:args("2000")
	%test:assertTrue
	%test:args("-2000")
	%test:assertTrue
	%test:args("807")
	%test:assertFalse
function t:date-is-leap-year($year as xs:integer) {
	date:is-leap-year($year)
};


declare 
	%test:args("2000", "2")
	%test:assertEquals("29")
	%test:args("-2000", "2")
	%test:assertEquals("29")
	%test:args("807", "4")
	%test:assertEquals("30")
	%test:args("-807", "2")
	%test:assertEquals("28")
function t:date-days-in-month($year as xs:integer, $month as xs:integer) {
	date:days-in-month($year, $month)
};

declare 
	%test:args("-MII")
	%test:assertEquals("-1002")
	%test:args("-IX")
	%test:assertEquals("-9")
	%test:args("XIV")
	%test:assertEquals("14")
function t:date-roman-numeral-to-integer($input as xs:string) as xs:integer {
	date:roman-numeral-to-integer($input)
};