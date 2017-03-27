package Catalyst::View::Template::Lace;

our $VERSION = '0.001';

use Moo;
use Module::Runtime;
use Scalar::Util;

extends 'Catalyst::View',
  'Template::Lace';

sub COMPONENT {
  my ($class, $app, $args) = @_;
  return $class->create_factory(
    $class->merge_config_hashes($class->config, $args));
}

has ctx => (is=>'ro', required=>1);

sub ACCEPT_CONTEXT {
  my ($factory, $c, @args) = @_;
  return $factory->create(@args, ctx=>$c);
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
