#-----------------------------------------------------------------------
# $Header: /usr/end70/mnt/admin/perl/Parse/Parse/FixedLength.pm,v 1.25 1999/12/09 02:22:52 end70 Exp $

=head1 NAME

Parse::FixedLength - parse a string containing fixed length fields into
component parts

=head1 SYNOPSIS

    use Parse::FixedLength;
    
    $phone_number=8037814191;
    parse_FL($phone_number,
	     \%moms_phone, 
	     [ 
	       {'area_code' => 3},
	       {'exchange'  => 3},
	       {'number'    => 4} ] );

    for (keys %moms_phone) {
      print $_, " ", $moms_phone{$_}, $/;
    }


    # yields $moms_phone{area_code} == 803
    #        $moms_phone{exchange}  == 781
    #        $moms_phone{number}    == 4191

    
=cut

#-----------------------------------------------------------------------

package Parse::FixedLength;
#use strict;

#-----------------------------------------------------------------------

=head1 DESCRIPTION

The C<Parse::FixedLength> module facilitates the process of breaking
a string into its fixed-length components.

=cut

#-----------------------------------------------------------------------

require Exporter;
use Carp;

#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION   = '1.00';
@ISA       = qw(Exporter);
@EXPORT    = qw(quick_parse);

#-----------------------------------------------------------------------
#	Global Variables for Program Use 
#-----------------------------------------------------------------------
@parse_record=();


#=======================================================================

=head1 PARSING ROUTINES

There is one parsing routine: C<parse()>.

=over 8

=item parse()

This function takes a string, a reference to a hash and a reference to a 
list of hashes and stores the results of fixed length parsing into the hash 
reference passed in.

=item quick_parse()

To facilitate the parsing of certain common fixed-length strings, the
C<quick_parse()> function takes the name of an LOH (list of hashes) 
containing formatting information, a string, and a reference to a hah in 
which to store parsing results. The currently available formatting routines
are:

=over 4
item * C<@us_phone> 
item * C<@us_ssan> 
item * C<@us_dob> 
item * C<@us_dob_long_year> 

=back

=cut

#=======================================================================
sub parse {
    my ($string_to_parse, $hash_ref, $parse_instruction_ref) = @_;
    my $offset=0;
    my $parse_record;
    my $parsed_string;

    $parse_record="Parsed [$string_to_parse]: ";

    foreach $parse_instruction (@{$parse_instruction_ref}) {
	for (keys %{$parse_instruction}) {
#	    print $_, " ", $parse_instruction->{$_},$/;
	    my $length=$parse_instruction->{$_};
	    $parsed_string=substr($string_to_parse, $offset, $length), $/;
	    $hash_ref->{$_}=$parsed_string;
	    $offset += $length;
	    $parse_record .= "\n\t/$_/ $parsed_string";
	    add_to_parse_record;
	}
    }

    push @parse_record, $parse_record;

}

#=======================================================================
sub quick_parse {
    my ($name_of_formatting_LOH, $string_to_parse, $hash_ref) = @_;
    my $offset=0;
    
    parse($string_to_parse,
	     $hash_ref,
	     \@{$name_of_formatting_LOH});
}

#=======================================================================

=head1 DIAGNOSTIC ROUTINES

There is one diagnostic routine: C<print_parsed()>.

=over 8

=item print_parsed()

This function prints all parses performed.

=back
=cut

#=======================================================================
sub print_parsed {
    map { print "$_\n" } (@parse_record);
}



#-----------------------------------------------------------------------

=head1 EXAMPLES

see SYNOPSIS

=head1 AUTHOR

Terrence Brannon E<lt>tbrannon@end70.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1999 End70 Corporation

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

#-----------------------------------------------------------------------

#=======================================================================
# initialisation code - stuff the DATA into the CODES hash
#=======================================================================
{
@us_phone= ( 
	     {'area_code' => 3},
	     {'exchange'  => 3},
	     {'number'    => 4} 
	     );

@us_ssan= ( 
	     {'A' =>  3},
	     {'B' =>  2},
	     {'C' =>  4} 
	     );

@MM_DD_YYYY= ( 
	     {'month' =>  2},
	     {'day'   =>  2},
	     {'year'  =>  4} 
	     );

@MM_DD_YY= ( 
	     {'month' =>  2},
	     {'day'   =>  2},
	     {'year'  =>  2} 
	     );

@YY_MM_DD= ( 
	     {'year'  =>  2},
	     {'day'   =>  2},
	     {'month'  =>  2} 
	     );

@YYYY_MM_DD= ( 
	     {'year'  =>  4},
	     {'month'   =>  2},
	     {'day'  =>  2} 
	     );

}

1;
