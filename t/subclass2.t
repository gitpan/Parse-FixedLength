# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}

BEGIN {
    use File::Spec;
    my @path = qw(Parse FixedLength);
    my $old_file = "FLTest.pt";
    my $new_file = "FLTest.pm";
    for my $lib (["t","lib"], ["lib"]) {
        my $dir = File::Spec->catdir(File::Spec->curdir, @$lib, @path);
        my $old_file = File::Spec->catfile($dir, $old_file);
        my $new_file = File::Spec->catfile($dir, $new_file);
        rename $old_file, $new_file and last;
    }
eval <<EOT;
# Include both relative directories so we can run
# from either this OR parent directory
use lib qw(t/lib lib);
# With import list
use Parse::FixedLength;
EOT
    print "not " if $@;
}
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $not = 'not ';

my $parser = Parse::FixedLength->new('FLTest');

print $not unless defined $parser;
print "ok 2\n";

my $data = '12345xxxxxabcdeyyyyy';
my $href =  $parser->parse($data);

print $not unless $href->{stuff} eq '12345';
print "ok 3\n";

print $not unless $href->{filler_1} eq 'xxxxx';
print "ok 4\n";

print $not unless $href->{more_stuff} eq 'abcde';
print "ok 5\n";

print $not unless $href->{filler_2} eq 'yyyyy';
print "ok 6\n";

print $not unless $parser->length == 20;
print "ok 7\n";
