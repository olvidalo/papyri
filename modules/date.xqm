xquery version "3.0";

(:~
 :  Daten interpretieren und formatieren 
 :)
module namespace date="http://papyri.uni-koeln.de:8080/papyri/date";


(:~
 : Versucht ein gültiges xs:date/xs:dateTime aus tei-Daten im Papyri-Bestand zu konstruieren
 :  
 : @param $dateString der String im Format "YYYY", "YYYY-MM-DD" oder "YYYY-MM-DDThh:mm:ss" 
 : @return konstruiertes Datum oder leere Sequenz
 :)
declare function date:parse-tei-date($dateString as xs:string?) {
  if ($dateString castable as xs:dateTime) then xs:dateTime($dateString)
  else if ($dateString castable as xs:date) then xs:date($dateString)
  else if ($dateString castable as xs:gYear) then xs:date($dateString || "-01-01")
  else ()
};



(:~
 : Berechne das Jahrhundert aus einem Datum
 :  
 : @param $date Jahreszahl als xs:integer, gültiger xs:date-castable String oder xs:date 
 : @return xs:integer Berechnetes Jahrhundert
 :)

declare function date:get-century($date) as xs:integer {
	let $year := if ($date castable as xs:date) then 
                  year-from-date($date cast as xs:date)
                  else if ($date castable as xs:integer) then
                  $date cast as xs:integer
                else 1

   let $bc := ($year < 0)
   
   let $century := let $cent := $year idiv 100
   				   let $add := if ($bc) then
                          if ($year mod 100)  then -1 else 0
                          else  1
   				   return $cent + $add

   return $century
};

(:~
 : Formatiert einen String für das Jahrhundert eines Datums
 :  
 : @param $date Jahreszahl als xs:integer, gültiger xs:date-castable String oder xs:date 
 : @return xs:string Jahrhundert als formatierter String
 :)

declare function date:format-century($date) as xs:string {
   
   let $century := date:get-century($date)

   return if ($century < 0)
    then let $abs := abs($century) return concat($abs, ". Jhdt. v. Chr.")  
    else concat($century, ". Jhdt. n. Chr.")
};
 
declare function date:dateRange($from as xs:string, $to as xs:string) {
  let $log := util:log-app("DEBUG", "papyri", "make date range from " || $from || " to " || $to)
  return map {
   "from" := xs:date($from),
   "to" := xs:date($to)
  }
};

declare function date:dateRange($century as xs:integer) {
  let $map := map {
    "from" := if ($century > 0) then xs:date(date:pad0(($century - 1) * 100 + 1, 4) || "-01-01")
                                else xs:date(date:pad0(($century * 100), 4) || "-01-01"),
    "to" := if ($century > 0) then xs:date(date:pad0(($century * 100), 4) || "-12-31")
                              else xs:date(date:pad0(($century + 1) * 100 - 1, 4) || "-12-31")
  }
  let $log := util:log-app("DEBUG", "papyri", "make date range from " || $map("from") || " to " || $map("to"))

    return $map

};

declare function date:pad0($value, $length as xs:integer) {
  let $string := xs:string($value)
  let $minus := if (substring($string, 1, 1) = "-") then "-"
                  else ()
  let $input := if ($minus) then substring($string, 2) else $string 
  let $inputLength := (string-length($input))
  return if ($inputLength = $length) then $minus || $input
  else let $zeros := for $i in (1 to $length - $inputLength)
                        return "0"
        return string-join(($minus, $zeros ,$input))
};

declare function date:is-leap-year
  ( $year as xs:integer )  as xs:boolean {

   ($year mod 4 = 0 and
    $year mod 100 != 0) or
    $year mod 400 = 0
 } ;

declare function date:days-in-month
  (  $year as xs:integer, $month as xs:integer )  as xs:integer? {

   if ($month = 2 and
       date:is-leap-year($year))
   then 29
   else
   (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
    [$month]
 } ;


(:~   
 :   Converts standard Roman numerals to integers. 
 :   Handles additive and subtractive but not double subtractive. 
 :   Case insensitive.
 :   Doesn't attempt to validate a numeral other than a naïve character check. 
 :   See discussion of standard modern Roman numerals at http://en.wikipedia.org/wiki/Roman_numerals.
 :   Adapted from an XQuery 1.0 module at 
 :   https://github.com/subugoe/ropen-backend/blob/master/src/main/xquery/queries/modules/roman-numerals.xqm
 :
 :   Originally by Joe Wicentowski, https://gist.github.com/joewiz/228e9cc174694e146cc8
 :
:)
 
declare function date:roman-numeral-to-integer($input as xs:string) as xs:integer {
    let $minus := if (substring($input, 1, 1) = "-") then true()
                  else false()
    let $string := if ($minus) then substring($input, 2) else $input
    let $characters := string-to-codepoints(upper-case($string)) ! codepoints-to-string(.)
    let $character-to-integer := 
        function($character as xs:string) { 
            switch ($character)
                case "I" return 1
                case "V" return 5
                case "X" return 10
                case "L" return 50
                case "C" return 100
                case "D" return 500
                case "M" return 1000
                default return error(xs:QName('roman-numeral-error'), concat('Invalid input: ', $input, '. Valid Roman numeral characters are I, V, X, L, C, D, and M. This function is case insensitive.'))
            }
    let $numbers := $characters ! $character-to-integer(.)
    let $values := 
        for $number at $n in $numbers
        return 
            if ($number < $numbers[position() = $n + 1]) then 
                (0 - $number) (: Handles subtractive principle of Roman numerals. :)
            else 
                $number
    return if ($minus) then
      -(sum($values))
    else sum($values)
};
