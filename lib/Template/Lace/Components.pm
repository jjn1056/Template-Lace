package Template::Lace::Components;

use Moo;
use UUID::Tiny;

has [qw(handlers component_info ordered_component_keys)] => (is=>'ro', required=>1);

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);
  my @prefixes = $class->get_prefixes($args);
  my %component_info = $class->get_component_info($args, @prefixes);
  my @ordered_component_keys = $class->get_component_ordered_keys(%component_info);
  my %handlers = $class->get_handlers($args, \%component_info, @ordered_component_keys);

  $args->{handlers} = \%handlers;
  $args->{component_info} = \%component_info;
  $args->{ordered_component_keys} = \@ordered_component_keys;

  return $args;
};

sub get_prefixes {
  my ($class, $args) = @_;
  my @prefixes = keys %{$args->{component_handlers}||+{}};
  return @prefixes;
}

sub get_component_info {
  my ($class, $args, @prefixes) = @_;
  my %component_info = ();
  foreach my $prefix(@prefixes) {
    my $offset = scalar keys %component_info;
      %component_info = (
      %component_info,
      $class->find_components($args->{dom}, $prefix, undef, $offset));
  }
  return %component_info;
}

sub get_handlers {
  my ($class, $args, $component_info, @ordered_component_keys) = @_;
  my %handlers = ();
  foreach my $key(@ordered_component_keys) {
    my $handler = $class->get_handler($args, %{$component_info->{$key}});
    # TODO deal with 'static' type handlers
    $handlers{$key} = $handler;
  }
  return %handlers;
}

sub get_handler {
  my ($class, $args, %component_info) = @_;
  my $prefix = $component_info{prefix};
  my $name = $component_info{name};
  my $handler = '';
  if(ref($args->{component_handlers}{$prefix}) eq 'CODE') {
    my %attrs = %{$component_info{attrs}};
    $handler = $args->{component_handlers}{$prefix}->($name, %attrs);
  } else {
    $handler = $args->{component_handlers}{$prefix}{$name};
  }
  return $handler;
}

sub find_components {
  my ($class, $dom, $prefix, $current_container_id, $offset, %components) = @_;
  $dom->child_nodes->each(sub {
      my ($child_dom, $num) = @_;
      if(my $component_name = (($child_dom->tag||'') =~m/^$prefix\-(.+)?/)[0]) {
        ## if uuid exists, that means we already processed it.
        unless($child_dom->attr('uuid')) {
          my $uuid = $class->generate_component_uuid($prefix);
          $child_dom->attr({'uuid',$uuid});
          $components{$uuid} = +{
            order => (scalar(keys %components) + $offset),
            key => $uuid,
            $class->setup_component_info($prefix,
              $current_container_id,
              $component_name,
              $child_dom),
          } unless $components{$uuid};

          if($current_container_id) {
            push @{$components{$current_container_id}{children_ids}}, $uuid;
          }

          my $old_current_container_id = $current_container_id;
          $current_container_id = $uuid;
          
          %components = $class->find_components($child_dom,
            $prefix,
            $current_container_id,
            $offset,
            %components);

          $current_container_id = $old_current_container_id;
        }
    }
    %components = $class->find_components($child_dom,
      $prefix,
      $current_container_id,
      $offset,
      %components);
  });
  return %components;
}

sub generate_component_uuid {
  my ($class, $prefix) = @_;
  my $uuid = UUID::Tiny::create_uuid_as_string;
  $uuid=~s/\-//g;
  return $uuid;
}

sub setup_component_info {
  my ($class, $prefix, $current_container_id, $name, $dom) = @_;
  my %attrs = $class->setup_component_attr($dom);
  return prefix => $prefix,
    name => $name,
    current_container_id => $current_container_id||'',
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
    my ($ctx, $dom) = @_;
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

sub get_component_ordered_keys {
  my ($class, %component_info) = @_;
  return map {
    $_->{key}
  } sort {
    $a->{order} <=> $b->{order}
  } map {
    $component_info{$_}
  } keys %component_info;
}

1;
