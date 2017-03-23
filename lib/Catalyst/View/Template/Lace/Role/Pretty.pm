package Catalyst::View::Template::Lace::Role::Pretty;

use Moo::Role;
use HTML::Tidy;

# Setup to support HTML5
our %DEFAULT_ARGS = (
  tidy_mark=>0,
  indent=>1,
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
