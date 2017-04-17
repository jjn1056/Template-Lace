package Template::Lace::ModelRole;

use Moo::Role;

sub template {
  my ($class, %init_args) = @_;
  use Devel::Dwarn;
  Dwarn \%init_args;
}

sub prepare_dom {
  my ($class, $dom) = @_;
}


sub process_dom {
  my ($self, $dom) = @_;
}

1;
