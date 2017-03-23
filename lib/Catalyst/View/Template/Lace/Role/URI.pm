package Catalyst::View::Template::Lace::Role::URI;

use Moo::Role;

sub uri_for { shift->ctx->uri_for(@_) }

sub action_for { shift->ctx->controller->action_for(@_) }

sub uri {
  my ($self, $action_proto, @args) = @_;
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
