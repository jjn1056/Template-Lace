package Catalyst::View::Template::Lace::Role::URI;

use Moo::Role;
use Scalar::Util;

sub uri_for { shift->ctx->uri_for(@_) }

sub action_for { shift->ctx->controller->action_for(@_) }

sub uri {
  my ($self, $action_proto, @args) = @_;
  return $self->ctx->uri_for($action_proto, @args)
    if Scalar::Util::blessed($action_proto);

  my $controller = $self->ctx->controller;
  my $action;
  if($action_proto =~/\//) {
    my $path = $action_proto=~m/^\// ? $action_proto : $controller->action_for($action_proto)->private_path;
    die "$action_proto is not an action for controller ${\$controller->component_name}" unless $path;
    die "$path is not a private path" unless $action = $self->ctx->dispatcher->get_action_by_path($path);
  } else {
    die "$action_proto is not an action for controller ${\$controller->component_name}"
      unless $action = $controller->action_for($action_proto);
  }
  die "Could not create a URI from '$action_proto' with the given arguments" unless $action;
  return $self->ctx->uri_for($action, @args);
}

1;

=head1 NAME

Catalyst::View::Template::Lace::Role::URI - Shortcut to create a URI on the current controller

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

    TBD

=head1 SEE ALSO
 
L<Catalyst::View::Template::Lace>.

=head1 AUTHOR

Please See L<Catalyst::View::Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Catalyst::View::Template::Lace> for copyright and license information.

=cut
