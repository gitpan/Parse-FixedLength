package Parse::FixedLength;
use strict;


#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION);
$VERSION   = '5.01';

#=======================================================================
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless {}, $class;
    my $format = shift;
    my $params = shift;
    my $delim = $params->{'delim'};
    my $spaces = $params->{'spaces'} ? 'a' : 'A';
    my (@names, @lengths);
    if (defined $delim) {
        for (@$format) {
            my ($name, $len) = split $delim;
            push @names, $name;
            push @lengths, $len;
        }
    } else {
        for (my $i=0; $i < $#$format; $i+=2) {
            push @names, $$format[$i];
            push @lengths, $$format[$i+1];
        }
    }
    $self->{NAMES} = \@names;
    $self->{UNPACK} = join '', map { "$spaces$_" } @lengths;
    $self->{PACK} = join '', map { "A$_" } @lengths;
    $self->{DEBUG} = 1 if $params->{'debug'};
    $self;
}

#=======================================================================
sub parse {
    my $parser = shift;
    my $string = shift;
    my @parsed = unpack($parser->{UNPACK}, $string);
    if ($parser->{DEBUG}) {
     for my $i (0..$#{$parser->{NAMES}}) {
         print "[$parser->{NAMES}[$i]][$parsed[$i]]\n";
     }
     print "\n";
    }
    return @parsed if wantarray;
    my %parsed;
    @parsed{@{$parser->{NAMES}}} = @parsed;
    return \%parsed;
}
#=======================================================================
sub pack {
    my $parser = shift;
    my $data = shift;
    pack $parser->{PACK}, @{$data}{@{$parser->{NAMES}}};
}
#=======================================================================
sub names {
   shift->{NAMES};
}
#=======================================================================

1;
__END__

=head1 NAME

Parse::FixedLength - parse a string containing fixed length fields into
component parts

=head1 SYNOPSIS

    use Parse::FixedLength;
    
    my $parser = Parse::FixedLength->new([
        first_name => 10,
        last_name  => 10,
        address    => 20,
    ]);

    my $data = 'Bob       Jones     1122 Main St.       ';
    my $parsed = $parser->parse($data);

    or:

    my $parser = Parse::FixedLength->new([qw(
        first_name:10
        last_name:10
        address:20
    )], {delim=>":"});

=cut

=head1 DESCRIPTION

The C<Parse::FixedLength> module facilitates the process of breaking
a string into its fixed-length components.

=cut

=head1 PARSING ROUTINES

=over 4

=item new() 

 new($aref_format, $href_parameters)

This method takes an array reference of field names and
lengths as either alternating elements, or delimited args in the
same field.

An optional hash ref may also be supplied which may contain the following:

 delim - The delimiter used to separate the name and length in
         the format array.

 spaces - If true, preserve trailing spaces in the parsed output.

 debug  - Print field names and values during parsing (as a quick
          format validation check).

=item parse() 

 parse($string_to_parse)

This function takes a string and returns the results of
fixed length parsing as a hash reference of field names and
values if called in scalar context, or just a list of the
values if called in list context.

=item pack($href_data_to_pack) 

This function takes a hash reference and returns a fixed length format
output string.

=item names

Return an ordered arrayref of the field names.

=back

=cut


#=======================================================================



#-----------------------------------------------------------------------

=head1 EXAMPLES

see SYNOPSIS

=head1 AUTHOR

 Douglas Wilson <dougw@cpan.org>,
 original by Terrence Brannon <tbone@cpan.org>

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
