#!/usr/bin/perl

use lib '/usr/end70/mnt/admin/perl';
use Parse::FixedLength;
use Parse::FixedDelimiter;

$phone_number=4152841111;
Parse::FixedLength::parse($phone_number,
	 \%moms_phone, 
	 [ 
	   {'area_code' => 3},
	   {'exchange'  => 3},
	   {'number',   => 4} ] );


$phone_number=8882221234;
Parse::FixedLength::quick_parse("us_phone",$phone_number, \%lncs_phone);

$ssan=247259666;
quick_parse("us_ssan",$ssan, \%bobos_ssan);

Parse::FixedLength::print_parsed;

$phone_number="412-284-1111";
Parse::FixedDelimiter::parse($phone_number,\%jimbob, '-', [ 'area_code', 'exchange', 'number' ]);

$phone_number="222-333-4444";
Parse::FixedDelimiter::quick_parse("us_phone",$phone_number,\%big_guy);

foreach (keys %jimbob) {
    print "$_\t$jimbob{$_}\n";
}

Parse::FixedDelimiter::print_parsed;

foreach (keys %jimbob) {
    print "$_\t$jimbob{$_}\n";
}

foreach (keys %big_guy) {
    print "$_\t$big_guy{$_}\n";
}

