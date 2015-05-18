xquery version "3.0";

module namespace search="http://papyri.uni-koeln.de:8080/papyri/search";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $search:data-path := "/db/apps/papyri/data/stuecke";

declare function search:get-inv($node as node(), $model as map(*)){
    
};