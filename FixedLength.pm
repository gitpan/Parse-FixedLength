package Parse::FixedLength;
use strict;


#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION);
$VERSION   = '5.03';

#=======================================================================
sub new {
    # Do the cargo cult object creation
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless {}, $class;
    my $format = shift;
    my $params = shift;
    my $delim = $params->{'delim'};
    my $spaces = $params->{'spaces'} ? 'a' : 'A';
    my (@names, @lengths);
    my $length = 0;
    if (defined $delim) {
        for (@$format) {
            my ($name, $len) = split $delim;
            push @names, $name;
            push @lengths, $len;
            $length += $len;
        }
    } else {
        for (my $i=0; $i < $#$format; $i+=2) {
            push @names, $$format[$i];
            push @lengths, $$format[$i+1];
            $length += $$format[$i+1];
        }
    }
    $self->{NAMES} = \@names;
    $self->{UNPACK} = join '', map { "$spaces$_" } @lengths;
    $self->{PACK} = join '', map { "A$_" } @lengths;
    $self->{LENGTH} = $length;
    my %lengths;
    @lengths{@names} = @lengths;
    $self->{LENGTHS} = \%lengths;
    $self->{DEBUG} = 1 if $params->{'debug'};
    $self;
}

#=======================================================================
sub parse {
    my $parser = shift;
    my @parsed = unpack($parser->{UNPACK}, shift);
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
    pack $parser->{PACK}, @{shift()}{@{$parser->{NAMES}}};
}
#=======================================================================
sub names {
   shift->{NAMES};
}
#=======================================================================
sub length {
   my $self = shift;
   my $field = shift or return $self->{LENGTH};
   $self->{LENGTHS}{$field};
}
#=======================================================================

1;
__END__

=head1 NAME

Parse::FixedLength - parse a string containing fixed length fields into component parts

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

 $parser = Parser::FixedLength->new($aref_format, $href_parameters)

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

 $href_parsed_data = $parser->parse($string_to_parse)

This function takes a string and returns the results of
fixed length parsing as a hash reference of field names and
values if called in scalar context, or just a list of the
values if called in list context.

=item pack
 $packed_str = $parser->pack($href_data_to_pack);

This function takes a hash reference and returns a fixed length format
output string.

=item names()

 $aref_names = $parser->names;

Return an ordered arrayref of the field names.

=item length()

 $tot_length   = $parser->length;
 $field_length = $parser->length($field_name);

Returns the total length of all the fields, or of just one field name.

=back

=cut

=head1 EXAMPLES

    use Parse::FixedLength;

    my $parser = Parse::FixedLength->new([
        first_name => 10,
        last_name  => 10,
        widgets_this_month => 5,
    ]);

    # Do a simple name casing of names
    # and print widgets projected for the year for each person
    # (Numbers are right justified for cut n paste purposes,
    # but will end up left justified to simplify this example)
    while (<DATA>) {
        warn "No record terminator found!\n" unless chomp;
        warn "Short Record!\n" unless $parser->length == length;
        my $data = $parser->parse($_);
        # See Lingua::EN::NameCase for a real attempt at name casing
        s/(\w+)/\u\L$1/g for @$data{qw(first_name last_name)};
        $data->{widgets_this_month} *= 12;
        print $parser->pack($data), "\n";
    }
    __DATA__
    BOB       JONES        24
    JOHN      SMITH         5
    JANE      DOE           7

=head1 AUTHOR

 Douglas Wilson <dougw@cpan.org>
 original by Terrence Brannon <tbone@cpan.org>

=head1 COPYRIGHT

 This module is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=cut
