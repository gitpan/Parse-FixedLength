# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Parse::FixedLength;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $parser = Parse::FixedLength->new([qw(
 first_name:10
 last_name:10
 address:20
)], {delim=>":"});
if (defined $parser) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}

my $data = 'Bob       Jones     1122 Main St.       ';
my $href =  $parser->parse($data);
if ($href->{first_name} eq 'Bob') {
    print "ok 3\n";
} else {
    print "not ok 3\n";
}
if ($href->{last_name} eq 'Jones') {
    print "ok 4\n";
} else {
    print "not ok 4\n";
}
if ($href->{address} eq '1122 Main St.') {
    print "ok 5\n";
} else {
    print "not ok 5\n";
}
