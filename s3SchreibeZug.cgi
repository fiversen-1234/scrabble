#!/usr/bin/perl

use FDebgCl;
use FScrabBase;
use FScrabProcess;
use FScrabSpieler;
use FScrabZuegeWorte;

use CGI 'param';    # beeinhaltet die Funktion param()

print "Content-type: text/html\n\n";

my $transzug   = '';
my $spieler    = '';
my $spielId    = '';
my $time       = '';

if ( param('transzug') ) {
    $transzug  = param('transzug');
    $spieler   = param('spieler');
    $spielId   = param('spielId');
    $time      = param('time');
}

my $ dbg = FDebgCl->new( 1, "dbgfiles/$spielId.s3SchreibeZug.dbg" );
FScrabBase::debug_move("dbgfiles/$spielId.FScrab.dbg");
$dbg->switch(1);
$dbg->printdbg("-1:$spieler, $spielId, $transzug" );

my @feld = split(/,/, $transzug);
$dbg->printdbg("-2: @feld  # " . $#feld);
#print "-";
#exit;

my $anzZuege = FScrabZuegeWorte::schreibe_zug($spielId, $transzug);
$dbg->printdbg("-3:$anzZuege" );

FScrabBase::init_brett();
FScrabBase::init_feldwert();
FScrabBase::init_wortwert();

FScrabBase::get_settings_globals($spielId);
$dbg->printdbg("-3..: $FScrabBase::VielePkte $FScrabBase::SoftEnd" );

my $ret = FScrabZuegeWorte::zuege_aufs_brett($spielId, $anzZuege -1);
$dbg->printdbg("-4: ret:$ret" );
my ($sp, $worte, $bstwerte, $fldwerte, $wortwerte) = FScrabZuegeWorte::worte_aus_zug($spielId, $transzug);

$dbg->printdbg("-5: sp:$sp" );
$dbg->printdbg("-5: worte:$worte" );
$dbg->printdbg("-5: bstwerte:$bstwerte" );
$dbg->printdbg("-5: fldwerte:$fldwerte" );
$dbg->printdbg("-5: wortewerte:$wortwerte" );

my ($pkt, $worte2) = FScrabZuegeWorte::punkte_aus_zug ($sp, $worte, $bstwerte, $fldwerte, $wortwerte);
$dbg->printdbg("-6: pkt:$pkt" );
$dbg->printdbg("-6: worte2:$worte2" );

if ((($#feld - 1) / 3) > 6) {
    $pkt = $pkt + 50;
    $dbg->printdbg("-7: bonus 50 pkt:$pkt" );
}

my $pkt_old = FScrabSpieler::get_spieler_punkte($spielId,$sp);

my $ret2 = FScrabZuegeWorte::schreibe_wortzeile($spielId, $sp, $worte2, $pkt+$pkt_old);
my $ret3 = FScrabSpieler::schreibe_pkt_spieler($spielId, $sp, $pkt);

$dbg->switch(0);


print "$anzZuege";


exit;

