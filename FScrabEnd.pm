#!/usr/bin/perl

# detect date of last change of a file
use strict;
use AutoLoader;
use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser);
use FDebgCl;

use FScrabBase;
use FScrabZuegeWorte;

package FScrabEnd;

use Fcntl qw(:flock);


sub SpielZuEnde
{
	my $spielId = $_[0];
	my $info    = "SpielZuEnde";

	my $fileName = "data/$spielId.ende.txt";
	my $ret = 0;

	if (-e $fileName) {
		$ret = 1;
	}
	
	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->printdbg("$info:ret:$ret");
	$FScrabBase::dbg->switch(0);

	return $ret;
}
sub SetSpielZuEnde
{
	my $spielId = $_[0];
	my $info    = "SetSpielZuEnde";
	
	my $fileName = "data/$spielId.ende.txt";

	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->printdbg("$info  fileName:$fileName");

	if (FScrabBase::fh_openlock(">", $fileName, $info)) {
		print $FScrabBase::DATA "123\n";
		FScrabBase::fh_close(">", $fileName, $info);
	}

	FScrabSpieler::deaktivieren_alle($spielId);

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

	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->printdbg("$info");

	## beutel leer ?
	my $beutel = FScrabBase::hole_beutel($spielId);
	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->printdbg("-beutel: $beutel");
	if ($beutel ne '-') {
		$ret = 0;
		$FScrabBase::dbg->printdbg("-ret: $ret");
		$FScrabBase::dbg->switch(0);
		return $ret;
	}

	my @lines;
	my $lineI = 0;
	if (FScrabBase::fh_openlock("<", $fileName, $info)) {
		while(!eof($FScrabBase::DATA)) {
			chomp($lines[$lineI] = <$FScrabBase::DATA>);
			$FScrabBase::dbg->printdbg("-lines[$lineI]: $lines[$lineI]");
			$lineI = $lineI + 1;
		}
		FScrabBase::fh_close("<", $fileName, $info);
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
		$FScrabBase::dbg->printdbg("-str:$line  len:$len");

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
		$FScrabBase::dbg->printdbg("- lines:$lines[$i]  - endeModes:$endeModes[$i]");
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
	
	$FScrabBase::dbg->printdbg("-hatEnde:$hatEnde  rundeZuEnde:$rundeZuEnde  alleGeschoben:$alleGeschoben");

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

	$FScrabBase::dbg->printdbg("-ret: $ret");
	$FScrabBase::dbg->switch(0);
	return $ret;		
}


sub EndAbrechnung
{
	my $spielId = $_[0];

	my $info = "EndAbrechnung";

	my $fileNameInfo = "data/$spielId.info.txt";
	my $fileNameBank = "data/$spielId.bank.txt";
	
	my $ret = 0;

	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->printdbg("$info  mit $fileNameInfo  $fileNameBank");

	my @blines;
	my $blineI = 0;
	if (FScrabBase::fh_openlock("<", $fileNameBank, $info)) {
		while(!eof($FScrabBase::DATA)) {
			my $line = '';
			chomp($line = <$FScrabBase::DATA>);
			my ($a,$b,$c) = split(/\,/, $line);
			$blines[$blineI][0] = $a;
			$blines[$blineI][1] = $b;
			$blines[$blineI][2] = $c;
			$blineI = $blineI + 1;
		}
		$ret = $ret + 1;
		FScrabBase::fh_close("<", $fileNameBank, $info);
	}


	my @spieler;
	my $spI = 0;
	my $settings = '';

	if (FScrabBase::fh_openlock("<", $fileNameInfo, $info))  {
		if (!eof($FScrabBase::DATA)) {
    		chomp($settings = <$FScrabBase::DATA>);
		}
		while ( !eof($FScrabBase::DATA)) {
			my $line;
			chomp($line = <$FScrabBase::DATA>);
			my ($a,$b,$c,$d) =  split(/\,/, $line);
			$FScrabBase::dbg->printdbg("- $a,$b,$c,$d");
			$spieler[$spI][0] = $a;
			$spieler[$spI][1] = $b;
			$spieler[$spI][2] = $c;
			$spI = $spI + 1;
    	}
		$ret = $ret + 1;
    	FScrabBase::fh_close("<", $fileNameInfo, $info);
	}

	FScrabBase::init_wortwert();

	for (my $i =0 ; $i < $spI; $i = $i + 1) {
		my $spieler = $spieler[$i][1];
		my $punkte  = $spieler[$i][2];

		$FScrabBase::dbg->printdbg("-spieler:$spieler punkte:$punkte");

		my $worttxt = '';

		for (my $j = 0; $j < $blineI; $j = $j + 1) {
			$FScrabBase::dbg->printdbg("-.:$spieler - $blineI - $j");
			$FScrabBase::dbg->printdbg("-..:$blines[$j][0]");
			if ($spieler eq $blines[$j][0]) {
				my $bstd = $blines[$j][1];
				$FScrabBase::dbg->printdbg("-...:$bstd - ", length($bstd));
				for (my $n = 0; $n < length($bstd); $n = $n +1) {
					my $b = substr($bstd, $n, 1);
					$FScrabBase::dbg->printdbg("--b:$b  wert:" . FScrabBase::_wert($b));
					if ($b ne '-' && $b ne '#') {
						$worttxt = $worttxt . $b . "_" . FScrabBase::_wert($b) . " ";
						$punkte = $punkte - FScrabBase::_wert($b);
					}
					$FScrabBase::dbg->printdbg("---punkte:$punkte");
				}
			}
		}
		if ($worttxt eq '') {
			$worttxt = '0_0';
		}
		$FScrabBase::dbg->printdbg("----:$worttxt");
		$worttxt = "Abzug:" . $worttxt;
		$FScrabBase::dbg->printdbg("----:vor schreibe_wortzeile");
		FScrabZuegeWorte::schreibe_wortzeile($spielId, $spieler, $worttxt, $punkte);
		$FScrabBase::dbg->printdbg("----:nach schreibe_wortzeile");

		$spieler[$i][2] = $punkte;
	}

	$settings = $settings . ",ende,1";
	if (FScrabBase::fh_openlock(">", $fileNameInfo, $info)) {
		print $FScrabBase::DATA "$settings\n";
		for (my $i = 0; $i < $spI; $i = $i +1) {
			print $FScrabBase::DATA "0,$spieler[$i][1],$spieler[$i][2],+\n";
			$FScrabBase::dbg->printdbg("-nicht aktiv:$spieler[$i][1], $spieler[$i][2]");
		}
		$ret = $ret + 1;
		FScrabBase::fh_close(">", $fileNameInfo, $info);
	}
	$FScrabBase::dbg->printdbg("-ret:$ret");
	$FScrabBase::dbg->switch(0);
	return $ret;
}

return 1;