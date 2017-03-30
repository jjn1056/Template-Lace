package  MyApp::View::Form;

use Moo;
extends 'Catalyst::View::Template::Lace';

has [qw/id fif errors content/] => (is=>'ro', required=>0);
has children => (is=>'rw');

sub add_children {
  shift->children(\@_);
}

sub finalize_dom {
  my ($class, $dom, $merged_args) = @_;
  $dom->at('form')->attr('data-lace-id','form1');
}

sub finalize_view_component {
  my ($class, $factory, $attr) = @_;
  $factory->{dom}->at('head')->prepend_content('<meta />');
}

sub process_dom {
  my ($self, $dom) = @_;
  $dom->at('form')
    ->attr(id=>$self->id)
    ->content($self->content);      
}

sub template {
  my $class = shift;
  return q[<form></form>];
}

1;
