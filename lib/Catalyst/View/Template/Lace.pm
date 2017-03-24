package Catalyst::View::Template::Lace;

our $VERSION = '0.001';

use Moo;
use overload
  bool => sub {1},
  '""' => sub { shift->get_processed_dom->to_string },
  fallback => 1;

extends 'Catalyst::View';

sub COMPONENT {
  my ($class, $app, $args) = @_;
  my $merged_args = $class->merge_config_hashes($class->config, $args);
  return $class->create_factory($merged_args);
}

sub create_factory {
  my ($class, $merged_args) = @_;
  my $dom = $class->create_dom($merged_args);
  return bless +{
    class => $class,
    dom => $dom,
    init_args => $merged_args,
  }, $class;
}

sub create_dom {
  my ($class, $merged_args) = @_;
  my $template = $class->template($merged_args);
  my $dom_class = _ensure_loaded($class->dom_class($merged_args));
  return $dom_class->new($template);
}

sub template { }

sub _ensure_loaded {
  eval "use $_[0]; 1" ||
    die "Can't load '$_[0]', $@";
  return $_[0];
}

sub dom_class { 'Template::Lace::DOM' }

has dom => (is=>'ro', required=>1);
has ctx => (is=>'ro', required=>1);

sub ACCEPT_CONTEXT {
  my ($factory, $c, @args) = @_;
  return $factory->create(@args, ctx=>$c);
}

sub create {
  my ($factory, @extra_args) = @_;
  return $factory->{class}->new(
    %{$factory->{init_args}},
    @extra_args,
    dom => $factory->{dom}->clone,
  );
}

sub respond {
  my ($self, $status, $headers) = @_;
  for ($self->ctx->res) {
    $_->status($status) if $_->status != 200; # Catalyst sets 200
    $_->content_type('text/html') if !$_->content_type;
    $_->headers->push_header(@{$headers}) if $headers;
    $_->body($self->render);
  }
  return $self;
}

sub render {
  return shift->get_processed_dom
    ->to_string;
}

sub get_processed_dom {
  my $self = shift;
  $self->process_dom($self->dom);
  return $self->dom;
} 

sub process_dom { pop }

# Support old school Catalyst::Action::RenderView for example (
# you probably also want the ::ArgsFromStash role).

sub process {
  my ($self, $c, @args) = @_;
  $self->response(200, @args);
}

# helper methods

sub overlay_view {
  my ($self, $view_name, $dom_proto, @args) = @_;
  if($dom_proto->can('each')) {
    $dom_proto->each(sub {
      return $self->overlay_view($view_name, $_, @args);
    });
  } else {
    $dom_proto->overlay(sub {
      return $self->view($view_name, @args, content=>$_)
        ->get_processed_dom;
    });
  }
}

# proxy methods 

sub detach { shift->ctx->detach(@_) }

sub view { shift->ctx->view(@_) }

1;
