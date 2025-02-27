requires 'perl', '5.014';

requires 'Text::VisualWidth::PP', '0.08';
requires 'List::Util', '1.45';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

