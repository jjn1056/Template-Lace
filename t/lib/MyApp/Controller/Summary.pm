package MyApp::Controller::Summary;

use base 'Catalyst::Controller';

sub display :Path('') Args(1) {
  my ($self, $c, $extra) = @_;
  $c->stash(title => 'A Dark and Stormy Night...');
  my $v = $c->view('Summary',
    names => [qw/aaa bbb ccc/, $extra]);
  $c->view('Summary')->http_ok;
}

1;
