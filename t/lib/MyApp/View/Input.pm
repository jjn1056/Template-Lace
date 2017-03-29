package  MyApp::View::Input;

use Moo;
extends 'Catalyst::View::Template::Lace';

has [qw/id label name type container view/] => (is=>'ro');

has value => (
  is=>'ro',
  lazy=>1,
  default=>sub { $_[0]->container->fif ? $_[0]->container->fif->{$_[0]->name} : 0 },
);

has errors => (
  is=>'ro',
  lazy=>1,
  default=>sub { $_[0]->container->errors ? $_[0]->container->errors->{$_[0]->name} : 0 },
);

sub process_dom {
  my ($self, $dom) = @_;
  
  $self->view->dom->append_link_uniquely({
    href=>'/css/input.min.css',
    rel=>'stylesheet'});

  $self->view->dom->append_script_uniquely({src=>'/js/input.min.js'});

  # Set Label content
  $dom->at('label')
    ->content($self->label)
    ->attr(for=>$self->name);

  # Set Input attributes
  $dom->at('input')->attr(
    type=>$self->type,
    value=>$self->value,
    id=>$self->id,
    name=>$self->name);

  # Set Errors or remove error block
  if($self->errors) {
    $dom->ol('.errors', $self->errors);
  } else {
    $dom->at("div.error")->remove;
  }
}

sub template {
  my $class = shift;
  return q[
    <link href="css/main.css" />
    <style id="min">
      div { border: 1px }
    </style>
    <div class="field">
      <label>LABEL</label>
      <input />
    </div>
    <div class="ui error message">
      <ol class='errors'>
        <li>ERROR</li>
      </ol>
    </div>
  ];
}

1;
