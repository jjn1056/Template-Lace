package Template::Lace::Model;

use Moo::Role;

sub template {
  my ($class, %init_args) = @_;
}

sub prepare_dom {
  my ($class, $dom) = @_;
}


sub process_dom {
  my ($self, $dom) = @_;
}

1;
