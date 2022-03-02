[![Actions Status](https://github.com/kaz-utashiro/Text-ANSI-Fold/workflows/test/badge.svg)](https://github.com/kaz-utashiro/Text-ANSI-Fold/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Text-ANSI-Fold.svg)](https://metacpan.org/release/Text-ANSI-Fold)
# NAME

Text::ANSI::Fold - Text folding library supporting ANSI terminal sequence and Asian wide characters with prohibition character handling.

# VERSION

Version 2.13

# SYNOPSIS

    use Text::ANSI::Fold qw(ansi_fold);
    ($folded, $remain) = ansi_fold($text, $width, [ option ]);

    use Text::ANSI::Fold;
    my $f = Text::ANSI::Fold->new(width => 80, boundary => 'word');
    $f->configure(ambiguous => 'wide');
    ($folded, $remain) = $f->fold($text);

    use Text::ANSI::Fold;
    while (<>) {
        print join "\n",
            Text::ANSI::Fold->new(width => 40, text => $_)->chops;
    }

    use Text::ANSI::Fold qw(:constants);
    my $fold = Text::ANSI::Fold->new(
        width     => 70,
        boundary  => 'word',
        linebreak => LINEBREAK_ALL,
        runin     => 4,
        runout    => 4,
        );

# DESCRIPTION

Text::ANSI::Fold provides capability to fold a text into two strings
by given width.  Text can include ANSI terminal sequences.  If the
text is divided in the middle of ANSI-effect region, reset sequence is
appended to folded text, and recover sequence is prepended to trimmed
string.

This module also support Unicode Asian full-width and non-spacing
combining characters properly.  Japanese text formatting with
head-or-end of line prohibition character is also supported.  Set
the linebreak mode to enable it.

Use exported **ansi\_fold** function to fold original text, with number
of visual columns you want to cut off the text.

    ($folded, $remain, $w) = ansi_fold($text, $width);

It returns a pair of strings; first one is folded text, and second is
the rest.

Additional third result is the visual width of folded text.  You may
want to know how many columns returned string takes for further
processing.

Negative width value is taken as unlimited.  So the string is never
folded, but you can use this to expand tabs and to get visual string
width.

This function returns at least one character in any situation.  If you
provide Asian wide string and just one column as width, it trims off
the first wide character even if it does not fit to given width.

Default parameter can be set by **configure** class method:

    Text::ANSI::Fold->configure(width => 80, padding => 1);

Then you don't have to pass second argument.

    ($folded, $remain) = ansi_fold($text);

Because second argument is always taken as width, use _undef_ when
using default width with additional parameter:

    ($folded, $remain) = ansi_fold($text, undef, padding => 1);

Some other easy-to-use interfaces are provided by sister module
[Text::ANSI::Fold::Util](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold%3A%3AUtil).

# OBJECT INTERFACE

You can create an object to hold parameters, which is effective during
object life time.  For example, 

    my $f = Text::ANSI::Fold->new(
        width => 80,
        boundary => 'word',
        );

makes an object folding on word boundaries with 80 columns width.
Then you can use this without parameters.

    $f->fold($text);

Use **configure** method to update parameters:

    $f->configure(padding => 1);

Additional parameter can be specified on each call, and they precede
saved value.

    $f->fold($text, width => 40);

# STRING OBJECT INTERFACE

Fold object can hold string inside by **text** method.

    $f->text("text");

And folded string can be taken by **retrieve** method.  It returns
empty string if nothing remained.

    while ((my $folded = $f->retrieve) ne '') {
        print $folded;
        print "\n" if $folded !~ /\n\z/;
    }

Method **chops** returns chopped string list.  Because **text** method
returns the object itself, you can use **text** and **chops** like this:

    print join "\n", $f->text($text)->chops;

Actually, text can be set by **new** or **configure** method through
**text** option.  Next program just works.

    use Text::ANSI::Fold;
    while (<>) {
        print join "\n",
            Text::ANSI::Fold->new(width => 40, text => $_)->chops;
    }

When using **chops** method, **width** parameter can take array
reference, and chops text into given width list.

    my $fold = Text::ANSI::Fold->new;
    my @list = $fold->text("1223334444")->chops(width => [ 1, 2, 3 ]);
    # return ("1", "22", "333") and keep "4444"

If the width value is 0, it returns empty string.

Negative width value takes all the rest of holded string in
**retrieve** and **chops** method.

# OPTIONS

Option parameter can be specified as name-value list for **ansi\_fold**
function as well as **new** and **configure** method.

    ansi_fold($text, $width, boundary => 'word', ...);

    Text::ANSI::Fold->configure(boundary => 'word');

    my $f = Text::ANSI::Fold->new(boundary => 'word');

    $f->configure(boundary => 'word');

- **width** => _n_, _\[ n, m, ... \]_

    Specify folding width.  Negative value means all the rest.

    Array reference can be specified but works only with **chops** method,
    and retunrs empty string for zero width.

- **boundary** => _word_ or _space_

    Option **boundary** takes _word_ and _space_ as a valid value.  These
    prohibit to fold a line in the middle of ASCII/Latin sequence.  Value
    _word_ means a sequence of alpha-numeric characters, and _space_
    means simply non-space printables.

    This operation takes place only when enough space will be provided to
    hold the word on next call with same width.

    If the color of text is altered within a word, that position is also
    taken as an boundary.

- **padding** => _bool_

    If **padding** option is given with true value, margin space is filled
    up with space character.  Default is 0.  Next code fills spaces if the
    given text is shorter than 80.

        ansi_fold($text, 80, padding => 1);

    If an ANSI **Erase Line** sequence is found in the string, color status
    at the position is remembered, and padding string is produced in that
    color.

- **padchar** => _char_

    **padchar** option specifies character used to fill up the remainder of
    given width.

        ansi_fold($text, 80, padding => 1, padchar => '_');

- **prefix** => _string_ | _coderef_

    **prefix** string is inserted before remained string if it is not
    empty.  This is convenient to produce indented series of text by
    **chops** interface.

    If the value is reference to subroutine, its result is used as a
    prefix string.

- **ambiguous** => "narrow" or "wide"

    Tells how to treat Unicode East Asian ambiguous characters.  Default
    is "narrow" which means single column.  Set "wide" to tell the module
    to treat them as wide character.

- **discard** => \[ "EL", "OSC" \]

    Specify the list reference of control sequence name to be discarded.
    **EL** means Erase Line; **OSC** means Operating System Command, defined
    in ECMA-48.  Erase Line right after RESET sequence is always kept.

- **linebreak** => _mode_
- **runin** => _width_
- **runout** => _width_

    These options specify the behavior of line break handling for Asian
    multi byte characters.  Only Japanese is supported currently.

    If the cut-off text start with space or prohibited characters
    (e.g. closing parenthesis), they are ran-in at the end of current line
    as much as possible.

    If the trimmed text end with prohibited characters (e.g. opening
    parenthesis), they are ran-out to the head of next line, if it fits to
    maximum width.

    Default **linebreak** mode is **LINEBREAK\_NONE** and can be set one of
    those:

        LINEBREAK_NONE
        LINEBREAK_RUNIN
        LINEBREAK_RUNOUT
        LINEBREAK_ALL

    Import-tag **:constants** can be used to access these constants.

    Option **runin** and **runout** is used to set maximum width of moving
    characters.  Default values are both 2.

- **expand** => _bool_
- **tabstop** => _n_
- **tabhead** => _char_
- **tabspace** => _char_

    Enable tab character expansion.

    Default tabstop is 8 and can be set by **tabstop** option.

    Tab character is converted to **tabhead** and following **tabspace**
    characters.  Both are white space by default.

- **tabstyle** => _style_

    Set tab expansion style.  This parameter set both **tabhead** and
    **tabspace** at once according to the given style name.  Each style has
    two values for tabhead and tabspace.

    If two style names are combined, like `symbol,space`, use
    `symbols`'s tabhead and `space`'s tabspace.

    Currently these names are available.

        space  => [ ' ', ' ' ],
        dot    => [ '.', '.' ],
        symbol => [ "\N{SYMBOL FOR HORIZONTAL TABULATION}",
                    "\N{SYMBOL FOR SPACE}" ],
        shade  => [ "\N{MEDIUM SHADE}",
                    "\N{LIGHT SHADE}" ],
        block  => [ "\N{LOWER ONE QUARTER BLOCK}",
                    "\N{LOWER ONE EIGHTH BLOCK}" ],
        bar    => [ "\N{BOX DRAWINGS HEAVY RIGHT}",
                    "\N{BOX DRAWINGS LIGHT HORIZONTAL}" ],
        dash   => [ "\N{BOX DRAWINGS HEAVY RIGHT}",
                    "\N{BOX DRAWINGS LIGHT DOUBLE DASH HORIZONTAL}" ],

    Below are styles providing same character for both tabhead and
    tabspace.

        arrow        => "\N{RIGHTWARDS ARROW}",
        double-arrow => "\N{RIGHTWARDS DOUBLE ARROW}",
        triple-arrow => "\N{RIGHTWARDS TRIPLE ARROW}",
        white-arrow  => "\N{RIGHTWARDS WHITE ARROW}",
        wave-arrow   => "\N{RIGHTWARDS WAVE ARROW}",
        circle-arrow => "\N{CIRCLED HEAVY WHITE RIGHTWARDS ARROW}",
        curved-arrow => "\N{HEAVY BLACK CURVED DOWNWARDS AND RIGHTWARDS ARROW}",
        shadow-arrow => "\N{HEAVY UPPER RIGHT-SHADOWED WHITE RIGHTWARDS ARROW}",
        squat-arrow  => "\N{SQUAT BLACK RIGHTWARDS ARROW}",
        squiggle     => "\N{RIGHTWARDS SQUIGGLE ARROW}",
        harpoon      => "\N{RIGHTWARDS HARPOON WITH BARB UPWARDS}",
        cuneiform    => "\N{CUNEIFORM SIGN TAB}",

# EXAMPLE

Next code implements almost perfect fold command for multi byte
characters with prohibited character handling.

    #!/usr/bin/env perl
    
    use strict;
    use warnings;
    use open IO => 'utf8', ':std';
    
    use Text::ANSI::Fold qw(:constants);
    my $fold = Text::ANSI::Fold->new(
        width     => 70,
        boundary  => 'word',
        linebreak => LINEBREAK_ALL,
        runin     => 4,
        runout    => 4,
        );
    
    $, = "\n";
    while (<>) {
        print $fold->text($_)->chops;
    }

# SEE ALSO

- [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold)
- [https://github.com/kaz-utashiro/Text-ANSI-Fold](https://github.com/kaz-utashiro/Text-ANSI-Fold)

    Distribution and repository.

- [App::ansifold](https://metacpan.org/pod/App%3A%3Aansifold)

    Command line utility using [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold).

- [Text::ANSI::Fold::Util](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold%3A%3AUtil)

    Collection of utilities using [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) module.

- [Text::ANSI::Tabs](https://metacpan.org/pod/Text%3A%3AANSI%3A%3ATabs)

    [Text::Tabs](https://metacpan.org/pod/Text%3A%3ATabs) compatible tab expand/unexpand module using
    [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) as a backend processor.

- [App::sdif](https://metacpan.org/pod/App%3A%3Asdif)

    [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) was originally implemented in **sdif** command for
    long time, which provide side-by-side view for diff output.  It is
    necessary to process output from **cdif** command which highlight diff
    output using ANSI escape sequences.

- [Text::ANSI::Util](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AUtil), [Text::ANSI::WideUtil](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AWideUtil)

    These modules provide a rich set of functions to handle string
    contains ANSI color terminal sequences.  In contrast,
    [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) provides simple folding mechanism with minimum
    overhead.  Also **sdif** need to process other than SGR (Select Graphic
    Rendition) color sequence, and non-spacing combining characters, those
    are not supported by these modules.

- [https://en.wikipedia.org/wiki/ANSI\_escape\_code](https://en.wikipedia.org/wiki/ANSI_escape_code)

    ANSI escape code definition.

- [https://www.w3.org/TR/jlreq/](https://www.w3.org/TR/jlreq/)

    Requirements for Japanese Text Layout,
    W3C Working Group Note 11 August 2020

- [ECMA-48](https://www.ecma-international.org/wp-content/uploads/ECMA-48_5th_edition_june_1991.pdf)

    ECMA-48: Control Functions for Coded Character Sets

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2018- Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
