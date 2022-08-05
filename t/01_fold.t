use strict;
use Test::More 0.98;
use utf8;

use Text::ANSI::Fold qw(ansi_fold);

sub folded {
    my($folded, $rest) = ansi_fold(@_);
    $folded;
}

$_ = "12345678901234567890123456789012345678901234567890";
is(folded($_, 1), "1",             "ASCII: 1");
is(folded($_, 10), "1234567890",   "ASCII: 10");
is(folded($_, length), $_,         "ASCII: just");
is(folded($_, length($_) * 2), $_, "ASCII: long");
is(folded($_, -1), $_,             "ASCII: negative");

$_ = "１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０";
is(folded($_, 1), "１", "WIDE: 1");
is(folded($_, 2), "１", "WIDE: 2");
is(folded($_, 10), "１２３４５",    "WIDE: 10");
is(folded($_, length($_) * 2), $_, "WIDE: just");
is(folded($_, length($_) * 4), $_, "WIDE: long");

is(folded($_, 9), "１２３４",    "WIDE: one short");
is(folded($_, 11), "１２３４５", "WIDE: one over");

$_ = "aaa/bbb/cccdddeeefff";
is(folded($_, 5), "aaa/b",   "boundary: none 5");
is(folded($_, 6), "aaa/bb",  "boundary: none 6");
is(folded($_, 7), "aaa/bbb", "boundary: none 7");

is(folded($_, 5, boundary => 'word'), "aaa/",      "boundary: word 5");
is(folded($_, 6, boundary => 'word'), "aaa/",      "boundary: word 6");
is(folded($_, 7, boundary => 'word'), "aaa/bbb",   "boundary: word 7");
is(folded($_, 9, boundary => 'word'), "aaa/bbb/c", "boundary: word 9");

configure Text::ANSI::Fold boundary => 'word';
is(folded($_, 5), "aaa/",      "config boundary: word 5");
is(folded($_, 6), "aaa/",      "config boundary: word 6");
is(folded($_, 7), "aaa/bbb",   "config boundary: word 7");
is(folded($_, 9), "aaa/bbb/c", "config boundary: word 9");

Text::ANSI::Fold->configure(width => 6);
is(folded($_), "aaa/",   "config width: word 6");
is(folded($_, undef, padding => 1), "aaa/  ",   "config width: padding");
is(folded($_, undef, padding => 1, padchar => '-'),
   "aaa/--", "config width: padding, padchar");

$_ = "000 000 000";
is(folded($_, 5, boundary => 'word'), "000 ",    "boundary: check 0");
is(folded($_, 6, boundary => 'word'), "000 ",    "boundary: check 0");
is(folded($_, 7, boundary => 'word'), "000 000", "boundary: check 0");

configure Text::ANSI::Fold width => 0, boundary => '';
$_ = "__________aaa bbb/ccc ddd";

is(folded($_, 15, boundary => 'space'), "__________aaa ", "boundary: space 15");
is(folded($_, 16, boundary => 'space'), "__________aaa ", "boundary: space 16");
is(folded($_, 17, boundary => 'space'), "__________aaa ", "boundary: space 17");
is(folded($_, 19, boundary => 'space'), "__________aaa ", "boundary: space 19");
is(folded($_, 21, boundary => 'space'), "__________aaa bbb/ccc", "boundary: space 21");

configure Text::ANSI::Fold boundary => 'space';
is(folded($_, 15), "__________aaa ", "config boundary: space 15");
is(folded($_, 16), "__________aaa ", "config boundary: space 16");
is(folded($_, 17), "__________aaa ", "config boundary: space 17");
is(folded($_, 19), "__________aaa ", "config boundary: space 19");
is(folded($_, 21), "__________aaa bbb/ccc", "config boundary: space 19");

done_testing;
