use strict;
use Test::More 0.98;
use utf8;
use open IO => 'utf8', ':std';
use Data::Dumper;

use Text::ANSI::Fold qw(:constants);

my $fold = Text::ANSI::Fold->new;

sub color {
    my $code = { r => 31 , b => 34 }->{+shift};
    my @result;
    while (my($color, $plain) = splice @_, 0, 2) {
	push @result, "\e[${code}m" . $color . "\e[m";
	push @result, $plain if defined $plain;
    }
    join '', @result;
}

sub r { color 'r', @_ }
sub g { color 'g', @_ }
sub b { color 'b', @_ }

sub fold  { $fold->fold(@_) }
sub left  { (fold @_)[0] }
sub right { (fold @_)[1] }

{
    $_ = r("12345678901234567890123456789012345678901234567890");
    is(left($_, width => 1), r("1"),             "ASCII: 1");
    is(left($_, width => 10), r("1234567890"),   "ASCII: 10");
    is(left($_, width => length), $_,         "ASCII: just");
    is(left($_, width => length($_) * 2), $_, "ASCII: long");
}

{
    $_ = r("一二三四五六七八九十");
    is(left($_, width => 1), r("一"),         "WIDECHAR: 1");
    is(left($_, width => 2), r("一"),         "WIDECHAR: 2");
    is(left($_, width => 3), r("一"),         "WIDECHAR: 3");
    is(left($_, width => 4), r("一二"),        "WIDECHAR: 4");
    is(left($_, width => 10), r("一二三四五"), "WIDECHAR: 10");
}

{
    $_ = r("一二三四五六七八九十" =~ /./g);
    is(left($_, width => 1), r("一"), "CYCLE: 1");
    is(left($_, width => 2), r("一"), "CYCLE: 2");
    is(left($_, width => 3), r("一"), "CYCLE: 3");
    is(left($_, width => 4), r(qw(一 二)), "CYCLE: 4");
    is(left($_, width => 6), r(qw(一 二 三)), "CYCLE: 6");
}

{
    $_ = r("一（二）三四五");

    is(left($_, width => 4), r("一（"), "linebreak_none: 4");
    is(left($_, width => 6), r("一（二"), "linebreak_none: 6");
    is(left($_, width => 8), r("一（二）"), "linebreak_none: 8");

    $fold->configure(linebreak => LINEBREAK_RUNIN);
    is(left($_, width => 2), r("一"), "linebreak_runin: 2");
    is(left($_, width => 4), r("一（"), "linebreak_runin: 4");
    is(left($_, width => 6), r("一（二）"), "linebreak_runin: 6");
    is(left($_, width => 8), r("一（二）"), "linebreak_runin: 8");

    $fold->configure(linebreak => LINEBREAK_ALL);
    is(left($_, width => 2), r("一"), "linebreak_runout: 2");
    is(left($_, width => 4), r("一"), "linebreak_runout: 4");
    is(left($_, width => 6), r("一（二）"), "linebreak_runout: 6");
    is(left($_, width => 8), r("一（二）"), "linebreak_runout: 8");
}

{
    $_ = r("一（二）三四五" =~ /./g);

    $fold->configure(linebreak => LINEBREAK_NONE);
    is(left($_, width => 4), r("一（" =~ /./g), "linebreak_none: 4");
    is(left($_, width => 6), r("一（二" =~ /./g), "linebreak_none: 6");
    is(left($_, width => 8), r("一（二）" =~ /./g), "linebreak_none: 8");

    $fold->configure(linebreak => LINEBREAK_RUNIN);
    is(left($_, width => 2), r("一" =~ /./g), "linebreak_runin: 2");
    is(left($_, width => 4), r("一（" =~ /./g), "linebreak_runin: 4");
    is(left($_, width => 6), r("一（二）" =~ /./g), "linebreak_runin: 6");
    is(left($_, width => 8), r("一（二）" =~ /./g), "linebreak_runin: 8");

    $fold->configure(linebreak => LINEBREAK_RUNOUT);
    is(left($_, width => 2), r("一" =~ /./g), "linebreak_runout: 2");
    is(left($_, width => 4), r("一" =~ /./g), "linebreak_runout: 4");
    is(left($_, width => 6), r("一（二" =~ /./g), "linebreak_runout: 6");
    is(left($_, width => 8), r("一（二）" =~ /./g), "linebreak_runout: 8");

    $fold->configure(linebreak => LINEBREAK_ALL);
    is(left($_, width => 2), r("一" =~ /./g), "linebreak_runall: 2");
    is(left($_, width => 4), r("一" =~ /./g), "linebreak_runall: 4");
    is(left($_, width => 6), r("一（二）" =~ /./g), "linebreak_runall: 6");
    is(left($_, width => 8), r("一（二）" =~ /./g), "linebreak_runall: 8");
}

{
    $_ = r("〇一（二）三四五" =~ /./g);

    $fold->configure(linebreak => LINEBREAK_NONE);
    is(left($_, width => 6),  r("〇一（" =~ /./g), "linebreak_none+: 6");
    is(left($_, width => 8),  r("〇一（二" =~ /./g), "linebreak_none+: 8");
    is(left($_, width => 10), r("〇一（二）" =~ /./g), "linebreak_none+: 10");

    $fold->configure(linebreak => LINEBREAK_RUNIN);
    is(left($_, width => 4),  r("〇一" =~ /./g), "linebreak_runin+: 4");
    is(left($_, width => 6),  r("〇一（" =~ /./g), "linebreak_runin+: 6");
    is(left($_, width => 8),  r("〇一（二）" =~ /./g), "linebreak_runin+: 8");
    is(left($_, width => 10), r("〇一（二）" =~ /./g), "linebreak_runin+: 10");

    $fold->configure(linebreak => LINEBREAK_RUNOUT);
    is(left($_, width => 4),  r("〇一" =~ /./g), "linebreak_runout+: 4");
    is(left($_, width => 6),  r("〇一" =~ /./g), "linebreak_runout+: 6");
    is(left($_, width => 8),  r("〇一（二" =~ /./g), "linebreak_runout+: 8");
    is(left($_, width => 10), r("〇一（二）" =~ /./g), "linebreak_runout+: 10");

    $fold->configure(linebreak => LINEBREAK_ALL);
    is(left($_, width => 4),  r("〇一" =~ /./g), "linebreak_runall+: 4");
    is(left($_, width => 6),  r("〇一" =~ /./g), "linebreak_runall+: 6");
    is(left($_, width => 8),  r("〇一（二）" =~ /./g), "linebreak_runall+: 8");
    is(left($_, width => 10), r("〇一（二）" =~ /./g), "linebreak_runall+: 10");
}

done_testing;
