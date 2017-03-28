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
  $self->_profile(begin => "=> ".Catalyst::Utils::class2classsuffix($self->catalyst_component_name)."->respond($status)");
  for ($self->ctx->res) {
    $_->status($status) if $_->status != 200; # Catalyst sets 200
    $_->content_type('text/html') if !$_->content_type;
    $_->headers->push_header(@{$headers}) if $headers;
    $_->body($self->render);
  }
  $self->_profile(end => "=> ".Catalyst::Utils::class2classsuffix($self->catalyst_component_name)."->respond($status)");
  return $self;
}

sub _profile {
  my $self = shift;
  $self->ctx->stats->profile(@_)
    if $self->ctx->debug;
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

__PACKAGE__->config(
  component_handlers => +{
    tag => +{
      anchor => sub {
        my ($self, $dom, $info, %attrs) = @_;
        my $attr = join ' ', map { "$_='$attrs{$_}'"  } grep { $_ ne 'uuid' } keys %attrs;
        $dom->wrap("<a $attr></a>");
      },
    },
  },
);

=head1 NAME

Catalyst::View::Template::Lace - Adapt Template::Lace for Catalyst

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

    TBD

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Template::Lace>, L<Catalyst::View::Template::Pure>

=head1 COPYRIGHT & LICENSE
 
Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
