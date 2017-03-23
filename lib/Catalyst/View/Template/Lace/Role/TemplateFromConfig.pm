package Catalyst::View::Template::Lace::Role::TemplateFromConfig;

use Moo::Role;

sub template {
  return shift->{init_args}{template} ||
    die "There is no template definition in configuration";
}


1;
