use Test::Most;
use Template::Lace::DOM;

use_ok 'Template::Lace::Factory';

{
  package Local::Template::Section;

  use Moo;

  has 'content' => (is=>'ro', required=>1);

  sub process_dom {
    my ($self, $dom) = @_;

    #my $string = $self->content->join("\n");
    #warn "\n111\n$string\n222";

    $dom->at('section')
      ->content($self->content);
  }

  sub template {q{
    <section class='1'>
    stuff
    </section>
  }}

  package Local::Template::Item;
   
  use Moo;

  has name => (is=>'ro', required=>1);
  has number => (is=>'ro', required=>1);

  sub process_dom {
    my ($self, $dom) = @_;
    $dom->for('p', $self);
  }
        
  sub template {
    my $class = shift;
    return q[
      <p>Hi there 
        <span class='name'>NAME</span>!
        You are number
        <span class='number'>Number</span></p>
    ];
  }

  1; 

  package Local::Template::Loop;

  use Moo;

  sub template {q{
    <html>
      <head>
        <title>Things To Do</title>
        <link href="/static/summary.css" rel="stylesheet"/>
        <link href="/static/core.css" rel="stylesheet"/>
      </head>
      <body>
        <ui-section>
          <h1>Loops</h1>
          <ul>
            <li><ui-item name=$.name number=$.number /></li>
          </ul>
        </ui-section>
      </body>
    </html>
  }}

  sub name { 'a' }
  sub number { 1 }

  sub process_dom {
    my ($self, $dom) = @_;
    my @data = (
      +{ name=>'John', number=>34 },
      +{ name=>'Vanessa', number=>24 },
    );

    use Devel::Dwarn;
    $dom->at('ul li')
      ->repeat(sub {
        my ($dom, $data) = @_;
        #$dom->components->each(sub { Dwarn $_->component_info });

        #warn $dom;
        #$self->context($dom, $data);
        return $dom;
      }, @data);

    #$dom->for('ul li', \@data);  # should also work

  }

  my $factory = Template::Lace::Factory->new(
    model_class=>'Local::Template::Loop',
    component_handlers => {
      ui => {
        item => Template::Lace::Factory->new(model_class=>'Local::Template::Item'),
        section => Template::Lace::Factory->new(model_class=>'Local::Template::Section'),

      },
    },
  );

  Test::Most::ok my $renderer = $factory->create;
  Test::Most::ok my $html = $renderer->render;

  warn $html;
}

done_testing;
