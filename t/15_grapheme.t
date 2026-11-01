use v5.14;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use Test::More;
use Text::ANSI::Fold;
use Text::VisualWidth::PP qw(vwidth);

sub lines {
    my($text, $width) = @_;
    Text::ANSI::Fold->new(width => $width)->text($text)->chops;
}

# A line is never wider than the width, unless it is one grapheme.
my $emoji = "\N{U+1F468}\N{U+200D}\N{U+1F469}\N{U+200D}\N{U+1F467}"	# family
	  . "\N{U+1F44D}\N{U+1F3FD}\N{U+1F3FD}"				# thumbs up, two modifiers
	  . "\N{U+1FAAA}";						# identification card
for my $width (2 .. 12) {
    my @over = grep { vwidth($_) > $width and (() = /\X/g) > 1 } lines($emoji x 3, $width);
    is(scalar @over, 0, "emoji sequences within width $width");
}

# A combining mark right after the width stays with its letter.
is_deeply([ lines("abe\N{U+301}xyz", 3) ], [ "abe\N{U+301}", "xyz" ],
	  "combining mark after ASCII at the width");

# Japanese is folded at the width.
is_deeply([ lines("日本語の文章です。" x 2, 10) ],
	  [ "日本語の文", "章です。日", "本語の文章", "です。" ],
	  "Japanese at width 10");

done_testing;
