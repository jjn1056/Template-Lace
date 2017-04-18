package  MyApp::View::User;

use Moo;
extends 'Catalyst::View::Template::Lace';
with 'Template::Lace::ModelRole',
  'Catalyst::View::Template::Lace::Role::ArgsFromStash',
  'Template::Lace::Model::AutoTemplate';

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
  $dom->dl('#user', +{
   age=>$self->age,
   name=>$self->name,
   motto=>$self->motto});
}

{
  package Tag::Anchor;
  use Template::Lace::DOM;

  sub create {
    my ($self, %attrs) = @_;
    # %attrs has ctx, model, content as automatic
    # as well as anything you setup as atttributes (like
    # in this case "href".  It wil be processed to resolve
    # as well.
    return bless \%attrs, ref($self);
  }

  sub get_processed_dom {
    my ($self) = @_;
    return Template::Lace::DOM
      ->new("<a href='${\$self->{href}}'>${\$self->{content}}</a>");
  }
}

__PACKAGE__->config(
  component_handlers => {
    tag => {
      anchor => bless {}, 'Tag::Anchor',
    }
  }
);
