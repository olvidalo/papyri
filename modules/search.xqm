xquery version "3.0";

(:~
 :  API zur Suche im Papyri-Bestand 
 :)


module namespace search="http://papyri.uni-koeln.de:8080/papyri/search";
import module namespace app="http://papyri.uni-koeln.de:8080/papyri/templates" at "app.xql";
import module namespace date="http://papyri.uni-koeln.de:8080/papyri/date" at "date.xqm";
import module namespace console="http://exist-db.org/xquery/console";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $search:data-path := "/db/apps/papyri/data/stuecke";

(:~
 : Gibt alle Objekte oder Texte der Papyri-Sammlung zurück, die den Suchbedingungen entsprechen
 :  
 : @param $constraints Suchbedingungen als Sequenz von Maps mit folgenden Einträgen (jeweils als xs:string):
 :          *  "searchField": die ID des Felds, in dem gesucht werden soll (siehe $search:fields)
 :          *  "combinationOperator": wie die Suchbedingung mit den andren kombiniert werden soll
 :                  gültige Werte z.Zt. "and" für UND sowie "nand" für UND NICHT
 :          * "searchOperator": Vergleichsoperator für die Bedingung (siehe $search:ops)
 :          * "searchTerm": Suchbegriff oder Sequenz von mit ODER zu kombinierenden Suchbegriffen
 : @return Sequenz von <tei:TEI>-Nodes
 :)
declare function search:search($constraints as map()*) {

    let $collection := xmldb:xcollection($search:data-path)

    (: parse für jede Bedingung die Suchbegriffe, entweder einfach mit normalize-space :)
    (: oder mit einer in der Suchfelddefinition definierten Funktion :)
    let $parsedConstraints := for $constraint in $constraints
                                  let $searchParams := $constraint("searchParams")
                                  let $field := $search:fields($constraint("searchField"))
                                  let $parseFunc := if (map:contains($field, $search:kFieldInputParser)) 
                                                        then $field($search:kFieldInputParser)
                                                         else normalize-space(?)
                                  let $parsedParams := for $paramSet in $searchParams
                                      return map:new (
                                            for $param in map:keys($paramSet)
                                            where $paramSet($param) != ""
                                            return map:entry($param, $parseFunc($paramSet($param)))
                                        )

                                   return map:new(($constraint, map:entry("searchParams", $parsedParams)))
                                  

    
    let $results := search:resolve($collection, $parsedConstraints)


    return search:sort($results, $constraints)
};

(:~
 : Wendet alle Suchbedingungen aus $constraints rekursiv (UND) auf die Nodes in $base an 
 :  
 : @param $base: die Nodes, die gefiltert werden sollen
 : @param $constraints Suchbedingungen als Sequenz von Maps (Format siehe $search:search)
 : @return Sequenz den Bedingungen entsprechender Nodes
 :)
declare function search:resolve($base as node()*, $constraints as map()*) {

     if (count($constraints) > 0) then

        let $constraint := $constraints[1]
        let $searchOp := $constraints[1]('searchOperator')
		let $field := $search:fields($constraint("searchField")) 
        let $resolveFunction := $field($search:kFieldResolve)

		let $results := for $searchParams in $constraint("searchParams")
                            return if ($constraint("combinationOperator") = 'nand') then 
                                                        $base[not($resolveFunction(., $searchOp, $searchParams))]
                                                    else
                                                        $resolveFunction($base, $searchOp, $searchParams)

		return search:resolve($results/ancestor::tei:TEI(:$distinctResults:), subsequence($constraints, 2))
	   
    else 
		$base
};

declare function search:sort($results as node()*, $constraints as map()*) {

    let $fieldNames := distinct-values(
        for $constraint in $constraints 
            return $constraint("searchField")
    )

    return for $result in $results
        order by 
            if ($fieldNames = "datierung") then
                if ($result//tei:date/@type = "Zeitpunkt") then 1
                    else  0
                else ()
                descending,
            $result//tei:sourceDesc/tei:msDesc/tei:msIdentifier[1]/tei:idno[1] ascending
        return $result
};

(: Definition der Vergleichsoperatoren :)
declare variable $search:ops := map {
    "eq" := "entspricht",
    "cont" := "enthält"
};

(: Konstanten für den Ergebnistyp :)
declare variable $search:cItem := "item"; (: Textträger :)
declare variable $search:cText := "text"; (: einzelner Text (msItemStruct) :)


(: 
 :  Definition der Suchfelder  
 :)

(: Schlüsselnamen der Maps für die Suchfelder:)
declare variable $search:kFieldTitle := "title"; (: Titel des Felds :)
declare variable $search:kFieldOperators := "operators"; (: Vergleichsoperatoren für dieses Feld, siehe $search:ops :)
declare variable $search:kFieldInput := "input"; (: Das HTML-Formularelement für dieses Feld :)
declare variable $search:kFieldResolve := "resolve"; (: Die Suchfunktion, die eine Bedingung für das entsprechende Feld auflöst :)
declare variable $search:kFieldValues := "values"; (: Funktion, die alle für das Feld im Korpus enthaltenen Werte zurückgibt
                                                      (für Facettenbrowsing und Drop-Down-Felder in der Suche) :)
declare variable $search:kFieldInputParser := "parser"; (: Optionale Funktion, die den vom Benutzer eingegebenen Suchbegriff 
                                                           transformiert (z.B. "8. Jahrhundert") in die entsprechende 
                                                           Zeitspanne :)
declare variable $search:kFieldParamPrinter := "paramPrinter";

declare function search:describeConstraint($constraint as map(*)) as xs:string {
    let $field := $search:fields($constraint("searchField"))
    let $params := for $paramSet in $constraint('searchParams')
        return if (map:contains($field, $search:kFieldParamPrinter))
            then $field($search:kFieldParamPrinter)($paramSet)
            else for $param in $paramSet
                    return $param('term')
    return string-join($params, " oder ")
};


(: Definition der Suchfelder :)
declare variable $search:fields := map {
	(: Suche nach Inventarnummer :)
    "inventarnummer" := map {
    	$search:kFieldTitle := "Inventarnummer",
        $search:kFieldOperators := ("cont"),
        $search:kFieldInput := <input class="term" type="text"></input>,
        $search:kFieldResolve := function($item as node()*, $op as xs:string?, $params as map(*)) {
			        	contains(substring-before(util:document-name($item), ".xml"), $params('term'))
        }
    },
    (: Suche nach Material :)
    "material" := map {
    	$search:kFieldTitle := "Material",
        $search:kFieldOperators := ("eq"),
        $search:kFieldInput := <select class="term"></select>,
        $search:kFieldResolve := function($items as node()*, $op as xs:string?, $params as map(*)) {
		      $items//tei:support//tei:material[tei:material = $params('term')]
		}, 
        $search:kFieldValues := function() {
            distinct-values(xmldb:xcollection($search:data-path)//tei:msDesc/tei:physDesc//tei:material/tei:material)
        }
				
    },
    (: Suche nach Herkunft :)
    "herkunft" := map {
    	$search:kFieldTitle := "Herkunft",
        $search:kFieldOperators := ("cont", "eq"),
        $search:kFieldInput := <input class="term" type="text"></input>,
        $search:kFieldResolve := function($items as node()*, $op as xs:string?, $params as map(*)) {
			        	 $items//tei:msItemStruct/tei:note[@type="orig_place" and contains(.//tei:placeName, $params('term'))]
        }
    },
    (: Suche nach Sammlung :)
    "sammlung" := map {
    	$search:kFieldTitle := "Sammlung",
        $search:kFieldOperators := ("cont"),       
    	$search:kFieldInput := <input class="term" type="text"></input>,
    	$search:kFieldResolve := function($items as node()*, $op as xs:string?, $params as map(*)) {
			        	$items//tei:msIdentifier[contains(./tei:collection, $params('term'))]
        }
    }, 
    (: Suche nach Publikationsstatus :)
   "publikationsstatus" := map {
    	$search:kFieldTitle := "Publikationsstatus",
        $search:kFieldOperators := ("eq"),
    	$search:kFieldInput := <select class="term"></select>,
    	$search:kFieldResolve := function($items as node()*, $op as xs:string?, $params as map(*)) {
			        	$items//tei:msItemStruct/tei:note[@type="availability" and contains(., $params('term'))]
        },
        $search:kFieldValues := function() {
            distinct-values(xmldb:xcollection($search:data-path)//tei:msItemStruct/tei:note[@type="availability"])
        }
    },
    (: Suche nach Textsorte :)
    "textsorte" := map {
    	$search:kFieldTitle := "Textsorte",
        $search:kFieldOperators := ("eq"),
    	$search:kFieldInput := <select class="term"></select>,
    	$search:kFieldResolve := function($items as node()*, $op as xs:string?, $params as map(*)) {
			        	$items//tei:msItemStruct/tei:note[@type="text_type" and contains(., $params('term'))]
        },
        $search:kFieldValues := function() {
            distinct-values(xmldb:xcollection($search:data-path)//tei:msItemStruct/tei:note[@type="text_type"])
        }
    },
    (: Suche nach Textsprache :)
    "sprache" := map {
    	$search:kFieldTitle := "Sprache",
        $search:kFieldOperators := ("eq"),
    	$search:kFieldInput := <select class="term"></select>,
    	$search:kFieldResolve := function($items as node()*, $op as xs:string?, $params as map(*)) {
                        $items//tei:textLang/tei:note[@type = "language"][tei:term = $params('term')]
        },
        $search:kFieldValues := function() {
            distinct-values(xmldb:xcollection($search:data-path)//tei:msItemStruct/tei:textLang/tei:note[@type="language"]/tei:term)
        }
    },
    "schrift" := map {
        $search:kFieldTitle := "Schrift",
        $search:kFieldOperators := ("eq"),
        $search:kFieldInput := <select class="term"></select>,
        $search:kFieldResolve := function($item as node()*, $op as xs:string?, $params as map(*)) {
                         $item//tei:msItemStruct/tei:textLang/tei:note[@type="script" and tei:term = $params('term')]
        },
        $search:kFieldValues := function() {
            distinct-values(xmldb:xcollection($search:data-path)//tei:msItemStruct/tei:textLang/tei:note[@type="script"]/tei:term)
        }
    },
    (: Suche in allen Elementen :)
    "volltext" := map {
        $search:kFieldTitle := "Beliebiges Feld",
        $search:kFieldOperators := ("cont, eq"),
        $search:kFieldInput := <input class="term" type="text"></input>,
        $search:kFieldResolve := function($item as node()*, $op as xs:string?, $params as map(*)) {
            $item//*[   contains(lower-case(string-join((@*/data(.)))), lower-case($params('term'))) or 
                        contains(lower-case(string-join((text()))), lower-case($params('term')))]
        }
    },
    (: Suche nach Datierung :)
    "datierung" := map {
        $search:kFieldTitle := "Datierung",
        $search:kFieldOperators := ("eq"),
        $search:kFieldInput := (<input class="post" id="von" type="text"></input>,
                                <input class="pre" id="bis" type="text"></input>),
        $search:kFieldParamPrinter := function($param) {
            
                if (map:contains($param, "post") and map:contains($param, "pre")) 
                    then "von " || $param("post") || " bis " || $param("pre")
                 else if (map:contains($param, "post"))
                    then "von " || $param("post")
                 else 
                    "bis " || $param("pre")
            
        },
        $search:kFieldInputParser := date:parse-date-input#1,
        $search:kFieldResolve := function($items as node()*, $op as xs:string?, $params as map(*)) {

            let $hasFromParam := map:contains($params, "post")
            let $hasToParam := map:contains($params, "pre")

            let $searchRange := map {
                "from": if ($hasFromParam) then $params("post")("from")
                                           else $date:cDistantPast, 
                "to":   if ($hasToParam) then $params("pre")("to")
                                         else $date:cDistantFuture
            }

            
                let $pointsInTime := $items//tei:date[@when]
                let $timeSpansBoth := $items//tei:date[@notBefore][@notAfter]
                let $timeSpansNotBefore := $items//tei:date[@notBefore][not(@notAfter)]
                let $timeSpansNotAfter := $items//tei:date[not(@notBefore)][@notAfter]
                
                let $results :=  (  
                            $pointsInTime[(date:parse-tei-date(@when)) ge $searchRange("from")]
                                         [(date:parse-tei-date(@when)) le $searchRange("to")],
                            $timeSpansBoth[(date:inRange(date:parse-tei-date(@notBefore), $searchRange))]
                                          [(date:inRange(date:parse-tei-date(@notAfter), $searchRange))],
                            $timeSpansNotBefore[(date:parse-tei-date(@notAfter)) le $searchRange("from")],
                            $timeSpansNotAfter[(date:parse-tei-date(@notAfter)) ge $searchRange("to")]                        
                        )

                return $results 
            }
    }
};


declare %private function search:filtered-collection($query as xs:string, $value) {
	for $stueck in xmldb:xcollection($search:data-path)
		where switch($query)
			case "material" return $stueck//tei:msDesc/tei:physDesc//tei:material/tei:material/lower-case(.) = lower-case($value)
			case "herkunft" return $stueck//tei:note[@type="orig_place"]//tei:placeName/lower-case(.) = lower-case($value)
			default return 1
		return $stueck
};


declare function search:query($node as node(), $model as map(*)) {

	let $limit := 30
	let $start := request:get-parameter("start", 1)
	let $parameters := request:get-parameter-names()

	let $results := if (count($parameters) > 0) 
					then for $param in $parameters
							for $value in request:get-parameter($param, "")
								for $stueck in search:filtered-collection($param, $value)
									return $stueck//tei:msIdentifier/tei:idno/data(.)
					else for $stueck in xmldb:xcollection($search:data-path)
						return $stueck//tei:msIdentifier/tei:idno/data(.)	

	return (<div>{count($results)} Ergebnisse</div>, <ul>{
				for $result in subsequence($results, $start, $start + $limit)
					return <li>{$result}</li>
				}
			</ul>)

};