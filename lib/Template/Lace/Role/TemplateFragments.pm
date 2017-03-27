package Template::Lace::Role::TemplateFragments;

use Moo::Role;

sub extract_fragments {
  my ($class, $dom) = @_;
  my $fragments = $dom->find('fragment');
  my %fragments;
  $fragments->each(sub {
    $fragments{$_->attr('id')} = $class->create_dom($_->content);
    $_->remove;
  });
  return %fragments;
}

around 'create_factory', sub {
  my ($orig, $class, $args) = @_;
  my $factory = $class->$orig($args);
  my %fragments = $class->extract_fragments($factory->{dom});
  $factory->{fragments} = \%fragments;
  return $factory;
};

has fragments => (is=>'ro', required=>1);

around 'ACCEPT_CONTEXT', sub {
  my ($orig, $factory, $c, @args) = @_;
  return $factory->$orig($c, @args, fragments => $factory->{fragments});
};

sub get_fragment {
  my ($self, $fragment_id) = @_;
  my $fragment_dom = $self->fragments->{$fragment_id} ||
    die "'$fragment_id' does not exist in this view";
  return $fragment_dom->clone;
}

1;
