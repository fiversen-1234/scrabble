#!/usr/bin/perl

use FDebgCl;
use FScrabBase;
use FScrabProcess;

use CGI 'param';    # beeinhaltet die Funktion param()

print "Content-type: text/html;charset=utf-8\n\n";

my $bank     = '';
my $anzahl   = '';
my $spieler  = '';
my $spielId  = '1';
my $time     = '';
if ( param('spielId') ) {
    $spielId = param('spielId');
    $spieler = param('spieler');
    $bank    = param('bank');
    $anzahl  = param('anzahl');
    $time = param('time');
}

my $dbg = FDebgCl->new( 1, "dbgfiles/$spielId.s3FulleBank.dbg" );
$dbg->printdbg("-1:$spielId,$spieler,$bank,$anzahl" );
FScrabBase::debug_move("dbgfiles/$spielId.FScrab.dbg");

$dbg->printdbg("-:bank:$bank  anz:$anzahl");

my $beutel = FScrabBase::hole_beutel($spielId);
$dbg->printdbg("-2:$beutel" );
my $steine = "-";
if ($beutel ne "-")  {
    $steine = FScrabBase::gebesteine_beutel($anzahl, $beutel, $spielId);
}
$dbg->printdbg("-3:>$steine<" );

#my $st = $steine;
#$st =~ s/\,//g;
#$bank = $bank . $st;
$bank = $bank . $steine;

$dbg->printdbg("--:schreibe bank:$bank");
my $bret = FScrabProcess::schreibe_bank($spielId,$spieler,$bank);
$dbg->printdbg("-bret:$bret" );

print "$steine";
$dbg->switch(0);

exit;

