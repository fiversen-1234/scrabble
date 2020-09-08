#!/usr/bin/perl

use FDebgCl;
use FScrabBase;
use FScrabProcess;

use CGI 'param';    # beeinhaltet die Funktion param()

print "Content-type: text/html;charset=utf-8\n\n";

my $dbg2 = FDebgCl->new( 1, "dbgfiles/s3VetoDatei.dbg" );
$dbg2->printdbg("s3VetoDatei");
$dbg2->switch(0);


my $aktion   = '';
my $spieler  = '';
my $spielId  = '';
my $time     = '';
if ( param('aktion') ) {
    $aktion  = param('aktion');
    $spieler = param('spieler');
    $spielId = param('spielId');
    $time = param('time');
}

my $dbg = FDebgCl->new( 1, "dbgfiles/$spielId.s3VetoDatei.dbg" );
$dbg->printdbg("-1:$aktion,$spieler,$spielId" );
FScrabBase::debug_move("dbgfiles/$spielId.FScrab.dbg");

my $ret = FScrabProcess::vetoDatei_aktionen($spielId, $spieler, $aktion);
$dbg->printdbg("ret:$ret" );
print "$ret";

$dbg->switch(0);

exit;

