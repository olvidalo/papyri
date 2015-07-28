xquery version "3.0";

(:~
 :  Daten interpretieren und formatieren 
 :)
module namespace date="http://papyri.uni-koeln.de:8080/papyri/date";


declare variable $date:cDistantFuture := xs:date("10000-01-01");
declare variable $date:cDistantPast := xs:date("-10000-01-01");

(:~
 : Versucht ein gültiges xs:date/xs:dateTime aus tei-Daten im Papyri-Bestand zu konstruieren
 :  
 : @param $dateString der String im Format "YYYY", "YYYY-MM-DD" oder "YYYY-MM-DDThh:mm:ss" 
 : @return konstruiertes Datum oder leere Sequenz
 :)
declare function date:parse-tei-date($dateString as xs:string?) as xs:date? {
 let $len := string-length($dateString)
  return if ($len = 10 or $len = 11) then xs:date($dateString)
  else if ($len = 4 or $len = 5) then xs:date($dateString || "-01-01")
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
 map {
   "from" := xs:date($from),
   "to" := xs:date($to)
  }
};

declare function date:inRange($date as xs:date, $range as map()) {
    ($date ge $range("from") and $date le $range("to"))          
};

declare function date:dateRange($century as xs:integer) {
 map {
    "from" := if ($century > 0) then xs:date(date:pad0(($century - 1) * 100 + 1, 4) || "-01-01")
                                else xs:date(date:pad0(($century * 100), 4) || "-01-01"),
    "to" := if ($century > 0) then xs:date(date:pad0(($century * 100), 4) || "-12-31")
                              else xs:date(date:pad0(($century + 1) * 100 - 1, 4) || "-12-31")
  }

};

declare function date:parse-date-input($term as xs:string) {
  
  let $getComponents := function($string as xs:string, $pattern as xs:string) {
                for $group in text:groups($string, $pattern)
                where $group != ""
                return $group
  }

  let $groups-US := $getComponents($term, "^(-?\d+)-?(\d+)?-?(\d+)?$")
   let $count-US := count($groups-US)
    (: YYYY :)
    return if ($count-US = 2) then 
      date:dateRange(date:format-parts($term, "01", "01"),
                     date:format-parts($term, "12", "31"))
    (: YYYY-MM :)
    else if ($count-US = 3) then
      let $year := $groups-US[2]
      let $month := $groups-US[3]
      return date:dateRange(date:format-parts($year, $month, "01"),
                            date:format-parts($year, $month, date:days-in-month($year, $month)))
    (: YYYY-MM-DD :)
    else if ($count-US = 4) then
      let $year := $groups-US[2]
      let $month := $groups-US[3]
      let $day := $groups-US[4]
      let $dateString: = date:format-parts($year, $month, $day)
      return date:dateRange($dateString, $dateString)
    else
        let $groups-EU :=  $getComponents($term, "^(-?\d+)\.?(\d+)?\.?(-?\d+)?$")
        let $count-EU := count($groups-EU)
        (: MM.YYYY :)
        return if ($count-EU = 3) then
            let $year := $groups-EU[3]
            let $month := $groups-EU[2]
            return date:dateRange(date:format-parts($year, $month, "01"),
                                  date:format-parts($year, $month, date:days-in-month($year, $month)))
        else if ($count-EU = 4) then 
            let $year := $groups-EU[4]
            let $month := $groups-EU[3]
            let $day := $groups-EU[2]
            let $dateString: = date:format-parts($year, $month, $day)
            return date:dateRange($dateString, $dateString)
    else
        (: Jahrhundert als String ("3. Jahrhundert", "1. Jhdt. v. Chr.") etc. :)
        let $groups-century-string :=  $getComponents($term, "(-?\d{1,2})\.?\s*([Jj][Hh]|[Jj]hdt|[Jj]ahrhdt|[Jj]ahrhundert)\.?\s*(n|v)?")
        (: XX. Jh. :)
        return if (count($groups-century-string) = 3) then
            date:dateRange(xs:integer($groups-century-string[2]))
        (: XX. Jh. x. Chr. :)
        else if (count($groups-century-string) = 4) then
            (: n. Chr. :)
            if ($groups-century-string[4] = "n") then
                date:dateRange(xs:integer($groups-century-string[2]))
            (: v. Chr. :)
            else if ($groups-century-string[4] = "v") then
                date:dateRange(xs:integer("-" || ($groups-century-string[2])))  
            else
              map {}
    else (: Jahrhundert als römische Zahl :)
        let $groups-roman-century := text:groups($term, "^-?(M{0,4})(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$")
        let $resultLength := sum(for-each(subsequence($groups-roman-century, 2), fn:string-length#1))
        return if ($resultLength > 0) then
            date:dateRange(date:roman-numeral-to-integer($term))
        (: TODO: Fehlerbehandlung :)
        else map {}
};

declare function date:format-parts($year, $month, $day) {
  let $yearInt := xs:integer($year)
  let $minus := if ($yearInt < 0) then "-" else "" 
  return concat(
      $minus,
      format-number(abs($yearInt), "0000"), 
      if ($month) then "-" || format-number(xs:integer($month), "00") else "",
      if ($day) then "-" || format-number(xs:integer($day), "00") else "" 
    )
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
