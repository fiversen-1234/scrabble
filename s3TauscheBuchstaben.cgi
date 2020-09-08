#!/usr/bin/perl

use FDebgCl;
use FScrabBase;

use CGI 'param';    # beeinhaltet die Funktion param()

print "Content-type: text/html;charset=utf-8\n\n";

my $bsts     = '';
my $spieler  = '';
my $spielId  = '';
my $time     = '';
if ( param('bsts') ) {
    $bsts  = param('bsts');
    $spieler = param('spieler');
    $spielId = param('spielId');
    $time = param('time');
}

my $dbg = FDebgCl->new( 1, "dbgfiles/$spielId.s3TauscheBuchstaben.dbg" );
$dbg->printdbg("-1:$bsts,$spieler,$spielId" );
FScrabBase::debug_move("dbgfiles/$spielId.FScrab.dbg");

my $beutel = FScrabBase::hole_beutel($spielId);
$dbg->printdbg("-2:$beutel" );
my $ret = FScrabBase::buchstaben_in_den_beutel($bsts,$beutel,$spielId);

#my $beutel = FScrab::hole_beutel($spielId);
#$dbg->printdbg("-2:$beutel" );
#my $steine = FScrab::gebesteine_beutel($anzahl, $beutel, $spielId);
#$dbg->printdbg("-3:$steine" );
#print "$steine";

$dbg->switch(0);

exit;

