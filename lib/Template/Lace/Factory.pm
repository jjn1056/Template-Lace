package Template::Lace::Factory;

use Moo;
use Module::Runtime 'use_module';

sub DOM_CLASS { use_module 'Template::Lace::DOM' }
sub RENDERER_CLASS { use_module 'Template::Lace::Renderer' }
sub COMPONENTS_CLASS { use_module 'Template::Lace::Components' }

has 'model_class' => (
  is=>'ro',
  required=>1);

has 'renderer_class' => (
  is=>'ro',
  required=>1,
  default=>sub { RENDERER_CLASS } );

has 'dom' => (
  is=>'ro',
  required=>1);

has 'init_args' => (
  is=>'ro',
  required=>1,
  default=>sub { +{} });

has 'components' => (
  is=>'ro',
  required=>1);

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);
  my $model_class = $class->_get_model_class($args);
  my $dom_class = $class->_get_dom_class($args);
  my $components_class = $class->_get_components_class($args);
  my $dom = $args->{dom} = $class->_build_dom($dom_class, $model_class);
  my $component_handlers = $args->{component_handlers};
  $args->{components} = $class->_build_components($components_class, $dom, $component_handlers);
  return $args;
};

  sub _get_model_class {
    my ($class, $args) = @_;
    my $model_class = use_module($args->{model_class});
    return $model_class;
  }

  sub _get_dom_class {
    my ($class, $args) = @_;
    my $dom_class = exists $args->{dom_class} ?
      use_module($args->{dom_class}) :
        DOM_CLASS;
    return $dom_class;
  }

  sub _get_components_class {
    my ($class, $args) = @_;
    my $components_class = exists $args->{components_class} ?
      use_module($args->{components_class}) :
        COMPONENTS_CLASS;
    return $components_class;
  }

  sub _build_dom {
    my ($class, $dom_class, $model_class) = @_;
    my $template = $model_class->template;
    my $dom = $dom_class->new($template);
    $model_class->prepare_dom($dom);
    return $dom;
  }

  sub _build_components {
    my ($class, $components_class, $dom, $component_handlers) = @_;
    my $components = $components_class->new(
      dom => $dom,
      component_handlers => $component_handlers);
    return $components;
  }

sub create {
  my ($self, %args) = @_;
  my $model = $self->create_model(%args);
  my $dom = $self->create_dom(%args);
  my $renderer = $self->create_renderer($model,$dom, $self->components);
  return $renderer;
}

sub create_dom {
  my ($self, %args) = @_;
  my $dom = $self->dom->clone;
  return $dom;
}

sub create_model {
  my ($self, %args) = @_;
  my $model = $self->model_class->new(%args); # Should %args be processed by process_attrs?
  return $model;
}

sub create_renderer {
  my ($self, $model, $dom, $components) = @_;
  my $renderer = $self->renderer_class->new(
    components=>$components,
    model=>$model,
    dom=>$dom);
  return $renderer;
}




1;
