#!/usr/bin/perl

use FDebgCl;
use FScrabBase;
use FScrabProcess;

use CGI 'param';    # beeinhaltet die Funktion param()

print "Content-type: text/html\n\n";

my $x           = '';
my $y           = '';
my $buchstabe   = '';
my $aktionsnr   = '';
my $clname      = '';
my $spieler     = '';
my $spielId     = '';
my $time        = '';

if ( param('buchstabe') ) {
    $x         = param('x');
    $y         = param('y');
    $buchstabe = param('buchstabe');
    $aktionsnr = param('aktionsnr');
    $clname    = param('clname');
    $spieler   = param('spieler');
    $spielId   = param('spielId');
    $time      = param('time');
}

my $ dbg = FDebgCl->new( 1, "dbgfiles/$spielId.s3SchreibeLegeBuchstabe.dbg" );
$dbg->printdbg("-1:$x,$y,$buchstabe,$aktionsnr,$spieler,$spielId" );
FScrabBase::debug_move("dbgfiles/$spielId.FScrab.dbg");


my $ok = FScrabProcess::schreibe_legeBuchstabe($spielId,$spieler,$x,$y,$buchstabe,$aktionsnr,$clname);
$dbg->printdbg("-3:$ok" );
print "$ok";

$dbg->switch(0);

exit;

