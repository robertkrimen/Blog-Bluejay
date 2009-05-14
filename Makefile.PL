use inc::Module::Install;

name     'Blog-Jive';
all_from 'lib/Blog/Jive.pm';
author   'Robert Krimen <rkrimen@cpan.org>';
license  'perl';

build_requires 'Test::More';

WriteAll;
