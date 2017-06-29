package Components::Todo;

use Moo;
use Template::Lace::Factory;

has 'task' => (is=>'ro', required=>1);

sub create_factory {
  my ($class) = @_;
  return Template::Lace::Factory->new(
    model_class => $class);
}

sub process_dom {
  my ($self, $dom) = @_;
  $dom->at('li')->content($self->task);
}

sub template {q[
    <li>Task...</li>
]}

1;
