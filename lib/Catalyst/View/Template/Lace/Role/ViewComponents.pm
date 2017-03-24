package Catalyst::View::Template::Lace::Role::ViewComponents;

use Moo::Role;

sub find_components {
  my ($class, $dom, %components) = @_;
  $dom->child_nodes->each(sub {
      my ($dom, $num) = @_;
      if(my $component_name = (($dom->tag||'') =~m/^lace\-(.+)?/)[0]) {
        $component_name = join '::', map { ucfirst $_ } split('-', $component_name);
        my %attrs = map {
          my $value = $dom->attr->{$_};
          if(my ($node, $css) = ($value=~m/^\\['"](\@?)(.+)['"]$/)) {
            my $content = $css=~s/\:content$//;
            $value = $node ? sub { my ($view, $dom) = @_; $dom->find($css) } :
                             sub { my ($view, $dom) = @_; $content ? $dom->at($css)->content : $dom->at($css) };
          } elsif(my $path = ($value=~m/^\$\.(.+)$/)[0]) {
            my @parts =($path);
            if($path=~m/\./) {
              @parts = split('\.', $path);
            };
            $value = sub {
              my ($view, $dom) = @_;
              my $ctx = $view;
              foreach my $part(@parts) {
                if(Scalar::Util::blessed $ctx) {
                  $ctx = $ctx->$part;
                } elsif(ref($ctx) eq 'HASH') {
                  $ctx = $ctx->{$part};
                } else {
                  die "No '$part' in path '$path' for this view";
                }
              }
              return $ctx;
            };
          }
          $_ => $value;
        } keys %{$_->attr};

        $components{$dom->attr('id')} = +{
          view => $component_name,
          attrs => \%attrs,

        };
      }
      %components = $class->find_components($_, %components);
  });
  return %components;
}

before 'get_processed_dom', sub {
  my ($self) = @_;
  $self->process_components($self->dom);
};

sub process_components {
  my ($self, $dom) = @_;
  foreach my $id(keys %{$self->components}) {
    my %attrs = map {
      my $proto = $self->components->{$id}{attrs}{$_};
      my $value = ref($proto) ? $proto->($self, $dom) : $proto;
      $_ => $value;
    } keys %{$self->components->{$id}{attrs}};
    $self->overlay_view(
      $self->components->{$id}{view},
      $dom->at("#$id"),
      %attrs, container=>$self);
  }
}

around 'create_factory', sub {
  my ($orig, $class, $args) = @_;
  my $factory = $class->$orig($args);
  my %components = $class->find_components($factory->{dom});
  $factory->{components} = \%components;
  return $factory;
};

has components => (is=>'ro', required=>1);

around 'ACCEPT_CONTEXT', sub {
  my ($orig, $factory, $c, @args) = @_;
  return $factory->$orig($c, @args, components => $factory->{components});
};

1;
