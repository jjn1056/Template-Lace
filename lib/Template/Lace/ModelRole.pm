package Template::Lace::ModelRole;

use Moo::Role;

sub template {
  my ($class) = @_;
  return;
}

sub prepare_dom {
  my ($class, $dom) = @_;
}


sub process_dom {
  my ($self, $dom) = @_;
}

1;
