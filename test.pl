# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Parse::FixedLength;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $parser = Parse::FixedLength->new([qw(
 first_name:10:morestuff
 last_name:10
 address:20
)], {delim=>":"});

my $not = 'not ';
print $not unless defined $parser;
print "ok 2\n";

my $data = 'Bob       Jones     1122 Main St.       ';
my $href =  $parser->parse($data);

print $not unless $href->{first_name} eq 'Bob';
print "ok 3\n";

print $not unless $href->{last_name} eq 'Jones';
print "ok 4\n";

print $not unless $href->{address} eq '1122 Main St.';
print "ok 5\n";

print $not unless $parser->length == 40;
print "ok 6\n";

print $not unless $parser->length('first_name') == 10;
print "ok 7\n";

my $parser1 = Parse::FixedLength->new([qw(
    first_name:10
    last_name:10
    widgets_this_month:5R0
)], {delim=>":"});

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

my $str_in = 'BOB       JONES        24';
my $str_out = $converter->convert($str);
print $not unless $str_out = '0000000001BOB       JONES     USA0000000288';
print "ok 8\n";
