use strict;
use Test::More 0.98;
use utf8;

use Text::ANSI::Fold qw(ansi_fold :regex);

# The control strings of ECMA-48 other than OSC: DCS, SOS, PM and APC,
# which $ctrl_string_re matches with OSC.  Each is an opening
# delimiter, a string and STRING TERMINATOR, and is kept as it is: it
# has no width and is never divided.  The images of the kitty graphics
# protocol are sent by APC, and Sixel by DCS.

sub width { (ansi_fold($_[0], -1))[2] }

my $data = "QUJD" x 10;
my %str = (
    APC     => "\e_Ga=T,i=1,q=2;$data\e\\",
    DCS     => "\eP0;0;0q#0;2;0;0;0#0~~~~\e\\",
    SOS     => "\eXsome string\e\\",
    PM      => "\e^privacy message\e\\",
    'APC BEL' => "\e_Ga=T,i=1;$data\a",
);

# The 8-bit forms are matched, and taken at the start of a text.  In
# the middle of a text they are not, as with OSC and CSI: the
# characters which are not ESC are taken as text there.
for my $s ("\x9fGa=T,i=1;$data\x9c", "\x{90}0;0;0q#0~~\x9c") {
    my $name = sprintf "8-bit %02X", ord $s;
    like($s, qr/\A$ctrl_string_re\z/, "$name: matches \$ctrl_string_re");
    is(width("${s}cd"), 2, "$name: has no width at the start");
}

for my $name (sort keys %str) {
    my $s = $str{$name};
    like($s, qr/\A$ctrl_string_re\z/, "$name: matches \$ctrl_string_re");
    is(width("ab${s}cd"), 4, "$name: has no width");

    # folded where the string is: it is not divided
    my($folded, $rest, $w) = ansi_fold("ab${s}cdef", 4);
    is($folded, "ab${s}cd", "$name: kept whole in the folded text");
    is($rest,   "ef",       "$name: the rest");
    is($w,      4,          "$name: width of the folded text");

    # longer than the width, alone
    ($folded, $rest) = ansi_fold("${s}abc", 2);
    is($folded, "${s}ab", "$name: longer than the width, not divided");
    is($rest,   "c",      "$name: the rest after a long string");
}

# at the folding point it stays with the former part, as OSC does
{
    my $s = $str{APC};
    my($folded, $rest) = ansi_fold("abc${s}def", 3);
    is($folded, "abc${s}", "at the folding point: with the former part");
    is($rest,   "def",     "at the folding point: the rest");
}

# with colors around it
{
    my $s = $str{APC};
    my($folded, $rest) = ansi_fold("\e[31mab${s}cdef\e[m", 4);
    is($folded, "\e[31mab${s}cd\e[m", "in colored text: kept whole");
    is($rest,   "\e[31mef\e[m",       "in colored text: color recovered");
}

# word boundary: the string is not taken as a part of the word, and
# stays on the line as OSC does
{
    my $s = $str{APC};
    my($folded, $rest) = ansi_fold("foo ${s}barbaz qux", 8, boundary => 'word');
    is($folded, "foo $s",     "word boundary: the string stays on the line");
    is($rest,   "barbaz qux", "word boundary: the word goes on");
    my $osc = "\e]0;title\a";
    my($of, $or) = ansi_fold("foo ${osc}barbaz qux", 8, boundary => 'word');
    is($folded =~ s/\Q$s\E/<S>/r, $of =~ s/\Q$osc\E/<S>/r, "word boundary: as OSC");
}

# a form feed after the string is at the beginning of the line
{
    my $s = $str{APC};
    my($folded, $rest) = ansi_fold("${s}\fabc", 10);
    is($folded, "${s}\fabc", "form feed after the string");
}

# OSC is one of the control strings too
like("\e]8;;http://example.com\e\\", qr/\A$ctrl_string_re\z/, "OSC: matches \$ctrl_string_re");
like("\x9d0;title\a", qr/\A$ctrl_string_re\z/, "8-bit OSC: matches \$ctrl_string_re");
unlike("\e[31m", qr/\A$ctrl_string_re/, "CSI: does not match");

# discard => ['CONTROL'] removes all the control strings, and OSC
# only OSC; the text and the colors are kept
{
    my $osc = "\e]0;title\a";
    my $t = "\e[31ma${osc}b$str{APC}c$str{DCS}d$str{SOS}e$str{PM}f\e[m";
    my $all = Text::ANSI::Fold->new(width => -1, discard => ['CONTROL']);
    is(($all->fold($t))[0], "\e[31mabcdef\e[m", "discard CONTROL: all removed");
    my $o = Text::ANSI::Fold->new(width => -1, discard => ['OSC']);
    is(($o->fold($t))[0], "\e[31mab$str{APC}c$str{DCS}d$str{SOS}e$str{PM}f\e[m",
       "discard OSC: only OSC removed");
    my $link = "\e]8;;http://example.com\e\\link text\e]8;;\e\\";
    is(join("|", $all->text($link)->chops(width => 5)), "link |text",
       "discard CONTROL: link text kept, link not reopened");
}

# an unterminated string is not taken as one
{
    my $s = "\e_Ga=T,i=1;QUJD";
    unlike($s, qr/\A$ctrl_string_re\z/, "unterminated: not matched");
}

done_testing;
