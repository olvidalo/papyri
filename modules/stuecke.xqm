xquery version "3.0";

module namespace stuecke="http://papyri.uni-koeln.de:8080/papyri/stuecke";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function stuecke:slides-sammlung($node as node(), $model as map(*)){
    for $st in (collection("/db/apps/papyri/data/stuecke")//tei:TEI)[(.//tei:idno)[1] = ("O. 0397", "T. 032", "00055", "03288", "03852", "05512", "10212", "21351", "00904 + P.Rob. inv. 38", "00906; P.Duke Inv. 769", "21351_21376")]
    let $anzahlTexte := count($st//tei:msItemStruct)
    return
    <div class="bg">
        <div class="wrap">
            <div class="md">
                <span class="label">Inventarnummer:</span>
                <span class="value">{stuecke:get-invnr($st)}</span>
                <span class="label">Datierung:</span>
                <span class="value">{stuecke:get-date($st)}</span>
                <span class="label">Herkunft:</span>
                <span class="value">{stuecke:get-place($st)}</span>
                <span class="label">Material:</span>
                <span class="value">{stuecke:get-material($st)}</span>
                <span class="label">Text{if ($anzahlTexte gt 1) then "e" else ()}:</span>
                <span class="value">{stuecke:get-text-titles($st)}</span>
            </div>
            <div class="img">
                {if (stuecke:get-preferred-image($st) != "")
                 then <img src="{stuecke:get-preferred-image($st)}" alt="{stuecke:get-invnr($st)}" />
                else "ohne Bild"}
            </div>
        </div>
    </div>
};

declare function stuecke:slides-texte($node as node(), $model as map(*)){
    for $text in collection("/db/apps/papyri/data/stuecke")//tei:msItemStruct[ancestor::tei:msDesc//tei:idno = ("00574", "06203", "05803", "01650", "07951", "20351", "20986a", "00651 Recto", "07614 Recto", "O. 0404")]
    return
    <div class="bg">
        <div class="wrap">
            <div class="md">
                <span class="label">Titel:</span>
                <span class="value">{$text/tei:title/data(.)}</span>
                <span class="label">Publikationsnummer:</span>
                <span class="value">{$text/tei:note[@type="publication"]/data(.)}</span>
                <span class="label">Datierung:</span>
                <span class="value">{stuecke:get-date($text)}</span>
                <span class="label">Herkunft:</span>
                <span class="value">{stuecke:get-place($text)}</span>
            </div>
            <div class="text">
                {stuecke:get-text-snippet($text/ancestor::tei:TEI)}
            </div>
            <div class="img">
                {if (stuecke:get-preferred-image($text/ancestor::tei:TEI) != "")
                 then <img src="{stuecke:get-preferred-image($text/ancestor::tei:TEI)}" alt="{stuecke:get-invnr($text)}" />
                else "ohne Bild"}
            </div>
        </div>
    </div>
};

declare function stuecke:get-text-snippet($st as node()){
    let $snippet := $st//tei:text//tei:div[@type="edition"][@xml:lang="grc"]
    return if (string-length($snippet/data(.)) gt 250)
           then concat(substring($snippet, 1, 250), "...")
           else $snippet/data(.)
};

declare function stuecke:get-preferred-image($st as node()){
    let $URL := ($st//tei:graphic[tei:desc[@type="preferred"]])[1]/@url
    let $prevURL := replace($URL, "orig", "preview")
    let $prevURL := if (contains($prevURL, ".jpg"))
                    then replace($prevURL, "\.jpg", ".png")
                    else if (contains($prevURL, ".jpeg"))
                    then replace($prevURL, "\.jpeg", ".png")
                    else if (contains($prevURL, ".JPG"))
                    then replace($prevURL, "\.JPG", ".png")
                    else if (contains($prevURL, ".tif"))
                    then replace($prevURL, "\.tif", ".png")
                    else if (contains($prevURL, ".tiff"))
                    then replace($prevURL, "\.tiff", ".png")
                    else if (contains($prevURL, ".png") or contains($prevURL, ".PNG"))
                    then $prevURL
                    else if ($prevURL = "")
                    then ()
                    else concat($prevURL, ".png")
    return $prevURL
};

declare function stuecke:get-date($st as node()){
    for $date in $st//tei:note[@type="orig_date"]/tei:date
    let $type := $date/@type
    return if ($type = "Zeitpunkt") then $date/@when/data(.)
           else if ($type = "Zeitraum") then concat($date/@notBefore/data(.), "-", $date/@notAfter/data(.))
           else "Datum nicht gefunden."
};

declare function stuecke:get-material($st as node()){
    $st//tei:material/tei:material/data(.)
};

declare function stuecke:get-invnr($st as node()){
    $st//tei:msIdentifier/tei:idno/data(.)
};

declare function stuecke:get-place($st as node()){
    $st//tei:note[@type="orig_place"]//tei:placeName/data(.)
};

declare function stuecke:get-text-titles($st){
    string-join($st//tei:msItemStruct/tei:title, "; ")
};
