#!/usr/bin/perl

# detect date of last change of a file
use strict;
use AutoLoader;
use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser);
use FileHandle;
use FDebgCl;
use FSessSC;
use FScrabBase;

# variables
my $inc = 0;
my $search;
my $FileName = "datum.ttt"; 
my ($mday,$mon,$year);

my $BASEURL = "/scrab";

my $dbg = FDebgCl->new(1, "dbgfiles/spiel3.dbg");


my $r = 1;
my $c = 1;
my $MAX = 15;


FScrabBase::init_brett();
FScrabBase::init_wortwert();
FScrabBase::init_feldwert();

my $zuegelist = ''; 
my $wortelist = '';
my $storedlist = '';

# the html-page with the date
my $q = new CGI;    # create new CGI object

FSessSC::init(1);
if (FSessSC::controlSessCookie(\$q) == 0) {
	FSessSC::setSessCookie(\$q);
}

if (defined($FSessSC::FtCookie) ) {
	print $q->header(
		-xmlns=>'http://www.w3.org/1999/xhtml',
		-type=>'text/html',
		-charset=>'utf-8',
		#  -charset=>'ISO-8859-1',
		-owner=>'frank iversen',
		-link=>{-rel=>'SHORTCUT ICON', 
				-href=>'/gif/icon3.ico'},
		-link=>{-rel=>'shortcut icon',
				-type=>'image/x-icon',
				-href=>'/gif/icon3.ico'},
		-content_style_type =>'text/css',
		-content_script_type =>'text/javascript',
		#-access_control_allow_origin => 'https://amazing.site',
		#-cookie => $FSess::FtCookie ,
		-expires=>'0',
		-cookie=>$FSessSC::FtCookie);
}
else  {
	print $q->header(
		-xmlns=>'http://www.w3.org/1999/xhtml',
		-type=>'text/html',
		-charset=>'utf-8',
		#  -charset=>'ISO-8859-1',
		-owner=>'frank iversen',
		-link=>{-rel=>'SHORTCUT ICON', 
				-href=>'/gif/icon3.ico'},
		-link=>{-rel=>'shortcut icon',
				-type=>'image/x-icon',
				-href=>'/gif/icon3.ico'},
		-content_style_type =>'text/css',
		-content_script_type =>'text/javascript',
		#-access_control_allow_origin => 'https://amazing.site',
		#-cookie => $FSess::FtCookie ,
		-expires=>'0');
}

print $q->start_html(
    -title   => 'scrab - multi',    # start the HTML
    -target  => 'lastchange',
    -expires => '0',
    -style   =>{src=>'spiel.css'},
    -script  =>[
				{-language=>'JAVASCRIPT', -src=>'base.2.js'},
				{-language=>'JAVASCRIPT', -src=>'stein.2.js'},
				{-language=>'JAVASCRIPT', -src=>'bank.2.js'},
				{-language=>'JAVASCRIPT', -src=>'brett.2.js'},
				{-language=>'JAVASCRIPT', -src=>'dlg.2.js'},
				{-language=>'JAVASCRIPT', -src=>'status.2.js'},
				{-language=>'JAVASCRIPT', -src=>'zugcontrol.2.js'},
				{-language=>'JAVASCRIPT', -src=>'spiel3.2.js'}
				#{-language=>'JAVASCRIPT', -src=>'spiel3ajfuncs.js'},
				#{-language=>'JAVASCRIPT', -src=>'spiel3controlfuncs.js'}
				]
);

my $spielId = "";
my $spieler = "";
my $name    = '';
my $owner   = '';

if (param('spielId'))
{
   $spielId = param('spielId');
}
if (param('owner'))
{
   $owner = param('owner');
}
   

my $e = ""   .
	"<div id='_container_'>\n";


$e = $e .
	"<form name='BrettForm' id='_brettform' expires= '-1d' >\n";

#anmeldedlg
$name = "_owner_";
my $e_login  =    
	"<table cellspacing='5' cellpadding='5'  >\n" .
	"	<tr>" .
	"  		<td name='_ownerL_' id='_ownerL_' class='lbl' >" . "Eingeladen von:" . "</td>" .
	"  		<td>" . 
	"           <input name=$name id=$name  size='8' maxlength='8' class='spielerdis' readonly value=$owner></input>" . 
	"       </td>";

my $e_login  =    $e_login .
	"  		<td rowspan='2'>";

$name = "_mitveto_";
my $e_login  =    $e_login .
	"			<label class='lbl' title='Mitspieler k&ouml;nnen Veto einlegen.'>" .
	"              <input type='checkbox' name=$name id=$name>Veto,<small>veto</small>" .
	"           </label>" .
	"      <br/>";


$name = "_vielePkte_";
my $e_login  =    $e_login .
	"			<label class='lbl' title='Wort-/Feldwerte behalten G&uuml;ltigkeit.'>" .
	"               <input type='checkbox' name=$name id=$name>Viele Pkte<small>,VP</small>" .
	"           </label>" .
	"       <br/>";

$name = "_softEnd_";
my $e_login  =    $e_login .
	"			<label class='lbl' title='Wenn einer fertig ist, wird die Runde zuende gespielt.'>" .
	"               <input type='checkbox' name=$name id=$name>Soft Ende,<small>SE</small>" .
	"           </label>" .
	"		<br/>";


my $e_login  =    $e_login .
	"		</td>" .
	"    </tr>";


$name = '_spieler_';
$e_login = $e_login .
	" 	<tr>" .
	"  		<td name='_spielerL_' id='_spielerL_' class='lbl'>" . "Selbst:" . "</td>" .
	"  		<td>" . "<input name=$name id=$name  size='8' maxlength='8' class='spieler'> </input>" . "</td>" .
	"   </tr>";

$name = "_spielId_";
$e_login  =    $e_login  .
    "   <tr>"  .
	"  		<td name='_spielIdL_' id='_spielIdL_' class='hide' >" . "" . "</td>" .
	"  		<td>" .
	"           <input name=$name id=$name  size='8' maxlength='8' value=$spielId class='hide'></input>" .
	"       </td>"  .
	"       <td></td>" .
	"   </tr>";

$name = '_anmelden_';
$e_login = $e_login .
	"	<tr>" .
	"		<td colspan='3'>" .
	"			<button type='button' class='mybutton' name=$name id=$name /*onclick='myAnmeldeFunc()'*/>Anmelden</button>\n";

$name = "_starte_";
$e_login = $e_login .
	"			<button type='button' class='mybuttondis' name=$name id=$name  /*onclick='myStarteFunc()' */>Starte</button>\n";

$name = "_multi_";
$e_login = $e_login .
	"			<button type='button' class='mybuttondis' name=$name id=$name  /*onclick='myMultiFunc()'*/>-</button>\n";

$e_login = $e_login .
	"		</td>\n" .
	"	</tr>" .
	"</table>\n";

$name = "_storedLbl_";	
$e_login = $e_login .
	"<span id=$name name=$name class='listlbl'>Gespeicherte Spiele</span>\n";
$name = "_stored_";	
$e_login = $e_login .
	"<select id=$name name=$name class='scrolldiv' size='8'></select>\n";


#ameldedlg II
$name = "_spieler_";
my $e_loginII  =    #anmeldedlgII
	"<table cellspacing='2' cellpadding='2'  >\n" .
	"	<tr>" .
	"  		<td name='_spielerL_' id='_spielerL_' class='lbl' title='Name'>" . "Selbst:" . "</td>" .
	"  		<td>" . 
	"           <input name=$name id=$name type='text'  placeholder='eigen. name'  size='8' maxlength='8' class='spieler'></input>" . 
	"       </td>";

$name = "_spielId_";
$e_loginII  =    $e_loginII  .
	"  		<td name='_spielIdL_' id='_spielIdL_' class='hide' >" . "" . "</td>" .
	"  		<td>" .
	"           <input name=$name id=$name  size='8' maxlength='8' class='hide'></input>" .
	"       </td>";

$e_loginII  =  $e_loginII .
	"   </tr>";


my $txt = 'Email Adresse vom Mitspieler';
$e_loginII = $e_loginII .
 	" 	<tr>" .
 	"  		<td name='_spielerL_' id='_spielerL_' valign='top' class='lbl' title=$txt>Mitspieler:</td>" .
    "		<td colspan='3'>";

$name = '_mitspielerAdr1_';
$txt  = '1.Mitspieler-Email';
$e_loginII = $e_loginII .
    "<ul id='mitspielerUL'> ".
    " <li> ".
 	"  <span class='mitspielerClose_sign'>" .
 	"   <input type='email' placeholder=$txt name=$name id=$name  size='25' maxlength='50' class='spieler'> </input>" .
 	"  </span> ";

$name = '_mitspielerAdr2_';
$txt  = '2.Mitspieler-Email';
$e_loginII = $e_loginII .
    "	 <ul class='mitspielerNested'> ".
    "     <li>" .
 	"       <span class='mitspielerClose_sign'>" .
 	"        <input type='email' placeholder=$txt name=$name id=$name  size='25' maxlength='50' class='spieler'> </input>" .
 	"       </span>";

$name = '_mitspielerAdr3_';
$txt  = '3.Mitspieler-Email';
$e_loginII = $e_loginII .
    "     	<ul class='mitspielerNested'> " .
    "        <li><span class='mitspielerEnd_sign'><input type='email' placeholder=$txt name=$name id=$name  size='25' maxlength='50' class='spieler'> </input></span>" .
    "        </li> ".
    "       </ul> " .
    "     </li>" .
    "   </ul>" .
    "  </li>".
    "</ul>";

$e_loginII = $e_loginII .
	"		</td>".
	"   </tr>";

	
$name = "_mitveto_";
$e_loginII  =    $e_loginII .
	"     <td colspan='4'> ".
	"       <table> ".
	"        <tr> "  .
	"         <td valign='top' name='_optionenL_' id='_optionenL_' class='lbl'> Optionen: </td>" .
	"         <td> " .
	"            <label class='lbl' title='Mitspieler k&ouml;nnen Veto einlegen.'>" .
	"              <input type='checkbox' name=$name id=$name>Veto,<small>veto</small>" .
	"            </label>" .
	"            <br/>";


$name = "_vielePkte_";
$e_loginII  =    $e_loginII .
	"			 <label class='lbl' title='Wort-/Feldwerte behalten G&uuml;ltigkeit.'>" .
	"              <input type='checkbox' name=$name id=$name>Viele Pkte<small>,VP</small>" .
	"            </label>" .
	"            <br/>";

$name = "_softEnd_";
$e_loginII  =    $e_loginII .
	"			 <label class='lbl' title='Wenn einer fertig ist, wird die Runde zuende gespielt.'>" .
	"             <input type='checkbox' name=$name id=$name>Soft Ende,<small>SE</small>" .
	"            </label>" .
	"	       </td>" .
	"         </tr>" .
	"       </table>" .
	"     </td>"  .
	"    </tr>";


$name = '_anmelden_';
$e_loginII = $e_loginII .
	"	<tr>" .
	"		<td colspan='4'>" .
	"			<button type='button' class='mybutton' name=$name id=$name /*onclick='myAnmeldeFunc()'*/>Einladen</button>\n";

$name = "_starte_";
$e_loginII = $e_loginII .
	"			<button type='button' class='mybuttondis' name=$name id=$name  /*onclick='myStarteFunc()' */>Starte</button>\n";

$name = "_multi_";
$e_loginII = $e_loginII .
	"			<button type='button' class='mybuttondis' name=$name id=$name  /*onclick='myMultiFunc()'*/>-</button>\n";

$e_loginII = $e_loginII .
	"		</td>\n" .
	"	</tr>" .
	"</table>\n";

$name = "_storedLbl_";	
$e_loginII = $e_loginII .
	"<span id=$name name=$name class='listlbl'>Gespeicherte Spiele</span>\n";
$name = "_stored_";	
$e_loginII = $e_loginII .
	"<select id=$name name=$name class='scrolldiv' size='8'></select>\n";

#ameldedlg




## Fehler/Warning...dialog
#html5
my $e_dlg_ = 
	"<dialog id='dlg' name='dlg' >" .
	"<big><lable name='_dlgtitle_' id='_dlgtitle_'> Meldung </label></big>"  .
	"<form <form method='post'>" .
	"  <lable name='_dlgtext_' id='_dlgtext_'>" . "</label><br/>" .
	"  <input name='_dlginput_' id='_dlginput_'  size='8' maxlength='8' class='spieler'> </input>" .
	"</form>" .
	"<p>" .
	"  <button type='button' class='likebut' name='_dlgok_' id='_dlgok_' onclick='myDlgFunc()'>OK</button>\n" .
	"</p>" .	
	"</dialog>";

#no html5
my $e_dlg = 
	"<div id='dlg' name='dlg' class='overlayHidden'>" .
	"<big><lable name='_dlgtitle_' id='_dlgtitle_'> Meldung </label></big>"  .
	" <p>" .
	"  <label name='_dlgtext_' id='_dlgtext_'>" . "</label><br/>" .
	"  <input type='text' name='_dlginput_' id='_dlginput_'  size='8' maxlength='8' />" .
	" </p>" .
	" <p>" .
	"  <button type='button' class='likebut' name='_dlgok_' id='_dlgok_' onclick='dlgO.myDlgFunc()' >OK</button>\n" .
	"  <button type='button' class='likebut' name='_dlgcancel_' id='_dlgcancel_' onclick='dlgO.myDlgCancel()' >Cancel</button>\n" .
	" </p>" .
	"</div>";




$e = $e .
	"<table class='all'  id='table_all'  >\n"  .
	"<tr><td>\n" .
	"<table class='brett' id='table_brett' border=1 > \n";

#  [0/0]   1................15   [0/16]
#          [01/01]     [01/15]
#          ...................
#          [15/01]     [15/15]
#  [0/16]  1................15   [16/16]

my $row = 0;
my $col = 0;
for ($row = 1; $row < 16; $row = $row + 1)  {
	$e = $e . "<tr>\n";
	for ($col = 1; $col < 16; $col = $col + 1)  {			
		$name    = "_brett_" . $row . "_" . $col . "_";
		my $namei = $name . "i";

		my $classTd = FScrabBase::feldstyle($row,$col);

		$dbg->printdbg("classTd $row,$col: $classTd");
		my $buch  = FScrabBase::buchstabe_brett($row, $col);
		my $classIn = $classTd;
		if ($buch ne '.') {
			$classIn = "stein";
		}
		my $center = 0;
		if ($row == 8 && $col == 8) {
			$center = 1;
		}
		my $imgsrc = FScrabBase::svg_inline_img($buch,$center);
		$dbg->printdbg("classIn $row,$col: $name, $classIn");
		$e = $e .  
			"<td name=$name id=$name class=$classTd  >" .
			"<img name=$buch id=$namei  src=$imgsrc class='svg_feld' " .
			"       onclick='myBrettFunc($row,$col)' />" .
			"</td>\n";
	}
	$e = $e . "</tr>\n";
}
$e = $e .
	"</table> \n".     #table_brett
	$e_dlg .
	"</td>\n" .
	#"<td> &nbsp;&nbsp; </td>\n" .
	"<td valign='bottom'><small><small>B<br/>R<br/>E<br/>T<br/>T</small></small></td>" .
	"<td valign='top'>\n";
	#"<td>\n";


$name = "-";
##if (defined($FSessSC::FtCookie) ) {
##	$name = "+";
##}
if (length($spielId) > 0) {
	$name = "+";
}

$e = $e .
	"<p>" .
	"<span name='_AktivL_' id='_AktivL_' class='lbl'>AKTIV:</span>" . "&nbsp;&nbsp;"  .
	"<span id='_spieler1_' name='_spieler1_' class='spielerinaktiv'>.</span>" . "&nbsp;&nbsp;" .
	"<span id='_spieler2_' name='_spieler2_' class='spielerinaktiv'>.</span>" . "&nbsp;&nbsp;" .
	"<span id='_spieler3_' name='_spieler3_' class='spielerinaktiv'>.</span>" . "&nbsp;&nbsp;" .
	"<span id='_spieler4_' name='_spieler4_' class='spielerinaktiv'>.</span>" . "&nbsp;&nbsp;" .
	"<span id='_spielIdCopy_' name='_spielIdCopy_' class='spielerinaktiv'>$name</span>" .
	"</p>";



$name = "_aktzuglbl_";	
my $e_zuege_worte = 
	"<span id=$name name=$name class='listlbldis'>Zug:</span> ";
$name = "_aktzug_";	
$e_zuege_worte = $e_zuege_worte .
	"<span id=$name class=$name class='aktzug'></span>\n";

$name = "_zuege_";	
$e_zuege_worte = $e_zuege_worte .
    "<div id=$name name=$name class='scrolldivdis'>$zuegelist</div>\n";

$name = "_wortelbl_";	
$e_zuege_worte = $e_zuege_worte .
	"<span id=$name name=$name class='listlbldis'>Worte</span>\n";
$name = "_worte_";	
$e_zuege_worte = $e_zuege_worte .
	"<div id=$name name=$name class='scrolldivdis'>$wortelist</div>\n";


$name = "_aktChat_";	
my $e_chat = 
	"<span id=$name name=$name class='listlbldis'>Chat&gt;:</span> ";
$name = "_chat_";	
$e_chat = $e_chat .
	"<span id=$name class=$name class='chat'></span>\n";

$name = "_oldchat_";	
$e_chat = $e_chat .
    "<small><div id=$name name=$name class='scrolldivlong'></div></small>\n";


my $e_info = 
	"<table>";

	$name    = "_brett_1_2_";
	my $namei = $name . "i";
	my $classTd = FScrabBase::feldstyle(1,2);
	my $buch  = ".";
	my $classIn = $classTd;
	my $imgsrc = FScrabBase::svg_inline_img($buch,0);
	$e_info = $e_info .  
	"<tr>" .
		"<td><small><b>Wortwert</b></small></td><td><small>=1</small></td>\n"  .
		"<td name=$name id=$name class=$classTd>" .
	     "<img name=$buch id=$namei  src=$imgsrc class='svg_feld_info' />" .
		"</td>" .
		"<td>&nbsp;&nbsp;&nbsp;&nbsp;</td>" .
		"<td name=$name id=$name class=$classTd>" .
	     "<img name=$buch id=$namei  src=$imgsrc class='svg_feld_info' />" .
		"</td>" .
		"<td><small>1=</small></td><td><small><b>Feldwert</b></small></td>\n"  .
	"</tr>\n";

	$name    = "_brett_2_2_";
	$namei = $name . "i";
	$classTd = FScrabBase::feldstyle(2,2);
	$buch  = ".";
	$classIn = $classTd;
	$imgsrc = FScrabBase::svg_inline_img($buch,0);
	$e_info = $e_info .  
	"<tr>" .
		"<td></td><td><small>*2</small></td>\n"  .
		"<td name=$name id=$name class=$classTd  >" .
	    	"<img name=$buch id=$namei  src=$imgsrc class='svg_feld_info' />" .
		"</td>" .
		"<td>&nbsp;&nbsp;&nbsp;&nbsp;</td>" ;

	$name    = "_brett_1_4_";
	$namei = $name . "i";
	$classTd = FScrabBase::feldstyle(1,4);
	$buch  = ".";
	$classIn = $classTd;
	$imgsrc = FScrabBase::svg_inline_img($buch,0);
	$e_info = $e_info .  
		"<td name=$name id=$name class=$classTd >"  .
	    	"<img name=$buch id=$namei  src=$imgsrc class='svg_feld_info' />" .
		"</td>"  .
		"<td><small>*2</small></td><td></td>\n"  .
	"</tr>\n";

	$name    = "_brett_1_1_";
	$namei = $name . "i";
	$classTd = FScrabBase::feldstyle(1,1);
	$buch  = ".";
	$classIn = $classTd;
	$imgsrc = FScrabBase::svg_inline_img($buch);
	$e_info = $e_info .  
	"<tr>" .
		"<td></td><td><small>*3</small></td>\n"  .
		"<td name=$name id=$name class=$classTd  >" .
	    	"<img name=$buch id=$namei  src=$imgsrc class='svg_feld_info' />" .
		"</td>" .
		"<td>&nbsp;&nbsp;&nbsp;&nbsp;</td>";


	$name    = "_brett_6_2_";
	$namei = $name . "i";
	$classTd = FScrabBase::feldstyle(6,2);
	$buch  = ".";
	$classIn = $classTd;
	$imgsrc = FScrabBase::svg_inline_img($buch,0);
	$e_info = $e_info .  
		"<td name=$name id=$name class=$classTd  >" .
	    	"<img name=$buch id=$namei  src=$imgsrc class='svg_feld_info' />" .
		"<td><small>*3</small></td><td></td>\n"  .
	"</tr>\n" .
	"</table>\n";


	$e_info = $e_info .  
	"<div style='height:400px; width:340px; border:2px solid grey; overflow:auto;'>" .
	#"<ul style='margin-left:-20px;'>" .
	"<dl>" .
	"<small>" .
		#"<li style='padding:0; margin:0;'>" .
		"<dt>Buchstaben setzen</dt>" .
		"<dd style='margin-left:15px;'>Bank: Buchstabe anklicken (markiert).<br/>" .
		"Brett: Zielfeld anklicken.<br/>" .
		"Neue Buchstaben werden <span style='color:red;'><b>'rot'</b></span> dargestellt." .
		"</dd>" .
		"<dt style='padding-top:3px;'>Zug abschliessen</dt>" .
		"<dd style='margin-left:15px;'>Nach dem Setzen der Buchstaben, schliesst ein Spieler den Zug " .
		"mit <b>[Fertig]</b> ab.<br/>" .
		"Dann <br/>" .
		".gibt es neue Buchstaben,<br/>" .
		".der n&auml;chse ist dran." .
		"</dd>" .
		"<dt style='padding-top:3px;'>Buchstaben tauschen</dt>" .
		"<dd style='margin-left:15px;'>Wurde noch kein Stein ber&uuml;hrt, kann mit <b>[Tausche]</b>, " .
		"anklicken der zu tauschenden Buchstaben  und <b>[Fertig]</b> " .
		"Buchstaben getauscht werden. Danach ist <br/>" . 
		".der n&auml;chse dran." .
		"</dd>" .
		"<dt style='padding-top:3px;'>Buchstaben ordnen</dt>" .
		"<dd style='margin-left:15px;'>Bank: die zu tauschenden Buchstaben nacheinander anklicken." .
		"</dd>" .
		"<dt style='padding-top:3px;'>Schieben</dt>" .
		"<dd style='margin-left:15px;'>Ein Spieler tauscht und setzt nichts und aktiviert [Fertig] - der n&auml;chste ist dran." .
		"</dd>" .
		"<dt style='padding-top:3px;'>Spielende</dt>" .
		"<dd style='margin-left:15px;'>Voraussetzung f&uuml;rs Spielende ist ein leerer Beutel.<br/>." .
		"Das Spiel ist zu Ende wenn alle Spieler geschoben haben.<br/>" .
		"Oder direkt nachdem ein Spieler alle Steine gesetz hat, Option 'SoftEnd' nicht gesetzt.<br/>" .
		"Andernfalls wird die Runde noch zuende gespielt." .
		"</dd>" .
		"<dt style='padding-top:3px;'>Weitere Optionen</dt>" .
		"<dd style='margin-left:15px;'>Wenn ein Spieler eine Option w&auml;hlt, ".
		"so gilt diese f&uuml;r alle." .
		"</dd>" .
		"<dt style='padding-top:3px;'>Option: Veto</dt>" .
		"<dd style='margin-left:15px;'>Nachdem ein Spieler seinen Zug mit <b>[Fertig]</b> abgeschlossen hat," .
		"gibt es eine kurze Zeitspanne, " .
		"in der ein anderer Spieler <b>[Veto?]</b> einlegen kann.<br/>" .
		"Bei Veto - muss der Spieler die Buchstaben ver&auml;ndern und ".
		"erneut den Zug abschliessen".
		"</dd>" .
		"<dt style='padding-top:3px;'>Option: Viele Punkte</dt>" .
		"<dd style='margin-left:15px;'>Die Feld- und Wortwerte behalten G&uuml;ltigkeit - nicht nur der erste, der die Felder nutzt" .
		"erh&auml;lt die Sonderpunkte." .
		"</dd>" .
		"<dt style='padding-top:3px;'>Spiel speichern</dt>" .
		"<dd style='margin-left:15px;'>Mit <b>[Speichern]</b> kann das Spiel gespeichert werden, um irgendwann sp&auml;ter das Spiel" .
		"weiter zu spielen." .
		"</dd>" .
		"<dt style='padding-top:3px;'>Spiel laden</dt>" .
		"<dd style='margin-left:15px;'>In der der Liste der 'Gespeicherten Spiele' werden die gesicherten Spiele aufgelistet." .
		"Vor Spielbeginn kann ein Spiel zum weiter spielen geladen werden." .
		"Dazu das Spiel in der Liste markieren, den 'Spieler' eintragen und <b>[Laden]</b> aktivieren. Dann wird das Passwort abgefragt." .
		"Wenn alle Spieler das Spiel geladen haben - kann weitergespielt werden." .
		"</dd>" .
		"<dt style='padding-top:3px;'>Kontakt: fiversen<img src='../gif/at.jpg'  style='vertical-align:middle'/>wedding.in-berlin.de </dt>" .
		"<dd></dd>" .

	"</small>" .
	"</dl>" .
	"</div>";


my $st =  "writing-mode: vertical-rl;
    -ms-transform: rotate(180deg);
    -moz-transform: rotate(180deg);
    -webkit-transform: rotate(180deg);
    transform: rotate(180deg);
    vertical-align: middle;
    font-weight: 500;
    word-break: break-word;
    height: inherit;
    width: inherit;
	font-family:monospace;";
 

my $bank = 
	"<p>" .
	"<table>" .
	#"<tr>" .
	#"	<td colspan='7' align='left'><small>Bank</small></td>" .
	#"</tr>" .
	" <tr>" .
	"  <td>" .
	"   <table>" .
	"    <tr>";

my $steine = ".,.,.,.,.,.,.";
	my @list   = split(/\,/, $steine);
	$dbg->printdbg("steine: $steine");
	for ($col = 0; $col < 7; $col = $col + 1)  {
		my $name  = "_bank_" . $col . "_";
		my $nameI = "_bank_" . $col . "_i";
		my $value= $list[$col];
		my $imgsrc = FScrabBase::svg_inline_img($value,0);
		$bank = $bank .  
			"<td id=$name class='leerebank' >" . 
			"<img name=$value id=$nameI title='.' src=$imgsrc  ".
			"     class='svg_feld' onclick='myBankFunc($col)' />" .
			"</td>\n";
	}
$bank = $bank .  
	#"<td><span style='$st'><small>Bank</small></span></td>" .
	"    </tr>" .
	"   </table>" .
	"  </td>" .
	"  <td><small><small>B<br/>A<br/>N<br/>K</small></small></td>" .
	" </tr>" .
	"</table>" .
	"</p>";

$e = $e .
	$bank;

my $buttable = 
	"<table><tr>";

my $name = "_undo_";
$buttable = 
	$buttable .
	"<td >" .
		"<button type='button' class='mybuttondis' name=$name id=$name  onclick='myUndoFunc()'>Undo</button>\n" .
	"</td>\n";

$name = "_tausche_";
$buttable = 
	$buttable .
	"<td >" .
		"<button type='button' class='mybuttondis' name=$name id=$name onclick='myTauscheFunc()' >Tausche</button>\n" .
	"</td>\n";

$name = "_fertig_";
$buttable = 
	$buttable .
	"<td >" .
		"<button type='button' class='mybuttondis' name=$name id=$name onclick='myFertigFunc()' >Fertig</button>\n" .
	"</td>\n";

$name = "_veto_";
$buttable = 
	$buttable .
	"<td >" .
		"<button type='button' class='mybuttondis' name=$name id=$name onclick='myVetoFunc()' >Veto ?</button>\n" .
	"</td>\n";

$buttable = 
	$buttable .
	"</tr></table></p>";

$e = $e .
	$buttable;

my $dlgtable = 
	"<table cellpadding='0' cellspacing='0' border='0' width='380px'  style='margin-top:5px;z-index:-1;'> \n" ;

my $dlgtabs = 
	"<tr> \n".
		"<td style='width:10px;'></td> \n" ;

$name = 'dat';
$dlgtabs = 
	$dlgtabs .
		"<td id='but_$name' class='normtab' align='center' onclick=ShowDiv('$name') > " .
			"&nbsp;Daten&nbsp;\n" .
		"</td>\n" .
		"<td style='width:10px;'></td> \n";

$name = 'chat';
$dlgtabs = 
	$dlgtabs .
		"<td id='but_$name' class='normtab' align='center' onclick=ShowDiv('$name') > " .
			"&nbsp;Debug&nbsp;\n" .
		"</td>\n" .
		"<td style='width:10px;'></td> \n";
	
$name = 'info';
$dlgtabs = 
	$dlgtabs .
		"<td id='but_$name' class='normtab' align='center' onclick=ShowDiv('$name')> " .
			"&nbsp;Info-Hilfe&nbsp;\n"  .
		"</td> \n" .
		"<td style='width:10px;'></td> \n" ;

$name = 'login';
$dlgtabs = 
	$dlgtabs .
		"<td id='but_$name' class='marktab' align='center' onclick=ShowDiv('$name')> " .
			"&nbsp;Start-Anmeldung&nbsp;\n"  .
		"</td> \n" .
		"<td style='width:30px;'></td> \n" .
	"</tr>\n";

       
my $dlgcontent = 
	"<tr> \n" .
		"<td colspan='9' > \n" ;


$name = 'dat';
$dlgcontent = 
	$dlgcontent .
		"<div id='div_$name' style='visibility:hidden;' height='390px' width='360px'>" .
			$e_zuege_worte .
		"</div>";

$name = 'chat';
$dlgcontent = 
	$dlgcontent .
		"<div id='div_$name' style='visibility:hidden;' height='390px' width='360px'>" .
			$e_chat .
		"</div> \n" ;

$name = 'info';
$dlgcontent = 
	$dlgcontent .
		"<div id='div_$name' style='visibility:hidden;' height='390px' width='360px'>" .
			$e_info .
		"</div> \n";

$name = 'login';
$dlgcontent = 
	$dlgcontent .
		"<div id='div_$name' style='visibility:visible;' height='390px' width='360px'>";
if (length($spielId) > 0) {
	$dlgcontent = 
		$dlgcontent .
		$e_login .
		"</div> \n" ;
}
else  {
	$dlgcontent = 
		$dlgcontent .
		$e_loginII .
		"</div> \n" ;
}

$dlgcontent = 
	$dlgcontent .
		"</td> \n".
	"</tr> \n" ;       

$dlgtable = 
	$dlgtable .
	$dlgtabs .
	$dlgcontent .
	"</table> \n";

$e = 
	$e .
	$dlgtable;


$e = $e .
	"</td>\n" .
	"</tr>\n" .
	"</table>\n";


#$e = $e . $e_dlg;

$e = $e .
	"</form> \n";

$e = $e .
	"</div> \n";



print $e;

print $q->end_html();

