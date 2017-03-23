package  MyApp::View::TwoColumnLayout;

use Moo;
extends 'Catalyst::View::Template::Lace';

has title => (is=>'ro', required=>1);
has content => (is=>'ro', required=>1);

sub process_dom {
  my ($self, $dom) = @_;
  $dom->at('.col-one')->content($self->title);
  $dom->at('.col-two')->content($self->content);
}

sub template {
  my $class = shift;
  return q[
    <div id="two-col-layout">
      <div class="col-one"></div>
      <div class="col-two"></div>
    </div>          
  ];
}

1;
