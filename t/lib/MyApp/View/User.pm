package  MyApp::View::User;

use Moo;
extends 'Catalyst::View::Template::Lace';
with 'Template::Lace::Role::Pretty',
  'Catalyst::View::Template::Lace::Role::ArgsFromStash',

has [qw/age name motto/] => (is=>'ro', required=>1);

sub template {q[
  <html>
    <head>
      <title>User Info</title>
    </head>
    <body>
      <dl id='user'>
        <dt>Name</dt>
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
  $dom->dl('#user', $self);
}

__PACKAGE__->config(
  prettify => 1,
);
