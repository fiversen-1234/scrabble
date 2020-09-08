#!/usr/bin/perl

# detect date of last change of a file
use strict;
use AutoLoader;
use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser);
use FDebgCl;
use FScrabBase;

package FScrabZuegeWorte;

use Fcntl qw(:flock);


#schreiben zug in 'data/$spielId.zuege.txt'
#  idx,spieler,buchstabe,x,y,buchstabe,x,y,buchstabe,x,y,...
sub schreibe_zug {
	my $spielId  = $_[0];
	my $neuerZug = $_[1];
	my $info     = "schreibe_zug";

	my $anzZuege = 0;
	if (FScrabBase::fh_openlock("<", "data/$spielId.zuege.txt", $info))  {
   		while ( <$FScrabBase::DATA> ) {
   			$anzZuege++;
   		}
    	FScrabBase::fh_close("<", "data/$spielId.zuege.txt", $info);
	}
	$anzZuege = $anzZuege + 1;
    
	#correct zugidx
	my @list = split(/\,/,$neuerZug);
	$list[0] = $anzZuege;
	my $neuerZug2 = join(',', @list) . ",";


	$FScrabBase::dbg->printdbg("zuege_schreiben\n");
	if (FScrabBase::fh_openlock(">>", "data/$spielId.zuege.txt", $info))  {
		print $FScrabBase::DATA "$neuerZug2\n";
		$FScrabBase::dbg->printdbg("-$neuerZug2\n");
		FScrabBase::fh_close(">>", "data/$spielId.zuege.txt", $info);
	}

	$FScrabBase::dbg->printdbg("--$anzZuege\n");
	return $anzZuege;
}

#lesen aus <spielId>.zuege.txt
sub leseLetzten_zug {
	my $spielId  = $_[0];
	my $zeilenNr = $_[1];

	my $info    = "leseLetzten_zug";
	my $i   = 0;
	my $ret = '';

	if (FScrabBase::fh_openlock("<",  "data/$spielId.zuege.txt", $info)) {
		$FScrabBase::dbg->printdbg("zuege_lesen\n");
		while ( ! eof($FScrabBase::DATA) ) {
        	chomp(my $line    =  <$FScrabBase::DATA>);
			$FScrabBase::dbg->printdbg("-line:" . $line . "\n");
			if (length($line) > 0) {
				#$ret = $line;
				my @feld = split(/\,/,$line);
				$FScrabBase::dbg->printdbg(".." . $feld[0] . ".." . $zeilenNr . "\n");
				if ($feld[0] > $zeilenNr) {
					$ret = $ret . $line . "+";
				}
			}
			$i = $i + 1;
		}
		FScrabBase::fh_close("<", "data/$spielId.zuege.txt", $info);
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
	if (FScrabBase::fh_openlock("<",  "data/$spielId.worte.txt", $info))  {
   		while ( <$FScrabBase::DATA> ) {
   			$wortZeilen++;
   		}
    	FScrabBase::fh_close("<",  "data/$spielId.worte.txt", $info);
	}
	$wortZeilen = $wortZeilen + 1;
    
	#
	my @list = split(/-/,$neueworte);
	my $neueworte2 = join(',', ($wortZeilen, $spieler, @list,$pkt)) . ",";

	$FScrabBase::dbg->printdbg("schreibe_wortzeile\n");
	if (FScrabBase::fh_openlock(">>", "data/$spielId.worte.txt", $info))  {
		print $FScrabBase::DATA "$neueworte2\n";
		$FScrabBase::dbg->printdbg("-$neueworte2\n");
		FScrabBase::fh_close(">>", "data/$spielId.worte.txt", $info);		
	}

	$FScrabBase::dbg->printdbg("--$wortZeilen\n");
	return $wortZeilen;
}
#---- wortzeile
sub leseLetzte_wortzeile {
	my $spielId      = $_[0];
	my $wortzeilennr = $_[1];

	my $info    = "leseLetzte_wortzeile";
	my $i   = 0;
	my $ret = '';

	if (FScrabBase::fh_openlock("<", "data/$spielId.worte.txt", $info)) {
		$FScrabBase::dbg->printdbg("leseLetzte_wortzeile\n");
		while ( ! eof($FScrabBase::DATA) ) {
        	chomp(my $line    =  <$FScrabBase::DATA>);
			$FScrabBase::dbg->printdbg("-line:" . $line . "\n");
			if (length($line) > 0) {
				my @feld = split(/\,/,$line);
				if ($feld[0] > $wortzeilennr) {
					$ret = $ret . $line . "+";
				}
			}
			$i = $i + 1;
		}
		FScrabBase::fh_close("<", "data/$spielId.worte.txt", $info);
	}
	return $ret;
}




# schreibt die zuege in $FScrabBase::brett[r][c] = B
sub zuege_aufs_brett {
	my $spielId  = $_[0];
	my $anzZuege = $_[1];     #anzahl zuege die gelesen werden sollen
	my $info     = "zuege_aufs_brett";

	$FScrabBase::dbg->switch(0);
	$FScrabBase::dbg->printdbg("zuege_aufs_brett: $spielId, $anzZuege");

	my $bst = 0;     #buchstaben aufs brett
	if ($anzZuege < 1) {
		return $bst;
	}

	my $z   = 0;
	if (FScrabBase::fh_openlock("<", "data/$spielId.zuege.txt", $info)) {
		$FScrabBase::dbg->printdbg("-zab");
		while ( ! eof($FScrabBase::DATA) && $z < $anzZuege) {
        	chomp(my $line    =  <$FScrabBase::DATA>);
			$FScrabBase::dbg->printdbg("-zab line:$line");
			if (length($line) > 0) {
				my @fld  = split(/\,/,$line);
				my $fldn = $#fld;
				$FScrabBase::dbg->printdbg("-zab fld:@fld  n:$fldn");
				for (my $i = 2; ($i+2) <= $fldn; $i = $i + 3) {
					$FScrabBase::dbg->printdbg("--zab $fld[$i+1] $fld[$i+2] =  $fld[$i]");
					$FScrabBase::brett[ $fld[$i+1] ] [ $fld[$i+2] ] = $fld[$i+0];
					$bst = $bst + 1;
				}  
			}
			$z = $z + 1;
		}
		FScrabBase::fh_close("<", "data/$spielId.zuege.txt", $info);
	}
	$FScrabBase::dbg->printdbg("-zab ret:$bst\n");
	$FScrabBase::dbg->switch(0);
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

	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->printdbg("worte_aus_zug: $spielId, $nzugstr");

	my @fld  = split(/\,/, $nzugstr);
	my $fldn = $#fld;
	for (my $i=0, my $fi=2; ($fi+2) <= $fldn; $i = $i + 1, $fi = $fi + 3) {
		$NBst[$i][0] = $fld[$fi];
		$NBst[$i][1] = $fld[$fi+1];
		$NBst[$i][2] = $fld[$fi+2];
		$NBst[$i][3] = 1;
		$NBst[$i][4] = 1;
		$FScrabBase::dbg->printdbg("-waz NBst: $NBst[$i][0] $NBst[$i][1] $NBst[$i][2] $NBst[$i][3]");
		$NBstN = $NBstN + 1;
	}
	$FScrabBase::dbg->printdbg("-waz NBst: $NBstN");

	for (my $i = 0; $i < $NBstN; $i = $i +1)   {
		my $b= $NBst[$i][0];
		my $x= $NBst[$i][1];
		my $y= $NBst[$i][2];
		my $xneu = $NBst[$i][3];
		my $yneu = $NBst[$i][4];
		$FScrabBase::dbg->printdbg("-waz b:$b x:$x y:$y xneu:$xneu yneu:$yneu");

		if ($xneu == 1)  {
			#suche nach dem Ende nach oben (X)
			my $xoben  = 0;
			my $xx     = $x - 1;
			my $ok     = 1;
			if ($xx < 1) { $ok = 0; }
			while ($ok) {
				$FScrabBase::dbg->printdbg("-waz $xx,$y b:" . $FScrabBase::brett[$xx][$y] . " z:" . bst_zug($xx,$y));
				if ($FScrabBase::brett[$xx][$y] ne '.' ||  bst_zug_neuX($xx,$y) ne "." )  {
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
			$FScrabBase::dbg->printdbg("-waz xoben:$xoben");

			#suche nach dem Ende nach unten (X)
			my $xunten = 0;
			$xx        = $x + 1;
			$ok        = 1;
			if ($xx > 15) { $ok = 0; }
			while ($ok) {
				$FScrabBase::dbg->printdbg("--waz $xx,$y b:" . $FScrabBase::brett[$xx][$y] . " z:" . bst_zug($xx,$y));
				if ($FScrabBase::brett[$xx][$y] ne '.' ||  bst_zug_neuX($xx,$y) ne "." )  {
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
			$FScrabBase::dbg->printdbg("-waz yunten:$xunten");

			if ($xoben > 0 || $xunten > 0) {
				if ($xoben  == 0)  { $xoben  = $x; }
				if ($xunten == 0)  { $xunten = $x; }
				$FScrabBase::dbg->printdbg("---waz wort von $xoben bis $xunten");
				for (my $xi = $xoben; $xi <= $xunten; $xi = $xi +1) {
					if ($FScrabBase::brett[$xi][$y] ne '.') {
						$worte = $worte . $FScrabBase::brett[$xi][$y];
						$bstwerte  = $bstwerte . FScrabBase::_wert($FScrabBase::brett[$xi][$y]) . "."; 
						if ($FScrabBase::VielePkte eq '1') {
							$fldwerte  = $fldwerte . $FScrabBase::feldwert[$xi][$y] . ".";  					
							$wortwerte = $wortwerte . $FScrabBase::wortwert[$xi][$y] . ".";  					
						} 	
						else {
							$fldwerte  = $fldwerte . "1" . ".";  					
							$wortwerte = $wortwerte . "1" . ".";  												
						}				
					}
					else {
						my $c = bst_zug($xi,$y);
						$worte = $worte . $c;
						$bstwerte  = $bstwerte . FScrabBase::_wert($c) . ".";  					
						$fldwerte  = $fldwerte . $FScrabBase::feldwert[$xi][$y] . ".";  					
						$wortwerte = $wortwerte . $FScrabBase::wortwert[$xi][$y] . ".";  					
					}
				}
				$worte = $worte . "-";
				$bstwerte  = $bstwerte . "-";  					
				$fldwerte  = $fldwerte . "-";  					
				$wortwerte = $wortwerte . "-";  					
			}
			else  {
				$FScrabBase::dbg->printdbg("---waz kein wort");
			}
		}
		if ($yneu == 1)  {
			#suche nach dem Ende nach links (Y)
			my $ylinks = 0;
			my $yy     = $y-1;
			my $ok     = 1;
			if ($yy < 1) { $ok = 0; }
			while ($ok) {
				$FScrabBase::dbg->printdbg("-waz $x,$yy b:" . $FScrabBase::brett[$x][$yy] . " z:" . bst_zug($x,$yy));
				if ($FScrabBase::brett[$x][$yy] ne '.' ||  bst_zug_neuY($x,$yy) ne "." )  {
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
			$FScrabBase::dbg->printdbg("-waz ylinks:$ylinks");

			#suche nach dem Ende nach rechts (Y)
			my $yrechts = 0;
			$yy         = $y + 1;
			$ok         = 1;
			if ($yy > 15) { $ok = 0; }
			while ($ok) {
				$FScrabBase::dbg->printdbg("--waz $x,$yy b:" . $FScrabBase::brett[$x][$yy] . " z:" . bst_zug($x,$yy));
				if ($FScrabBase::brett[$x][$yy] ne '.' ||  bst_zug_neuY($x,$yy) ne "." )  {
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
			$FScrabBase::dbg->printdbg("-waz yrechts:$yrechts");

			if ($ylinks > 0 || $yrechts > 0) {
				if ($ylinks  == 0)  { $ylinks  = $y; }
				if ($yrechts == 0)  { $yrechts = $y; }
				$FScrabBase::dbg->printdbg("---waz wort von $ylinks bis $yrechts");
				for (my $yi = $ylinks; $yi <= $yrechts; $yi = $yi +1) {
					if ($FScrabBase::brett[$x][$yi] ne '.') {
						$worte = $worte . $FScrabBase::brett[$x][$yi];
						$bstwerte  = $bstwerte . FScrabBase::_wert($FScrabBase::brett[$x][$yi]) . ".";  					
						if ($FScrabBase::VielePkte eq '1') {
							$fldwerte  = $fldwerte . $FScrabBase::feldwert[$x][$yi] . ".";  					
							$wortwerte = $wortwerte . $FScrabBase::wortwert[$x][$yi] . ".";  					
						}
						else {
							$fldwerte  = $fldwerte . "1" . ".";  					
							$wortwerte = $wortwerte . "1" . ".";  					
						}
					}
					else {
						my $c = bst_zug($x,$yi);
						$worte = $worte . $c;
						$bstwerte  = $bstwerte . FScrabBase::_wert($c) . ".";  					
						$fldwerte  = $fldwerte . $FScrabBase::feldwert[$x][$yi] . ".";  					
						$wortwerte = $wortwerte . $FScrabBase::wortwert[$x][$yi] . ".";  					
					}
				}
				$worte = $worte . "-";
				$bstwerte  = $bstwerte . "-";  					
				$fldwerte  = $fldwerte . "-";  					
				$wortwerte = $wortwerte . "-";  					
			}
			else  {
				$FScrabBase::dbg->printdbg("---waz kein wort");
			}
		}
	}
	$FScrabBase::dbg->printdbg("-waz return $fld[1] $worte, $bstwerte, $fldwerte, $wortwerte");
	$FScrabBase::dbg->switch(0);
	return ($fld[1], $worte, $bstwerte, $fldwerte, $wortwerte);
}

sub punkte_aus_zug
{
	my $spieler   = $_[0];
	my $worte     = $_[1];
	my $bstwerte  = $_[2];
	my $fldwerte  = $_[3];
	my $wortwerte = $_[4];

	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->printdbg("punkte_aus_zug:" . 
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
	$FScrabBase::dbg->printdbg("-paz:" . 
	               @wortA . "," .
				   @bstA . "," .
				   @fldwA . "," .
				   @wortwA . ":" . $anz );
	for (my $i = 0; $i < $anz; $i = $i +1) {
		my @bstAA    = split(/\./, $bstA[$i]);
		my @fldwAA   = split(/\./, $fldwA[$i]);
		my @wortwAA  = split(/\./, $wortwA[$i]);
		$FScrabBase::dbg->printdbg("paz:" . $i . "," . $wortA[$i]);
 
		my $anzz = scalar @bstAA;
		my $pktw = 0;
		my $wortww = 1;
		for (my $j = 0; $j < $anzz; $j = $j +1) {
			$pktw = $pktw + $bstAA[$j] * $fldwAA[$j];
			$wortww = $wortww * $wortwAA[$j];
			$FScrabBase::dbg->printdbg("paz-b:" . $j . "," . $bstAA[$j] * $fldwAA[$j] . "," . $pktw );
		}
		$pktw = $pktw * $wortww;
		$wortA[$i] = $wortA[$i] . "_" . $pktw;
		$pkt = $pkt + $pktw;
		$FScrabBase::dbg->printdbg("paz:" .  $wortA[$i] . "," . $pkt);
	}
	my $worte2 = join (',', @wortA);

	$FScrabBase::dbg->printdbg("paz ret:" .  $pkt . "," . $worte2);
	$FScrabBase::dbg->switch(0);

	return ($pkt, $worte2);
}




sub zuege_getlist
{
	#zuege_lesen();

	my $idx = 1;
	my $e = '';
	while($idx <= $FScrabBase::zuegeN) {
		$e      = $e . $FScrabBase::zuege[$idx][0] . ' ';
		$e      = $e . '[' . $FScrabBase::zuege[$idx][1] . '] ';
		my $anz = $FScrabBase::zuege[$idx][2];
		my $i   = 3;
		while ( $i<=($anz*3) ) {
			$e = $e . '(' . 
				$FScrabBase::zuege[$idx][$i] . ',' .
				$FScrabBase::zuege[$idx][$i+1] . ',' .
				$FScrabBase::zuege[$idx][$i+2] . ')';
			$i = $i + 3;
		}
		$e = "$e<br/>\n";
		$idx = $idx + 1;
	}
	return $e;
}

my $zuegelist = zuege_getlist();

return 1;