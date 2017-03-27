package  MyApp::View::Summary;

use Moo;
extends 'Catalyst::View::Template::Lace';
with 'Template::Lace::Role::Pretty',
  'Template::Lace::Role::TemplateFragments',
  'Template::Lace::Role::AutoTemplate',
  'Catalyst::View::Template::Lace::Role::ArgsFromStash',
  'Catalyst::View::Template::Lace::Role::ResponseHelpers',
  'Catalyst::View::Template::Lace::Role::PerContext',
  'Catalyst::View::Template::Lace::Role::URI';

has [qw/title names copydate/] => (is=>'ro', required=>1);

sub process_dom {
  my ($self, $dom) = @_;

  # overlay master layout
  $self->overlay_view(
    'Master', $dom,
    title => $dom->at('title')->content,
    css => $dom->find('link'),
    body => $dom->at('body')->content);

  # fill a bunch of placeholders
  $dom->title($self->title)
    ->form('#login', sub {
        $_->target($self->uri('display', 22));
        $_->at('#email_input')
          ->overlay(sub {
              $self->get_fragment('email_input_errors')
                ->at('.errors')
                ->prepend_content($_)
                ->ol('.message', ['bad password', 'expired password']);
            });
      })
    ->ul('#names', sub {
        $_->at('li')
          ->fill($self->names);
          $self->overlay_view( # wrap content
            'TwoColumnLayout', $_, 
            title=>'More Stuff');
      })
    ->at('body')
    ->append_content($self->view('Footer', $self));
}

__PACKAGE__->config(
  returns_status => [200],
  prettify => 1,
);
