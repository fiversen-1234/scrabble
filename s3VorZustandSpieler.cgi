#!/usr/bin/perl

use strict;

use FDebgCl;
use FScrabBase;
use FScrabProcess;
use FScrabSpieler;

use CGI 'param';    # beeinhaltet die Funktion param()

print "Content-type: text/html\n\n";

my $spieler  = '';
my $spielId  = '';
my $neu      = '';
my $time     = '';
if ( param('spielId') ) {
    $spielId = param('spielId');
    $neu     = param('neu');
    $time = param('time');
}

my $dbg = FDebgCl->new( 1, "dbgfiles/$spielId.s3VorZustandSpieler.dbg" );
$dbg->printdbg("-1:$spielId" );
FScrabBase::debug_move("dbgfiles/$spielId.FScrab.dbg");

my $ret  = FScrabSpieler::zustand_spieler($spielId, "1");

$dbg->printdbg("- ret:$ret");
print "$ret";

$dbg->switch(0);

exit;

