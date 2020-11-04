use v5.14;
use warnings;
use Test::More 0.98;
use utf8;

use Data::Dumper;
use open IO => ':utf8', ':std';
use Text::ANSI::Fold qw(ansi_fold);

sub folded {
    local $_ = shift;
    my($folded, $rest) = ansi_fold($_, @_);
    $folded;
}

for my $ent (
    [ bold      => sub { $_[0] =~ s/(.)/$1\b$1/gr     } ],
    [ bold3     => sub { $_[0] =~ s/(.)/$1\b$1\b$1/gr } ],
    [ underline => sub { $_[0] =~ s/(.)/_\b$1/gr      } ],
    [ bold_ul   => sub { $_[0] =~ s/(.)/_\b$1\b$1/gr  } ],
    )
{
    my($msg, $sub) = @$ent;
    $_ = "12345678901234567890123456789012345678901234567890";
    my $len = length;
    $_ = $sub->($_);
    is(folded($_, 1),        $sub->("1"),          "$msg: 1");
    is(folded($_, 10),       $sub->("1234567890"), "$msg: 10");
    is(folded($_, $len),     $_,                   "$msg: just");
    is(folded($_, $len * 2), $_,                   "$msg: long");
    is(folded($_, -1),       $_,                   "$msg: negative");
}

is(folded("\b", -1), "\b", "backspace only (1)");
is(folded("\b"x10, -1), "\b"x10, "backspace only (10)");

$_ = "漢\b漢字\b字";
is(folded($_, 1), "漢\b漢", "wide char with single bs 1");
is(folded($_, 2), "漢\b漢", "wide char with single bs 2");
is(folded($_, 3), "漢\b漢", "wide char with single bs 3");
is(folded($_, 4), "漢\b漢字\b字", "wide char with single bs 4");

$_ = "漢\b\b漢字\b\b字";
is(folded($_, 1), "漢\b\b漢", "wide char with double bs 1");
is(folded($_, 2), "漢\b\b漢", "wide char with double bs 2");
is(folded($_, 3), "漢\b\b漢", "wide char with double bs 3");
is(folded($_, 4), "漢\b\b漢字\b\b字", "wide char with double bs 4");

$_ = "漢\b\b\b漢字\b\b\b字";
is(folded($_, 1), "漢\b\b\b漢", "wide char with triple bs 1");
is(folded($_, 2), "漢\b\b\b漢", "wide char with triple bs 2");
is(folded($_, 3), "漢\b\b\b漢", "wide char with triple bs 3");
is(folded($_, 4), "漢\b\b\b漢字\b\b\b字", "wide char with triple bs 4");

$_ = "漢\b漢字\b";
is(folded($_, 1), "漢\b漢", "broken wide char with single bs 1");
is(folded($_, 2), "漢\b漢", "broken wide char with single bs 2");
is(folded($_, 3), "漢\b漢字\b", "broken wide char with single bs 3");
is(folded($_, 4), "漢\b漢字\b", "broken wide char with single bs 4");

done_testing;
