package Text::ANSI::Fold::Japanese::W3C;

use strict;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = qw(%prohibition);

# https://www.w3.org/TR/2009/NOTE-jlreq-20090604/
# Requirements for Japanese Text Layout
# W3C Working Group Note 4 June 2009

my %character_class = (

# A.1 Opening brackets
cl_01 => <<'END',
Character	UCS	Name	Remark
‘	2018	LEFT SINGLE QUOTATION MARK	used horizontal composition
“	201C	LEFT DOUBLE QUOTATION MARK	used horizontal composition
（	0028	LEFT PARENTHESIS	
(
〔	3014	LEFT TORTOISE SHELL BRACKET	
［	005B	LEFT SQUARE BRACKET	
[
｛	007B	LEFT CURLY BRACKET	
{
〈	3008	LEFT ANGLE BRACKET	
《	300A	LEFT DOUBLE ANGLE BRACKET	
「	300C	LEFT CORNER BRACKET	
『	300E	LEFT WHITE CORNER BRACKET	
【	3010	LEFT BLACK LENTICULAR BRACKET	
⦅	2985	LEFT WHITE PARENTHESIS	
〘	3018	LEFT WHITE TORTOISE SHELL BRACKET	
〖	3016	LEFT WHITE LENTICULAR BRACKET	
«	00AB	LEFT-POINTING DOUBLE ANGLE QUOTATION MARK	
〝	301D	REVERSED DOUBLE PRIME QUOTATION MARK	used vertical composition
END

# A.2 Closing brackets
cl_02 => <<'END',
Character	UCS	Name	Remark
’	2019	RIGHT SINGLE QUOTATION MARK	used horizontal composition
”	201D	RIGHT DOUBLE QUOTATION MARK	used horizontal composition
）	0029	RIGHT PARENTHESIS	
〕	3015	RIGHT TORTOISE SHELL BRACKET	
］	005D	RIGHT SQUARE BRACKET	
]
｝	007D	RIGHT CURLY BRACKET	
}
〉	3009	RIGHT ANGLE BRACKET	
》	300B	RIGHT DOUBLE ANGLE BRACKET	
」	300D	RIGHT CORNER BRACKET	
』	300F	RIGHT WHITE CORNER BRACKET	
】	3011	RIGHT BLACK LENTICULAR BRACKET	
⦆	2986	RIGHT WHITE PARENTHESIS	
〙	3019	RIGHT WHITE TORTOISE SHELL BRACKET	
〗	3017	RIGHT WHITE LENTICULAR BRACKET	
»	00BB	RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK	
〟	301F	LOW DOUBLE PRIME QUOTATION MARK	used vertical composition
END

# A.3 Hyphens
cl_03 => <<'END',
Character	UCS	Name	Remark
‐	2010	HYPHEN	quarter em width
〜	301C	WAVE DASH	
゠	30A0	KATAKANA-HIRAGANA DOUBLE HYPHEN	half-width
–	2013	EN DASH	half-width
END
    
# A.4 Dividing punctuation marks
cl_04 => <<'END',
Character	UCS	Name	Remark
？	003F	QUESTION MARK	
！	0021	EXCLAMATION MARK	
!
‼	203C	DOUBLE EXCLAMATION MARK	
⁇	2047	DOUBLE QUESTION MARK	
⁈	2048	QUESTION EXCLAMATION MARK	
⁉	2049	EXCLAMATION QUESTION MARK	
END
    
# A.5 Middle dots
cl_05 => <<'END',
Character	UCS	Name	Remark
・	30FB	KATAKANA MIDDLE DOT	
：	003A	COLON	
:
；	003B	SEMICOLON	used horizontal composition
;
END
    
# A.6 Full stops
cl_06 => <<'END',
Character	UCS	Name	Remark
。	3002	IDEOGRAPHIC FULL STOP	
．	002E	FULL STOP	used horizontal composition
.
END
    
# A.7 Commas
cl_07 => <<'END',
Character	UCS	Name	Remark
、	3001	IDEOGRAPHIC COMMA	
，	002C	COMMA	used horizontal composition
,
END
    
# A.8 Inseparable characters
cl_08 => <<'END',
Character	UCS	Name	Remark
—	2014	EM DASH	Some systems implement U+2015 HORIZONTAL BAR very similar behavior to U+2014 EM DASH
…	2026	HORIZONTAL ELLIPSIS	
‥	2025	TWO DOT LEADER	
〳	3033	VERTICAL KANA REPEAT MARK UPPER HALF	used vertical composition, U+3035 follows this
〴	3034	VERTICAL KANA REPEAT WITH VOICED SOUND MARK UPPER HALF	used vertical composition, U+3035 follows this
〵	3035	VERTICAL KANA REPEAT MARK LOWER HALF	used vertical composition
END

# A.9 Iteration marks
cl_09 => <<'END',
Character	UCS	Name	Remark
ヽ	30FD	KATAKANA ITERATION MARK	
ヾ	30FE	KATAKANA VOICED ITERATION MARK	
ゝ	309D	HIRAGANA ITERATION MARK	
ゞ	309E	HIRAGANA VOICED ITERATION MARK	
々	3005	IDEOGRAPHIC ITERATION MARK	
〻	303B	VERTICAL IDEOGRAPHIC ITERATION MARK	
END

# A.10 Prolonged sound mark
cl_10 => <<'END',
Character	UCS	Name	Remark
ー	30FC	KATAKANA-HIRAGANA PROLONGED SOUND MARK	
END

# A.11 Small kana
cl_11 => <<'END',
Character	UCS	Name	Remark
ぁ	3041	HIRAGANA LETTER SMALL A	
ぃ	3043	HIRAGANA LETTER SMALL I	
ぅ	3045	HIRAGANA LETTER SMALL U	
ぇ	3047	HIRAGANA LETTER SMALL E	
ぉ	3049	HIRAGANA LETTER SMALL O	
ァ	30A1	KATAKANA LETTER SMALL A	
ィ	30A3	KATAKANA LETTER SMALL I	
ゥ	30A5	KATAKANA LETTER SMALL U	
ェ	30A7	KATAKANA LETTER SMALL E	
ォ	30A9	KATAKANA LETTER SMALL O	
っ	3063	HIRAGANA LETTER SMALL TU	
ゃ	3083	HIRAGANA LETTER SMALL YA	
ゅ	3085	HIRAGANA LETTER SMALL YU	
ょ	3087	HIRAGANA LETTER SMALL YO	
ゎ	308E	HIRAGANA LETTER SMALL WA	
ゕ	3095	HIRAGANA LETTER SMALL KA	
ゖ	3096	HIRAGANA LETTER SMALL KE	
ッ	30C3	KATAKANA LETTER SMALL TU	
ャ	30E3	KATAKANA LETTER SMALL YA	
ュ	30E5	KATAKANA LETTER SMALL YU	
ョ	30E7	KATAKANA LETTER SMALL YO	
ヮ	30EE	KATAKANA LETTER SMALL WA	
ヵ	30F5	KATAKANA LETTER SMALL KA	
ヶ	30F6	KATAKANA LETTER SMALL KE	
ㇰ	31F0	KATAKANA LETTER SMALL KU	
ㇱ	31F1	KATAKANA LETTER SMALL SI	
ㇲ	31F2	KATAKANA LETTER SMALL SU	
ㇳ	31F3	KATAKANA LETTER SMALL TO	
ㇴ	31F4	KATAKANA LETTER SMALL NU	
ㇵ	31F5	KATAKANA LETTER SMALL HA	
ㇶ	31F6	KATAKANA LETTER SMALL HI	
ㇷ	31F7	KATAKANA LETTER SMALL HU	
ㇸ	31F8	KATAKANA LETTER SMALL HE	
ㇹ	31F9	KATAKANA LETTER SMALL HO	
ㇺ	31FA	KATAKANA LETTER SMALL MU	
ㇻ	31FB	KATAKANA LETTER SMALL RA	
ㇼ	31FC	KATAKANA LETTER SMALL RI	
ㇽ	31FD	KATAKANA LETTER SMALL RU	
ㇾ	31FE	KATAKANA LETTER SMALL RE	
ㇿ	31FF	KATAKANA LETTER SMALL RO	
ㇷ゚	<31F7, 309A>	<KATAKANA LETTER SMALL HU, COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK>	
END
    
# A.12 Prefixed abbreviations
cl_12 => <<'END',
Character	UCS	Name	Remark
￥	00A5	YEN SIGN	
¥
＄	0024	DOLLAR SIGN	
$
￡	00A3	POUND SIGN	
£
＃	0023	NUMBER SIGN	
#
€	20AC	EURO SIGN	
№	2116	NUMERO SIGN	
END
    
# A.13 Postfixed abbreviations
cl_13 => <<'END',
Character	UCS	Name	Remark
°	00B0	DEGREE SIGN	proportional
′	2032	PRIME	proportional
″	2033	DOUBLE PRIME	proportional
℃	2103	DEGREE CELSIUS	
￠	00A2	CENT SIGN	
％	0025	PERCENT SIGN	
%
‰	2030	PER MILLE SIGN	
㏋	33CB	SQUARE HP	
ℓ	2113	SCRIPT SMALL L	
END

# A.14 Full-width ideographic space
cl_14 => <<'END',
Character	UCS	Name	Remark
　	3000	IDEOGRAPHIC SPACE	
END

);

sub class_chars {
    join '', map { /^(?![A-Z])(\X)/mg } @character_class{@_};
}

our %prohibition = (
    head        => class_chars( qw(cl_02 cl_03 cl_04 cl_05 cl_06 cl_07 cl_09 cl_10 cl_11) ),
    end         => class_chars( qw(cl_01) ),
    prefix      => class_chars( qw(cl_12) ),
    postfix     => class_chars( qw(cl_13) ),
    inseparable => class_chars( qw(cl_08) ),
    );

1;
