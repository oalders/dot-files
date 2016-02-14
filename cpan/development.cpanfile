# cpanm --installdeps --cpanfile cpan/development.cpanfile .
requires 'App::GitGot';
requires 'Archive::Tar::Wrapper'; # for more speed via dzil
requires 'autodie';
requires 'Carton';
requires 'Code::TidyAll';
requires 'Code::TidyAll::Plugin::SortLines::Naturally';
requires 'Code::TidyAll::Plugin::UniqueLines';
requires 'Code::TidyAll::Plugin::YAML';
requires 'Data::Printer::Filter::DBIx::Class';
requires 'Data::Printer::Filter::JSON';
requires 'Data::Printer::Filter::URI';
requires 'Modern::Perl';
requires 'Moo', '>= 2.000002';
requires 'Perl::Critic';
requires 'Perl::Tidy';
requires 'Test::Perl::Critic';
