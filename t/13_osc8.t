use strict;
use Test::More 0.98;

use Text::ANSI::Fold qw(ansi_fold);

my $fold = Text::ANSI::Fold->new;

sub fold  { $fold->fold(@_) }
sub left  { (fold @_)[0] }
sub right { (fold @_)[1] }

# OSC 8 hyperlink helpers
sub osc8_start { "\e]8;;$_[0]\e\\" }
sub osc8_end   { "\e]8;;\e\\" }
sub osc8_link  { osc8_start($_[0]) . $_[1] . osc8_end() }

{
    # Basic OSC 8 recognition
    my $url = "https://example.com";
    my $text = osc8_link($url, "Click");

    is(left($text, width => 10), $text, "osc8: fits in width");
    is(left($text, width => 5),  $text, "osc8: just fits");
}

{
    # OSC 8 with folding
    my $url = "https://example.com";
    my $text = osc8_link($url, "This is a long link text");

    my $l = left($text, width => 15);
    my $r = right($text, width => 15);

    like($l, qr/^\e\]8;;/, "osc8 fold: left has start");
    like($r, qr/\e\]8;;\e\\$/, "osc8 fold: right has end");

    # Verify visible text is split correctly
    my $l_visible = $l =~ s/\e\]8[^\a\e]*(?:\e\\|\a)//gr;
    my $r_visible = $r =~ s/\e\]8[^\a\e]*(?:\e\\|\a)//gr;
    is($l_visible, "This is a long ", "osc8 fold: left visible text");
    is($r_visible, "link text", "osc8 fold: right visible text");
}

{
    # OSC 8 close/reopen at fold boundary
    my $url = "https://example.com";
    my $start = osc8_start($url);
    my $end   = osc8_end();
    my $text  = osc8_link($url, "ABCDEFGHIJ");

    my $l = left($text, width => 5);
    my $r = right($text, width => 5);

    # left should have: start + "ABCDE" + end (closed at boundary)
    is($l, "${start}ABCDE${end}", "osc8 boundary: left closed");

    # right should have: start + "FGHIJ" + end (reopened and closed)
    is($r, "${start}FGHIJ${end}", "osc8 boundary: right reopened");
}

{
    # OSC 8 with params close/reopen
    my $start = "\e]8;id=foo;https://example.com\e\\";
    my $end   = osc8_end();
    my $text  = $start . "ABCDEFGHIJ" . $end;

    my $l = left($text, width => 5);
    my $r = right($text, width => 5);

    is($l, "${start}ABCDE${end}", "osc8 params boundary: left closed");
    is($r, "${start}FGHIJ${end}", "osc8 params boundary: right reopened");
}

{
    # After link ends, no reopen on next fold
    my $url = "https://example.com";
    my $text = osc8_link($url, "AB") . "CDEFGHIJKL";

    my $l = left($text, width => 5);
    my $r = right($text, width => 5);

    is($l, osc8_link($url, "AB") . "CDE", "osc8 ended: left correct");
    is($r, "FGHIJKL", "osc8 ended: right has no link");
}

{
    # OSC 8 fold with discard
    my $url = "https://example.com";
    my $text = osc8_link($url, "ABCDEFGHIJ");

    $fold->configure(discard => { OSC => 1 });
    my $l = left($text, width => 5);
    my $r = right($text, width => 5);

    is($l, "ABCDE", "osc8 discard fold: left no OSC");
    is($r, "FGHIJ" . osc8_end(), "osc8 discard fold: right has trailing end");
    $fold->configure(discard => {});
}

{
    # URL with tilde (ECMA-48 compliance test)
    my $url = "https://example.com/~user/path";
    my $text = osc8_link($url, "Home");

    is(left($text, width => 10), $text, "osc8 tilde: recognized");
    like($text, qr/~user/, "osc8 tilde: URL preserved");
}

{
    # OSC 8 with params (id attribute)
    my $start = "\e]8;id=link1;https://example.com\e\\";
    my $end = osc8_end();
    my $text = $start . "Click" . $end;

    is(left($text, width => 10), $text, "osc8 params: recognized");
}

{
    # OSC 8 with BEL terminator
    my $text = "\e]8;;https://example.com\aClick\e]8;;\a";

    is(left($text, width => 10), $text, "osc8 BEL: recognized");
}

{
    # Multiple links
    my $link1 = osc8_link("https://a.com", "AAA");
    my $link2 = osc8_link("https://b.com", "BBB");
    my $text = $link1 . " " . $link2;

    is(left($text, width => 10), $text, "osc8 multi: fits");

    my $l = left($text, width => 4);
    my $r = right($text, width => 4);
    like($l, qr/AAA/, "osc8 multi: first link in left");
    like($r, qr/BBB/, "osc8 multi: second link in right");
}

{
    # OSC 8 combined with SGR color
    my $url = "https://example.com";
    my $text = "\e[31m" . osc8_link($url, "Red Link") . "\e[m";

    my $l = left($text, width => 4);
    like($l, qr/^\e\[31m/, "osc8+sgr: color preserved");
    like($l, qr/\e\]8;;/, "osc8+sgr: link preserved");
}

{
    # discard OSC option
    my $url = "https://example.com";
    my $text = osc8_link($url, "Click");

    $fold->configure(discard => { OSC => 1 });
    is(left($text, width => 10), "Click", "osc8 discard: OSC removed");

    $fold->configure(discard => {});
    is(left($text, width => 10), $text, "osc8 discard: OSC restored");
}

{
    # OSC 8 with SGR and word boundary folding
    # Regression: word boundary logic must skip OSC sequences
    # to avoid splitting SGR sequences like \e[48;5;254m
    # The bug: [^\e]* in the word boundary regex stops at \e inside OSC,
    # causing ${csi_re} to fail and .*? to match through SGR sequences,
    # which allows the word group to grab digits from inside SGR as a "word".
    my $osc = osc8_link("https://github.com/tecolicom", "[app-ansi-tools]");
    my $sgr = "\e[48;5;254m";
    my $rst = "\e[m";

    # Build a line long enough that width 78 causes fold inside SGR region
    my $text = "| $osc | ";
    for my $name (qw(ansicolumn ansiecho ansifold ansicut ansicolrm ansiprintf)) {
        $text .= "${sgr}${name}${rst}, ";
    }
    $text .= "| description text |";

    my ($l, $r) = fold($text, width => 78, boundary => 'word');

    # Strip all valid ANSI sequences from right side to get visible text
    (my $r_visible = $r) =~ s/\e\[ [^m]* m//gx;
    $r_visible =~ s/\e\]8 [^\a\e]* (?:\e\\|\a)//gx;

    # Visible text must not start with orphan SGR parameters (e.g., "254m")
    unlike($r_visible, qr/\A[\d;]+m/, "osc8+sgr word: no orphan SGR params in visible text");

    # Left must not end with incomplete SGR (before any trailing reset)
    (my $l_no_reset = $l) =~ s/\e\[m\z//;
    unlike($l_no_reset, qr/\e\[[\d;]*\z/, "osc8+sgr word: no partial SGR at end of left");
}

{
    # OSC 8 with narrow width and word boundary must not loop forever
    # When $lead contains only OSC sequences (pwidth=0), word pushback
    # must be suppressed to guarantee visible progress.
    my $text = osc8_link("https://github.com/tecolicom", "[tecolicom on GitHub]");

    my @chops = $fold->text($text)->chops(width => 6, boundary => 'word');

    ok(@chops > 0, "osc8 narrow word: produces output");

    # Verify all visible text is preserved
    my $joined = join '', @chops;
    (my $visible = $joined) =~ s/\e\]8[^\a\e]*(?:\e\\|\a)//g;
    is($visible, "[tecolicom on GitHub]", "osc8 narrow word: visible text preserved");
}

{
    # OSC 8 with narrow width, word boundary, and linebreak (runin/runout)
    # Regression: run-out pushback of prohibition chars (e.g., "[") after OSC
    # must not cause infinite loop when only OSC sequences remain in $folded.
    use Text::ANSI::Fold qw(:constants);
    my $f = Text::ANSI::Fold->new(
        boundary => 'word', linebreak => LINEBREAK_ALL,
        runin => 2, runout => 2,
    );
    my $text = "- " . osc8_link("https://github.com/tecolicom", "[tecolicom on GitHub]");

    my @chops = $f->text($text)->chops(width => 9);

    ok(@chops > 0, "osc8 narrow linebreak: produces output");

    my $joined = join '', @chops;
    (my $visible = $joined) =~ s/\e\]8[^\a\e]*(?:\e\\|\a)//g;
    is($visible, "- [tecolicom on GitHub]", "osc8 narrow linebreak: visible text preserved");
}

done_testing;
