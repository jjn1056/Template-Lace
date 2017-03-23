package  MyApp::View::List;

use Moo;
extends 'Catalyst::View::Template::Lace';
with 'Catalyst::View::Template::Lace::Role::Pretty',
  'Catalyst::View::Template::Lace::Role::ArgsFromStash',
  'Catalyst::View::Template::Lace::Role::ResponseHelpers',
  'Catalyst::View::Template::Lace::Role::PerContext',
  'Catalyst::View::Template::Lace::Role::URI',
  'Catalyst::View::Template::Lace::Role::AutoTemplate',
  'Catalyst::View::Template::Lace::Role::ViewComponents';

has [qw/form items copywrite/] => (is=>'ro', required=>1);

sub process_dom {
  my ($self, $dom) = @_;
  $dom->ol('#todos', $self->items);
}

__PACKAGE__->config(
  returns_status => [200,400],
  prettify => 1,
);
