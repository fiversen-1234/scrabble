#!/usr/bin/perl

# detect date of last change of a file
use strict;
use AutoLoader;
use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser);
use FDebgCl;

use FScrabBase;
use FScrabSpieler;

package FScrabMulti;

use Fcntl qw(:flock);
 
my $HOMEDIR = "scrab";

sub Speichern
{
	my $spielId = $_[0];
	my $passwd  = $_[1];
	my $info    = "Speichern";

	my $fileName = "data/$spielId.speichern.txt";
	my $ret = 0;

	#$FScrabBase::dbg = FDebgCl->new(0, "dbgfiles/11.FScrab.dbg");
	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->printdbg("$info  fileName:$fileName");

	$FScrabBase::dbg->printdbg(".vor zustand");
	my $alle = FScrabSpieler::alle_spielername($spielId);
	my @fld  = split(/\,/, $alle);
	my $fldN = $#fld;
	$FScrabBase::dbg->printdbg("..nach..:$alle - @fld - $fldN");

	my $allSpieler = '';
	for (my $i = 0; $i <= $fldN; $i = $i + 1)  {
		if (length ($fld[$i]) > 0) {
			$allSpieler = $allSpieler . $fld[$i] . "-";
		}
	}
	$FScrabBase::dbg->printdbg("..allSpieler:$allSpieler");

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    $mon++;
    $year = $year - 100;

	my $server  = "/home/www/wedding/public_html";
	my $data    = $server . "/$HOMEDIR/data";
	my $dirname = "data/$allSpieler$mday.$mon.$year";
	$FScrabBase::dbg->printdbg("zip $dirname $data/$spielId.*.txt");
	##system("mkdir $dirname");
	##system("cp data/$spielId.*.txt $dirname");

	if (FScrabBase::fh_openlock(">", $fileName, $info)) {
		print $FScrabBase::DATA "$dirname\n";
		print $FScrabBase::DATA "$passwd\n";
		for (my $i = 0; $i <= $fldN; $i = $i + 1) {
			print $FScrabBase::DATA "$fld[$i],-\n";
		}
		FScrabBase::fh_close(">", $fileName, $info);
	}

	system("mkdir $dirname");
	system("cp data/$spielId.*.txt $dirname");

	return "$allSpieler$mday.$mon.$year";
}


sub StoredList
{
	my $info    = "StoredList";

	$FScrabBase::dbg->printdbg("$info");

	my $root = "data";

	opendir my $dh, $root
  		or die "$0: opendir: $!";


	my @dirs = grep {-d "$root/$_" && ! /^\.{1,2}$/} readdir($dh);
	$FScrabBase::dbg->printdbg(". dirs:@dirs");

	my $ret = '-';
	
	if ($#dirs >= 0) {
		$ret = join('+', @dirs);
	}
	$FScrabBase::dbg->printdbg(".. ret:$ret");
	return $ret;
}


sub Laden
{
	my $spieler    = $_[0];
	my $passwd     = $_[1];
	my $storedname = $_[2];

	my $info    = "Laden";

	my $ret = "";

	#$FScrabBase::dbg = FDebgCl->new(0, "dbgfiles/11.FScrab.dbg");
	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->printdbg("$info:  $spieler, $passwd, $storedname");

	#my $server  = "/home/www/wedding/public_html";
	#my $data    = $server . "$HOMEDIR/data";
	my $dirname = "data/$storedname";
	$FScrabBase::dbg->printdbg(".dirname: $dirname");

	opendir my $dh, $dirname
  		or die "$0: opendir: $!";

	my @files = readdir($dh);
	$FScrabBase::dbg->printdbg(". dirs:@files");

	#spielId ?
    my $spielId = "0";
	for (my $i = 0; $i <= $#files &&  $spielId eq "0"; $i = $i + 1) {
		if (length($files[$i]) > 3 ) {
			my @fld = split(/\./, $files[$i]);
			$spielId = $fld[0];
		}
	} 
	$FScrabBase::dbg->printdbg(".. spielId: $spielId");

	if ($spielId eq "0") {
		$ret = "-";
		return $ret;
	}


	#password, spieler ?
	my $allreadyCopied = 0;
	my $ok = 0;
	my @lines;
	my $linesN = 0;
	my $fileName = "data/$spielId.speichern.txt";

	if (-e $fileName) { 
		$allreadyCopied = 1;
	}
	if ($allreadyCopied == 0) {
		$fileName = "$dirname/$spielId.speichern.txt";
	}
	$FScrabBase::dbg->printdbg("..fileName: $fileName");

	if (FScrabBase::fh_openlock("<", $fileName, $info)) {
		while (!eof($FScrabBase::DATA)) {
			my $line = "";
			chomp($line = <$FScrabBase::DATA>);
			$lines[$linesN] = $line;
			$linesN = $linesN + 1;
		}
		FScrabBase::fh_close("<", $fileName, $info);
	}
	
	$ret = "PWD";
	if ($lines[1] eq $passwd) {
		$ret = $ret . "+";
	}
	else {
		$ret = $ret . "-";
	}
	$FScrabBase::dbg->printdbg("...ret: $ret");

	my $found = 0;
	for (my $i = 2; $i < $linesN; $i = $i +1) {
		if ($lines[$i] eq "$spieler,\-") {			
			$found = 1;
			$lines[$i] = "$spieler,+";
		}
	}
	if($found==1)  { 
		$ret = $ret . ",SP+";
	}
	else {
		$ret = $ret .  ",SP-";
	}
	$FScrabBase::dbg->printdbg("....ret: $ret");

	if ($ret eq "PWD+,SP+") {
		if (FScrabBase::fh_openlock(">", $fileName, $info)) {
			for (my $i = 0; $i < $linesN; $i = $i +1) {
				print $FScrabBase::DATA "$lines[$i]\n";
			}
    		FScrabBase::fh_close(">", $fileName, $info);
		}

		if ($allreadyCopied == 0) {
			system("cp -n $dirname/* data/");
		}
	}

	$FScrabBase::dbg->printdbg("ret :$ret,$spielId");

	return ($ret,$spielId);
}

sub AllLoaded
{
	my $spielId    = $_[0];

	my $info    = "AllLoaded";

	my $ret = 0;

	my $fileName = "data/$spielId.speichern.txt";

	#$FScrabBase::dbg = FDebgCl->new(0, "dbgfiles/11.FScrab.dbg");
	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->printdbg("$info:  $spielId");

    my @lines;
	my $linesN = 0;
	if (FScrabBase::fh_openlock("<", $fileName, $info)) {
		while (!eof($FScrabBase::DATA)) {
			my $line = "";
			chomp($line = <$FScrabBase::DATA>);
			$lines[$linesN] = $line;
			$linesN = $linesN + 1;
		}
		FScrabBase::fh_close("<", $fileName, $info);
	}
	

	for (my $i = 2; $i < $linesN; $i = $i +1) {
		if (index($lines[$i], ",-") > -1) {
			$ret = $ret . "-";
		}
		if (index($lines[$i], ",+") > -1) {
			$ret = $ret . "+";
		}
	}
	return $ret;
}


###Speichern("11");

return 1;
