xquery version "3.0";

module namespace error="http://papyri.uni-koeln.de:8080/papyri/error";

declare variable $error:login := "LOGIN-Fehler. Bitte versuchen Sie es noch einmal.";
declare variable $error:filename := "FEHLER: Der Dateiname enthält ungültige Zeichen. Bitte nur Zahlen, Bindestriche und Unterstriche verwenden.";
declare variable $error:no-filename := "FEHLER: Bitte geben Sie einen Dateinamen ein.";
declare variable $error:file-exists := "FEHLER: Eine Datei mit diesem Dateinamen existiert bereits. Bitte wählen Sie einen neuen Namen.";
declare variable $error:delete := "FEHLER: Die Datei konnte nicht gelöscht werden. Bitte stellen Sie sicher, dass die Datei existiert und Sie berechtigt sind, sie zu löschen.";

declare function error:get-message($error as xs:string) as xs:string{
    util:eval(concat("$error:", $error))
};