package Template::Lace::Renderer;

use Moo;
use Scalar::Util;

has [qw(model dom components)] => (is=>'ro', required=>1);

sub render {
  my $self = shift;
  $self->process_components($self->dom);
  return $self->get_processed_dom
    ->to_string;
}

sub get_processed_dom {
  my $self = shift;
  my $dom = $self->dom;
  $self->model->process_dom($dom);
  return $dom;
} 

sub process_components {
  my ($self, $dom) = @_;
  my @ordered_keys = @{$self->components->ordered_component_keys};
  foreach my $id(@ordered_keys) {
    next unless $self->components->handlers->{$id}; # might skip if 'static' handler
    $self->process_component(
      $dom->at("[uuid='$id']"), 
      $self->components->handlers->{$id},
      %{$self->components->component_info->{$id}});
  }
}

sub process_component {
  my ($self, $dom, $component, %component_info) = @_;
  my %attrs = ( 
    $self->process_attrs($dom, %{$component_info{attrs}}),
    content=>$dom->content,
    model=>$self->model);
  if(Scalar::Util::blessed $component) {
    my $processed_component = $component
      ->create(%attrs)
      ->get_processed_dom;
    $dom->replace($processed_component);
  } else {
    $component->($dom, %attrs);
  }
}

sub process_attrs {
  my ($self, $dom, %attrs) = @_;
  return map {
    my $proto = $attrs{$_};
    my $value = ref($proto) ? $proto->($self->model, $dom) : $proto;
    $_ => $value;
  } keys %attrs;
}

1;
