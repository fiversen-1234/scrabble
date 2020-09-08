#!/usr/bin/perl

# detect date of last change of a file
use strict;
use AutoLoader;
use CGI qw/:standard/;
use CGI::Carp qw(fatalsToBrowser);
use Net::SMTP;
use FDebgCl;

use FScrabBase;

package FScrabSpieler;

use Fcntl qw(:flock);

my $HOMEDIR = "scrab";


# add a row to data/<spielId>.info.txt
#  > ..info.txt    mit    name,0,0
sub add_spieler
{
	my $spielId  = $_[0];
	my $spieler  = $_[1];
	my $vielepkte = $_[2];
	my $softend  = $_[3];
	my $mitveto  = $_[4];

	my $info     = "add_spieler";

	my $ret      = 0;

	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->print("add_spieler:$spielId,$spieler");

    #prevent double names   &&  not used an already used spielId
	my $alleSpieler = alle_spieler($spielId);
	$FScrabBase::dbg->switch(1);
	
	$FScrabBase::dbg->print(".alleSp:$alleSpieler");
	if ($alleSpieler ne "-") {
		my @all    = split(/\,/, $alleSpieler);
		for (my $i = 0; $i <= $#all; $i = $i + 1) {
			if ($all[$i] eq $spieler) {
				$FScrabBase::dbg->print("-1 spieler");
				return "-1";   #spieler schon belegt
			}		
			if ($all[$i] eq "+"  ||  $all[$i] eq "-") {
				$FScrabBase::dbg->print("-2 spielid");
				return "-2";   #spielid schon belegt
			}		
		}
	}

	my $fileName = "data/$spielId.info.txt";
	
	FScrabBase::add_settings($fileName,$vielepkte,$softend,$mitveto);

	if (FScrabBase::fh_openlock(">>", $fileName, $info)) {
		$FScrabBase::dbg->print("..spieler:$spieler");
		print $FScrabBase::DATA "0,$spieler,0,0\n";
		$FScrabBase::dbg->print("-:0,$spieler");
		$ret = 1;
		FScrabBase::fh_close(">>", $fileName, $info);
	}

	$FScrabBase::dbg->print("-ret:$ret");
	$FScrabBase::dbg->switch(0);
	return $ret;
}
sub alle_spieler
{
	my $spielId  = $_[0];
	my $info     = "alle_spieler";

	my $fileName = "data/$spielId.info.txt";

	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->print("alle_spieler: $spielId >$fileName<");

	my $ret = "";
	unless (-e $fileName)  {
		$ret = "-";
		$FScrabBase::dbg->print(".ret:$ret");
		return $ret;
	}		
	
	my  $settings = "";
	if (FScrabBase::fh_openlock("<", $fileName, $info)) {
		if (!eof($FScrabBase::DATA)) {
    		chomp($settings = <$FScrabBase::DATA>);
		}
		while (!eof($FScrabBase::DATA)) {
			my $line;
			chomp($line = <$FScrabBase::DATA>);
			$ret = $ret . "," . $line;
		}
		FScrabBase::fh_close("<", $fileName, $info);
	}
	
	if ($ret eq "") {
		$ret = "-";
	}
	$FScrabBase::dbg->print("-alle:$ret");
	$FScrabBase::dbg->switch(0);
	return $ret;
}
sub alle_spielername
{
	my $spielId  = $_[0];
	my $info     = "alle_spieler";

	my $fileName = "data/$spielId.info.txt";

	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->printdbg("$info: $spielId, $fileName");

	my $ret = "";

	my $settings = '';

	if (FScrabBase::fh_openlock("<", $fileName, $info)) {
		if (!eof($FScrabBase::DATA)) {
    		chomp($settings = <$FScrabBase::DATA>);
		}
    	while ( !eof($FScrabBase::DATA)) {
			my $line;
			chomp($line = <$FScrabBase::DATA>);
			my ($a,$b,$c,$d) =  split(/\,/, $line);
			$ret = $ret . "$b,";
			$FScrabBase::dbg->printdbg("- $a,$b,$c,$d");
		}
    	FScrabBase::fh_close("<", $fileName, $info);
	} 
	
	if (length($ret) < 2) {
		$ret = "-";
	}
	$FScrabBase::dbg->printdbg("-ret:$ret");
	return $ret;
}



sub aktiviere_spieler
{
	my $spielId  = $_[0];
	my $spieler  = $_[1];
	my $aktiv    = $_[2];
	my $info     = "aktiviere_spieler";

	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->printdbg("aktiviere_spieler:$spielId,$spieler,$aktiv");

	my $fileName = "data/$spielId.info.txt";

	
	my $ret = -1;
	my @spieler;
	my $spI = 0;
	my $settings = '';

	if (FScrabBase::fh_openlock("<", $fileName, $info))  {
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
    	FScrabBase::fh_close("<", $fileName, $info);
	}

	if ($aktiv == 1)  {
		if (FScrabBase::fh_openlock(">", $fileName, $info)) {
			print $FScrabBase::DATA "$settings\n";
			for (my $i = 0; $i < $spI; $i = $i +1) {
				if ($spieler[$i][1] eq $spieler) {
					print $FScrabBase::DATA "1,$spieler[$i][1],$spieler[$i][2],+\n";
					$FScrabBase::dbg->printdbg("-aktiv:$spieler[$i][1]");
					$ret = 1;
				} 
				else {
					print $FScrabBase::DATA "0,$spieler[$i][1],$spieler[$i][2],+\n";
					$FScrabBase::dbg->printdbg("-nicht aktiv:$spieler[$i][1]");
				}
			}
			FScrabBase::fh_close(">", $fileName, $info);
		}
	}
	if ($aktiv == 0)  {
		if (FScrabBase::fh_openlock(">", $fileName, $info)) {
			print $FScrabBase::DATA "$settings\n";
			for (my $i = 0; $i < $spI; $i = $i +1) {
				print $FScrabBase::DATA "0,$spieler[$i][1],$spieler[$i][2],+\n";
				$FScrabBase::dbg->printdbg("--all nicht aktiv:$spieler[$i][1]");
			}
			FScrabBase::fh_close(">", $fileName, $info);
			$ret = 0;
		}
	}			

	$FScrabBase::dbg->printdbg("-ret:$ret");
	$FScrabBase::dbg->switch(0);
	return $ret;
}

sub aktiviere_nachfolger
{
	my $spielId  = $_[0];
	my $spieler  = $_[1];
	my $info     = "aktiviere_nachfolger";

	$FScrabBase::dbg->switch(0);
	$FScrabBase::dbg->printdbg("aktiviere_nachfolger:$spielId,$spieler");

	my $fileName = "data/$spielId.info.txt";

	
	my $ret = -1;
	my @spieler;
	my $spI = 0;
	my $settings = '';

	if (FScrabBase::fh_openlock("<", $fileName, $info))  {
		if (!eof($FScrabBase::DATA)) {
    		chomp($settings = <$FScrabBase::DATA>);
		}
    	while ( !eof($FScrabBase::DATA)) {
			my $line;
			chomp($line = <$FScrabBase::DATA>);
			my ($a,$b,$c,$d) = split(/\,/, $line);
			$FScrabBase::dbg->printdbg("- $a,$b,$c,$d");
			$spieler[$spI][0] = $a;
			$spieler[$spI][1] = $b;
			$spieler[$spI][2] = $c;
			$spI = $spI + 1;
    	}
    	FScrabBase::fh_close("<", $fileName, $info);
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

	if (FScrabBase::fh_openlock(">", $fileName, $info)) {
		print $FScrabBase::DATA "$settings\n";
		for (my $i = 0; $i < $spI; $i = $i +1) {
			if ($i == $nextI)  {
				print $FScrabBase::DATA "1,$spieler[$i][1],$spieler[$i][2],+\n";
				$FScrabBase::dbg->printdbg("-aktiv:$spieler[$i][1]");
			}
			else  {
				print $FScrabBase::DATA "0,$spieler[$i][1],$spieler[$i][2],+\n";
				$FScrabBase::dbg->printdbg("--nicht aktiv:$spieler[$i][1]");
			}
		}
		FScrabBase::fh_close(">", $fileName, $info);
		$ret = 1;
	}
	
	$FScrabBase::dbg->printdbg("-ret:$nextI");
	$FScrabBase::dbg->switch(0);
	return $ret;
}



## vorhandene Spieler, und wer ist aktiv
## DatenStruktur: data/<spielId>.info.txt
## bsp:  0,hugo,10     - hugo ist nicht aktiv und hat 10 Punkte  

sub deaktivieren_alle
{
	my $spielId  = $_[0];
	my $info     = "deaktivieren_alle";

	$FScrabBase::dbg->switch(1);
	$FScrabBase::dbg->printdbg("$info:$spielId");

	my $fileName = "data/$spielId.info.txt";
	
	my $ret = -1;
	my @spieler;
	my $spI = 0;
	my $settings = '';

	if (FScrabBase::fh_openlock("<", $fileName, $info))  {
		if (!eof($FScrabBase::DATA)) {
    		chomp($settings = <$FScrabBase::DATA>);
		}
    	while ( !eof($FScrabBase::DATA)) {
			my $line;
			chomp($line = <$FScrabBase::DATA>);
			my ($a,$b,$c,$d) = split(/\,/, $line);
			$FScrabBase::dbg->printdbg("- $a,$b,$c,$d");
			$spieler[$spI][0] = $a;
			$spieler[$spI][1] = $b;
			$spieler[$spI][2] = $c;
			$spI = $spI + 1;
    	}
    	FScrabBase::fh_close("<", $fileName, $info);
	}
	$FScrabBase::dbg->printdbg("- gelesen:$spI");

	if (FScrabBase::fh_openlock(">", $fileName, $info)) {
		print $FScrabBase::DATA "$settings\n";
		for (my $i = 0; $i < $spI; $i = $i +1) {
			print $FScrabBase::DATA "0,$spieler[$i][1],$spieler[$i][2],+\n";
			$FScrabBase::dbg->printdbg("--nicht aktiv:$spieler[$i][1],$spieler[$i][2],+");
		}
		FScrabBase::fh_close(">", $fileName, $info);
		$ret = 1;
	}

	$FScrabBase::dbg->printdbg("-ret:$ret");	
	$FScrabBase::dbg->switch(0);
	return $ret;
}


sub zustand_spieler
{
	my $spielId  = $_[0];
	my $info     = "zustand_spieler";

	my $fileName = "data/$spielId.info.txt";

	#if (scalar (@_)  > 1  &&  $_[1] == "1") {
	#	$fileName = "data/$spielId.info.neu.txt";
	#}

	$FScrabBase::dbg->switch(0);
	$FScrabBase::dbg->printdbg("zustand_spieler:$fileName");

	my $ret = "";

	my $settings = '';

	if (FScrabBase::fh_openlock("<", $fileName, $info)) {
		if (!eof($FScrabBase::DATA)) {
    		chomp($settings = <$FScrabBase::DATA>);
		}
    	while ( !eof($FScrabBase::DATA)) {
			my $line;
			chomp($line = <$FScrabBase::DATA>);
			my ($a,$b,$c,$d) =  split(/\,/, $line);
			$ret = $ret . "$a,$b,$c,$d,";
			$FScrabBase::dbg->printdbg("- $a,$b,$c,$d");
		}
    	FScrabBase::fh_close("<", $fileName, $info);
	} 
	else {
		$fileName = "data/$spielId.info.txt";
		if (FScrabBase::fh_openlock("<", $fileName, $info)) {
			if (!eof($FScrabBase::DATA)) {
				chomp($settings = <$FScrabBase::DATA>);
			}
    		while ( !eof($FScrabBase::DATA)) {
				my $line;
				chomp($line = <$FScrabBase::DATA>);
				my ($a,$b,$c,$d) =  split(/\,/, $line);
				$ret = $ret . "$a,$b,$c,$d,";
				$FScrabBase::dbg->printdbg("- $a,$b,$c,$d");
			}
    		FScrabBase::fh_close("<", $fileName, $info);
		}
	}	
	
	if (length($ret) < 2) {
		$ret = "-";
	}
	$FScrabBase::dbg->printdbg("-ret:$ret");
	return $ret;
}


sub get_spieler_punkte
{
	my $spielId     = $_[0];
	my $pktspieler  = $_[1];
	my $info        = "get_spieler_punkte";
	$FScrabBase::dbg->switch(0);
	$FScrabBase::dbg->printdbg("$info:$spielId,$pktspieler");

	my $fileName = "data/$spielId.info.txt";
	
	my $ret = -1;

	my $settings = '';

	if (FScrabBase::fh_openlock("<", $fileName, $info))  {
		if (!eof($FScrabBase::DATA)) {
    		chomp($settings = <$FScrabBase::DATA>);
		}		
    	while ( !eof($FScrabBase::DATA)) {
			my $line;
			chomp($line = <$FScrabBase::DATA>);
			my ($a,$b,$c,$d) =  split(/\,/, $line);
			$FScrabBase::dbg->printdbg("- $a,$b,$c,$d");
			if ($b eq $pktspieler) {
				$ret = $c;
			}
		}
    	FScrabBase::fh_close("<", $fileName, $info);
	}
	$FScrabBase::dbg->printdbg("-ret:$ret");
	$FScrabBase::dbg->switch(0);
	return $ret;
}

sub schreibe_pkt_spieler
{
	my $spielId     = $_[0];
	my $pktspieler  = $_[1];
	my $pkt         = $_[2];
	my $info        = "schreibe_pkt_spieler";

	$FScrabBase::dbg->switch(0);
	$FScrabBase::dbg->printdbg("scheibe_pkt_spieler:$spielId,$pktspieler,$pkt");

	my $fileName = "data/$spielId.info.txt";

	
	my $ret = -1;
	my @spieler;
	my $spI = 0;
	my $settings = '';

	if (FScrabBase::fh_openlock("<", $fileName, $info))  {
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
    	FScrabBase::fh_close("<", $fileName, $info);
	}

	for (my $i = 0; $i < $spI; $i = $i +1) {
		if ($spieler[$i][1] eq $pktspieler) {
			$spieler[$i][2] = $spieler[$i][2] + $pkt;
			$FScrabBase::dbg->printdbg("- sps:$spieler[$i][1] $spieler[$i][2]");
		}
	}
	if (FScrabBase::fh_openlock(">", $fileName, $info)) {
		print $FScrabBase::DATA "$settings\n";
		for (my $i = 0; $i < $spI; $i = $i +1) {
			print $FScrabBase::DATA "$spieler[$i][0],$spieler[$i][1],$spieler[$i][2],0\n";
			$ret = 1;
		} 
    	FScrabBase::fh_close(">", $fileName, $info);
	}
	$FScrabBase::dbg->printdbg("-sps ret:$ret");
	$FScrabBase::dbg->switch(0);
	return $ret;
}


sub send_email
{
	my $spielId  		= $_[0];
	my $spieler  		= $_[1];
	my $mitspieleradr 	= $_[2];
	my $info        = "send_email";

	my $obj = "Scrabble spiele mit: " . $spieler;
	my $text = "'$spieler' laedt ein zum scrabble-spielen.\n".
	           "Zum Spielen diesen Link verwenden: " . 
			   "https://wedding.in-berlin.de/$HOMEDIR/spiel3.cgi?" . "spielId=" . $spielId .
			   "&amp;owner=" . $spieler;

	my $ret = send_mail2($obj, $mitspieleradr, $text);
	return $ret;
}

sub send_mail2 {
    my $obj          = $_[0];
    my $name         = $_[1];
    my $text         = $_[2];
    ###my $testgeld = $_[3];

    $FScrabBase::dbg->switch(0);
    $FScrabBase::dbg->printdbg( "send_mail2\n  obj:$obj<\n  name:$name<\n  text-length:",
        length($text) );

    #----- test if email adresses are real
    if (
        $name ne "scrabble\@wedding.in-berlin.de"
        && length($name) < 5
      )
    {
        $FScrabBase::dbg->printdbg("send_mail2  return -1");
        $FScrabBase::dbg->switch(0);
        return -1;
    }

    my $absender   = 'scrabble\@wedding.in-berlin.de';
    my $empfaenger = $name;

    $text = $text . "\n";
    $text = $text . "\n" . "---";
    $text = $text . "\n" . "scrabble";
 
    $FScrabBase::dbg->switch(0);
    $FScrabBase::dbg->printdbg("send_mail2  vor send_mail_pur - $obj, $empfaenger, ..");
    $FScrabBase::dbg->switch(0);

    send_mail_pur( $obj, $empfaenger, $text );

    return 1;
}

sub send_mail_pur {
    my $obj  = $_[0];
    my $name = $_[1];
    my $text = $_[2];

    if ( length($name) > 1 ) {

        #print "\n--send email: $name \n";
        my $mailServer = "mail.vr.in-berlin.de";
        my $absender   = "scrabble\@wedding.in-berlin.de";
        my $empfaenger = $name;

        #print "Mailserver ist : $mailServer\n";

        my $smtp = Net::SMTP->new($mailServer);
        $smtp->mail($absender);
        $smtp->to($name);
        $smtp->data();
        $smtp->datasend("Subject: $obj\n");
        $smtp->datasend("To: $name\n");
        $smtp->datasend("\n");
        $smtp->datasend($text);
        $smtp->dataend();
        $smtp->quit;
    }
}


return 1;
