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
  let $log := util:log-app("DEBUG", "papyri", "make date range from " || $from || " to " || $to)
  return map {
   "from" := xs:date($from),
   "to" := xs:date($to)
  }
};

declare function date:inRange($range as map(), $date as xs:date) {


    ($date >= $range("from") and $date <= $range("to"))          
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
      let $year := date:pad0($term, 4)
      return date:dateRange($year || "-01-01", $year || "-12-31")
    (: YYYY-MM :)
    else if ($count-US = 3) then
      let $year := date:pad0($groups-US[2], 4)
      let $month := date:pad0($groups-US[3], 2)
      return date:dateRange(concat($year, "-", $month, "-01"), concat($year, "-", $month, "-", date:days-in-month($year, $month)))
    (: YYYY-MM-DD :)
    else if ($count-US = 4) then
      let $year := date:pad0($groups-US[2], 4)
      let $month := date:pad0($groups-US[3], 2)
      let $day := date:pad0($groups-US[4], 2)
      return date:dateRange($year || "-" || $month || "-" || $day, $year || "-" || $month || "-" || $day)
    else
        let $groups-EU :=  $getComponents($term, "^(-?\d+)\.?(\d+)?\.?(-?\d+)?$")
        let $count-EU := count($groups-EU)
        (: MM.YYYY :)
        return if ($count-EU = 3) then
            let $year := date:pad0($groups-EU[3], 4)
            let $month := date:pad0($groups-EU[2], 2)
            return date:dateRange($year || "-" || $month || "-01", $year || "-" || $month || "-" || date:days-in-month(xs:integer($year), xs:integer($month)))
        (: DD.MM.YYYY :)
        else if ($count-EU = 4) then 
            let $year := date:pad0($groups-EU[4], 4)
            let $month := date:pad0($groups-EU[3], 2)
            let $day := date:pad0($groups-EU[2], 2)
            return date:dateRange($year || "-" || $month || "-" || $day, $year || "-" || $month || "-" || $day)
    else
        (: Jahrhundert als String ("3. Jahrhundert", "1. Jhdt. v. Chr.") etc. :)
        let $groups-century-string :=  $getComponents($term, "(-?\d{1,2})\.?\s*(Jh|JH|Jhdt|Jahrhdt|Jahrhundert)\.?\s*(n|v)?")
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
