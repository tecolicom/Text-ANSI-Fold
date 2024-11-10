use strict;
use Test::More 0.98;
use utf8;

use Text::ANSI::Fold;

my $fold = Text::ANSI::Fold->new;

sub chops {
    my $obj = shift;
    [ $fold->chops(@_) ];
}

$fold->configure(text => "a\rb", width => 5);
is_deeply(chops($fold),
	  [ "a\rb" ],
	  "cr");

$fold->configure(text => "12345\r6789012345", width => 5);
is_deeply(chops($fold),
	  [ "12345\r67890", "12345" ],
	  "cr");

$fold->configure(text => "a\n\fb", width => 10);
is_deeply(chops($fold),
	  [ "a\n", "\fb" ],
	  "formfeed at tol");

$fold->configure(text => "a\fb", width => 10);
is_deeply(chops($fold),
	  [ "a", "\fb" ],
	  "formfeed in the middle");

done_testing;
