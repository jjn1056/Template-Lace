package Catalyst::View::Template::Lace::Role::ArgsFromStash;

use Moo::Role;

around 'ACCEPT_CONTEXT', sub {
  my ($orig, $self, $c, @args) = @_;
  my @stash_args = %{$c->stash};
  return $self->$orig($c, @args, @stash_args);
};

1;
