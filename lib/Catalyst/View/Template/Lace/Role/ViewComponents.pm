package Catalyst::View::Template::Lace::Role::ViewComponents;

use Moo::Role;

around 'create_factory', sub {
  my ($orig, $class, $args) = @_;
  my $factory = $class->$orig($args);
  my %components = $factory->find_component_by_prefixes($args);
  $factory->{components} = \%components;
  return $factory;
};

sub find_component_by_prefixes {
  my ($factory, $args) = @_;
  my %components = ();
  my @prefixes = $factory->get_component_prefixes($args);
  foreach my $prefix(@prefixes) {
    %components = (
      %components,
      $factory->find_components($factory->{dom}, $prefix)
    );
  }
  return %components;
}

sub get_component_prefixes {
  my ($factory, $args) = @_;
  return @{$args->{component_prefixes}||[$factory->default_component_prefixes]};
}

sub default_component_prefixes { 'lace' }

sub find_components {
  my ($class, $dom, $prefix, %components) = @_;
  $dom->child_nodes->each(sub {
      my ($child_dom, $num) = @_;
      if(my $component_name = (($child_dom->tag||'') =~m/^$prefix\-(.+)?/)[0]) {
        $components{$child_dom->attr('id')} = +{ $class->setup_component_info($prefix, $component_name, $child_dom) };
      }
      # Here we should be able to identify the 'containing' component if any
      # maybe need to descend via the found components above.
      %components = $class->find_components($child_dom, $prefix, %components);
  });
  return %components;
}

sub setup_component_info {
  my ($class, $prefix, $name, $dom) = @_;
  my %attrs = $class->setup_component_attr($dom);

  # TODO split out into stand alone component
  my $view = join '::', map { ucfirst $_ } split('-', $name);
  return view => $view, 
    name => $name,
    prefix => $prefix,
    attrs => \%attrs;
}

sub setup_component_attr {
  my ($class, $dom) = @_;
  return map {
    $_ => $class->attr_value_handler_factory($dom->attr->{$_});
  } keys %{$dom->attr||+{}};
}

sub attr_value_handler_factory {
  my ($class, $value) = @_;
  if(my ($node, $css) = ($value=~m/^\\['"](\@?)(.+)['"]$/)) {
    return $class->setup_css_match_handler($node, $css); # CSS match to content DOM
  } elsif(my $path = ($value=~m/^\$\.(.+)$/)[0]) {
    return $class->setup_data_path_hander($path); # is path to data
  } else {
    return $value; # is literal or 'passthru' value
  }
}

sub setup_css_match_handler {
  my ($class, $node, $css) = @_;
  if($node) {
    return sub { my ($view, $dom) = @_; $dom->find($css) };
  } else {
    if(my $content = $css=~s/\:content$//) { # hack to CSS to allow match on content
      return sub { my ($view, $dom) = @_; $dom->at($css)->content };
    } else {
      return sub { my ($view, $dom) = @_; $dom->at($css) };
    }
  }
}

sub setup_data_path_hander {
  my ($class, $path) = @_;
  my @parts = $path=~m/\./ ? (split('\.', $path)) : ($path);
  return sub {
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

has components => (is=>'ro', required=>1);

around 'ACCEPT_CONTEXT', sub {
  my ($orig, $factory, $c, @args) = @_;
  return $factory->$orig($c, @args, components => $factory->{components});
};

before 'get_processed_dom', sub {
  return $_[0]->process_components($_[0]->dom);
};

sub process_components {
  my ($self, $dom) = @_;
  foreach my $id(keys %{$self->components}) {
    $self->process_component(
      $dom->at("#$id"), 
      %{$self->components->{$id}});
  }
}

sub process_component {
  my ($self, $dom, %component_info) = @_;
  my %attrs = $self->process_attrs($dom, %{$component_info{attrs}});

  ## This is the bit that needs to move to a component 'handler'
  $self->overlay_view(
    $component_info{view},
    $dom,
    %attrs, container=>$self);
}

sub process_attrs {
  my ($self, $dom, %attrs) = @_;
  return map {
    my $proto = $attrs{$_};
    my $value = ref($proto) ? $proto->($self, $dom) : $proto;
    $_ => $value;
  } keys %attrs;
}

1;
