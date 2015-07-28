xquery version "3.0";

module namespace auth="http://papyri.uni-koeln.de:8080/papyri/auth";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";

declare function auth:login(){
    let $loginuser := request:get-parameter('username',())
    let $loginpassword := request:get-parameter('password',())
    return
        if ($loginuser and $loginpassword) then
            xmldb:login('/db',$loginuser,$loginpassword)
        else
            false()
};

declare function auth:logout(){
   xmldb:login("/db","guest","guest")
};

declare function auth:logged-in() {
    if (xmldb:get-user-groups(xmldb:get-current-user()) = ("papyri")) then true() else false()
};