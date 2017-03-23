package MyApp::Controller::List;

use base 'Catalyst::Controller';

sub display :Path('') Args(0) {
  my ($self, $c) = @_;
  $c->view('List',
    copywrite => '2015',
    form => {
      fif => {
        item => 'milk',
      },
      errors => {
        item => ['too short', 'too similar it existing item'],
      }
    },
    items => [
      'Buy Milk',
      'Walk Dog',
    ],
  )->http_bad_request;
}

1;
