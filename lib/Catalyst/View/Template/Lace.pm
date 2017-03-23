package Catalyst::View::Template::Lace;

our $VERSION = '0.001';

use Moo;
use Scalar::Util ();
use Template::Lace::DOM;
use overload
  bool => sub {1},
  '""' => sub { shift->get_processed_dom->to_string },
  fallback => 1;

extends 'Catalyst::View';

sub COMPONENT {
  my ($class, $app, $args) = @_;
  return $class->create_factory(
    $class->create_dom($class->template),
    $class->merge_config_hashes($class->config, $args)
  );
}

sub create_dom { Template::Lace::DOM->new(pop) }

sub create_factory {
  my ($class, $dom, $merged_args) = @_;
  return bless +{
    dom => $dom,
    init_args => $merged_args,
  }, $class;
}

sub template { die 'Subclass needs to complete this!' }

has dom => (is=>'ro', required=>1);
has ctx => (is=>'ro', required=>1);

sub ACCEPT_CONTEXT {
  my ($factory, $c, @args) = @_;
  return ref($factory)->new(
    %{$factory->{init_args}}, # Merge in from ->config
    @args,
    dom => $factory->{dom}->clone,
    ctx => $c,
  );
}

sub process_dom { pop }

sub get_processed_dom {
  my $self = shift;
  $self->process_dom($self->dom);
  return $self->dom;
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
  return shift
    ->get_processed_dom
    ->to_string;
}

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
      my $dom = shift;
      return $self
        ->view($view_name, @args, content=>$dom)
        ->get_processed_dom;
    });
  }
}

# proxy methods 

sub detach { shift->ctx->detach(@_) }

sub view { shift->ctx->view(@_) }

1;
