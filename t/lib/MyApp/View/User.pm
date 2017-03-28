package  MyApp::View::User;

use Moo;
extends 'Catalyst::View::Template::Lace';
with 'Template::Lace::Role::Pretty',
  'Catalyst::View::Template::Lace::Role::ArgsFromStash';

has [qw/age name motto/] => (is=>'ro', required=>1);

sub template {q[
  <html>
    <head>
      <title>User Info</title>
    </head>
    <body>
      <dl id='user'>
        <dt><tag-anchor href="/profile/john">Name</tag-anchor></dt>
        <dd id='name'>NAME</dd>
        <dt>Age</dt>
        <dd id='age'>AGE</dd>
        <dt>Motto</dt>
        <dd id='motto'>MOTTO</dd>
      </dl>
    </body>
  </html>
]}

sub process_dom {
  my ($self, $dom) = @_;
  $self->fill_at('#user');

  # All these are the same result (might vary performance-wise)
  #$dom->dl('#user', $self); #maybe not the fastest option!

  #$dom->dl('#user', +{
  # age=>$self->age,
  # name=>$self->name,
  # motto=>$self->motto});

  #$dom->at('#user')
  # ->fill({
  #   age=>$self->age,
  #   name=>$self->name,
  #   motto=>$self->motto});

}

__PACKAGE__->config(
  prettify => 1);
