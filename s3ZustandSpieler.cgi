#!/usr/bin/perl

use strict;
use FDebgCl;
use FScrabBase;
use FScrabProcess;
use FScrabSpieler;

use CGI 'param';    # beeinhaltet die Funktion param()

print "Content-type: text/html\n\n";

my $spieler   = '';
my $spielId   = '';
my $aktionsnr = '';
my $time      = '';
if ( param('spielId') ) {
    $spielId   = param('spielId');
    $aktionsnr = param('aktionsnr');
    $time      = param('time');
}

my $dbg = FDebgCl->new( 1, "dbgfiles/$spielId.s3ZustandSpieler.dbg" );
$dbg->printdbg("-1:$spielId" );
FScrabBase::debug_move("dbgfiles/$spielId.FScrab.dbg");

if   (-e "data/$spielId.aktionen.txt")  {}
else { system("touch data/$spielId.aktionen.txt"); }

my $ret  = FScrabSpieler::zustand_spieler($spielId);
$dbg->printdbg("-ret:$ret");

my $ret2 = FScrabProcess::lese_legeBuchstaben($spielId, $aktionsnr);
$dbg->printdbg("-ret2:$ret2");

$dbg->printdbg("-vor vetoDatei_status");
my $ret3 = FScrabProcess::vetoDatei_status($spielId);
$dbg->printdbg("-nach vetoDatei_status");
$dbg->printdbg("-ret3:$ret3");

FScrabBase::get_settings_globals($spielId);

$dbg->switch(1);
$dbg->printdbg("-globals $FScrabBase::VielePkte,$FScrabBase::SoftEnd,$FScrabBase::Ende");


my $ret4 = "$spielId";
if ($FScrabBase::VielePkte eq '1') { 
    $ret4 = $ret4 . ",vp"; 
}
if ($FScrabBase::SoftEnd   eq '1') { 
    $ret4 = $ret4 . ",se";  
}
if ($FScrabBase::MitVeto   eq '1') { 
    $ret4 = $ret4 . ",veto";  
}
if ($FScrabBase::Ende  eq '1') { 
    $ret4 = $ret4 . ",<span style='color:red;'>ENDE</span>";  
}

$dbg->printdbg("-ret:$ret#$ret2#$ret3#$ret4");

print "$ret#$ret2#$ret3#$ret4";
$dbg->switch(0);

exit;

