package Catalyst::View::Template::Lace::Role::PerContext;

use Moo::Role;
use Scalar::Util ();

around 'ACCEPT_CONTEXT', sub {
  my ($orig, $self, $c, @args) = @_;
  my $key = Scalar::Util::refaddr($self) || $self;
  return $c->stash->{"__Pure_${key}"} ||= do {
    $self->$orig($c, @args);
  };
};

1;
