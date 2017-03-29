package Template::Lace::Role::Pretty;

use Moo::Role;
use HTML::Tidy;

# Setup to support HTML5
our %DEFAULT_ARGS = (
  tidy_mark => 0,
  indent => 1,
  'input-xml' => 0,
  'new-blocklevel-tags' => 'article aside audio bdi canvas details dialog figcaption figure footer header hgroup main menu menuitem nav section source summary template track video fragment',
  'new-empty-tags' => 'command embed keygen source track wbr fragment',
  'new-inline-tags' => 'audio command datalist embed keygen mark menuitem meter output progress source time video wbr template fragment',
  );

has prettify => (is=>'rw', required=>1, default=>1);

has htidy_args => (
  is=>'ro',
  required=>1,
  isa => sub { ref($_[0]) eq 'HASH' },
  default=>sub { \%DEFAULT_ARGS });

has htidy => (
  is=>'bare',
  init_arg=>undef,
  required=>1,
  lazy=>1,
  handles=>['clean'],
  builder=>'_build_htidy');

  sub _build_htidy {
    return HTML::Tidy
      ->new($_[0]->htidy_args);
  }

around 'render', sub {
  my ($orig, $self, @args) = @_;
  my $content = $self->$orig(@args);
  return $self->prettify ? $self->clean($content) : $content;
};

1;

=head1 NAME

Template::Lace::Role::Pretty - Pretty print filter your HTML output

=head1 SYNOPSIS

Create a template class:

    package  MyApp::Template::List;

    use Moo;
    extends 'Template::Lace';
    with 'Template::Lace::Role::Pretty',

    has 'items' => (is=>'ro', required=>1);

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->ol('#todos'=>$self->items);
    }

    sub template {q[
      <html>
        <head>
          <title>Things To Do</title>
        </head>
        <body>
          <ol id='todos'>
            <li>What To Do?</li>
          </ol>
        </body>
      </html>
    ]}

    1;

Create and render an instance:

    my $factory = MyApp::Template::List
      ->create_factory;

    my $html = $factory->create(items=>['Walk dogs', 'Buy Milk'])
      ->render;

Output (in C<$html>) looks like:

    <html>
        <head>
          <title>Things To Do</title>
        </head>
        <body>
          <ol id='todos'>
            <li>Walk dogs</li>
            <li>Buy Milk</li>
          </ol>
        </body>
      </html>

=head1 DESCRIPTION

Uses L<HTML::Tidy> to 'prettify' your HTML output.  Please not this can also alter
your HTML (if your HTML has errors in it) and it also slows down processing so this
really is something you only use in development.

=head1 ATTRIBUTES

This class defines the following attributes

=head2 prettify

Boolean, defaults to true.  Set to a false value to turn off passing your HTML thru
L<HTML::Tidy>.  Or just remove the role.

=head2 htidy_args

A hashref of arguments used to initialize L<HTML::Tidy>.  Please see C<%DEFAULT_ARGS>
in the source for the defaults we use.  If you want to change the args it might me a good
idea to merge in the defaults.

=head1 SEE ALSO
 
L<Template::Pure>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut 
