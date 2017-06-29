package Page;

use Moo;
use Template::Lace::Factory;

has 'list_todo_factory' => (is=>'ro', required=>1);
has 'master_factory' => (is=>'ro', required=>1);

sub create_factory {
  my ($class, $list_todo_factory, $master_factory) = @_;
  return Template::Lace::Factory->new(
    model_class => $class,
    init_args => +{
      list_todo_factory=>$list_todo_factory,
      master_factory=>$master_factory,
    }
  );
}

sub process_dom {
  my ($self, $dom) = @_;
  $dom->at('master')
    ->replace($self->master_factory->create(content=>$dom->at('master')->content)->render)
    ->at('todo-list')
    ->replace($self->list_todo_factory->render)
    ->at('master');
}

sub template {q[
  <master>
    <h1>Todos</h1>
    <form method="POST">
      <input name="item">
    </form>
    <todo-list />
  </master>
]}

1;
