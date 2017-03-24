package  MyApp::View::Input;

use Moo;
extends 'Catalyst::View::Template::Lace';

has [qw/id label name type value errors/] => (is=>'ro');

sub process_dom {
  my ($self, $dom) = @_;

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
      $dom->ol('#errors', $self->errors);
    } else {
      $dom->at("div.error")->remove;
    }
}

sub template {
  my $class = shift;
  return q[
    <div class="field">
      <label>LABEL</label>
      <input />
    </div>
    <div class="ui error message">
      <ol id='errors'>
        <li>ERROR</li>
      </ol>
    </div>
  ];
}

1;
