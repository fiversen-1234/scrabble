#!/usr/bin/perl

use FDebgCl;
use FScrabBase;
use FScrabProcess;
use FScrabZuegeWorte;
use FScrabMulti;

use CGI 'param';    # beeinhaltet die Funktion param()

print "Content-type: text/html;charset=utf-8\n\n";

my $mode       = '';
my $spieler    = '';
my $spielId    = '0';
my $passwd     = '';
my $storedname = '';
my $time       = '';
if ( param('mode') ) {
    $mode       = param('mode');
    $spieler    = param('spieler');
    $spielId    = param('spielId');
    $passwd     = param('passwd');
    $storedName = param('storedName');
    $time = param('time');
}

my $ret = 0;
my $dbg = FDebgCl->new( 1, "dbgfiles/$spielId.s3Multi.dbg" );
$dbg->printdbg("-1:$mode,$spieler,$spielId,$passwd,$storedName");
FScrabBase::debug_move("dbgfiles/$spielId.FScrab.dbg");

if ($mode eq "speichern") {
    $dbg->printdbg("-vor Speichern" );
    $ret = FScrabMulti::Speichern($spielId, $passwd);
    $dbg->printdbg("--nach..:$ret" );
}
if ($mode eq "holestored") {
    $dbg->printdbg("-vor StoredList");
    $ret = FScrabMulti::StoredList();
    $dbg->printdbg("--nach..:$ret" );
}
if ($mode eq "laden") {
    $dbg->printdbg("-vor Laden");
    my ($err, $spielId) = FScrabMulti::Laden($spieler, $passwd, $storedName);
    $ret = "$err#$spielId";
    $dbg->printdbg("--nach..:$ret" );
}
if ($mode eq "loadall") {
    ##lade 
    # - bank
    # - worte
    # - zuege
    # - aktionen
    my $wortzeilennr = 0;
    my $aktionsnr    = 0;
    $dbg->printdbg("-vor loadall");
    my $bank     = FScrabProcess::lese_bank($spielId, $spieler);
    $dbg->printdbg("-bank:$bank" );
    my $zuege    = FScrabZuegeWorte::leseLetzten_zug($spielId, $wortzeilennr);
    $dbg->printdbg("-zuege:$zuege" );
    my $worte    = FScrabZuegeWorte::leseLetzte_wortzeile($spielId, $wortzeilennr);
    $dbg->printdbg("-worte:$worte" );
    my $aktionen = FScrabProcess::lese_legeBuchstaben($spielId, $aktionsnr);
    $dbg->printdbg("-aktionen:$aktionen" );
    $ret = "$bank#$zuege#$worte#$aktionen";
}
if ($mode eq "allloaded") {
    $ret = FScrabMulti::AllLoaded($spielId);
}
my $all = "$mode#$ret";
$dbg->printdbg("-all:$all");

print "$all";

$dbg->switch(0);

exit;

