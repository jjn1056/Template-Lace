package  MyApp::View::List;

use Moo;
extends 'Catalyst::View::Template::Lace';
with 'Template::Lace::Role::Pretty',
  'Template::Lace::Role::AutoTemplate',
  'Catalyst::View::Template::Lace::Role::ResponseHelpers',
  'Catalyst::View::Template::Lace::Role::ViewComponents';

has [qw/form items copywrite/] => (is=>'ro', required=>1);

sub process_dom {
  my ($self, $dom) = @_;
  $dom->ol('#todos', $self->items);
}

__PACKAGE__->config(
  returns_status => [200,400],
  prettify => 1,
  component_handlers => +{
    lace => +{
      timestamp => sub {
        my ($self, $dom, $info, %attrs) = @_;
        $dom->append("<div>${\do { scalar localtime }}</div>");
      },
    },
  },
);
