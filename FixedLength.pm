package Parse::FixedLength;
use strict;


#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use Carp;
use Scalar::Util qw(reftype);
use vars qw($VERSION $DELIM $DEBUG);
$VERSION   = '5.14';
$DELIM = ":";
$DEBUG = 0;

#=======================================================================
sub new {
    # Do the cargo cult OO construction thing
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless {}, $class;
    my $format = shift;
    croak "Format argument not an array ref"
        unless (reftype($format) || '') eq 'ARRAY';
    my $params = shift;
    croak "Params argument not a hash ref"
        if $params and (reftype($params) || '') eq 'ARRAY';
    my $delim = exists $params->{'delim'} ? $params->{'delim'} : $DELIM;
    $self->{DELIM} = $delim;
    my $delim_re = qr/\Q$delim/;
    croak "Delimiter argument must be one character" unless length($delim)==1;
    my $spaces = $params->{'spaces'} ? 'a' : 'A';
    my $is_hsh = $self->{IS_HSH} = _chk_format_type($format, $delim_re);

    # Convert hash-like array to delimited array
    $format = [ map  { $$format[$_].$delim.$$format[$_+1] }
                grep { not $_ % 2 } 0..$#$format
              ] if $is_hsh;
    my ($names, $alengths, $hlengths, $justify, $length) =
        _parse_format($format, $delim_re, $params);

    $self->{NAMES} = $names;
    $self->{UNPACK} = join '', map { "$spaces$_" } @$alengths;
    $self->{PACK} = uc($self->{UNPACK});
    $self->{LENGTH} = $length;
    # Save justify fields no matter what for benefit of dumper()
    if (%$justify) {
        $self->{JFIELDS} = $justify;
        $self->{JUST} = 1 unless $$params{no_justify};
    }
    $self->{LENGTHS} = $hlengths;
    $self->{DEBUG} = exists $$params{'debug'} ? $$params{'debug'} : $DEBUG;
    $self;
}

# Determine which format we have, the delimited array ref
# or the hash-like array ref.
# There must be delimiters in either all of the elements or none in
# alternating elements with an even number of elements.
# Assume what we have from the first element.
sub _chk_format_type {
    my ($format, $delim) = @_;
    my $is_hsh = 1 unless $$format[0] =~ $delim;
    croak "Odd number of name/length pairs or missing delimiter on first field"
        if $is_hsh and @$format % 2;
    for my $i (0..$#$format) {
        my $field = $$format[$i];
        if ($field =~ $delim) {
            croak "Field $field contains delimiter" if $is_hsh and not $i % 2;
        } else { croak "Field $field is missing delimiter" unless $is_hsh }
    }
    return $is_hsh;
}

sub _parse_format {
    my ($format, $delim, $params) = @_;
    my (@names, @lengths, %lengths, %justify, %dups);
    my $dups_ok = $$params{autonum};
    my $all_dups_ok;
    if ($dups_ok) {
        if ((reftype($dups_ok) || '') eq 'ARRAY') {
            @dups{@$dups_ok} = undef;
        } else { $all_dups_ok = 1 }
    }
    my $length = 0;
    my $nxt = 1;
    for (@$format) {
        my ($name, $tmp_len, $start, $end) = split $delim;
        _chk_start_end($name, $nxt, $start, $end) unless $$params{no_validate};
        $name = _chk_dups(
            $name, \@names, \%lengths, \%justify, \%dups, $dups_ok, $all_dups_ok
        );
        push @names, $name;
        # The results of the inner-parens is not guaranteed unless the
        # outer parens match, so we do it this way
        my ($len, $is_just, $chr) = $tmp_len =~ /^(\d+)((?:R(.?))?)$/
            or croak "Bad length $tmp_len for field $name";
        $len > 0 or croak "Length must be > 0 for field $name";
        $justify{$name} = ($chr eq '') ? ' ' : $chr if $is_just;
        $lengths{$name} = $len;
        push @lengths, $len;
        $length += $len;
        $nxt = $end + 1 if defined $end;
    }
    return \@names, \@lengths, \%lengths, \%justify, $length;
}

# Check for duplicate field name, and if a duplicate,
# either die or return new autonumbered field name
sub _chk_dups {
    my ($name, $names, $lengths, $justify, $dups, $dups_ok, $all_dups_ok) = @_;
    if (exists $$lengths{$name}) {
        croak "Duplicate field $name in format" 
            if !$dups_ok or !$all_dups_ok && !exists $$dups{$name};
    } else { return $name unless $$dups{$name} }
    # If this is the first duplicate found, fix the previous field
    unless ($$dups{$name}) {
        my $new_name = "${name}_".++$$dups{$name};
        croak "Can't autonumber field $name" if exists $$lengths{$new_name};
        for (@$names) { $_ = $new_name if $_ eq $name }
        $$lengths{$new_name} = $$lengths{$name};
        delete $$lengths{$name};
        if (exists $$justify{$name}) {
            $$justify{$new_name} = $$justify{$name};
            delete $$justify{$name};
        }
    }
    return "${name}_".++$$dups{$name};
}

sub _chk_start_end {
    my ($name, $prev, $start, $end) = @_;
    if (defined $start) {
        $start =~ /^\d+$/ or croak "Start position not a number in field $name";
        $start == $prev   or croak "Bad start position in field $name";
        defined $end      or croak "End position missing in field $name";
        $end =~ /^\d+$/   or croak "End position not a number in field $name";
        $end < $start    and croak "End position < start in field $name";
    }
}
#=======================================================================
sub parse {
    my $parser = shift;
    my @parsed = unpack($parser->{UNPACK}, shift);
    if ($parser->{DEBUG}) {
     print "# Debug parse\n";
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
            # Should we warn if we're truncating the field?
            $$href{$name} = substr(($chr x $len) . $field, -$len);
        }
    }
    # Print debug output after justifying fields
    if ($parser->{DEBUG}) {
     print "# Debug pack\n";
     for my $name (@{$parser->{NAMES}}) {
         print "[$name][$$href{$name}]\n";
     }
     print "\n";
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
sub dumper {
    my $parser = shift;
    my $pos_comment = shift;
    my $start = 1;
    my $end;
    my $delim = $parser->{DELIM};
    my $format = $pos_comment
       ? sub { sprintf("%s => %s, # %s-%s", @_) }
       : $parser->{IS_HSH}
         ? sub { sprintf("%s => '%s${delim}%s${delim}%s',", @_) }
         : sub { join $delim, @_ };
    my $layout = '';
    my $jfields = $parser->{JFIELDS} || {};
    for my $name (@{$parser->names}) {
        my $len = $parser->length($name);
        my $just = exists $jfields->{$name}
          ? $jfields->{$name} eq ' ' ? 'R' : "R$jfields->{$name}"
          : '';
        $len .= $just;
        $len = qq('$len') if $just and ($parser->{IS_HSH} or $pos_comment);
        $end = $start + $len - 1;
        $layout .= $format->($name, $len, $start, $end) . "\n";
        $start = $end + 1;
    }
    $layout;
}
#=======================================================================
sub converter {
    Parse::FixedLength::Converter->new(@_);
}

package Parse::FixedLength::Converter;
use Carp;
use Scalar::Util qw(reftype);

#=======================================================================
sub new {
   # Do the OO cargo cult construction thing
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $self = bless {}, $class;

   my ($parser1, $parser2, $mappings, $defaults) = @_;
   $self->{UNPACKER} = $parser1;
   $self->{PACKER} = $parser2;
   my $type = reftype($mappings) || '';
   croak 'Map arg not a hash or array ref' unless $type =~ /^(HASH|ARRAY)$/;
   $self->{MAP} = { reverse $type eq 'HASH' ? %$mappings : @$mappings };
   croak 'Defaults arg not a hash ref'
     unless (reftype($defaults) || '') eq 'HASH';
   $self->{DEFAULTS} = $defaults;
   $self;
}
#=======================================================================
sub convert {
    my $converter = shift;
    my $data_in   = shift;
    my $unpacker = $converter->{UNPACKER};
    my $packer   = $converter->{PACKER};
    my $map_to   = $converter->{MAP};
    my $defaults = $converter->{DEFAULTS};

    $data_in = $unpacker->parse($data_in)
        unless (reftype($data_in) || '') eq 'HASH';
    my $names_out = $packer->names;

    # Map the data from input to output
    my %data_out; @data_out{@$names_out} = map {
        exists $map_to->{$_} ? $data_in->{$map_to->{$_}}
      : exists $data_in->{$_} ? $data_in->{$_} : ''
    } @$names_out;

    # Default/Convert the fields
    while (my ($name, $default) = each %$defaults) {
        $data_out{$name} = ref $default
          ? do {
            my $tmp = eval { $default->($data_out{$name}, $data_in) };
            croak "Failed to default field $name: $@" if $@;
            $tmp;
          } : $default;
    }
    $packer->pack(\%data_out);
}

1;
__END__

=head1 NAME

Parse::FixedLength - parse an ascii string containing fixed length fields into component parts

=head1 SYNOPSIS

    use Parse::FixedLength;
    
    $parser = Parse::FixedLength->new(\@format);
    $parser = Parse::FixedLength->new(\@format, \%parameters);

    $hash_ref = $parser->parse($data);
    $data = $parser->pack($hash_ref);

    $converter = $parser1->converter($parser2);
    $converter = $parser1->converter($parser2, \%mappings);
    $converter = $parser1->converter($parser2, \@mappings);
    $converter = $parser1->converter($parser2, \%mappings, \%defaults);
    $converter = $parser1->converter($parser2, \@mappings, \%defaults);

    $data_out = $converter->convert($data_in);

=cut

=head1 DESCRIPTION

The C<Parse::FixedLength> module facilitates the process of breaking
a string into its fixed-length components.

=cut

=head1 PARSING ROUTINES

=over 4

=item new() 

 $parser = Parser::FixedLength->new(\@format)
 $parser = Parser::FixedLength->new(\@format, \%parameters)

This method takes an array reference of field names and
lengths as either alternating elements, or delimited args in the
same field, e.g.:

    my $parser = Parse::FixedLength->new([
        first_name => 10,
        last_name  => 10,
        address    => 20,
    ]);

    or:

    my $parser = Parse::FixedLength->new([qw(
        first_name:10
        last_name:10
        address:20
    )]);

If the first format is chosen, then no delimiter characters may
appear in the field names (see delim option below).

To right justify a field (during the 'pack' method), an "R" may
be appended to the length of the field along with (optionally)
the character to pad the string with (if no character follows the
"R", then a space is assumed). This is somewhat inefficient,
so its only recommended if actually necessary to preserve the format
during operations such as math or converting format lengths. If its
not needed but you'd like to specify it anyway for documentation
purposes, you can use the no_justify option below. Also, it does change
the data in the hash ref argument.

An optional hash ref may also be supplied which may contain the following:

 delim - The delimiter used to separate the name and length in the
         format array. If another delimiter follows the length then
         the next two fields are assumed to be start and end position,
         and after that any 'extra' fields are ignored.  The default
         delimiter is ":". The package variable DELIM may also be used.

 autonum - This option controls the behavior of new() when duplicate field
         names are found. Normally the a fatal error will be generated if
         duplicate field names are found. If you have, e.g., some unused
         filler fields, then as the value to this option, you can either
         supply an arrayref containing valid duplicate names or a simple
         true value to accept all duplicate values. If there is
         more than one duplicate field, then when parsed, they will be
         renamed '<name>_1', '<name>_2', etc.

 spaces - If true, preserve trailing spaces during parse.

 no_justify - If true, ignore the "R" format option during pack.

 no_validate - By default, if two fields exist after the length argument
          in the format (delimited by whatever delimiter is set), then
          they are assumed to be the start and end position (starting at 1),
          of the field, and these fields are validated to be correct, and
          a fatal error will be generated if they are not correct.
          If this option is true, then the start and end are not validated.

 debug  - Print field names and values during parsing (as a quick
          format validation check). The package variable DEBUG may also be
          used.

=item parse() 

 $hash_ref = $parser->parse($string)
 @ary      = $parser->parse($string)

This function takes a string and returns the results of
fixed length parsing as a hash reference of field names and
values if called in scalar context, or just a list of the
values if called in list context.

=item pack()

 $data = $parser->pack(\%data_to_pack);

This function takes a hash reference of field names and values and
returns a fixed length format output string.

=item names()

 $ary_ref = $parser->names;

Return an ordered arrayref of the field names.

=item length()

 $tot_length   = $parser->length;
 $field_length = $parser->length($name);

Returns the total length of all the fields, or of just one field name.
E.g.:

 while (read FH, $data, $parser->length) {
  $parser->parse($data);
  ...
 }

=item dumper()

 $parser->dumper($pos_as_comments);

Returns the parser's format layout information in a format suitable
for cutting and pasting into the format array argument of a
Parse::FixedFormat->new() call, and includes the start and end positions
of all the fields (starting with position 1). If a true argument is supplied
then it will include the start and ending positions as comments. E.g.:

 # Assume the parser is from the ones defined in the new() example:
 print $parser->dumper(1);

 produces for first example:
 first_name => 10, # 1-10
 last_name => 10, # 11-20
 address => 20, # 21-40 

 or for the second example:
 print $parser->dumper;

 first_name:10:1:10
 last_name:10:11:20
 address:20:21:40

=item converter()

 $converter = $parser1->converter($parser2);
 $converter = $parser1->converter($parser2, \%mappings);
 $converter = $parser1->converter($parser2, \@mappings);
 $converter = $parser1->converter($parser2, \%mappings, \%defaults);
 $converter = $parser1->converter($parser2, \@mappings, \%defaults);

Returns a format converting object. $parser1 is the parsing object
to convert from, $parser2 is the parsing object to convert to.

By default, common field names will be mapped from one format to the other.
Fields with different names can be mapped from the first format to the
other (or you can override the default) using the second argument.
The keys are the source field names and the corresponding values are
the target field names. This argument can be a hash ref or an array
ref since you may want to map one source field to more than one
target field.

Defaults for any field in the target format can be supplied
using the third argument, where the keys are the field names of
the target format, and the value can be a scalar constant, or a
subroutine reference where the first argument is simply the mapped
value (or the empty string if there was no mapping), and the
second argument is the entire hash reference that results from parsing
the data with the 'from' parser object. E.g. if you were mapping
from a separate 'zip' and 'plus_4' field to a 'zip_plus_4' field,
you could map 'zip' to 'zip_plus_4' and then supply as one of the
key/value pairs in the 'defaults' hash ref the following:

 zip_plus_4 => sub { shift() . $_[0]{plus_4} }

=item convert()

 $data_out = $converter->convert($data_in);
 $data_out = $converter->convert(\%hash);

Converts a string or a hash reference from one fixed length format to another.

=back

=cut

=head1 EXAMPLES

    use Parse::FixedLength;

    # Include start and end position for extra check
    # of format integrity
    my $parser = Parse::FixedLength->new([
        first_name => '10:1:10',
        last_name  => '10:11:20',
        widgets_this_month => '5R0:21:25',
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
    BOB       JONES     00024
    JOHN      SMITH     00005
    JANE      DOE       00007

    Another way if we're converting formats:

    my $parser1 = Parse::FixedLength->new([
        first_name => 10,
        last_name  => 10,
        widgets_this_month => '5R0',
    ]);

    # Use delim option just for example
    my $parser2 = Parse::FixedLength->new([qw(
        seq_id:10
        first_name:10
        last_name:10
        country:3
        widgets_this_year:10R0
    )]);

    my $converter = $parser1->converter($parser2, {
        widgets_this_month => widgets_this_year,
    },{
        seq_id => do { my $cnt = '0' x $parser2->length('seq_id');
                       sub { ++$cnt };
                     },
        widgets_this_year => sub { 12 * shift },
        country => 'USA',
    });
    

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
