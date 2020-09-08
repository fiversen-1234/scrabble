#!/usr/bin/perl

use FDebgCl;
use FScrabBase;
use FScrabProcess;
use FScrabZuegeWorte;
use FScrabMulti;

use CGI 'param';    # beeinhaltet die Funktion param()

print "Content-type: text/html;charset=utf-8\n\n";

my $spielId    = '0';
my $time       = '';
if ( param('spielId') ) {
    $spielId = param('spielId');
    $time    = param('time');
}

my $ret = 0;
my $dbg = FDebgCl->new( 1, "dbgfiles/$spielId.s3End.dbg" );
$dbg->printdbg("-1:$spielId");
FScrabBase::debug_move("dbgfiles/$spielId.FScrab.dbg");


FScrabBase::delete_all_data_dbg_files($spielId);

print "1";

$dbg->switch(0);

exit;

