#!/usr/bin/perl

use FDebgCl;
use FScrabBase;
use FScrabProcess;
use FScrabSpieler;
use FScrabEnd;

use CGI 'param';    # beeinhaltet die Funktion param()

print "Content-type: text/html\n\n";

my $spieler    = '';
my $spielId    = '1';
my $aktivieren = 0;
my $geschoben  = 0;
#my $bank       = '';
my $time     = '';
if ( param('spieler') ) {
    $spieler = param('spieler');
    $spielId = param('spielId');
    $aktivieren = param('aktivieren');
    $geschoben = param('geschoben');
    #$bank = param('bank');
    $time = param('time');
}

my $dbg = FDebgCl->new( 1, "dbgfiles/$spielId.s3Aktiviere.dbg" );
$dbg->printdbg("-1:$spielId,$spieler,$aktivieren,$bank" );
FScrabBase::debug_move("dbgfiles/$spielId.FScrab.dbg");

if ($geschoben eq '1') {
    $dbg->printdbg("--:schreibe geschoben" );
    my $sret = FScrabProcess::schreibe_geschoben($spielId,$spieler);
    $dbg->printdbg("-sret:$sret" );
}


## pruefe ob ENDE ?
my $ret = '';
if (FScrabEnd::SpielZuEnde($spielId)) {
    $ret = FScrabSpieler::zustand_spieler($spielId);
    print "$ret";
    $dbg->switch(0);
    exit;
}

## lese <spielId>.bank.txt
## bei 
## - hartem Ende  
##     ein spieler blank (nur '-')
## - softes Ende
##     ein spieler blank, alle anderen schieben
## - lahmes Ende
##     alle spieler haben buchstaben und schieben
## -> dann 
##    <spielId>.ende.txt  erstellen per  touch
##    alle spieler auf nicht aktiv setzen
##    endAbrechnung = 1
my $endAbrechnung = 0;
my $eret = FScrabEnd::SpielerZuegeZuEnde($spielId);
$dbg->printdbg("-eret:$eret" );
if ($eret > 0) {
    FScrabBase::get_settings_globals($spielId);
    ## hartes Ende
    if (($FScrabBase::SoftEnd eq '0'  &&  $eret == 1) ||     # hartes Ende
        ($FScrabBase::SoftEnd eq '1'  &&  $eret == 2) ||     # softes Ende 
        ($eret == 3)                                )    # lahmes Ende - alle schieben    
    {
        $dbg->printdbg("---vor SetSpielZuEnde" );
        FScrabEnd::SetSpielZuEnde($spielId);
        $dbg->switch(1);
        $endAbrechnung = 1;
    }
}
$dbg->printdbg("-:endAbrechnung:$endAbrechnung" );

## normales 
##    nur wenn endAbbrechung==0
if ($endAbrechnung == 0) 
{
    #if ($geschoben eq '1') {
    #    $dbg->printdbg("--:schreibe geschoben" );
    #    my $sret = FScrab::schreibe_geschoben($spielId,$spieler);
    #    $dbg->printdbg("-sret:$sret" );
    #}

    $dbg->printdbg("-2:vor aktviere_spieler" );
    my $res = FScrabSpieler::aktiviere_spieler($spielId, $spieler, $aktivieren);
    $dbg->printdbg("-2:nach aktviere_spieler" );

    # deaktivieren - dann aktiviere den nächsten
    if ($aktivieren == 0) {
        $dbg->printdbg("-..:vor aktviere_nachfolger" );
        FScrabSpieler::aktiviere_nachfolger($spielId,$spieler);
        $dbg->printdbg("-..:nach aktviere_nachfolger" );
        
        my $fn = "data/$spielId.info.neu.txt";
        if (-e $fn) {
            system("rm $fn");
        }
    }
}

##kontrol auf Spiel-ENDE
## nur wenn endAbbrechung==1
##wenn ENDE
## - auswertung
##!! - bank buchstaben abziehen
if ($endAbrechnung == 1)  {
    $dbg->switch(1);
    $dbg->printdbg("-vor EndAbrechnung");
    my $aret = FScrabEnd::EndAbrechnung($spielId);
    $dbg->printdbg("--aret:$aret" );
}


$dbg->printdbg("-3:vor zustand_spieler" );
my $ret = FScrabSpieler::zustand_spieler($spielId);



$dbg->printdbg("-:$res, $ret");
print "$ret";

$dbg->switch(0);

exit;

