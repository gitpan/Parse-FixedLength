package Parse::FixedLength;
use strict;


require Exporter;
use Carp;

our $debug = 1;

#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION   = '3.1';
@ISA       = qw(Exporter);
@EXPORT    = qw(parse print_parsed quick_parse);

#-----------------------------------------------------------------------
#	Global Variables for Program Use 
#-----------------------------------------------------------------------
our @parse_record=();

our %quick_parse =
(
 us_phone   => \@Parse::FixedLength::us_phone,
 us_ssan    => \@Parse::FixedLength::us_ssan,
 MM_DD_YYYY => \@Parse::FixedLength::MM_DD_YYYY,
 MM_DD_YY   => \@Parse::FixedLength::MM_DD_YY,
 YY_MM_DD   => \@Parse::FixedLength::YY_MM_DD,
 YYYY_MM_DD => \@Parse::FixedLength::YYYY_MM_DD
);
#=======================================================================

sub print_parsed {
    map { print "$_\n" } (@parse_record);
}


#=======================================================================
sub parse {
    my ($string_to_parse, $hash_ref, $parse_instruction_ref,$debug) = @_;
    my $offset=0;
    my $parse_record;
    my $parsed_string;

    warn Data::Dumper->Dump([\@_],['Parse::FL::parse::@_']) if $debug;

    $parse_record="Parsed [$string_to_parse]: ";

    foreach my $parse_instruction (@{$parse_instruction_ref}) {
	for (keys %{$parse_instruction}) {
#	    print $_, " ", $parse_instruction->{$_},$/;
	    my $length=$parse_instruction->{$_};
	    $parsed_string=substr($string_to_parse, $offset, $length), $/;
	    $hash_ref->{$_}=$parsed_string;
	    $offset += $length;
	    $parse_record .= "\n\t/$_/ $parsed_string";
	    push @parse_record, $parse_record;
	}
    }

    my $debug_string;
    if ($debug) {
      foreach my $parse_instruction (@{$parse_instruction_ref}) {
	my $key = (keys %$parse_instruction)[0];
	my $val = $hash_ref->{$key};
	$debug_string .= "$key => $val\n";
      }
      warn $debug_string;
    }

    $hash_ref;

}

#=======================================================================


sub quick_parse {
    my ($name_of_formatting_LOH, $string_to_parse, $hash_ref) = @_;
    my $offset=0;
    
    parse(
	  $string_to_parse,
	  $hash_ref,
	  $quick_parse{$name_of_formatting_LOH}
	 )
      ;
}

#=======================================================================


#-----------------------------------------------------------------------

#=======================================================================
# initialisation code - stuff the DATA into the CODES hash
#=======================================================================
{
our @us_phone= ( 
	     {'area_code' => 3},
	     {'exchange'  => 3},
	     {'number'    => 4} 
	     );

our @us_ssan= ( 
	     {'A' =>  3},
	     {'B' =>  2},
	     {'C' =>  4} 
	     );

our @MM_DD_YYYY= ( 
	     {'month' =>  2},
	     {'day'   =>  2},
	     {'year'  =>  4} 
	     );

our @MM_DD_YY= ( 
	     {'month' =>  2},
	     {'day'   =>  2},
	     {'year'  =>  2} 
	     );

our @YY_MM_DD= ( 
	     {'year'  =>  2},
	     {'day'   =>  2},
	     {'month'  =>  2} 
	     );

our @YYYY_MM_DD= ( 
	     {'year'  =>  4},
	     {'month'   =>  2},
	     {'day'  =>  2} 
	     );

}

1;
=head1 NAME

Parse::FixedLength - parse a string containing fixed length fields into
component parts

=head1 SYNOPSIS

    use Parse::FixedLength;
    
    $phone_number=8037814191;
    parse($phone_number,
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

=head1 DESCRIPTION

The C<Parse::FixedLength> module facilitates the process of breaking
a string into its fixed-length components.

=cut

=head1 PARSING ROUTINES

=over 4

=item parse() 

 parse($string_to_parse, $href_storing_parse, $LOH_parse_instructions)

This function takes a string, a reference to a hash and a reference to a 
list of hashes and stores the results of fixed length parsing into the hash 
reference passed in.

=item quick_parse()

To facilitate the parsing of certain common fixed-length strings, the
C<quick_parse()> function takes the name of an LOH (list of hashes) 
containing formatting information, a string, and a reference to a hah in 
which to store parsing results. The currently available formatting routines
are:

=item * C<@us_phone> 

 $phone_number=8882221234;
 Parse::FixedLength::quick_parse("us_phone",$phone_number, \%lncs_phone);


=item * C<@us_ssan> 

=item * C<@MM_DD_YYYY> 

=item * C<@MM_DD_YY> 

=item * C<@YY_MM_DD> 

=item * C<@YYYY_MM_DD> 

=item print_parsed()

This routine can be called after parsing to print a record of parse results.



=back

=cut


#=======================================================================



#-----------------------------------------------------------------------

=head1 EXAMPLES

see SYNOPSIS

=head1 AUTHOR

Terrence Brannon <tbone@cpan.org>

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
