#!/usr/bin/perl

use strict;

use FDebgCl;
use FScrabBase;
use FScrabProcess;
use FScrabSpieler;

use CGI 'param';    # beeinhaltet die Funktion param()

print "Content-type: text/html\n\n";

my $spieler    = '';
my $spielId    = '';
my $aktivieren = 1;
my $time     = '';
if ( param('spieler') ) {
    $spieler = param('spieler');
    $spielId = param('spielId');
    $time = param('time');
}

my $dbg = FDebgCl->new( 1, "dbgfiles/$spielId.s3Starten.dbg" );
$dbg->printdbg("-1:$spielId,$spieler" );
FScrabBase::debug_move("dbgfiles/$spielId.FScrab.dbg");

$dbg->printdbg("-2:vor kontrolle_spielId" );

my $res = '';
my $ret = '';
$res = FScrabProcess::ready_to_start($spielId,$spieler);

if ($res == 1)  {
    $dbg->printdbg("-3:vor aktviere_spieler:$spielId, $spieler, $aktivieren" );
    $res = FScrabSpieler::aktiviere_spieler($spielId, $spieler, $aktivieren);
    $dbg->printdbg("-3:res: $res" );

    # deaktivieren - dann aktiviere den nächsten
    if ($aktivieren == 0) {
        $dbg->printdbg("-4:vor aktviere_nachfolger" );
        FScrabSpieler::aktiviere_nachfolger($spielId,$spieler);
    }

    $dbg->printdbg("-5:vor zustand_spieler" );
    $ret = FScrabSpieler::zustand_spieler($spielId);
}


$dbg->printdbg("-:$res, $ret");
print "$ret";

$dbg->switch(0);

exit;

