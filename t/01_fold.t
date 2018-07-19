use strict;
use Test::More 0.98;
use utf8;

use Text::ANSI::Fold qw(ansi_fold);

$_ = "12345678901234567890123456789012345678901234567890";
is(folded($_, 10), "1234567890",   "ASCII");
is(folded($_, length), $_,         "ASCII: just");
is(folded($_, length($_) * 2), $_, "ASCII: long");

$_ = "１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０";
is(folded($_, 10), "１２３４５",    "WIDE");
is(folded($_, length($_) * 2), $_, "WIDE: just");
is(folded($_, length($_) * 4), $_, "WIDE: long");

is(folded($_, 9), "１２３４",    "WIDE: one short");
is(folded($_, 11), "１２３４５", "WIDE: one over");

$_ = "aaa bbb cccdddeeefff";
is(folded($_, 5), "aaa b", "boundary: none");
is(folded($_, 6), "aaa bb", "boundary: none");
is(folded($_, 7), "aaa bbb", "boundary: none");
is(folded($_, 5, boundary => 'word'), "aaa ", "boundary: word");
is(folded($_, 6, boundary => 'word'), "aaa ", "boundary: word");
is(folded($_, 7, boundary => 'word'), "aaa bbb", "boundary: word");
is(folded($_, 9, boundary => 'word'), "aaa bbb c", "boundary: word");

done_testing;

sub folded {
    my($folded, $rest, $len) = ansi_fold(@_);
    $folded;
}
