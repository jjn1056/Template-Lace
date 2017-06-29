package Components::Master;

use Moo;
use Template::Lace::Factory;

has 'content' => (is=>'ro', required=>1);

sub create_factory {
  my ($class) = @_;
  return Template::Lace::Factory->new(
    model_class => $class);
}

sub process_dom {
  my ($self, $dom) = @_;
  $dom->at('wrapped-content')
    ->replace($self->content);
}

sub template {q[
  <html>
    <head>
      <title>Todo List</title>
    </head>
    <body>
      <wrapped-content />
    </body>
  </html>
]}

1;
