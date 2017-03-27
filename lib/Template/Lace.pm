package Template::Lace;

our $VERSION = '0.001';

use Moo;
use Module::Runtime;
use Scalar::Util;
use overload
  bool => sub {1},
  '""' => sub { shift->get_processed_dom->to_string },
  fallback => 1;

sub create_factory {
  my $class = shift;
  my $merged_args = ref($_[0]) eq 'HASH' ? $_[0] : +{ @_ }; # Allow init args as list or ref
  my $dom = $class->create_dom($merged_args);
  my %components = $class->find_components_by_prefixes($dom, $merged_args);
  return bless +{
    class => $class,
    dom => $dom,
    components => \%components,
    init_args => $merged_args,
  }, $class;
}

sub create_dom {
  my ($class, $merged_args) = @_;
  my $template = $class->template($merged_args);
  my $dom_class = Module::Runtime::use_module($class->dom_class($merged_args));
  return $dom_class->new($template);
}

sub template { }

sub dom_class { 'Template::Lace::DOM' }

sub find_components_by_prefixes {
  my ($class, $dom, $merged_args) = @_;
  my %components = ();
  my @prefixes = $class->get_component_prefixes($merged_args);
  foreach my $prefix(@prefixes) {
    %components = (
      %components,
      $class->setup_components($dom, $prefix)
    );
  }
  return %components;
}

sub get_component_prefixes {
  my ($class, $merged_args) = @_;
  return @{$merged_args->{component_prefixes}||[$class->default_component_prefixes]};
}

sub default_component_prefixes { 'lace' }

sub setup_components {
  my ($class, $dom, $prefix, $current_container_id, %components) = @_;
  $dom->child_nodes->each(sub {
      my ($child_dom, $num) = @_;
      if(my $component_name = (($child_dom->tag||'') =~m/^$prefix\-(.+)?/)[0]) {
        die "A component MUST set an unique 'id' attribute" unless my $id = $child_dom->attr('id');
        $components{$id} = +{
          $class->setup_component_info($prefix,
            $current_container_id,
            $component_name,
            $child_dom) };
        $current_container_id = $id;
      }
      %components = $class->setup_components($child_dom,
        $prefix,
        $current_container_id,
        %components);
  });
  return %components;
}

sub setup_component_info {
  my ($class, $prefix, $current_container_id, $name, $dom) = @_;
  my %attrs = $class->setup_component_attr($dom);
  return prefix => $prefix,
    name => $name,
    current_container_id => $current_container_id,
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

has dom => (is=>'ro', required=>1);
has components => (is=>'ro', required=>1);
has component_handlers => (is=>'ro', required=>1);

sub create {
  my $factory = shift;
  return $factory->{class}->new(
    $factory->prepare_args(@_),
    dom => $factory->prepare_dom,
    components => $factory->prepare_components,
    component_handlers => $factory->prepare_component_handlers,
  );
}

sub prepare_args {
  my $factory = shift;
  my @extra_args = ref($_[0]) ? @{$_[0]} : @_; # Allow init args as list or ref
  my %merged_args = (%{$factory->{init_args}}, @extra_args);
  return %merged_args;
}

sub prepare_dom { shift->{dom}->clone }

sub prepare_components { shift->{components} }

sub prepare_component_handlers {
  my ($factory, %merged_args) = @_;
  return $merged_args{component_handlers}||+{};
}

sub render {
  return shift->get_processed_dom
    ->to_string;
}

sub get_processed_dom {
  my $self = shift;
  $self->process_components($self->dom);
  $self->process_dom($self->dom);
  return $self->dom;
} 

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
  my $handler = $self->find_component_handler_for(%component_info) ||
   die "No component handler for $component_info{prefix} :: $component_info{name}"; 
  $handler->($self, $dom, \%component_info, %attrs);
}

sub process_attrs {
  my ($self, $dom, %attrs) = @_;
  return map {
    my $proto = $attrs{$_};
    my $value = ref($proto) ? $proto->($self, $dom) : $proto;
    $_ => $value;
  } keys %attrs;
}

sub find_component_handler_for {
  my ($self, %component_info) = @_;
  if(my $prefix = $self->component_handlers->{$component_info{prefix}}) {
    if(ref $prefix eq 'CODE') {
      return $prefix;
    } elsif(ref $prefix eq 'HASH') {
      if(my $name = $prefix->{$component_info{name}}) {
        die "component handler at $component_info{prefix} :: $component_info{name} not a CODE ref" unless ref($name) eq 'CODE';
        return $name;
      } 
    } else {
      die "component handler for $component_info{prefix} misconfigured, should be CODE or HASH ref";
    }
  }
}

sub process_dom { pop }

1;

