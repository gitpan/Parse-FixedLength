#-----------------------------------------------------------------------
# $Header: /usr/end70/mnt/admin/perl/Parse/Parse/FixedDelimiter.pm,v 1.11 1999/12/09 02:22:32 end70 Exp $

=head1 NAME

Parse::FixedDelimiter - parse a string containing a fixed delimiter into
component parts

=head1 SYNOPSIS

    use Parse::FixedDelimiter;
    
    $phone_number=803-781-4191;
    Parse::FixedDelimiter::parse($phone_number,
				 \%moms_phone, 
				 '-',
				 [ 'area_code', 'exchange', 'number' ]);

    for (keys %moms_phone) {
      print $_, " ", $moms_phone{$_}, $/;
    }


    # yields $moms_phone{area_code} == 803
    #        $moms_phone{exchange}  == 781
    #        $moms_phone{number}    == 4191

    
=cut

#-----------------------------------------------------------------------

package Parse::FixedDelimiter;
#use strict;

#-----------------------------------------------------------------------

=head1 DESCRIPTION

The C<Parse::FixedDelimiter> module facilitates the process of breaking
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
@EXPORT    = qw();

#-----------------------------------------------------------------------
#	Global Variables for Program Use 
#-----------------------------------------------------------------------
@parse_record=();


#=======================================================================

=head1 PARSING ROUTINES

There are two parsing routines: C<parse()> and C<quick_parse>.

=over 8

=item parse()

This function takes a string, a reference to a hash and a reference to a 
list of hashes and stores the results of fixed length parsing into the hash 
reference passed in.

=item quick_parse()

This function takes the name of a pre-packaged datatype, a string, a reference to a hash 
and stores the results of fixed length parsing into the hash 
reference passed in.

=cut

#=======================================================================
sub parse {
    my ($string_to_parse, $hash_ref, $delimiter, $parse_fields) = @_;
    my $offset=0;
    my $parse_record;
    my @parsed_string;

    $parse_record="Parsed [$string_to_parse] into ";

    @parsed_string = split "$delimiter", $string_to_parse;
    my $i;
    for (@{$parse_fields}) {
	$hash_ref->{$_}=$parsed_string[$i++];
    }

    $parse_record .= join " ",  @parsed_string;

    push @parse_record, $parse_record;

}

sub quick_parse {
    my ($data_type, $string_to_parse, $hash_ref) = @_;

    my ($parse_fields, $delimiter) = @{$data_type};

#    print "parse ($string_to_parse, $hash_ref, $delimiter, $parse_fields)\n";
    parse ($string_to_parse, $hash_ref, $parse_fields, $delimiter);
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
    @us_phone  = ( '-', [ 'area_code', 'exchange', 'number' ] );
    @us_ssan   = ( '-', [ 'A', 'B', 'C' ] );
    @MM_DD_YYYY= ( '-', [ 'month', 'day', 'year' ] );
    @MM_DD_YY  = ( '-', [ 'month', 'day', 'year' ] );
    @YY_MM_DD  = ( '-', [ 'year',  'day', 'month' ] );
    @YYYY_MM_DD= ( '-', [ 'year', 'month', 'day' ] );
}

1;
