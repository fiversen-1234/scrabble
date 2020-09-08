#!/usr/bin/perl

# detect date of last change of a file
use strict;
use AutoLoader;
use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser);
use FDebgCl;

package FScrabBase;

use Fcntl qw(:flock);

# variables
# - settings
our $VielePkte = '0';
our $SoftEnd   = '0';
our $MitVeto   = '0';
our $Ende      = '0';

our $dbg = FDebgCl->new(0, "dbgfiles/FScrab.dbg");

my $MIN = 1;
my $MAX = 15;

our @brett;        
# array 1..15x1..15   
# '.' / Buchstabe  
# $brett[zeile][spalte]  
our @colheader = ('A','B','C','D','E', 'F','G','H','I','J',  'K','L','M','N','O'); 
#our @colheader = ('1','2','3','4','5', '6','7','8','9','10', '11','12','13','14','15'); 
our @rowheader = ('1','2','3','4','5', '6','7','8','9','10', '11','12','13','14','15'); 

our @wortwert;     
# array 1..15x1..15
# 1 /  2,3  - wortfaktor

our @feldwert;
# array 1..15x1..15
# 1 /  2,3 - buchstabenfaktor


our @zuege;
our $zuegeN;
#  array mit unterschiedlichen längen
#  ein zug je zeile
#    idx spieler anz  (x,y,b) (x,y,b) (x,y,b) ....   


our @steine_basis;
# array mit Buchstabe und Wert

#our $beutel;
# beutel mit den zur verfuegung stehenden steine

##files
#            12.beutel.txt  12.info.txt  12.info.txt  12.letztesLegen.txt  12.worte.txt  12.zuege.txt
# filenames  fnBeutel       fnInfo       fnInfoNeu    fnLetztesLegen       fnWorte       fnZuege
# LOCK hdls  LOCKBeutel     LOCKInfo     LOCKInfoNeu  LOCKLetztesLegen     LOCKWorte     LOCKZuege
# DATA hdls  DATABeutel     DATAInfo     DATAInfoNeu  DATALetztesLegen     DATAWorte     DATAZuege

sub debug_move
{
   	my $fname = $_[0];
	$dbg->move($fname);
}
sub debug_switch
{
   	my $i = $_[0];
	$dbg->switch($i);
}

# filehandle funcs
# versuch nur mit   LOCK und DATA
my $FILEopened = 0;
our $DATA;
our $LOCK;
sub fh_openlock
{
   	my $op    = $_[0]; 
   	my $fname = $_[1];
   	my $info  = $_[2];

	my $fnameSem = $fname . ".lock";

	$dbg->printdbg("fh_open($info): $op $fname");
	open($LOCK, ">$fnameSem") or die "Can't open $fnameSem ($!)";
	flock($LOCK, LOCK_EX);

   	open($DATA, "$op$fname") or die "($info): Can't open $fname with $op --($!)";
	$FILEopened++;   
	$dbg->printdbg("..opened($info): $op $fname--$FILEopened");
   	return 1;
}
sub fh_close
{
   	my $op    = $_[0]; 
   	my $fname = $_[1];
   	my $info  = $_[2];

	close ($DATA);
	close ($LOCK);
	$FILEopened--;
	$dbg->printdbg("fh_close($info): $op $fname--$FILEopened");;
   	return 1;
}




sub init_brett
{
	##################brett
	#- je feld - idx vom zug
	my $r = 1;
	my $c = 1;
	for ($r = $MIN; $r <= $MAX,; $r = $r + 1) {
		for ($c = $MIN; $c <= $MAX,; $c = $c + 1) {
			$brett[$r][$c] = '.';
		}
	}
	$dbg->printdbg("init_brett, 3,4:$brett[3][4]");
}


sub init_wortwert
{
	##################wortwert
	#- je feld - der Wortwert - Faktor für das Wort
	my $r = 1;
	my $c = 1;
	for ($r = 1; $r <= $MAX,; $r = $r + 1) {
		for ($c = 1; $c <= $MAX,; $c = $c + 1) {
			$wortwert[$r][$c] = 1;
		}
	}
	#dreifacher wortwert  - rot
	#-  1/1    1/8   1/15
	#-  8/1          8/15
	#- 15/1   8/15  15/15
	$wortwert[1][1]  = $wortwert[1][8]  = $wortwert[1][15] = 3;
	$wortwert[8][1]  = $wortwert[8][15] = 3;
	$wortwert[15][1] = $wortwert[15][8] = $wortwert[15][15] = 3;
	#doppelter wortwert  - gelb 
	#-   2/2    2/14
	#-   3/3    3/13
	#-   4/4    4/12
	#-   5/5    5/11 
	#-   8/8
	#-  11/5   11/11
	#-  12/4   12/12
	#-  13/3   13/13
	#-  14/2   14/14
	$wortwert[2][2]  = $wortwert[2][14] = 2;
	$wortwert[3][3]  = $wortwert[3][13] = 2;
	$wortwert[4][4]  = $wortwert[4][12] = 2;
	$wortwert[5][5]  = $wortwert[5][11] = 2;
	$wortwert[8][8]  = 2;
	$wortwert[11][5]  = $wortwert[11][11] = 2;
	$wortwert[12][4]  = $wortwert[12][12] = 2;
	$wortwert[13][3]  = $wortwert[13][13] = 2;
	$wortwert[14][2]  = $wortwert[14][14] = 2;
	$dbg->printdbg("init_wortwert, 8 1:$wortwert[8][1]");
}

sub wortwert {
	my $r = $_[0];
	my $c = $_[1];
	my $ret = $wortwert[$r][$c];

	#$dbg->printdbg("wortwert -" . $r . "/" . $c . ":" . $ret);

	return $ret;
}

sub init_feldwert
{
	##################feldwert
	#- je feld - der Feldwert - Faktor für den Buchstaben
	my $r = 1;
	my $c = 1;
	for ($r = 1; $r <= $MAX,; $r = $r + 1) {
		for ($c = 1; $c <= $MAX,; $c = $c + 1) {
			$feldwert[$r][$c] = 1;
		}
	}
	#doppelter buchstabenwert - hellblau
	#-   1/4    1/12
	#-   3/7    3/9
	#-   4/1    4/8    4/15
	#-   7/3    7/7    7/9      7/13
	#-   8/4    8/12
	#-   9/3    9/7    9/9      9/13
	#-  12/1   12/8   12/15
	#-  13/7   13/9
	#-  15/4   15/12
	$feldwert[1][4]   = $feldwert[1][12]  = 2;
	$feldwert[3][7]   = $feldwert[3][9]   = 2;
	$feldwert[4][1]   = $feldwert[4][8]   = $feldwert[4][15]  = 2;
	$feldwert[7][3]   = $feldwert[7][7]   = $feldwert[7][9]   = $feldwert[7][13] = 2;
	$feldwert[8][4]   = $feldwert[8][12]  = 2;
	$feldwert[9][3]   = $feldwert[9][7]   = $feldwert[9][9]   = $feldwert[9][13] = 2;
	$feldwert[12][1]  = $feldwert[12][8]  = $feldwert[12][15] = 2;
	$feldwert[13][7]  = $feldwert[13][9]  = 2;
	$feldwert[15][4]  = $feldwert[15][12] = 2;
	#dreifacher buchstabenwert - blau
	#-   2/6    2/10
	#-   6/2    6/6    6/10    6/14
	#-  10/2   10/6   10/10   10/14
	#-  14/6   14/10
	$feldwert[2][6]   = $feldwert[2][10]  = 3;
	$feldwert[6][2]   = $feldwert[6][6]   = $feldwert[6][10]  = $feldwert[6][14]  = 3;
	$feldwert[10][2]  = $feldwert[10][6]  = $feldwert[10][10] = $feldwert[10][14] = 3;
	$feldwert[14][6]  = $feldwert[14][10] = 3;
	$dbg->printdbg("init_feldwert, 8,12:$feldwert[8][12]");
}
sub feldwert {
	my $r = $_[0];
	my $c = $_[1];
	my $ret = $feldwert[$r][$c];
	#$dbg->printdbg("feldwert -" . $r . "/" . $c . ":" . $ret);
	return $ret;
}

#returns css class
sub feldstyle
{
	my $r = $_[0];
	my $c = $_[1];
	my $ret = "\"feld feld-leer\"";

	$dbg->switch(0);
	if ($r == 0 || $r == 16 || $c == 0 || $c == 16)  {
		$ret = "\"feld feld-border\"";
		$dbg->printdbg("-feldstyle -" . $r . "/" . $c . ":" . $ret);
	}
	else {
		my $wert = feldwert($r,$c);
		if ($wert == 2) {
			$ret = "\"feld feld-buch2\"";
		}
		elsif ($wert == 3)  {
			$ret = "\"feld feld-buch3\"";
		}
		else {
			$wert = wortwert($r,$c);
			if ($wert == 2)  {
				$ret = "\"feld feld-wort2\"";
			}
			elsif ($wert == 3) {
				$ret = "\"feld feld-wort3\"";
			}
		}
	}
	$dbg->switch(0);
	return $ret;
}
sub feldstyleborder
{
	my $r     = $_[0];
	my $c     = $_[1];
	my $color = $_[2];

	my $ret = "feld feld-leer";
	if ($r == 0 || $r == 16 || $c == 0 || $c == 16)  {
		$ret = "feld feld-border";
	}

	my $wert = feldwert($r,$c);
	if ($wert == 2) {
		$ret = "feld feld-buch2";
	}
	elsif ($wert == 3)  {
		$ret = "feld feld-buch3";
	}
	else {
		$wert = wortwert($r,$c);
		if ($wert == 2)  {
			$ret = "feld feld-wort2";
		}
		elsif ($wert == 3) {
			$ret = "feld feld-wort3";
		}
	}
	if ($color eq "w") {
		$ret = "\"" .  $ret . " feld-border-white" . "\"";
	}
	elsif ($color eq "b") {
		$ret = "\"" .  $ret . " feld-border-black" . "\"";
	}
	else  {
		$ret = "\"" .  $ret .  "\"";
	}

	#$dbg->printdbg("feldfarbe -" . $r . "/" . $c . ":" . $ret);
	return $ret;
}








sub buchstabe_brett {
	my $r = $_[0];
	my $c = $_[1];
	my $buch = $brett[$r][$c];
	return $buch;
}



sub _wert 
{
	my $arg = $_[0];
	my $idx = _idx($arg);
	my $ret = 0;
	if ($idx > -1 ) {
		$ret = $steine_basis[$idx][1];
	}
	#print "_wert $arg  ret:$ret\n";
	return $ret;
}
sub _anz 
{
	my $arg = $_[0];
	my $idx = _idx($arg);
	my $ret = 0;
	if ($idx > -1 ) {
		$ret = $steine_basis[$idx][2];
	}
	#print "_anz $arg  ret:$ret\n";
	return $ret;
}

sub _idx   #von steine_basis
{
	my $arg = $_[0];
	my $a   = ord('A');
	my $z   = ord('Z');
	my $ret = -1;
	
	if ($arg ge 'A' &&  $arg le 'Z')  { $ret = ord($arg) - $a;	}
	elsif ($arg eq 'Ä') { $ret = $z-$a+1; }
	elsif ($arg eq 'Ö') { $ret = $z-$a+2; }
	elsif ($arg eq 'Ü') { $ret = $z-$a+3; }
	elsif ($arg eq '?') { $ret = $z-$a+4; }
	#print "_idx $arg  ret:$ret\n";
	return $ret;
}
sub init_steine_basis 
{
#1 Punkt: E (15), N (9), S (7), I (6), R (6), T (6), U (6), A (5), D (4)
#2 Punkte: H (4), G (3), L (3), O (3)
#3 Punkte: M (4), B (2), W (1), Z (1)
#4 Punkte: C (2), F (2), K (2), P (1)
#6 Punkte: Ä (1), J (1), Ü (1), V (1)
#8 Punkte: Ö (1), X (1)
#10 Punkte: Q (1), Y (1)
#0 Punkte: Joker/Blanko (2)

	@steine_basis = (
	 	['A', 1, 5],  #0
		['B', 3, 2],
		['C', 4, 2],
		['D', 1, 4],
		['E', 1, 15],
		['F', 4, 2],  #5
		['G', 2, 3],
		['H', 2, 4],
		['I', 1, 6],
		['J', 6, 1],
		['K', 4, 2],  #10
		['L', 2, 3],
		['M', 3, 4],
		['N', 1, 9],
		['O', 2, 3],
		['P', 4, 1],  #15
		['Q', 10, 1],
		['R', 1, 6],
		['S', 1, 7],
		['T', 1, 6],
		['U', 1, 6],  #20
		['V', 6, 1],  
		['W', 3, 1],  
		['X', 8, 1],  
		['Y', 10, 1],
		['Z', 3, 1],  #25
		['Ä', 6, 1],  #Ä   '&#196;'
		['Ö', 8, 1],  #Ö   '&#214;'
		['Ü', 6, 1],  #Ü   '&#220;'
		['_', 0, 2]  #Jocker    #29
		#['a', 0, 2]  #Jocker    #29
	);
}
init_steine_basis();

 

## beutel - vorhandene Spielsteine
## DatenStruktur:  data/<spielId>.beutel.txt
## der aktuelle  Beutelinhalt in einer Zeile - Buchstaben, mit "," getrennt
sub delete_beutel
{
	unlink <data/*.beutel.txt>;
}
sub delete_zuege
{
	unlink <data/*.zuege.txt>;
}
sub delete_all_data_dbg_files
{
	my $spielId = $_[0]; 
	$dbg->printdbg("delete_all_data_dbg_files");
	unlink <data/$spielId.*.txt>;
	unlink <data/$spielId.*.txt.lock>;
	unlink <dbgfiles/$spielId.*.dbg>;
}
sub delete_all_data_files
{
	my $spielId = $_[0]; 
	$dbg->printdbg("delete_all_data_files");
	unlink <data/$spielId.beutel.txt>;
	unlink <data/$spielId.info.txt>;
	unlink <data/$spielId.letztesLegen.txt>;
	unlink <data/$spielId.worte.txt>;
	unlink <data/$spielId.zuege.txt>;
	unlink <data/$spielId.bank.txt>;
	unlink <data/$spielId.speichern.txt>;
	unlink <data/$spielId.ende.txt>;
}

sub init_beutel
{
	my $ret = '';
	##ori 	
	for (my $a1 = 0 ; $a1 < 30; $a1=$a1+1) {
	##test	for (my $a1 = 0 ; $a1 < 5; $a1=$a1+1) {
		for (my $b = 0; $b < $steine_basis[$a1][2]; $b=$b+1) {
			$ret = $ret . $steine_basis[$a1][0] . ",";
		}
	}
	##test
	#$ret = substr($ret,0, 2*20);

	##$beutel = $ret;
	return $ret;
}
#init_beutel();

#for (my $a1 = 0 ; $a1 < 30; $a1=$a1+1) {
#	print "$a1)", $steine_basis[$a1][0], "-", 
#				  $steine_basis[$a1][1], "-", 
#				  $steine_basis[$a1][2], "\n";	
#}

sub hole_beutel
{
	my $spielId = $_[0];
	my $info    = "hole_beutel";
	my $fileName = "data/$spielId.beutel.txt";

	$dbg->switch(0);
    #file neu anlegen ?
	if (-e $fileName) {
	} 
	else  {
		if (fh_openlock(">", $fileName, $info)) {
			my $beutel = init_beutel();
			print $DATA "$beutel\n";
			fh_close(">", $fileName, $info);
		}		
	}	
	
	my $ret = '';
	my $line = '';
	if (fh_openlock("<", $fileName, $info)) {
		#letzte zeile lesen
		while (!eof($DATA)) {
			chomp($line = <$DATA>);
			if (length($line) > 0) {
				$ret = $line;
			}
		}
		fh_close("<", $fileName, $info);
	}
	$dbg->printdbg("hole_beutel:$ret");
	$dbg->switch(0);
	return $line;
}

sub gebesteine_beutel 
{
	my $anzahl  = $_[0];
	my $beutel  = $_[1];
	my $spielId = $_[2];
	my $info    = "gebesteine_beutel";

	$dbg->switch(0);
	$dbg->printdbg("gebesteine_beutel: $anzahl");
	$dbg->printdbg("-gb: $beutel");
	my $ret = '';
	my $r = 0;

	my @list  = split(/\,/,$beutel);
	my $listN = scalar @list;
	$dbg->printdbg("-listN:$listN");

	my $i = 0;
	while ($i < $anzahl  &&  $i < $listN)  {
		$r   = int(rand($#list));
		#if ($#list == 101) {  ####test Ü
	    #		$r = 66;
	    #}
		$ret = $ret . $list[$r] . ",";
		splice(@list, $r, 1);
		$i = $i +1;
	}

	$beutel = '';
	$listN = scalar @list;
	$dbg->printdbg("--listN:$listN");
	if ($listN > 0)  {
		foreach (@list) {
			$beutel = $beutel . "$_,";
		}
	}
	else  {
		$beutel = "-";
	}	

	$dbg->printdbg("--$ret");
	$dbg->printdbg("--$beutel");

	my $fileName = "data/$spielId.beutel.txt";
	if (fh_openlock(">>", $fileName, $info)) {
		print $DATA "$beutel\n";
		fh_close(">>", $fileName, $info);
	}
	$dbg->switch(0);
	return $ret;
}

sub buchstaben_in_den_beutel 
{
	my $bsts    = $_[0];
	my $beutel  = $_[1];
	my $spielId = $_[2];
	my $info    = "buchstaben_in_den_beutel";
	my $ret = 0;

	$dbg->switch(0);
	$dbg->printdbg("buchstaben_in_den_beutel: $bsts");
	$dbg->printdbg("-bidb: $beutel");


	$beutel = $beutel . $bsts;
	$beutel =~ s/\,\,/\,/;

	$dbg->printdbg("--bidb: $beutel");

	my $fileName = "data/$spielId.beutel.txt";
	if (fh_openlock(">>", $fileName, $info)) {
		print $DATA "$beutel\n";
		fh_close(">>", $fileName, $info);
		$ret = 1;
	}

	$dbg->printdbg("---ret: $ret");
	$dbg->switch(0);

	return $ret;
}

#print "$beutel\n";
#gebesteine_beutel(7);

sub svg_inline_img
{
	my $buch   = $_[0];
	my $center = $_[1];
	my $buchwert = _wert($buch);

	my $ret = "\"data:image/svg+xml;utf8,<svg width='100' height='100' viewBox='0 0 100 100' " .
	    		"xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>" ;
	if ($buch eq '.') {
		if ($center == 1) {
			$ret = $ret .
				"<polygon points='0,0 100,0 100,100 0,100' style='fill:transparent' /> " .
				"<text x='45' y='55' fill='black' font-size='80px' >.</text>" .
				"<text x='30' y='55' fill='black' font-size='80px' >.</text>" .
				"<text x='60' y='55' fill='black' font-size='80px' >.</text>" .
				"<text x='45' y='40' fill='black' font-size='80px' >.</text>" .
				"<text x='45' y='70' fill='black' font-size='80px' >.</text>";
		}
		else  {
			$ret = $ret .
				"<polygon points='0,0 100,0 100,100 0,100' style='fill:transparent' /> " .
				"<text x='45' y='55' fill='black' font-size='80px' >.</text>";
		}
	}
	else  {
		$ret = $ret .
			"<polygon points='0,0 100,0 100,100 0,100' style='fill:beige;stroke:brown;stroke-width:3' />" .
			"<text x='20' y='75' fill='black' font-size='80px' >$buch</text>" .
			"<text x='80' y='90' fill='black' font-size='30px' >$buchwert</text>";
	}
	$ret = $ret .
		"</svg>\"";
	return $ret;
}



sub linesNo_file
{
	my $fileName  = $_[0];
	my $info      = "linesNo_file";
    my $lines = 0;
	my $ok    = 0;

    if (fh_openlock("<", $fileName, $info))  {
		while (!eof($DATA)) {
			my $line;
			chomp($line = <$DATA>);
			if (strlen($line) > 0) {
				$lines = $lines + 1;
			}
			$ok = 1;	
		}
		fh_close("<", $fileName, $info);
	}

    if ($ok == 0)  {
		return -1;
	}
    return $lines;
}

## info.txt
## - mit 1.zeile  vielepkte,0,softend,0      
##   vielepkte,1  ueberschreibt vielepkte,0
##   softend,1  ueberschreibt softend,0
sub add_settings
{
	my $fileName  = $_[0];
	my $vielepkte = $_[1];
	my $softend   = $_[2];
	my $mitveto   = $_[3];
	my $info      = "add_settings";

	my @lines;
	my $lineI = 0;
	if (-e $fileName) {
		my $line;
		if (fh_openlock("<", $fileName, $info)) {
			while(!eof($DATA)) {
				chomp($lines[$lineI] = <$DATA>);
				$lineI = $lineI + 1;
			}
			fh_close("<", $fileName, $info);
		}
		if (index($lines[0],"vielepkte") > -1) {
			my ($a,$b,$c,$d,$e,$f) = split(/\,/,$lines[0]);
			if ($vielepkte eq '1') {
				$b = '1';
			}
			if ($softend eq '1') {
				$d = '1';
			}
			if ($mitveto eq '1') {
				$f = '1';
			}
			$lines[0] = "$a,$b,$c,$d,$e,$f";
			if (fh_openlock(">", $fileName, $info)) {
				my $i = 0;
				while ($i < $lineI) {
					print $DATA "$lines[$i]\n";
					$i = $i + 1;
				}
				fh_close(">", $fileName, $info);
			}
		}
		else{
			if (fh_openlock(">", $fileName, $info)) {
				print $DATA "vielepkte,$vielepkte,softend,$softend,mitveto,$mitveto\n";
				my $i = 0;
				while ($i < $lineI) {
					print $DATA "$lines[$i]\n";
					$i = $i + 1;
				}
				fh_close(">", $fileName, $info);
			}
		}
	} 
	else   #in neue datei schreiben
	{
		if (fh_openlock(">", $fileName, $info)) {
			print $DATA "vielepkte,$vielepkte,softend,$softend,mitveto,$mitveto\n";
			fh_close(">", $fileName, $info);
		}
	}
}

##  returns vielepkte,softend
sub get_settings_globals
{
	my $spielId = $_[0];

	my $info    = "get_settings";

	my $fileName = "data/$spielId.info.txt";
	my $ret = "0,0"; 
	$VielePkte = '0';
	$SoftEnd   = '0';
	$MitVeto   = '0';

	if (-e $fileName) {
		my $line;
		if (fh_openlock("<", $fileName, $info)) {
			if (!eof($DATA)) {
				chomp($line = <$DATA>);
			}
			fh_close("<", $fileName, $info);
		}
		if (index($line,"vielepkte") > -1) {
			my ($a,$b,$c,$d,$e,$f,$g,$h) = split(/\,/,$line);
			$VielePkte = $b;
			$SoftEnd   = $d;
			$MitVeto   = $f;
			$ret = "$b,$d,$f";
			if ($g  && $h)  {
				$Ende = $h;
				$ret = $ret . ",$h";
			}

		}
	}
	return $ret;
}



return 1;