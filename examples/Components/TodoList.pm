package Components::TodoList;

use Moo;
use Template::Lace::Factory;
use Components::Todo;

has 'tasks' => (is=>'ro', required=>1);
has 'todo_factory' => (is=>'ro', required=>1);

sub create_factory {
  my ($class, $tasks) = @_;
  return Template::Lace::Factory->new(
    model_class => $class,
    init_args => +{
      tasks=>$tasks,
      todo_factory=>Components::Todo->create_factory,
    });
}

sub process_dom {
  my ($self, $dom) = @_;
  $dom->at('task')
   ->repeat(sub {
    my ($dom, $data) = @_;
    $dom->content($self->todo_factory->create(task=>$data)->render);
  }, @{$self->tasks});

}

sub template {q[
  <ol id="tasks">
    <task/>
  </ol>
]}

1;
