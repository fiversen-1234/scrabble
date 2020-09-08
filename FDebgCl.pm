#!/usr/bin/perl


use strict;
use FileHandle;

package  FDebgCl;



sub new {
   my $class = shift;
   my $self = {
      _debug => shift,
      _filename  => shift,
   };
   # Print all the values just for clarification.
   #print "debug is $self->{_debug}\n";
   #print "filename is $self->{_filename}\n";
   bless $self, $class;
   return $self;
}


sub switch {
    my ( $self, $debug) = @_;
    $self->{_debug} = $debug if defined($debug);
    return $self->{_debug};
}
sub move {
    my ( $self, $filen) = @_;
    $self->{_filename} = $filen if defined($filen);
    return $self->{_filename};
}

sub printdbg  {
    my ( $self, $text) = @_;
    if ($self->{_debug} > 0)  {
        my $fh = FileHandle->new(">> $self->{_filename}");
        if (defined $fh)  {
            print $fh "$text \n";
	        $fh->close();
       }
    }
}
sub print  {
    my ( $self, $text) = @_;
    $self->printdbg($text);
}
sub printscr {
    my ( $self, $text) = @_;

    if ($self->{_debug} > 0)  {
        print "$text \n";
    }
    $self->printdbg($text);
}

1;


