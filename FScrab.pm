#!/usr/bin/perl

# detect date of last change of a file
use strict;
use AutoLoader;
use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser);
use FDebgCl;

package FScrab;

use Fcntl qw(:flock);

# variables
# - settings
our $VielePkte = '0';
our $SoftEnd   = '0';
our $MitVeto   = '0';
our $Ende      = '0';

my $dbg = FDebgCl->new(0, "dbgfiles/FScrab.dbg");

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

# filehandle funcs
# versuch nur mit   LOCK und DATA
my $FILEopened = 0;
sub fh_openlock
{
   	my $op    = $_[0]; 
   	my $fname = $_[1];
   	my $info  = $_[2];

	my $fnameSem = $fname . ".lock";

	$dbg->printdbg("fh_open($info): $op $fname");
	open(LOCK, ">$fnameSem") or die "Can't open $fnameSem ($!)";
	flock(LOCK, LOCK_EX);

   	open(DATA, "$op$fname") or die "($info): Can't open $fname with $op --($!)";
	$FILEopened++;   
	$dbg->printdbg("..opened($info): $op $fname--$FILEopened");
   	return 1;
}
sub fh_close
{
   	my $op    = $_[0]; 
   	my $fname = $_[1];
   	my $info  = $_[2];

	close DATA;
	close LOCK;
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







#schreiben zug in 'data/$spielId.zuege.txt'
#  idx,spieler,buchstabe,x,y,buchstabe,x,y,buchstabe,x,y,...
sub schreibe_zug {
	my $spielId  = $_[0];
	my $neuerZug = $_[1];
	my $info     = "schreibe_zug";

	my $anzZuege = 0;
	if (fh_openlock("<", "data/$spielId.zuege.txt", $info))  {
   		while ( <DATA> ) {
   			$anzZuege++;
   		}
    	fh_close("<", "data/$spielId.zuege.txt", $info);
	}
	$anzZuege = $anzZuege + 1;
    
	#correct zugidx
	my @list = split(/\,/,$neuerZug);
	$list[0] = $anzZuege;
	my $neuerZug2 = join(',', @list) . ",";


	$dbg->printdbg("zuege_schreiben\n");
	if (fh_openlock(">>", "data/$spielId.zuege.txt", $info))  {
		print DATA "$neuerZug2\n";
		$dbg->printdbg("-$neuerZug2\n");
		fh_close(">>", "data/$spielId.zuege.txt", $info);
	}

	$dbg->printdbg("--$anzZuege\n");
	return $anzZuege;
}

#lesen aus <spielId>.zuege.txt
sub leseLetzten_zug {
	my $spielId = $_[0];
	my $info    = "leseLetzten_zug";
	my $i   = 0;
	my $ret = '';

	if (fh_openlock("<",  "data/$spielId.zuege.txt", $info)) {
		$dbg->printdbg("zuege_lesen\n");
		while ( ! eof(DATA) ) {
        	chomp(my $line    =  <DATA>);
			$dbg->printdbg("-line:" . $line . "\n");
			if (length($line) > 0) {
				$ret = $line;
			}
			$i = $i + 1;
		}
		fh_close("<", "data/$spielId.zuege.txt", $info);
	}
	return $ret;
}

#--- wortzeile
sub schreibe_wortzeile {
	my $spielId   = $_[0];
	my $spieler   = $_[1];
	my $neueworte = $_[2];
	my $pkt       = $_[3];
	my $info    = "schreibe_wortzeile";

	my $wortZeilen = 0;
	if (fh_openlock("<",  "data/$spielId.worte.txt", $info))  {
   		while ( <DATA> ) {
   			$wortZeilen++;
   		}
    	fh_close("<",  "data/$spielId.worte.txt", $info);
	}
	$wortZeilen = $wortZeilen + 1;
    
	#
	my @list = split(/-/,$neueworte);
	my $neueworte2 = join(',', ($wortZeilen, $spieler, @list,$pkt)) . ",";

	$dbg->printdbg("schreibe_wortzeile\n");
	if (fh_openlock(">>", "data/$spielId.worte.txt", $info))  {
		print DATA "$neueworte2\n";
		$dbg->printdbg("-$neueworte2\n");
		fh_close(">>", "data/$spielId.worte.txt", $info);		
	}

	$dbg->printdbg("--$wortZeilen\n");
	return $wortZeilen;
}
#---- wortzeile
sub leseLetzte_wortzeile {
	my $spielId      = $_[0];
	my $wortzeilennr = $_[1];

	my $info    = "leseLetzte_wortzeile";
	my $i   = 0;
	my $ret = '';

	if (fh_openlock("<", "data/$spielId.worte.txt", $info)) {
		$dbg->printdbg("leseLetzte_wortzeile\n");
		while ( ! eof(DATA) ) {
        	chomp(my $line    =  <DATA>);
			$dbg->printdbg("-line:" . $line . "\n");
			if (length($line) > 0) {
				my @feld = split(/\,/,$line);
				if ($feld[0] > $wortzeilennr) {
					$ret = $ret . $line . "+";
				}
			}
			$i = $i + 1;
		}
		fh_close("<", "data/$spielId.worte.txt", $info);
	}
	return $ret;
}




# schreibt die zuege in $brett[r][c] = B
sub zuege_aufs_brett {
	my $spielId  = $_[0];
	my $anzZuege = $_[1];     #anzahl zuege die gelesen werden sollen
	my $info     = "zuege_aufs_brett";

	$dbg->switch(0);
	$dbg->printdbg("zuege_aufs_brett: $spielId, $anzZuege");

	my $bst = 0;     #buchstaben aufs brett
	if ($anzZuege < 1) {
		return $bst;
	}

	my $z   = 0;
	if (fh_openlock("<", "data/$spielId.zuege.txt", $info)) {
		$dbg->printdbg("-zab");
		while ( ! eof(DATA) && $z < $anzZuege) {
        	chomp(my $line    =  <DATA>);
			$dbg->printdbg("-zab line:$line");
			if (length($line) > 0) {
				my @fld  = split(/\,/,$line);
				my $fldn = $#fld;
				$dbg->printdbg("-zab fld:@fld  n:$fldn");
				for (my $i = 2; ($i+2) <= $fldn; $i = $i + 3) {
					$dbg->printdbg("--zab $fld[$i+1] $fld[$i+2] =  $fld[$i]");
					$brett[ $fld[$i+1] ] [ $fld[$i+2] ] = $fld[$i+0];
					$bst = $bst + 1;
				}  
			}
			$z = $z + 1;
		}
		fh_close("<", "data/$spielId.zuege.txt", $info);
	}
	$dbg->printdbg("-zab ret:$bst\n");
	$dbg->switch(0);
	return $bst;
}


my @NBst;   #neue Bst - array
my $NBstN;
sub bst_zug  {
	my $x = $_[0];
	my $y = $_[1];

	for (my $i = 0; $i < $NBstN; $i = $i+1) {
		if ($NBst[$i][1] == $x  &&  $NBst[$i][2] == $y)  {
			return $NBst[$i][0];
		}
	}
	return ".";
}
# buchstaben-zug  
# - sucht nur neue 
# - wenn gefunden setzt auf alt 
sub bst_zug_neuX  {
	my $x = $_[0];
	my $y = $_[1];

	for (my $i = 0; $i < $NBstN; $i = $i+1) {
		if ($NBst[$i][1] == $x  &&  
			$NBst[$i][2] == $y  && 
			$NBst[$i][3] == 1     )  {
			$NBst[$i][3] = 0;	
			return $NBst[$i][0];
		}
	}
	return ".";
}
sub bst_zug_neuY  {
	my $x = $_[0];
	my $y = $_[1];

	for (my $i = 0; $i < $NBstN; $i = $i+1) {
		if ($NBst[$i][1] == $x  &&  
			$NBst[$i][2] == $y  && 
			$NBst[$i][4] == 1     )  {
			$NBst[$i][4] = 0;	
			return $NBst[$i][0];
		}
	}
	return ".";
}
sub worte_aus_zug  {
	my $spielId  = $_[0];
	my $nzugstr  = $_[1];  

	my $worte     = '';  #wort1-wort2-...
	my $bstwerte  = '';  #12345-12345-...
	my $fldwerte  = '';  #12345-12345-...
	my $wortwerte = '';  #12-12-...
	my $ret       = '';  #$worte,$bstwerte,$fldwerte,$wortwerte

	my $nI    = 0;

	$dbg->switch(0);
	$dbg->printdbg("worte_aus_zug: $spielId, $nzugstr");

	my @fld  = split(/\,/, $nzugstr);
	my $fldn = $#fld;
	for (my $i=0, my $fi=2; ($fi+2) <= $fldn; $i = $i + 1, $fi = $fi + 3) {
		$NBst[$i][0] = $fld[$fi];
		$NBst[$i][1] = $fld[$fi+1];
		$NBst[$i][2] = $fld[$fi+2];
		$NBst[$i][3] = 1;
		$NBst[$i][4] = 1;
		$dbg->printdbg("-waz NBst: $NBst[$i][0] $NBst[$i][1] $NBst[$i][2] $NBst[$i][3]");
		$NBstN = $NBstN + 1;
	}
	$dbg->printdbg("-waz NBst: $NBstN");

	for (my $i = 0; $i < $NBstN; $i = $i +1)   {
		my $b= $NBst[$i][0];
		my $x= $NBst[$i][1];
		my $y= $NBst[$i][2];
		my $xneu = $NBst[$i][3];
		my $yneu = $NBst[$i][4];
		$dbg->printdbg("-waz b:$b x:$x y:$y xneu:$xneu yneu:$yneu");

		if ($xneu == 1)  {
			#suche nach dem Ende nach oben (X)
			my $xoben  = 0;
			my $xx     = $x - 1;
			my $ok     = 1;
			if ($xx < 1) { $ok = 0; }
			while ($ok) {
				$dbg->printdbg("-waz $xx,$y b:" . $brett[$xx][$y] . " z:" . bst_zug($xx,$y));
				if ($brett[$xx][$y] ne '.' ||  bst_zug_neuX($xx,$y) ne "." )  {
					$xoben = $xx;
					$xx    = $xx - 1;
					if ($xx < 1)  {
						$ok = 0;
					}
				}
				else  {
					$ok = 0;
				}
			}
			$dbg->printdbg("-waz xoben:$xoben");

			#suche nach dem Ende nach unten (X)
			my $xunten = 0;
			$xx        = $x + 1;
			$ok        = 1;
			if ($xx > 15) { $ok = 0; }
			while ($ok) {
				$dbg->printdbg("--waz $xx,$y b:" . $brett[$xx][$y] . " z:" . bst_zug($xx,$y));
				if ($brett[$xx][$y] ne '.' ||  bst_zug_neuX($xx,$y) ne "." )  {
					$xunten = $xx;
					$xx     = $xx + 1;
					if ($xx > 15)  {
						$ok = 0;
					}
				}
				else  {
					$ok = 0;
				}
			}	
			$dbg->printdbg("-waz yunten:$xunten");

			if ($xoben > 0 || $xunten > 0) {
				if ($xoben  == 0)  { $xoben  = $x; }
				if ($xunten == 0)  { $xunten = $x; }
				$dbg->printdbg("---waz wort von $xoben bis $xunten");
				for (my $xi = $xoben; $xi <= $xunten; $xi = $xi +1) {
					if ($brett[$xi][$y] ne '.') {
						$worte = $worte . $brett[$xi][$y];
						$bstwerte  = $bstwerte . _wert($brett[$xi][$y]) . "."; 
						if ($VielePkte eq '1') {
							$fldwerte  = $fldwerte . $feldwert[$xi][$y] . ".";  					
							$wortwerte = $wortwerte . $wortwert[$xi][$y] . ".";  					
						} 	
						else {
							$fldwerte  = $fldwerte . "1" . ".";  					
							$wortwerte = $wortwerte . "1" . ".";  												
						}				
					}
					else {
						my $c = bst_zug($xi,$y);
						$worte = $worte . $c;
						$bstwerte  = $bstwerte . _wert($c) . ".";  					
						$fldwerte  = $fldwerte . $feldwert[$xi][$y] . ".";  					
						$wortwerte = $wortwerte . $wortwert[$xi][$y] . ".";  					
					}
				}
				$worte = $worte . "-";
				$bstwerte  = $bstwerte . "-";  					
				$fldwerte  = $fldwerte . "-";  					
				$wortwerte = $wortwerte . "-";  					
			}
			else  {
				$dbg->printdbg("---waz kein wort");
			}
		}
		if ($yneu == 1)  {
			#suche nach dem Ende nach links (Y)
			my $ylinks = 0;
			my $yy     = $y-1;
			my $ok     = 1;
			if ($yy < 1) { $ok = 0; }
			while ($ok) {
				$dbg->printdbg("-waz $x,$yy b:" . $brett[$x][$yy] . " z:" . bst_zug($x,$yy));
				if ($brett[$x][$yy] ne '.' ||  bst_zug_neuY($x,$yy) ne "." )  {
					$ylinks = $yy;
					$yy = $yy - 1;
					if ($yy < 1)  {
						$ok = 0;
					}
				}
				else  {
					$ok = 0;
				}
			}
			$dbg->printdbg("-waz ylinks:$ylinks");

			#suche nach dem Ende nach rechts (Y)
			my $yrechts = 0;
			$yy         = $y + 1;
			$ok         = 1;
			if ($yy > 15) { $ok = 0; }
			while ($ok) {
				$dbg->printdbg("--waz $x,$yy b:" . $brett[$x][$yy] . " z:" . bst_zug($x,$yy));
				if ($brett[$x][$yy] ne '.' ||  bst_zug_neuY($x,$yy) ne "." )  {
					$yrechts = $yy;
					$yy = $yy + 1;
					if ($yy > 15)  {
						$ok = 0;
					}
				}
				else  {
					$ok = 0;
				}
			}	
			$dbg->printdbg("-waz yrechts:$yrechts");

			if ($ylinks > 0 || $yrechts > 0) {
				if ($ylinks  == 0)  { $ylinks  = $y; }
				if ($yrechts == 0)  { $yrechts = $y; }
				$dbg->printdbg("---waz wort von $ylinks bis $yrechts");
				for (my $yi = $ylinks; $yi <= $yrechts; $yi = $yi +1) {
					if ($brett[$x][$yi] ne '.') {
						$worte = $worte . $brett[$x][$yi];
						$bstwerte  = $bstwerte . _wert($brett[$x][$yi]) . ".";  					
						if ($VielePkte eq '1') {
							$fldwerte  = $fldwerte . $feldwert[$x][$yi] . ".";  					
							$wortwerte = $wortwerte . $wortwert[$x][$yi] . ".";  					
						}
						else {
							$fldwerte  = $fldwerte . "1" . ".";  					
							$wortwerte = $wortwerte . "1" . ".";  					
						}
					}
					else {
						my $c = bst_zug($x,$yi);
						$worte = $worte . $c;
						$bstwerte  = $bstwerte . _wert($c) . ".";  					
						$fldwerte  = $fldwerte . $feldwert[$x][$yi] . ".";  					
						$wortwerte = $wortwerte . $wortwert[$x][$yi] . ".";  					
					}
				}
				$worte = $worte . "-";
				$bstwerte  = $bstwerte . "-";  					
				$fldwerte  = $fldwerte . "-";  					
				$wortwerte = $wortwerte . "-";  					
			}
			else  {
				$dbg->printdbg("---waz kein wort");
			}
		}
	}
	$dbg->printdbg("-waz return $fld[1] $worte, $bstwerte, $fldwerte, $wortwerte");
	$dbg->switch(0);
	return ($fld[1], $worte, $bstwerte, $fldwerte, $wortwerte);
}

sub punkte_aus_zug
{
	my $spieler   = $_[0];
	my $worte     = $_[1];
	my $bstwerte  = $_[2];
	my $fldwerte  = $_[3];
	my $wortwerte = $_[4];

	$dbg->switch(0);
	$dbg->printdbg("punkte_aus_zug:" . 
	               $worte . "," .
				   $bstwerte . "," .
				   $fldwerte . "," .
				   $wortwerte );

	my @wortA  = split(/\-/, $worte);
	my @bstA   = split(/\-/, $bstwerte);
	my @fldwA  = split(/\-/, $fldwerte);
	my @wortwA = split(/\-/, $wortwerte);

	my $pkt = 0;
	my $anz = scalar @wortA;
	$dbg->printdbg("-paz:" . 
	               @wortA . "," .
				   @bstA . "," .
				   @fldwA . "," .
				   @wortwA . ":" . $anz );
	for (my $i = 0; $i < $anz; $i = $i +1) {
		my @bstAA    = split(/\./, $bstA[$i]);
		my @fldwAA   = split(/\./, $fldwA[$i]);
		my @wortwAA  = split(/\./, $wortwA[$i]);
		$dbg->printdbg("paz:" . $i . "," . $wortA[$i]);
 
		my $anzz = scalar @bstAA;
		my $pktw = 0;
		my $wortww = 1;
		for (my $j = 0; $j < $anzz; $j = $j +1) {
			$pktw = $pktw + $bstAA[$j] * $fldwAA[$j];
			$wortww = $wortww * $wortwAA[$j];
			$dbg->printdbg("paz-b:" . $j . "," . $bstAA[$j] * $fldwAA[$j] . "," . $pktw );
		}
		$pktw = $pktw * $wortww;
		$wortA[$i] = $wortA[$i] . "_" . $pktw;
		$pkt = $pkt + $pktw;
		$dbg->printdbg("paz:" .  $wortA[$i] . "," . $pkt);
	}
	my $worte2 = join (',', @wortA);

	$dbg->printdbg("paz ret:" .  $pkt . "," . $worte2);
	$dbg->switch(0);

	return ($pkt, $worte2);
}




sub zuege_getlist
{
	#zuege_lesen();

	my $idx = 1;
	my $e = '';
	while($idx <= $zuegeN) {
		$e      = $e . $zuege[$idx][0] . ' ';
		$e      = $e . '[' . $zuege[$idx][1] . '] ';
		my $anz = $zuege[$idx][2];
		my $i   = 3;
		while ( $i<=($anz*3) ) {
			$e = $e . '(' . 
				$zuege[$idx][$i] . ',' .
				$zuege[$idx][$i+1] . ',' .
				$zuege[$idx][$i+2] . ')';
			$i = $i + 3;
		}
		$e = "$e<br/>\n";
		$idx = $idx + 1;
	}
	return $e;
}

my $zuegelist = zuege_getlist();

sub schreibe_legeBuchstabe
{
   my $spielId 	 = $_[0];
   my $spieler 	 = $_[1];
   my $x 	     = $_[2];
   my $y 	     = $_[3];
   my $buchstabe = $_[4];
   my $aktionsnr = $_[5];
   my $clname    = $_[6];
   my $info      = "schreibe_legeBuchstabe";

   $dbg->printdbg("schreibe_legeBuchstabe: $spielId $spieler $x $y $buchstabe $clname");

   my $ret = 0;
   if (fh_openlock(">>", "data/$spielId.aktionen.txt", $info)) {
		print DATA "$aktionsnr,$spieler,$x,$y,$buchstabe,$clname\n";
		fh_close(">>", "data/$spielId.aktionen.txt", $info);
		$ret = 1;
   }		
   return $ret;
}
sub lese_legeBuchstaben
{
	my $spielId 	= $_[0];
	my $aktionsnrAb	= $_[1];
   	my $info      = "lese_legeBuchstaben";

	my $ret  = "";
	my $line = "-";
   	$dbg->printdbg("lese_legeBuchstaben ab: $aktionsnrAb");
   	$dbg->printdbg("-vor open");
	if (fh_openlock("<", "data/$spielId.aktionen.txt", $info))  {
   		$dbg->printdbg("-nach open");
		while(!eof(DATA)) {
   			$dbg->printdbg("-vor lese");
			chomp($line = <DATA>);
   			$dbg->printdbg("-nach lese:" . $line);
			my ($aktionsnr, $spieler, $x, $y, $buchstabe, $clname) = split(/\,/,$line);
			if ($aktionsnr > $aktionsnrAb)  {
				$ret = $ret . $line . "+";				
			}
		}
   		$dbg->printdbg("-vor close");
		fh_close("<", "data/$spielId.aktionen.txt", $info);		
	}
	if (length($ret) == 0)  {
		$ret = "-";
	}
   	$dbg->printdbg("-ret: $ret");
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
	$dbg->printdbg("delete_all_data_dbg_files");
	unlink <data/*.txt>;
	unlink <dbgfiles/*.dbg>;
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
	unlink <data/$spielId.ende.txt>;
}

sub init_beutel
{
	my $ret = '';
	##ori 
	for (my $a1 = 0 ; $a1 < 30; $a1=$a1+1) {
	##test
	#for (my $a1 = 0 ; $a1 < 4; $a1=$a1+1) {
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
			print DATA "$beutel\n";
			fh_close(">", $fileName, $info);
		}		
	}	
	
	my $ret = '';
	my $line = '';
	if (fh_openlock("<", $fileName, $info)) {
		#letzte zeile lesen
		while (!eof(DATA)) {
			chomp($line = <DATA>);
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
		print DATA "$beutel\n";
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
		print DATA "$beutel\n";
		fh_close(">>", $fileName, $info);
		$ret = 1;
	}

	$dbg->printdbg("---ret: $ret");
	$dbg->switch(0);

	return $ret;
}

#print "$beutel\n";
#gebesteine_beutel(7);



sub linesNo_file
{
	my $fileName  = $_[0];
	my $info      = "linesNo_file";
    my $lines = 0;
	my $ok    = 0;

    if (fh_openlock("<", $fileName, $info))  {
		while (!eof(DATA)) {
			my $line;
			chomp($line = <DATA>);
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
			while(!eof(DATA)) {
				chomp($lines[$lineI] = <DATA>);
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
					print DATA "$lines[$i]\n";
					$i = $i + 1;
				}
				fh_close(">", $fileName, $info);
			}
		}
		else{
			if (fh_openlock(">", $fileName, $info)) {
				print DATA "vielepkte,$vielepkte,softend,$softend,mitveto,$mitveto\n";
				my $i = 0;
				while ($i < $lineI) {
					print DATA "$lines[$i]\n";
					$i = $i + 1;
				}
				fh_close(">", $fileName, $info);
			}
		}
	} 
	else   #in neue datei schreiben
	{
		if (fh_openlock(">", $fileName, $info)) {
			print DATA "vielepkte,$vielepkte,softend,$softend,mitveto,$mitveto\n";
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
			if (!eof(DATA)) {
				chomp($line = <DATA>);
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


## vorhandene Spieler, und wer ist aktiv
## DatenStruktur: data/<spielId>.info.txt
## bsp:  0,hugo,10     - hugo ist nicht aktiv und hat 10 Punkte  

# add a row to data/<spielId>.info.txt
sub add_spieler
{
	my $spielId  = $_[0];
	my $spieler  = $_[1];
	my $vielepkte = $_[2];
	my $softend  = $_[3];
	my $mitveto  = $_[4];

	my $info     = "add_spieler";

	my $ret      = 0;

	$dbg->printdbg("add_spieler:$spielId,$spieler");

	my $fileName = "data/$spielId.info.neu.txt";
	
	add_settings($fileName,$vielepkte,$softend,$mitveto);

	if (fh_openlock(">>", $fileName, $info)) {
		print DATA "0,$spieler,0,0\n";
		$dbg->printdbg("-:0,$spieler");
		$ret = 1;
		fh_close(">>", $fileName, $info);
	}

	$dbg->printdbg("-ret:$ret");
	return $ret;
}
sub alle_spieler
{
	my $spielId  = $_[0];
	my $info     = "alle_spieler";

	$dbg->printdbg("alle_spieler:$spielId");

	my $fileName = "data/$spielId.info.txt";

	my $ret = '';
	if (fh_openlock("<", $fileName, $info)) {
    	while (!eof(DATA)) {
			my $line;
			chomp($line = <DATA>);
      		$ret = $ret . "," . $line;
    	}
    	fh_close("<", $fileName, $info);
	}

	$dbg->printdbg("-alle:$ret");
	return $ret;
}


sub aktiviere_spieler
{
	my $spielId  = $_[0];
	my $spieler  = $_[1];
	my $aktiv    = $_[2];
	my $info     = "aktiviere_spieler";

	$dbg->switch(0);
	$dbg->printdbg("aktiviere_spieler:$spielId,$spieler,$aktiv");

	my $fileName = "data/$spielId.info.txt";

	
	my $ret = -1;
	my @spieler;
	my $spI = 0;
	my $settings = '';

	if (fh_openlock("<", $fileName, $info))  {
		if (!eof(DATA)) {
    		chomp($settings = <DATA>);
		}
		while ( !eof(DATA)) {
			my $line;
			chomp($line = <DATA>);
			my ($a,$b,$c,$d) =  split(/\,/, $line);
			$dbg->printdbg("- $a,$b,$c,$d");
			$spieler[$spI][0] = $a;
			$spieler[$spI][1] = $b;
			$spieler[$spI][2] = $c;
			$spI = $spI + 1;
    	}
    	fh_close("<", $fileName, $info);
	}

	if ($aktiv == 1)  {
		if (fh_openlock(">", $fileName, $info)) {
			print DATA "$settings\n";
			for (my $i = 0; $i < $spI; $i = $i +1) {
				if ($spieler[$i][1] eq $spieler) {
					print DATA "1,$spieler[$i][1],$spieler[$i][2],+\n";
					$dbg->printdbg("-aktiv:$spieler[$i][1]");
					$ret = 1;
				} 
				else {
					print DATA "0,$spieler[$i][1],$spieler[$i][2],+\n";
					$dbg->printdbg("-nicht aktiv:$spieler[$i][1]");
				}
			}
			fh_close(">", $fileName, $info);
		}
	}
	if ($aktiv == 0)  {
		if (fh_openlock(">", $fileName, $info)) {
			print DATA "$settings\n";
			for (my $i = 0; $i < $spI; $i = $i +1) {
				print DATA "0,$spieler[$i][1],$spieler[$i][2],+\n";
				$dbg->printdbg("--all nicht aktiv:$spieler[$i][1]");
			}
			fh_close(">", $fileName, $info);
			$ret = 0;
		}
	}			

	$dbg->printdbg("-ret:$ret");
	$dbg->switch(0);
	return $ret;
}

sub aktiviere_nachfolger
{
	my $spielId  = $_[0];
	my $spieler  = $_[1];
	my $info     = "aktiviere_nachfolger";

	$dbg->switch(0);
	$dbg->printdbg("aktiviere_nachfolger:$spielId,$spieler");

	my $fileName = "data/$spielId.info.txt";

	
	my $ret = -1;
	my @spieler;
	my $spI = 0;
	my $settings = '';

	if (fh_openlock("<", $fileName, $info))  {
		if (!eof(DATA)) {
    		chomp($settings = <DATA>);
		}
    	while ( !eof(DATA)) {
			my $line;
			chomp($line = <DATA>);
			my ($a,$b,$c,$d) = split(/\,/, $line);
			$dbg->printdbg("- $a,$b,$c,$d");
			$spieler[$spI][0] = $a;
			$spieler[$spI][1] = $b;
			$spieler[$spI][2] = $c;
			$spI = $spI + 1;
    	}
    	fh_close("<", $fileName, $info);
	}

	my $aktI   = 0;
	my $nextI  = -1;
	for (my $i = 0; $i < $spI; $i = $i +1) {
		if ($spieler[$i][1] eq $spieler) {
			$aktI = $i;
		}
	}
	
	if ($spI == 1)  {    #nur ein spieler
						 #der muss neu 'starten' druecken   
	}
	else  {              #mehrere spieler
		$nextI = $aktI + 1;
		if ($nextI >= $spI)  {
			$nextI = 0;
		}
	}

	if (fh_openlock(">", $fileName, $info)) {
		print DATA "$settings\n";
		for (my $i = 0; $i < $spI; $i = $i +1) {
			if ($i == $nextI)  {
				print DATA "1,$spieler[$i][1],$spieler[$i][2],+\n";
				$dbg->printdbg("-aktiv:$spieler[$i][1]");
			}
			else  {
				print DATA "0,$spieler[$i][1],$spieler[$i][2],+\n";
				$dbg->printdbg("--nicht aktiv:$spieler[$i][1]");
			}
		}
		fh_close(">", $fileName, $info);
		$ret = 1;
	}
	
	$dbg->printdbg("-ret:$nextI");
	$dbg->switch(0);
	return $ret;
}
sub deaktivieren_alle
{
	my $spielId  = $_[0];
	my $info     = "deaktivieren_alle";

	$dbg->switch(1);
	$dbg->printdbg("$info:$spielId");

	my $fileName = "data/$spielId.info.txt";
	
	my $ret = -1;
	my @spieler;
	my $spI = 0;
	my $settings = '';

	if (fh_openlock("<", $fileName, $info))  {
		if (!eof(DATA)) {
    		chomp($settings = <DATA>);
		}
    	while ( !eof(DATA)) {
			my $line;
			chomp($line = <DATA>);
			my ($a,$b,$c,$d) = split(/\,/, $line);
			$dbg->printdbg("- $a,$b,$c,$d");
			$spieler[$spI][0] = $a;
			$spieler[$spI][1] = $b;
			$spieler[$spI][2] = $c;
			$spI = $spI + 1;
    	}
    	fh_close("<", $fileName, $info);
	}
	$dbg->printdbg("- gelesen:$spI");

	if (fh_openlock(">", $fileName, $info)) {
		print DATA "$settings\n";
		for (my $i = 0; $i < $spI; $i = $i +1) {
			print DATA "0,$spieler[$i][1],$spieler[$i][2],+\n";
			$dbg->printdbg("--nicht aktiv:$spieler[$i][1],$spieler[$i][2],+");
		}
		fh_close(">", $fileName, $info);
		$ret = 1;
	}

	$dbg->printdbg("-ret:$ret");	
	$dbg->switch(0);
	return $ret;
}


sub zustand_spieler
{
	my $spielId  = $_[0];
	my $info     = "zustand_spieler";

	my $fileName = "data/$spielId.info.txt";

	if (scalar (@_)  > 1  &&  $_[1] == "1") {
		$fileName = "data/$spielId.info.neu.txt";
	}

	$dbg->switch(0);
	$dbg->printdbg("zustand_spieler:$fileName");

	my $ret = "";

	my $settings = '';

	if (fh_openlock("<", $fileName, $info)) {
		if (!eof(DATA)) {
    		chomp($settings = <DATA>);
		}
    	while ( !eof(DATA)) {
			my $line;
			chomp($line = <DATA>);
			my ($a,$b,$c,$d) =  split(/\,/, $line);
			$ret = $ret . "$a,$b,$c,$d,";
			$dbg->printdbg("- $a,$b,$c,$d");
		}
    	fh_close("<", $fileName, $info);
	} 
	else {
		$fileName = "data/$spielId.info.txt";
		if (fh_openlock("<", $fileName, $info)) {
			if (!eof(DATA)) {
				chomp($settings = <DATA>);
			}
    		while ( !eof(DATA)) {
				my $line;
				chomp($line = <DATA>);
				my ($a,$b,$c,$d) =  split(/\,/, $line);
				$ret = $ret . "$a,$b,$c,$d,";
				$dbg->printdbg("- $a,$b,$c,$d");
			}
    		fh_close("<", $fileName, $info);
		}
	}	
	
	if (length($ret) < 2) {
		$ret = "-";
	}
	$dbg->printdbg("-ret:$ret");
	return $ret;
}

#nach anmelden der spieler
sub kontrolle_spieltId
{
	my $spielId = $_[0];
	my $spieler = $_[1];
	my $info    = "kontrolle_spieltId";
	
	my $fn    = "data/$spielId.info.txt";
	my $fnNeu = "data/$spielId.info.neu.txt";

    my $ret  = 0;

	$dbg->switch(0);
	$dbg->printdbg("kontrolle_spielId:" . $spielId);

	my $spieler_alt = '';
	my $spieler_neu = '';

	my $settings = '';

	if (fh_openlock("<", $fnNeu, $info)) {
		if (!eof(DATA)) {
    		chomp($settings = <DATA>);
		}
		while ( !eof(DATA)) {
			my $line;
			chomp($line = <DATA>);
			my ($a,$b,$c,$d) =  split(/\,/, $line);
			$spieler_neu = $spieler_neu . $b . ",";
		}
		fh_close("<", $fnNeu, $info);
	}
	$dbg->printdbg("-neu: $spieler_neu");
	my @neu = split(/\,/, $spieler_neu);


	my @alt;
	my $settings2 = '';
	if (-e $fn) {
		$dbg->printdbg("-es gibt schon $spielId.info.txt");
		#es gibt schon eine session mit 'spielId'
		if (fh_openlock("<", $fn, $info)) {
			if (!eof(DATA)) {
				chomp($settings2 = <DATA>);
			}
			while ( ! eof(DATA)) {
				my $line;
				chomp($line = <DATA>);
				my ($a,$b,$c,$d) =  split(/\,/, $line);
				$spieler_alt = $spieler_alt . $b . ",";
			}
			fh_close("<", $fn, $info);
			@alt = split(/\,/, $spieler_alt);
		}
	}
	else  {
		$dbg->printdbg("- OK $spielId.info.txt");
		if (fh_openlock(">", $fnNeu, $info)) {
			print DATA "$settings\n";
			for (my $i = 0; $i < scalar(@neu); $i = $i +1) {
				print DATA "0,$neu[$i],0,+\n";
				$dbg->printdbg("- $fnNeu: 0,$neu[$i],0,+");
			}
			fh_close(">", $fnNeu, $info);
			system("cp $fnNeu $fn");  
			$ret = 1;
			return $ret;
		}
	}

	$dbg->printdbg("-alt: $spieler_alt");

	my $idIstBelegt = 1;
	if (scalar(@alt) == scalar(@neu)) {
		for (my $i = 0; $i < scalar(@neu); $i = $i +1) {
			my $found = 0;
			for (my $j = 0; $j < scalar(@alt); $j = $j +1) {
				if ($neu[$i] eq $alt[$j])  {
					$found = 1;
				}
				$dbg->printdbg("- ?: $neu[$i] -- $alt[$j], $found");
			}
			if ($found == 0)  {
				$idIstBelegt = 0;
			}
			$dbg->printdbg("- ??: $found, $idIstBelegt");
		}
	} 
	else  {
		$idIstBelegt = 0;
	}

	$dbg->printdbg("- idIstBelegt:$idIstBelegt");

	my $neueId = '';
	if ($idIstBelegt == 1) {
		my @chars = ("A".."Z", "a".."z", "0".."9");
		$neueId .= $chars[rand @chars] for 1..4;

		$dbg->printdbg("- neue id: $neueId");
	
		if (fh_openlock(">", $fnNeu, $info)) {
			print DATA "$settings\n";
			for (my $i = 0; $i < scalar(@neu); $i = $i +1) {
				print DATA "n,$neu[$i],0,$neueId\n";
				$dbg->printdbg("- $fnNeu: n,$neu[$i],0,$neueId");
			}
			fh_close(">", $fnNeu, $info);
			$ret = 2;
		}
		my $fnNeueId = "data/$neueId.info.txt";
		if (fh_openlock(">", $fnNeueId, $info)) {
			print DATA "$settings\n";
			for (my $i = 0; $i < scalar(@neu); $i = $i +1) {
				if ($spieler eq $neu[$i]) {
					print DATA "1,$neu[$i],0,0\n";
					$dbg->printdbg("-- $fnNeueId: 1,$neu[$i],0,0");
				}
				else {
					print DATA "0,$neu[$i],0,0\n";
					$dbg->printdbg("-- $fnNeueId: 0,$neu[$i],0,0");
				}
			}
			fh_close(">", $fnNeueId, $info);
			$ret = 2;
		}
	}
	if ($idIstBelegt == 0) {
		$dbg->printdbg("- OK nach delete.. $spielId.info.txt");
    	FScrab::delete_all_data_files($spielId);
		if (fh_openlock(">", $fnNeu, $info)) {
			print DATA "$settings\n";
			for (my $i = 0; $i < scalar(@neu); $i = $i +1) {
				print DATA "0,$neu[$i],0,+\n";
				$dbg->printdbg("- $fnNeu: n,$neu[$i],0,+");
			}
			fh_close(">", $fnNeu, $info);
		}
		system("cp $fnNeu $fn");  
		$ret = 1;
	}
	return $ret;
}


sub get_spieler_punkte
{
	my $spielId     = $_[0];
	my $pktspieler  = $_[1];
	my $info        = "get_spieler_punkte";
	$dbg->switch(0);
	$dbg->printdbg("$info:$spielId,$pktspieler");

	my $fileName = "data/$spielId.info.txt";

	
	my $ret = -1;

	my $settings = '';

	if (fh_openlock("<", $fileName, $info))  {
		if (!eof(DATA)) {
    		chomp($settings = <DATA>);
		}		
    	while ( !eof(DATA)) {
			my $line;
			chomp($line = <DATA>);
			my ($a,$b,$c,$d) =  split(/\,/, $line);
			$dbg->printdbg("- $a,$b,$c,$d");
			if ($b eq $pktspieler) {
				$ret = $c;
			}
		}
    	fh_close("<", $fileName, $info);
	}
	$dbg->printdbg("-ret:$ret");
	$dbg->switch(0);
	return $ret;
}

sub schreibe_pkt_spieler
{
	my $spielId     = $_[0];
	my $pktspieler  = $_[1];
	my $pkt         = $_[2];
	my $info        = "schreibe_pkt_spieler";

	$dbg->switch(0);
	$dbg->printdbg("scheibe_pkt_spieler:$spielId,$pktspieler,$pkt");

	my $fileName = "data/$spielId.info.txt";

	
	my $ret = -1;
	my @spieler;
	my $spI = 0;
	my $settings = '';

	if (fh_openlock("<", $fileName, $info))  {
		if (!eof(DATA)) {
    		chomp($settings = <DATA>);
		}
    	while ( !eof(DATA)) {
			my $line;
			chomp($line = <DATA>);
			my ($a,$b,$c,$d) =  split(/\,/, $line);
			$dbg->printdbg("- $a,$b,$c,$d");
			$spieler[$spI][0] = $a;
			$spieler[$spI][1] = $b;
			$spieler[$spI][2] = $c;
			$spI = $spI + 1;
    	}
    	fh_close("<", $fileName, $info);
	}

	for (my $i = 0; $i < $spI; $i = $i +1) {
		if ($spieler[$i][1] eq $pktspieler) {
			$spieler[$i][2] = $spieler[$i][2] + $pkt;
			$dbg->printdbg("- sps:$spieler[$i][1] $spieler[$i][2]");
		}
	}
	if (fh_openlock(">", $fileName, $info)) {
		print DATA "$settings\n";
		for (my $i = 0; $i < $spI; $i = $i +1) {
			print DATA "$spieler[$i][0],$spieler[$i][1],$spieler[$i][2],0\n";
			$ret = 1;
		} 
    	fh_close(">", $fileName, $info);
	}
	$dbg->printdbg("-sps ret:$ret");
	$dbg->switch(0);
	return $ret;
}



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




sub vetoDatei_aktionen
{
	my $spielId = $_[0];
	my $spieler = $_[1];
	my $aktion  = $_[2];

	my $info    = "vetoDatei_aktionen";
	my $ret 	= 1;

	# aktion:'c'  - create veto-datei
	if ($aktion eq 'c') {
		my $fileName = "data/$spielId.info.txt";
		my @spielerA;
		my $spI = 0;

		if (fh_openlock("<", $fileName, $info))  {
			while ( !eof(DATA)) {
				my $line;
				chomp($line = <DATA>);
				my ($a,$b,$c,$d) =  split(/\,/, $line);
				$dbg->printdbg("- $a,$b,$c,$d");
				$spielerA[$spI][0] = $a;
				$spielerA[$spI][1] = $b;
				$spielerA[$spI][2] = $c;
				$spI = $spI + 1;
			}
			fh_close("<", $fileName, $info);
		}
		else {
			$ret = 0;
		}

		$fileName = "data/$spielId.veto.txt";
		if (fh_openlock(">", $fileName, $info))  {
			for (my $i = 0; $i < $spI; $i = $i + 1) {
				print DATA "$spielerA[$i][0],$spielerA[$i][1],0\n";
			}
			fh_close(">", $fileName, $info);
		}
		else {
			$ret = 0;
		}
	}

	# aktion:'d'  - delete veto-datei
	if ($aktion eq 'd') {
		unlink <data/$spielId.veto.txt>;
	}

	# aktion:'y' 'n'  - veto entscheidung schreiben
	if ($aktion eq 'y' ||  $aktion eq 'n') {
		my $fileName = "data/$spielId.veto.txt";
		my @spielerA;
		my $spI = 0;

		if (fh_openlock("<", $fileName, $info))  {
			while ( !eof(DATA)) {
				my $line;
				chomp($line = <DATA>);
				my ($a,$b,$c) =  split(/\,/, $line);
				$dbg->printdbg("- $a,$b,$c");
				$spielerA[$spI][0] = $a;
				$spielerA[$spI][1] = $b;
				$spielerA[$spI][2] = $c;
				$spI = $spI + 1;
			}
			fh_close("<", $fileName, $info);
		}
		else {
			$ret = 0;
		}

		if (fh_openlock(">", $fileName, $info))  {
			for (my $i = 0; $i < $spI; $i=$i+1)	{
				if ($spieler eq $spielerA[$i][1]) {
					print DATA "$spielerA[$i][0],$spielerA[$i][1],$aktion\n";
				}
				else  {
					print DATA "$spielerA[$i][0],$spielerA[$i][1],$spielerA[$i][2]\n";
				}
			}
			fh_close(">", $fileName, $info);
		}
		else {
			$ret = 0;
		}
	}
	return $ret;
}

sub vetoDatei_status
{
	my $spielId  = $_[0];
	my $info     = "vetoDatei_status";

	my $fileName = "data/$spielId.veto.txt";
	my $ret      = "";

	$dbg->switch(0);
	$dbg->printdbg("vetoDatei_status:$spielId");

	my  $fexists = 0;
	if (-e $fileName)  { 
		$fexists = 1; 
	};
	$dbg->printdbg("-$fileName,$fexists");
	$dbg->printdbg("--");
	
	if ($fexists == 0)  {
		$dbg->printdbg("---");
		$ret = "-";
		$dbg->printdbg("-ret:$ret");
		$dbg->switch(0);
		return $ret;
	}

	if (fh_openlock("<", $fileName, $info))  {
		$dbg->printdbg("----");
		while ( !eof(DATA)) {
				my $line;
				chomp($line = <DATA>);
				$ret = $ret . $line . "+";
		}
		fh_close("<", $fileName, $info);
	}
	$dbg->printdbg("-ret:$ret");
	$dbg->switch(0);
	return $ret;			
}


sub schreibe_bank
{
	my $spielId = $_[0];
	my $spieler = $_[1];
	my $bank    = $_[2];

	my $info      = "schreibe_bank";
	
	my $fileName  = "data/$spielId.bank.txt";

	my $ret = 0;
	my @lines;
	my $lineI = 0;
	if (-e $fileName) {
		my $line;
		if (fh_openlock("<", $fileName, $info)) {
			while(!eof(DATA)) {
				chomp($lines[$lineI] = <DATA>);
				$lineI = $lineI + 1;
			}
			fh_close("<", $fileName, $info);
		}

		my $found = 0;
		my $i = 0;
		for ($i = 0; $i < $lineI; $i = $i +1)
		{
			if (index($lines[$i],$spieler) > -1) {
				$lines[$i] = "$spieler,$bank";
				$found = 1;
				$ret = 1;
			}
		}
		if ($found == 0) {
			$lines[$lineI] = "$spieler,$bank";
			$lineI = $lineI +1;
			$ret = 1;
		}
	}
	else  {
		$lines[$lineI] = "$spieler,$bank";
		$lineI = $lineI +1;
		$ret = 1;
	}

	if (fh_openlock(">", $fileName, $info)) {
		my $i = 0;
		while ($i < $lineI) {
			print DATA "$lines[$i]\n";
			$i = $i + 1;
		}
		fh_close(">", $fileName, $info);
	}
	return $ret;
}



# schreibt in  <spielId>.bank.txt    ein  '#'
# als Zeichen dafür das ein Spieler geschoben hat 
#  (ohne tausch/setzen einfach weiter)
sub schreibe_geschoben  
{
	my $spielId = $_[0];
	my $spieler = $_[1];

	my $info      = "schreibe_geschoben";
	
	my $fileName  = "data/$spielId.bank.txt";

	my $ret = 0;
	my @lines;
	my $lineI = 0;
	if (-e $fileName) {
		my $line;
		if (fh_openlock("<", $fileName, $info)) {
			while(!eof(DATA)) {
				chomp($lines[$lineI] = <DATA>);
				$lineI = $lineI + 1;
			}
			fh_close("<", $fileName, $info);
		}

		my $found = 0;
		my $i = 0;
		for ($i = 0; $i < $lineI; $i = $i +1)
		{
			if (index($lines[$i],$spieler) > -1) {
				$lines[$i] = $lines[$i] .",#";
				$found = 1;
				$ret = 1;
			}
		}
		if ($found == 0) {
			$lines[$lineI] = "$spieler,#";
			$lineI = $lineI +1;
			$ret = 1;
		}
	}
	if (fh_openlock(">", $fileName, $info)) {
		my $i = 0;
		while ($i < $lineI) {
			print DATA "$lines[$i]\n";
			$i = $i + 1;
		}
		fh_close(">", $fileName, $info);
	}
	return $ret;
}

sub SpielZuEnde
{
	my $spielId = $_[0];
	my $info    = "SpielZuEnde";

	my $fileName = "data/$spielId.ende.txt";
	my $ret = 0;

	if (-e $fileName) {
		$ret = 1;
	}
	
	$dbg->switch(1);
	$dbg->printdbg("$info:ret:$ret");
	$dbg->switch(0);

	return $ret;
}
sub SetSpielZuEnde
{
	my $spielId = $_[0];
	my $info    = "SetSpielZuEnde";
	
	my $fileName = "data/$spielId.ende.txt";

	$dbg->switch(1);
	$dbg->printdbg("$info  fileName:$fileName");

	if (fh_openlock(">", $fileName, $info)) {
		print DATA "123\n";
		fh_close(">", $fileName, $info);
	}

	deaktivieren_alle($spielId);

	return SpielZuEnde();
}


## - hartem Ende  
##     ob eine Zeile mit keinen Buchstaben (nur '-')
## - softes Ende
##     ob alle Zeilen mit - keinem Buchstaben (nur '-') oder  '#'
sub SpielerZuegeZuEnde
{
	my $spielId = $_[0];

	my $info     = "SpielerZuegeZuEnde";

    my $fileName = "data/$spielId.bank.txt";

	my $ret = 0;

	$dbg->switch(1);
	$dbg->printdbg("$info");

	## beutel leer ?
	my $beutel = hole_beutel($spielId);
	$dbg->switch(1);
	$dbg->printdbg("-beutel: $beutel");
	if ($beutel ne '-') {
		$ret = 0;
		$dbg->printdbg("-ret: $ret");
		$dbg->switch(0);
		return $ret;
	}

	my @lines;
	my $lineI = 0;
	if (fh_openlock("<", $fileName, $info)) {
		while(!eof(DATA)) {
			chomp($lines[$lineI] = <DATA>);
			$dbg->printdbg("-lines[$lineI]: $lines[$lineI]");
			$lineI = $lineI + 1;
		}
		fh_close("<", $fileName, $info);
	}

	## je spieler
	#   0: spieler hat buchstaben und nicht geschoben
	#   1: spieler hat die bank leer und nicht geschoben
	#  10: spieler hat buchstaben und geschoben
	#  11: spieler hat die bank leer und geschoben 
	my @endeModes;    # 0:hat buchstaben   1:bank leer   +10:geschoben
	for (my $i = 0; $i < $lineI; $i = $i + 1) {

		$endeModes[$i] = 0;

		my $line = $lines[$i];
		my $len  = length($line);
		$dbg->printdbg("-str:$line  len:$len");

		my $leer      = 1;
		my $geschoben = 0;
		my $kommas    = 0;
		for (my $j = 0; $j < $len; $j = $j + 1) {
			my $b = substr($line,$j, 1);
			if ($b eq ',') {
				$kommas = $kommas + 1;
			}
			if ($kommas > 0) {
				if ($b ne ',' &&  $b ne '-'  &&  $b ne '#') {
					$leer = 0;				
				}
				if ($b eq '#') {
					$geschoben = 1;				
				}
			}
		}
		if ($leer == 1) {
			$endeModes[$i] =  1;
		}
		if ($geschoben == 1) {
			$endeModes[$i] = $endeModes[$i] + 10;
		}
		$dbg->printdbg("- lines:$lines[$i]  - endeModes:$endeModes[$i]");
	}

	##zufa
	my $hatEnde = 0;
	my $rundeZuEnde = 0;
	my $alleGeschoben = 1;
	
	for (my $i = 0; $i < $lineI; $i = $i + 1) {
		if ($endeModes[$i] == 1) {
			$hatEnde = 1;
		} elsif ($endeModes[$i] == 11) {
			$hatEnde     = 1;
			$rundeZuEnde = 1;
		}

		if ($endeModes[$i] == 0) {
			$alleGeschoben = 0;
		}
	}
	
	$dbg->printdbg("-hatEnde:$hatEnde  rundeZuEnde:$rundeZuEnde  alleGeschoben:$alleGeschoben");

	my $ret = 0;
	if ($hatEnde == 1)  {
		$ret = 1;     # Voraussetung fuers harte Ende
	}
	if ($rundeZuEnde == 1)  {
		$ret = 2;     # Voraussetung fuers harte+softes Ende
	}
	if ($alleGeschoben == 1) {
		$ret = 3;     # Bedingung fuers lahmes Ende
	}

	$dbg->printdbg("-ret: $ret");
	$dbg->switch(0);
	return $ret;		
}


sub EndAbrechnung
{
	my $spielId = $_[0];

	my $info = "EndAbrechnung";

	my $fileNameInfo = "data/$spielId.info.txt";
	my $fileNameBank = "data/$spielId.bank.txt";
	
	my $ret = 0;

	$dbg->switch(1);
	$dbg->printdbg("$info  mit $fileNameInfo  $fileNameBank");

	my @blines;
	my $blineI = 0;
	if (fh_openlock("<", $fileNameBank, $info)) {
		while(!eof(DATA)) {
			my $line = '';
			chomp($line = <DATA>);
			my ($a,$b,$c) = split(/\,/, $line);
			$blines[$blineI][0] = $a;
			$blines[$blineI][1] = $b;
			$blines[$blineI][2] = $c;
			$blineI = $blineI + 1;
		}
		$ret = $ret + 1;
		fh_close("<", $fileNameBank, $info);
	}


	my @spieler;
	my $spI = 0;
	my $settings = '';

	if (fh_openlock("<", $fileNameInfo, $info))  {
		if (!eof(DATA)) {
    		chomp($settings = <DATA>);
		}
		while ( !eof(DATA)) {
			my $line;
			chomp($line = <DATA>);
			my ($a,$b,$c,$d) =  split(/\,/, $line);
			$dbg->printdbg("- $a,$b,$c,$d");
			$spieler[$spI][0] = $a;
			$spieler[$spI][1] = $b;
			$spieler[$spI][2] = $c;
			$spI = $spI + 1;
    	}
		$ret = $ret + 1;
    	fh_close("<", $fileNameInfo, $info);
	}

	init_wortwert();

	for (my $i =0 ; $i < $spI; $i = $i + 1) {
		my $spieler = $spieler[$i][1];
		my $punkte  = $spieler[$i][2];

		$dbg->printdbg("-spieler:$spieler punkte:$punkte");

		my $worttxt = '';

		for (my $j = 0; $j < $blineI; $j = $j + 1) {
			if ($spieler eq $blines[$j][0]) {
				my $bstd = $blines[$j][1];
				for (my $n = 0; $n < length($bstd); $n = $n +1) {
					my $b = substr($bstd, $n, 1);
					$dbg->printdbg("--b:$b  wert:" . _wert($b));
					if ($b ne '-' && $b ne '#') {
						$worttxt = $worttxt . $b . "_" . _wert($b) . " ";
						$punkte = $punkte - _wert($b);
					}
					$dbg->printdbg("---punkte:$punkte");
				}
			}
		}
		if ($worttxt eq '') {
			$worttxt = '0_0';
		}
		$worttxt = "Abzug:" . $worttxt;
		schreibe_wortzeile($spielId, $spieler, $worttxt, $punkte);

		$spieler[$i][2] = $punkte;
	}

	$settings = $settings . ",ende,1";
	if (fh_openlock(">", $fileNameInfo, $info)) {
		print DATA "$settings\n";
		for (my $i = 0; $i < $spI; $i = $i +1) {
			print DATA "0,$spieler[$i][1],$spieler[$i][2],+\n";
			$dbg->printdbg("-nicht aktiv:$spieler[$i][1], $spieler[$i][2]");
		}
		$ret = $ret + 1;
		fh_close(">", $fileNameInfo, $info);
	}
	$dbg->printdbg("-ret:$ret");
	$dbg->switch(0);
	return $ret;
}
