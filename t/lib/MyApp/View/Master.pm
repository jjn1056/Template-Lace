package  MyApp::View::Master;

use Moo;
extends 'Catalyst::View::Template::Lace';

has title => (is=>'ro', required=>1);
has css => (is=>'ro', required=>1);
has meta => (is=>'ro', required=>1);
has body => (is=>'ro', required=>1);

## Example cookbook hack for 'preprocessing the DOM for some
## possible runtime performance improvements.  This only works
## if all the attributes /args are static at setup time.

sub finalize_view_component {
  my ($class, $containing_view, $component_info) = @_;
  my $containing_dom = $containing_view->{dom};
  my $component_dom = $class->{dom};
  my $self = $class->create(
    $class->process_attrs($containing_dom, %{$component_info->{attrs}}),
    ctx=>'null');

  $self->process_dom($component_dom);
  $containing_dom->replace($component_dom);

  $containing_view->delete_component_by_key($component_info->{key});
}

sub process_dom {
  my ($self, $dom) = @_;
  $dom->title($self->title)
    ->head(sub { $_->append_content($self->css->join) })
    ->head(sub { $_->prepend_content($self->meta->join) })
    ->body(sub { $_->at('h1')->append($self->body) });
}

sub template {
  my $class = shift;
  return q[
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta content="width=device-width, initial-scale=1" name="viewport" />
        <title>Page Title</title>
        <link href="/static/base.css" rel="stylesheet" />
        <link href="/static/index.css" rel="stylesheet"/ >
      </head>
      <body id="body">
        <h1>Intro</h1>
      </body>
    </html>        
  ];
}

1;
