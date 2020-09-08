#!/usr/bin/perl

use strict;
use warnings;
use CGI;
#use CGI::Carp qw(fatalsToBrowser);

use AutoLoader;
use FileHandle;


package FSessSC;


my $COOKNAME  = "idspielcook";
my $COOKVALUE = "scrab";
my $redadr    = '../gif/red.png';
my $blueadr   = '../gif/blue.png';

our $SessionControl = 1;
our $SessionOK      = 0;
our $FtCookie;

sub init 
{
  if (scalar(@_) > 0)  { $SessionControl = $_[0];  }
  else                 { $SessionControl = 0;      }
}

sub controlSessCookie
{
   my $q = $_[0];
   $SessionOK = 0;
   if ($SessionControl > 0)  
   {
      my $cookVal = $$q->cookie($COOKNAME);
      if (length $cookVal)  {
         if ($cookVal eq $COOKVALUE) {
           $SessionOK = 1;
	      }
      }
	   else  {
	      $SessionOK = 0;
      }
   }
   return $SessionOK;
}

sub setSessCookie
{
   my $q = $_[0];
   if ($SessionControl > 0)  
   {
      $FtCookie = $$q->cookie(-name => $COOKNAME,
			 -value => $COOKVALUE,
			 -expires => "+6000000s",
			 -path => "/");  			 
   }
   return $FtCookie;
}

sub getSessLabel
{
   my $sessTxt = "<small style='color:blue;'>S:1</small>";
   if ($SessionOK == 0)  {
      $sessTxt = "<small style='color:red;'>S:0</small>";
   }
   return $sessTxt;
}


return 1;
  
