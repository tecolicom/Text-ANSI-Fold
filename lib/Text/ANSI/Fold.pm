package Text::ANSI::Fold;
use 5.014;
use strict;
use warnings;

our $VERSION = "0.01";

use Exporter 'import';
our @EXPORT_OK = qw(&ansi_fold);

use Carp;
use Text::VisualWidth::PP qw(vwidth);

my $alphanum_re = qr{ [_\d\p{Latin}] }x;
my $reset_re    = qr{ \e \[ [0;]* m (?: \e \[ [0;]* [mK])* }x;
my $color_re    = qr{ \e \[ [\d;]* [mK] }x;
my $control_re  = qr{ \e \] [\;\:\/0-9a-z]* \e \\ }x;

use constant SGR_RESET => "\e[m";

sub IsWideSpacing {
    return <<"END";
+utf8::East_Asian_Width=Wide
+utf8::East_Asian_Width=FullWidth
-utf8::Nonspacing_Mark
END
}

sub IsWideAmbiguousSpacing {
    return <<"END";
+utf8::East_Asian_Width=Wide
+utf8::East_Asian_Width=FullWidth
+utf8::East_Asian_Width=Ambiguous
-utf8::Nonspacing_Mark
END
}

sub _startWideSpacing {
    # look at $_
    if ($Text::VisualWidth::PP::EastAsian) {
	/^\p{IsWideAmbiguousSpacing}/;
    } else {
	/^\p{IsWideSpacing}/;
    }
}

sub ansi_fold {
    goto &fold;
}

sub fold {
    local $_ = shift // "";
    my $width = shift;
    my %opt = @_;
    $opt{boundary} = '' if not exists $opt{boundary};
    $opt{padchar} //= ' ';

    $width < 1 and croak "width should be greater than 0";

    my $folded = '';
    my $room = $width;
    my @color_stack;
    while (length) {

	if (s/^([\f\r]+)//) {
	    $folded .= $1;
	    $room = $width;
	    next;
	}
	if (s/^($control_re)//) {
	    $folded .= $1;
	    next;
	}
	if (s/^($reset_re)//) {
	    $folded .= $1;
	    @color_stack = ();
	    next;
	}

	last if $room < 1;
	last if $room != $width and &_startWideSpacing and $room < 2;

	if (s/^($color_re)//) {
	    $folded .= $1;
	    push @color_stack, $1;
	    next;
	}

	if (s/^(\e*[^\e\f\r]+)//) {
	    my $s = $1;
	    if ((my $w = vwidth($s)) <= $room) {
		$folded .= $s;
		$room -= $w;
		next;
	    }
	    my($a, $b, $w) = simple_fold($s, $room);
	    if ($w > $room and $room < $width) {
		$_ = $s . $_;
		last;
	    }
	    ($folded, $_) = ($folded . $a, $b . $_);
	    $room -= $w;
	} else {
	    die "panic ($_)";
	}
    }

    if ($opt{boundary} eq 'word'
	and my($tail) = /^(${alphanum_re}+)/o
	and $folded =~ m{
		^
		( (?: [^\e]* ${color_re} ) *+ )
		( .*? )
		( ${alphanum_re}+ )
		$
	}xo
	) {
	## Break line before word only when enough space will be
	## provided for the word in the next turn.
	my($s, $e) = ($-[3], $+[3]);
	my $l = $e - $s;
	if ($room + $l < $width and $l + length($tail) <= $width) {
	    $_ = substr($folded, $s, $l, '') . $_;
	    $room += $l;
	}
    }

    if (@color_stack) {
	$folded .= SGR_RESET;
	$_ = join '', @color_stack, $_ if $_ ne '';
    }

    if ($opt{pad}) {
	$folded .= $opt{padchar} x $room if $room > 0;
    }

    ($folded, $_);
}

##
## Trim off one or more *logical* characters from the top.
##
sub simple_fold {
    my $orig = shift;
    my $width = shift;
    $width <= 0 and croak "parameter error";

    my($s1, $s2) = $orig =~ m/^(\X{0,$width})(.*)/ or die;

    my $w = vwidth($s1);
    while ($w > $width) {
	my $trim = int(($w - $width) / 2 + 0.5) || 1;
	$s1 =~ s/\X \K ( \X{$trim} ) \z//x or last;
	$s2 = $1 . $s2;
	$w -= vwidth($1);
    }

    ($s1, $s2, $w);
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::ANSI::Fold - Text folding with ANSI sequence and Asian wide characters.

=head1 SYNOPSIS

    use Text::ANSI::Fold qw(ansi_fold);

    ($folded, $remain) = ansi_fold($text, $width, [ option ]);

=head1 DESCRIPTION

Text::ANSI::Fold provides capability to fold text by given width
including ANSI terminal escape sequences.  If the text is divided in
the middle of ANSI-effect region, reset sequence is appended to folded
text, and recover sequence is prepended to trimmed string.

This module also support Unicode Asian full-width string and
non-spacing combining characters.

Use exported B<ansi_fold> funciton or B<Text::ANSI::Fold::fold>
function to fold original text, with number of visual columns you want
to cut off the text.  Width parameter have to be number greater than
zero.

    ($folded, $remain) = ansi_fold($text, $width);

It returns a pair of strings.  First one is folded text, and second is
cut-off text.

This function keeps at least one character in any situation.  If you
provide Asian multi-byte characters and just 1 as width, it trims
first single character even if it does not fit to given width.

=head1 OPTIONS

You can provide option parameters as name-value list like this:

    ansi_fold($text, $width, boundary => 'word', ...);

=over 7

=item B<boundary> => "word"

B<boundary> option currently takes only "word" as a valid vaulue.  In
this case, text is folded on word boundary.  This occurs only when
enough space will be provided to hold the word on next call with same
width, to avoid infinite loop.

=item B<pad> => I<bool>

If B<pad> option is given with true value, margin space is filled up
with space character.  Next code fills spaces if the given text is
shorter than 80.

    ansi_fold($text, 80, pad => 1);

=item B<padchar> => I<char>

B<padchar> option specifies character used to fill up the remainder of
given width.

    ansi_fold($text, 80, pad => 1, padchar => '<');

=back

=head1 SEE ALSO

=over 7

=item L<App::sdif>

L<Text::ANSI::Fold> was originally implemented in B<sdif> command.  It
is necessary to process output from B<cdif> command.

=item L<Text::ANSI::Util>, L<Text::ANSI::WideUtil>

These modules provide rich set of functions to handle string including
ANSI color terminal sequences.  In contrast, L<Text::ANSI::Fold>
provides simple folding mechanism with minimum overhead.  Also B<sdif>
need to process other than SGR (Select Graphic Rendition) sequence,
and non-spacing combining characters, those are not supported by these
modules.

=item L<Getopt::EX::Colormap>

=back

=head1 LICENSE

Copyright (C) Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kazumasa Utashiro

=cut

