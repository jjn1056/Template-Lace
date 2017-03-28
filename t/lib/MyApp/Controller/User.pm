package MyApp::Controller::User;

use Moose;
use MooseX::MethodAttributes;
extends 'Catalyst::Controller';

sub display :Path('') {
  my ($self, $c) = @_;
  $c->stash(
    name => 'John',
    age => 42,
    motto => 'Why Not?');
  $c->view('User')
    ->respond(200);
}

__PACKAGE__->meta->make_immutable;
