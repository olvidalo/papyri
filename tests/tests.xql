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
	%test:args("200","","")
	%test:assertEquals("0200")
	%test:args("-3", "1","")
	%test:assertEquals("-0003-01")
	%test:args("1988", "29", "3")
	%test:assertEquals("1988-29-03")
function t:date-format-parts($year, $month as xs:untypedAtomic?, $day as xs:untypedAtomic) {
	date:format-parts($year, $month, $day)
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


declare 
	(: Nur Jahr :)
	%test:args("2000")
	%test:assertEquals("2000-01-01 to 2000-12-31")
	%test:args("-2000")
	%test:assertEquals("-2000-01-01 to -2000-12-31")

	(: Daten im US-Format :)
	%test:args("800-02")
	%test:assertEquals("0800-02-01 to 0800-02-29")
	%test:args("-1-12-10")
	%test:assertEquals("-0001-12-10 to -0001-12-10")

	(: Daten im deutschen Format :)
	%test:args("10.-130")
	%test:assertEquals("-0130-10-01 to -0130-10-31")
	%test:args("29.03.1988")
	%test:assertEquals("1988-03-29 to 1988-03-29")
	%test:args("1.1.2000")
	%test:assertEquals("2000-01-01 to 2000-01-01")

	(: Jahrhunderte v./n. Chr.:)
	%test:args("3. Jh.")
	%test:assertEquals("0201-01-01 to 0300-12-31")
	%test:args("13. Jahrhundert n. Chr.")
	%test:assertEquals("1201-01-01 to 1300-12-31")
	%test:args("1. Jahrhdt. v. Chr.")
	%test:assertEquals("-0100-01-01 to -0001-12-31")

	(: Jahrhunderte in römischen Zahlen :)
	%test:args("V")
	%test:assertEquals("0401-01-01 to 0500-12-31")
	%test:args("-XIII")
	%test:assertEquals("-1300-01-01 to -1201-12-31")

function t:date-parse-date-input($input as xs:string) {
	let $dateRange := date:parse-date-input($input)
	return $dateRange("from") || " to " || $dateRange("to")
};

declare
	%test:args("0123-02-28", "0125-11-24", "0124-02-28")
	%test:assertTrue
	%test:args("-0123-02-28", "0125-11-24", "2000-02-28")
	%test:assertFalse
	%test:args("-0001-01-01", "-0001-01-01", "-0001-01-01")
	%test:assertTrue
function t:date-inRange($from as xs:date, $to as xs:date, $date as xs:date) {
	 date:inRange(date:dateRange($from, $to), $date)
};