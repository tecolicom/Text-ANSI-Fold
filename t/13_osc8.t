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

done_testing;
