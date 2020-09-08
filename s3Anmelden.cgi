#!/usr/bin/perl

use strict;
use FDebgCl;
use FScrabBase;
use FScrabProcess;
use FScrabSpieler;

use CGI 'param';    # beeinhaltet die Funktion param()

print "Content-type: text/html\n\n";

my $spieler   = '';
my $spielId   = '0';
my $mitspieleradr1 = '';
my $mitspieleradr2 = '';
my $mitspieleradr3 = '';
my $vielepkte = '';
my $softend   = '';
my $mitveto   = '';
my $time      = '';
if ( param('spieler') ) {
    $spieler   = param('spieler');
    $spielId   = param('spielId');
    $mitspieleradr1 = param('mitspieleradr1');
    $mitspieleradr2 = param('mitspieleradr2');
    $mitspieleradr3 = param('mitspieleradr3');
    $vielepkte = param('vielepkte');
    $softend   = param('softend');
    $mitveto   = param('mitveto');
    $time = param('time');
}

my $dbg = FDebgCl->new( 1, "dbgfiles/$spielId.s3Anmelden.dbg" );
$dbg->printdbg("-1:$spielId,$spieler,$vielepkte,$softend,$mitveto");
FScrabBase::debug_move("dbgfiles/$spielId.FScrab.dbg");
FScrabBase::debug_switch(1);

#if ($neu eq "true")   {
#    FScrab::delete_all_data_dbg_files();
#}

my $ret = "";
my $adr = "";
my $control = FScrabSpieler::add_spieler($spielId, $spieler,$vielepkte,$softend,$mitveto);
FScrabBase::debug_switch(1);
$dbg->printdbg("-2 control:$control");
if ($control eq "-1"  ||  $control eq "-2") {
    print $control;
}
else {
    my $adr1 = FScrabSpieler::send_email($spielId, $spieler, $mitspieleradr1);
    my $adr2 = "";
    my $adr3 = "";
    if (length($mitspieleradr2) > 0) {
        $adr2 = FScrabSpieler::send_email($spielId, $spieler, $mitspieleradr2);
    }
    if (length($mitspieleradr3) > 0) {
        $adr3 = FScrabSpieler::send_email($spielId, $spieler, $mitspieleradr3);
    }

    $ret = FScrabSpieler::zustand_spieler($spielId);
    FScrabBase::debug_switch(1);
    $dbg->printdbg("-3 adr1:$adr1 adr2:$adr2 adr3:$adr3 ret:$ret");
    print "$ret";
}

$dbg->switch(0);
FScrabBase::debug_switch(0);

exit;

