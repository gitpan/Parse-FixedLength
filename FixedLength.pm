package Parse::FixedLength;
use strict;


#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION);
$VERSION   = '5.05';

#=======================================================================
sub new {
    # Do the cargo cult OO construction thing
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless {}, $class;
    my $format = shift;
    my $params = shift;
    my $delim = $params->{'delim'};
    my $spaces = $params->{'spaces'} ? 'a' : 'A';
    my (@names, @lengths, %justify);
    my $length = 0;
    if (defined $delim) {
        for (@$format) {
            my ($name, $len) = split $delim;
            push @names, $name;
            ($len, my $chr) = _right_justify($len);
            $justify{$name} = $chr if defined $chr;
            push @lengths, $len;
            $length += $len;
        }
    } else {
        for (my $i=0; $i < $#$format; $i+=2) {
            my $name = $$format[$i];
            my $len = $$format[$i+1];
            ($len, my $chr) = _right_justify($len);
            $justify{$name} = $chr if defined $chr;
            push @names, $name;
            push @lengths, $len;
            $length += $len;
        }
    }
    $self->{NAMES} = \@names;
    $self->{UNPACK} = join '', map { "$spaces$_" } @lengths;
    $self->{PACK} = join '', map { "A$_" } @lengths;
    $self->{LENGTH} = $length;
    if (%justify and ! $params->{'no_justify'}) {
     $self->{JUST} = 1;
     $self->{JFIELDS} = \%justify;
    }
    my %lengths;
    @lengths{@names} = @lengths;
    $self->{LENGTHS} = \%lengths;
    $self->{DEBUG} = 1 if $params->{'debug'};
    $self;
}

sub _right_justify {
    my $len = shift;
    my $chr;
    if ((my $pos = index($len, "R")) >= 0) {
        my $tmp_len = substr($len, 0, $pos);
        $chr = (length($len) > $pos) ? substr($len,$pos+1,1) : ' ';
        $len = $tmp_len;
    }
    return $len, $chr;
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
    my $href = shift;
    if ($parser->{JUST}) {
        while (my ($name, $chr) =  each %{$parser->{JFIELDS}}) {
            (my $field = $$href{$name}) =~ s/^\s+|\s+$//g;
            $field =~ s/^${chr}+// if $chr ne ' ';
            my $len = $parser->length($name);
            $$href{$name} = $chr x ($len-length($field)) . $field;
        }
    }
    CORE::pack $parser->{PACK}, @$href{@{$parser->{NAMES}}};
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
# Maybe not a clean OO way, this should be a different
# object in a different class, but oh well...it ain't rocket science.
sub converter {
   my ($parser1, $parser2, $mappings, $defaults) = @_;
   # Do the OO cargo cult dance
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $self = bless {}, $class;
   $self->{UNPACKER} = $parser1;
   $self->{PACKER} = $parser2;
   $self->{MAP} = { reverse %$mappings };
   $self->{DEFAULTS} = $defaults;
   $self;
}
#=======================================================================
sub convert {
    my $converter = shift;
    my $data = shift;
    my $unpacker = $converter->{UNPACKER};
    my $packer   = $converter->{PACKER};
    my $map_to   = $converter->{MAP};
    my $defaults = $converter->{DEFAULTS};

    my $data_in   = $unpacker->parse($data);
    my $names_out = $packer->names;

    # Map the data from input to output
    my %data_out; @data_out{@$names_out} = map {
        exists $map_to->{$_} ? $data_in->{$map_to->{$_}}
      : exists $data_in->{$_} ? $data_in->{$_} : ''
    } @$names_out;

    # Default/Convert the fields
    for (keys %$defaults) {
        $data_out{$_} =
        ref($defaults->{$_}) ?
            $defaults->{$_}->($data_out{$_},$data_in) : $defaults->{$_};
    }
    $packer->pack(\%data_out);
}

1;
__END__

=head1 NAME

Parse::FixedLength - parse a ascii string containing fixed length fields into component parts

=head1 SYNOPSIS

    use Parse::FixedLength;
    
    my $parser = Parse::FixedLength->new([
        first_name => 10,
        last_name  => 10,
        address    => 20,
    ]);

    my $data = 'Bob       Jones     1122 Main St.       ';
    my $parsed_href = $parser->parse($data);
    my $orig_data = $parser->pack($parsed_href);

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

To right justify a field (during the 'pack' method), an "R" may
be appended to the length of the field along with (optionally)
the character to pad the string with. This is somewhat inefficient,
so its only recommended if actually necessary to preserve the format
during operations such as math or converting format lengths. If its
not needed but you'd like to specify it anyway for documentation
purposes, you can use the no_justify option below. Also, it does change
the data in the hash ref argument.

An optional hash ref may also be supplied which may contain the following:

 delim - The delimiter used to separate the name and length in
         the format array.

 spaces - If true, preserve trailing spaces during parse.

 no_justify - Ignore the "R" format option during pack.

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

This function takes a hash reference of field names and values and
returns a fixed length format output string.

=item names()

 $aref_names = $parser->names;

Return an ordered arrayref of the field names.

=item length()

 $tot_length   = $parser->length;
 $field_length = $parser->length($field_name);

Returns the total length of all the fields, or of just one field name.

=item converter()

 $converter = $parser1->converter($parser2, \%mapping, \%defaults);

Returns a format converting object. $parser1 is the parsing object
to convert from, $parser2 is the parsing object to convert to.

By default, common field names will be mapped from one format to the other.
Fields with different names can be mapped from the first format to the
other (or you can override the default) using the second argument
(See examples).

And defaults for any field in the target format can be supplied
using the third argument, where the keys are the field names of
the target format, and the value can be a scalar constant, or a
subroutine reference where the first argument is simply the mapped
value (or the empty string if there was no mapping), and the
second argument is the entire hash reference that results from parsing
the data with the 'from' parser object. E.g. if you were mapping
from a separate 'zip' and 'plus_4' field to a 'zip_plus_4' field,
you could supply in the default hash ref the following:

 zip => sub { shift() . $$_[1]{plus_4} }

=item convert()

 $formatted_in_str = $converter->convert($formatted_out_str);

Converts a string from one fixed length format to another.

=back

=cut

=head1 EXAMPLES

    use Parse::FixedLength;

    my $parser = Parse::FixedLength->new([
        first_name => 10,
        last_name  => 10,
        widgets_this_month => '5R0',
    ]);

    # Do a simple name casing of names
    # and print widgets projected for the year for each person
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

    A alternate way if we're converting formats:

    my $parser1 = Parse::FixedLength->new([
        first_name => 10,
        last_name  => 10,
        widgets_this_month => '5R0',
    ]);

    my $parser2 = Parse::FixedLength->new([
        seq_id     => 10,
        first_name => 10,
        last_name  => 10,
        country    =>  3,
        widgets_this_year => '10R0',
    ]);

    my $converter = $parser1->converter($parser2, {
        widgets_this_month => widgets_this_year,
    },{
        seq_id => do { my $cnt = '0' x $parser2->length('seq_id');
                       sub { ++$cnt };
                     },
        widgets_this_year => sub { 12 * shift },
        country => 'USA',
    });
    

    # Do a simple name casing of names
    # and print widgets projected for the year for each person
    while (<DATA>) {
        warn "No record terminator found!\n" unless chomp;
        warn "Short Record!\n" unless $parser1->length == length;
        print $converter->convert($_), "\n";
    }

=head1 AUTHOR

 Douglas Wilson <dougw@cpan.org>
 original by Terrence Brannon <tbone@cpan.org>

=head1 COPYRIGHT

 This module is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=cut
