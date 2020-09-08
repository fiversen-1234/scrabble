#!/usr/bin/perl

# detect date of last change of a file
use strict;
use AutoLoader;
use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser);
use FDebgCl;

use FScrabBase;

package FScrabProcess;

use Fcntl qw(:flock);


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

   $FScrabBase::dbg->printdbg("schreibe_legeBuchstabe: $spielId $spieler $x $y $buchstabe $clname");

   my $ret = 0;
   if (FScrabBase::fh_openlock(">>", "data/$spielId.aktionen.txt", $info)) {
		print $FScrabBase::DATA "$aktionsnr,$spieler,$x,$y,$buchstabe,$clname\n";
		FScrabBase::fh_close(">>", "data/$spielId.aktionen.txt", $info);
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
   	$FScrabBase::dbg->printdbg("lese_legeBuchstaben ab: $aktionsnrAb");
   	$FScrabBase::dbg->printdbg("-vor open");
	if (FScrabBase::fh_openlock("<", "data/$spielId.aktionen.txt", $info))  {
   		$FScrabBase::dbg->printdbg("-nach open");
		while(!eof($FScrabBase::DATA)) {
   			$FScrabBase::dbg->printdbg("-vor lese");
			chomp($line = <$FScrabBase::DATA>);
   			$FScrabBase::dbg->printdbg("-nach lese:" . $line);
			my ($aktionsnr, $spieler, $x, $y, $buchstabe, $clname) = split(/\,/,$line);
			if ($aktionsnr > $aktionsnrAb)  {
				$ret = $ret . $line . "+";				
			}
		}
   		$FScrabBase::dbg->printdbg("-vor close");
		FScrabBase::fh_close("<", "data/$spielId.aktionen.txt", $info);		
	}
	if (length($ret) == 0)  {
		$ret = "-";
	}
   	$FScrabBase::dbg->printdbg("-ret: $ret");
	return $ret;
}






#nach anmelden aller spieler
#-starten 
sub ready_to_start
{
	my $spielId = $_[0];
	my $spieler = $_[1];
	my $info    = "kontrolle_spieltId";
	
	my $fn    = "data/$spielId.info.txt";

    my $ret  = 0;

	$FScrabBase::dbg->switch(0);
	$FScrabBase::dbg->printdbg("kontrolle_spielId:" . $spielId);

	my $spieler_alt = '';
	my $spieler_neu = '';

	my $settings = '';

	my @neu;
	my $neuI = 0;
	if (FScrabBase::fh_openlock("<", $fn, $info)) {
		if (!eof($FScrabBase::DATA)) {
    		chomp($settings = <$FScrabBase::DATA>);
		}
		while ( !eof($FScrabBase::DATA)) {
			my $line;
			chomp($line = <$FScrabBase::DATA>);
			my ($a,$b,$c,$d) =  split(/\,/, $line);
			$neu[$neuI] = $b;
			$neuI = $neuI + 1;
		}
		FScrabBase::fh_close("<", $fn, $info);
	}
	$FScrabBase::dbg->printdbg("-neu: @neu");


	$FScrabBase::dbg->printdbg("- OK $spielId.info.txt");
	if (FScrabBase::fh_openlock(">", $fn, $info)) {
		print $FScrabBase::DATA "$settings\n";
		for (my $i = 0; $i < $neuI; $i = $i +1) {
			print $FScrabBase::DATA "0,$neu[$i],0,-\n";
			$FScrabBase::dbg->printdbg("- $fn: 0,$neu[$i],0,-");
		}
		FScrabBase::fh_close(">", $fn, $info);
		$ret = 1;
	}
	return $ret;
}

sub kontrolle_spieltId_
{
	my $spielId = $_[0];
	my $spieler = $_[1];
	my $info    = "kontrolle_spieltId";
	
	my $fn    = "data/$spielId.info.txt";
	my $fnNeu = "data/$spielId.info.neu.txt";

    my $ret  = 0;

	$FScrabBase::dbg->switch(0);
	$FScrabBase::dbg->printdbg("kontrolle_spielId:" . $spielId);

	my $spieler_alt = '';
	my $spieler_neu = '';

	my $settings = '';

	if (FScrabBase::fh_openlock("<", $fnNeu, $info)) {
		if (!eof($FScrabBase::DATA)) {
    		chomp($settings = <$FScrabBase::DATA>);
		}
		while ( !eof($FScrabBase::DATA)) {
			my $line;
			chomp($line = <$FScrabBase::DATA>);
			my ($a,$b,$c,$d) =  split(/\,/, $line);
			$spieler_neu = $spieler_neu . $b . ",";
		}
		FScrabBase::fh_close("<", $fnNeu, $info);
	}
	$FScrabBase::dbg->printdbg("-neu: $spieler_neu");
	my @neu = split(/\,/, $spieler_neu);


	my @alt;
	my $settings2 = '';
	if (-e $fn) {
		$FScrabBase::dbg->printdbg("-es gibt schon $spielId.info.txt");
		#es gibt schon eine session mit 'spielId'
		if (FScrabBase::fh_openlock("<", $fn, $info)) {
			if (!eof($FScrabBase::DATA)) {
				chomp($settings2 = <$FScrabBase::DATA>);
			}
			while ( ! eof($FScrabBase::DATA)) {
				my $line;
				chomp($line = <$FScrabBase::DATA>);
				my ($a,$b,$c,$d) =  split(/\,/, $line);
				$spieler_alt = $spieler_alt . $b . ",";
			}
			FScrabBase::fh_close("<", $fn, $info);
			@alt = split(/\,/, $spieler_alt);
		}
	}
	else  {
		$FScrabBase::dbg->printdbg("- OK $spielId.info.txt");
		if (FScrabBase::fh_openlock(">", $fnNeu, $info)) {
			print $FScrabBase::DATA "$settings\n";
			for (my $i = 0; $i < scalar(@neu); $i = $i +1) {
				print $FScrabBase::DATA "0,$neu[$i],0,+\n";
				$FScrabBase::dbg->printdbg("- $fnNeu: 0,$neu[$i],0,+");
			}
			FScrabBase::fh_close(">", $fnNeu, $info);
			system("cp $fnNeu $fn");  
			$ret = 1;
			return $ret;
		}
	}

	$FScrabBase::dbg->printdbg("-alt: $spieler_alt");

	my $idIstBelegt = 1;
	if (scalar(@alt) == scalar(@neu)) {
		for (my $i = 0; $i < scalar(@neu); $i = $i +1) {
			my $found = 0;
			for (my $j = 0; $j < scalar(@alt); $j = $j +1) {
				if ($neu[$i] eq $alt[$j])  {
					$found = 1;
				}
				$FScrabBase::dbg->printdbg("- ?: $neu[$i] -- $alt[$j], $found");
			}
			if ($found == 0)  {
				$idIstBelegt = 0;
			}
			$FScrabBase::dbg->printdbg("- ??: $found, $idIstBelegt");
		}
	} 
	else  {
		$idIstBelegt = 0;
	}

	$FScrabBase::dbg->printdbg("- idIstBelegt:$idIstBelegt");

	my $neueId = '';
	if ($idIstBelegt == 1) {
		my @chars = ("A".."Z", "a".."z", "0".."9");
		$neueId .= $chars[rand @chars] for 1..4;

		$FScrabBase::dbg->printdbg("- neue id: $neueId");
	
		if (FScrabBase::fh_openlock(">", $fnNeu, $info)) {
			print $FScrabBase::DATA "$settings\n";
			for (my $i = 0; $i < scalar(@neu); $i = $i +1) {
				print $FScrabBase::DATA "n,$neu[$i],0,$neueId\n";
				$FScrabBase::dbg->printdbg("- $fnNeu: n,$neu[$i],0,$neueId");
			}
			FScrabBase::fh_close(">", $fnNeu, $info);
			$ret = 2;
		}
		my $fnNeueId = "data/$neueId.info.txt";
		if (FScrabBase::fh_openlock(">", $fnNeueId, $info)) {
			print $FScrabBase::DATA "$settings\n";
			for (my $i = 0; $i < scalar(@neu); $i = $i +1) {
				if ($spieler eq $neu[$i]) {
					print $FScrabBase::DATA "1,$neu[$i],0,0\n";
					$FScrabBase::dbg->printdbg("-- $fnNeueId: 1,$neu[$i],0,0");
				}
				else {
					print $FScrabBase::DATA "0,$neu[$i],0,0\n";
					$FScrabBase::dbg->printdbg("-- $fnNeueId: 0,$neu[$i],0,0");
				}
			}
			FScrabBase::fh_close(">", $fnNeueId, $info);
			$ret = 2;
		}
	}
	if ($idIstBelegt == 0) {
		$FScrabBase::dbg->printdbg("- OK nach delete.. $spielId.info.txt");
    	FScrab::delete_all_data_files($spielId);
		if (FScrabBase::fh_openlock(">", $fnNeu, $info)) {
			print $FScrabBase::DATA "$settings\n";
			for (my $i = 0; $i < scalar(@neu); $i = $i +1) {
				print $FScrabBase::DATA "0,$neu[$i],0,+\n";
				$FScrabBase::dbg->printdbg("- $fnNeu: n,$neu[$i],0,+");
			}
			FScrabBase::fh_close(">", $fnNeu, $info);
		}
		system("cp $fnNeu $fn");  
		$ret = 1;
	}
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

		if (FScrabBase::fh_openlock("<", $fileName, $info))  {
			while ( !eof($FScrabBase::DATA)) {
				my $line;
				chomp($line = <$FScrabBase::DATA>);
				my ($a,$b,$c,$d) =  split(/\,/, $line);
				$FScrabBase::dbg->printdbg("- $a,$b,$c,$d");
				$spielerA[$spI][0] = $a;
				$spielerA[$spI][1] = $b;
				$spielerA[$spI][2] = $c;
				$spI = $spI + 1;
			}
			FScrabBase::fh_close("<", $fileName, $info);
		}
		else {
			$ret = 0;
		}

		$fileName = "data/$spielId.veto.txt";
		if (FScrabBase::fh_openlock(">", $fileName, $info))  {
			for (my $i = 0; $i < $spI; $i = $i + 1) {
				print $FScrabBase::DATA "$spielerA[$i][0],$spielerA[$i][1],0\n";
			}
			FScrabBase::fh_close(">", $fileName, $info);
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

		if (FScrabBase::fh_openlock("<", $fileName, $info))  {
			while ( !eof($FScrabBase::DATA)) {
				my $line;
				chomp($line = <$FScrabBase::DATA>);
				my ($a,$b,$c) =  split(/\,/, $line);
				$FScrabBase::dbg->printdbg("- $a,$b,$c");
				$spielerA[$spI][0] = $a;
				$spielerA[$spI][1] = $b;
				$spielerA[$spI][2] = $c;
				$spI = $spI + 1;
			}
			FScrabBase::fh_close("<", $fileName, $info);
		}
		else {
			$ret = 0;
		}

		if (FScrabBase::fh_openlock(">", $fileName, $info))  {
			for (my $i = 0; $i < $spI; $i=$i+1)	{
				if ($spieler eq $spielerA[$i][1]) {
					print $FScrabBase::DATA "$spielerA[$i][0],$spielerA[$i][1],$aktion\n";
				}
				else  {
					print $FScrabBase::DATA "$spielerA[$i][0],$spielerA[$i][1],$spielerA[$i][2]\n";
				}
			}
			FScrabBase::fh_close(">", $fileName, $info);
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

	$FScrabBase::dbg->switch(0);
	$FScrabBase::dbg->printdbg("vetoDatei_status:$spielId");

	my  $fexists = 0;
	if (-e $fileName)  { 
		$fexists = 1; 
	};
	$FScrabBase::dbg->printdbg("-$fileName,$fexists");
	$FScrabBase::dbg->printdbg("--");
	
	if ($fexists == 0)  {
		$FScrabBase::dbg->printdbg("---");
		$ret = "-";
		$FScrabBase::dbg->printdbg("-ret:$ret");
		$FScrabBase::dbg->switch(0);
		return $ret;
	}

	if (FScrabBase::fh_openlock("<", $fileName, $info))  {
		$FScrabBase::dbg->printdbg("----");
		while ( !eof($FScrabBase::DATA)) {
				my $line;
				chomp($line = <$FScrabBase::DATA>);
				$ret = $ret . $line . "+";
		}
		FScrabBase::fh_close("<", $fileName, $info);
	}
	$FScrabBase::dbg->printdbg("-ret:$ret");
	$FScrabBase::dbg->switch(0);
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
		if (FScrabBase::fh_openlock("<", $fileName, $info)) {
			while(!eof($FScrabBase::DATA)) {
				chomp($lines[$lineI] = <$FScrabBase::DATA>);
				$lineI = $lineI + 1;
			}
			FScrabBase::fh_close("<", $fileName, $info);
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

	if (FScrabBase::fh_openlock(">", $fileName, $info)) {
		my $i = 0;
		while ($i < $lineI) {
			print $FScrabBase::DATA "$lines[$i]\n";
			$i = $i + 1;
		}
		FScrabBase::fh_close(">", $fileName, $info);
	}
	return $ret;
}

sub lese_bank
{
	my $spielId = $_[0];
	my $spieler = $_[1];

	my $info      = "lese_bank";
	
	my $fileName  = "data/$spielId.bank.txt";

	my $ret = "";
	my @lines;
	my $lineI = 0;
	my $bank = '';
	if (-e $fileName) {
		my $line;
		if (FScrabBase::fh_openlock("<", $fileName, $info)) {
			while(!eof($FScrabBase::DATA)) {
				chomp($lines[$lineI] = <$FScrabBase::DATA>);
				$lineI = $lineI + 1;
			}
			FScrabBase::fh_close("<", $fileName, $info);
		}

		my $found = 0;
		for (my $i = 0; $i < $lineI; $i = $i +1)
		{
			if (index($lines[$i],$spieler) > -1) {
				$bank = $lines[$i];
				$found = 1;
			}
		}
	}
	my $sonder = 0;
	for (my $i = 0; $i < length($bank); $i = $i +1)
	{
		my $c = substr($bank, $i, 1);
		if ($c eq "," || $c eq "-" || $c eq "#") {
			$sonder = $sonder + 1;
		}
		elsif ($sonder > 0)  {
			$ret = $ret . $c;
		}
	}

	if (length($ret) == 0)  {
		$ret = "-";
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
		if (FScrabBase::fh_openlock("<", $fileName, $info)) {
			while(!eof($FScrabBase::DATA)) {
				chomp($lines[$lineI] = <$FScrabBase::DATA>);
				$lineI = $lineI + 1;
			}
			FScrabBase::fh_close("<", $fileName, $info);
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
	if (FScrabBase::fh_openlock(">", $fileName, $info)) {
		my $i = 0;
		while ($i < $lineI) {
			print $FScrabBase::DATA "$lines[$i]\n";
			$i = $i + 1;
		}
		FScrabBase::fh_close(">", $fileName, $info);
	}
	return $ret;
}

return 1;
