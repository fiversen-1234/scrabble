#!/usr/bin/perl

use FDebgCl;
use FScrabBase;
use FScrabProcess;
use FScrabZuegeWorte;

use CGI 'param';    # beeinhaltet die Funktion param()

print "Content-type: text/html\n\n";

my $spielId  = '';
my $time     = '';
my $wortzeilennr = '';
if ( param('spielId') ) {
    $spielId = param('spielId');
    $wortzeilennr = param('wortzeilennr');
    $time = param('time');
}

my $dbg = FDebgCl->new( 1, "dbgfiles/$spielId.s3LeseZug.dbg" );
$dbg->printdbg("-1:$spielId,$wortzeilennr " );
FScrabBase::debug_move("dbgfiles/$spielId.FScrab.dbg");
FScrabBase::debug_switch(1);

if   (-e "data/$spielId.zuege.txt")  {}
else { system("touch data/$spielId.zuege.txt"); }
if   (-e "data/$spielId.worte.txt")  {}
else { system("touch data/$spielId.worte.txt"); }

my $ret1 = FScrabZuegeWorte::leseLetzten_zug($spielId, $wortzeilennr);
my $ret2 = FScrabZuegeWorte::leseLetzte_wortzeile($spielId, $wortzeilennr);
my $ret = $ret1 . "#" . $ret2;

$dbg->printdbg("- ret:$ret");
print "$ret";

FScrabBase::debug_switch(0);
$dbg->switch(0);

exit;

