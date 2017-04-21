use Test::Most;
use Mojo::DOM58;

use_ok 'Template::Lace::Factory';

{
  package  Local::Template::Master;

  use Moo;
  with 'Template::Lace::ModelRole';

  has title => (is=>'ro', required=>1);
  has body => (is=>'ro', required=>1);

  sub prepare_dom {
    my ($self, $dom) = @_;
    $dom->body(sub { $_->append_content('fffffff') });
  }

  sub on_component_add {
    my ($self, $dom) = @_;
    $dom->title($self->title)
      ->body(sub {
        $_->at('h1')->append($self->body);
      });
  }

  sub template {
    my $class = shift;
    return q[
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8" />
          <meta content="width=device-width, initial-scale=1" name="viewport" />
          <title>Master Title</title>
          <link href="/static/base.css" rel="stylesheet" />
          <link href="/static/index.css" rel="stylesheet"/ >
        </head>
        <body id="body">
          <h1>Intro</h1>
        </body>
      </html>        
    ];
  }



  package Local::Template::User;

  use Moo;
  with 'Template::Lace::ModelRole';

  has [qw(title story cites form)] => (is=>'ro', required=>1);

  sub prepare_dom {
    my ($class, $dom) = @_;
    $dom->body(sub {
      $_->append_content('<meta version=1 />');
    });
  }

  sub process_dom {
    my ($class, $dom) = @_;
    $dom->at('body')
      ->append_content('<footer>copyright 2017</footer>');
  }

  sub template {q[
    <layout-master
        title=\'title:content'
        body=\'body:content'>
      <html>
        <head>
          <title>Page Title</title>
        </head>
        <body>
          <section id='story'>
            Story
          </section>
          <ul id="cites">
            <li>Citations</li>
          </ul>
          <lace-form action='/postit'
              method='POST'>
            <lace-input type='text'
                name='user'
                label='User:'
                value='$.form.fields.user.value' />
            <lace-input type='password'
                name='passwd'
                label='Password'
                value='$.form.fields.passwd.value' />
          </lace-form>
          <lace-timestamp tz='America/Chicago'/>
        </body>
      </html>
    </layout-master>
  ]}

  sub process_dom {
    my ($self, $dom) = @_;
    $dom->title($self->title)
      ->at_id('#story', $self->story)
      ->ul('#cites', $self->cites);
  }

  package Local::Template::Timestamp;

  use Moo;
  use DateTime;
  with 'Template::Lace::ModelRole';

  has 'tz' => (is=>'ro', predicate=>'has_tz');

  sub time {
    my ($self) = @_;
    my $now = DateTime->now;
    $now->set_time_zone($self->tz)
      if $self->has_tz;
    return $now;
  }

  sub template {
    q[<span class='timestamp'>time</span>];
  }

  sub process_dom {
    my ($self, $dom) = @_;
    $dom->at('.timestamp')
      ->content($self->time);
  }

  package Local::Template::Form;

  use Moo;
  with 'Template::Lace::ModelRole';

  has [qw(method action content)] => (is=>'ro', required=>1);

  sub template {q[
    <style id='formstyle'>sdfsdfsd</style>
    <form></form>
  ]}

  sub process_dom {
    my ($self, $dom) = @_;
    $dom->at('form')
      ->action($self->action)
      ->method($self->method)
      ->content($self->content);
  }

  package Local::Template::Input;

  use Moo;
  with 'Template::Lace::ModelRole';

  has [qw(name label type value container)] => (is=>'ro', required=>1);

  sub template {q[
    <style id="inputstyle">fff</style>
    <div>
      <label></label>
      <input></input>
    </div>
  ]}

  sub process_dom {
    my ($self, $dom) = @_;
    $dom->at('label')
      ->content($self->label)
      ->attr(for=>$self->name);
    $dom->at('input')->attr(
      type=>$self->type,
      value=>$self->value,
      name=>$self->name);
  }
}

ok my $factory = Template::Lace::Factory->new(
  model_class=>'Local::Template::User',
  component_handlers=>+{
    layout => sub {
      my ($name, $args, %args) = @_;
      $name = ucfirst $name;
      return Template::Lace::Factory->new(model_class=>"Local::Template::$name");
    },
    lace => {
      timestamp => Template::Lace::Factory->new(model_class=>'Local::Template::Timestamp'),
      form => Template::Lace::Factory->new(model_class=>'Local::Template::Form'),
      input => Template::Lace::Factory->new(model_class=>'Local::Template::Input'),
    },
  },
);

ok my $template = $factory->create(
  title => 'the real story',
  story => 'you are doomed to discover you can never recover...',
  cites => [
    'another book',
    'yet another',
    'padding'],
  form => +{
    fields => +{
      user => +{ value => 'jjn'},
      passwd => +{ value => 'whatwhyhow?'},
    },
  });

warn $template->render;

done_testing;
