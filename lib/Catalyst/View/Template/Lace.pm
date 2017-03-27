package Catalyst::View::Template::Lace;

our $VERSION = '0.001';

use Moo;
use Scalar::Util;
use overload
  bool => sub {1},
  '""' => sub { shift->get_processed_dom->to_string },
  fallback => 1;

extends 'Catalyst::View';

sub COMPONENT {
  my ($class, $app, $args) = @_;
  my $merged_args = $class->merge_config_hashes($class->config, $args);
  return $class->create_factory($merged_args);
}

sub create_factory {
  my ($class, $merged_args) = @_;
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
  my $dom_class = _ensure_loaded($class->dom_class($merged_args));
  return $dom_class->new($template);
}

sub template { }

sub _ensure_loaded {
  eval "use $_[0]; 1" ||
    die "Can't load '$_[0]', $@";
  return $_[0];
}

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
  my ($class, $args) = @_;
  return @{$args->{component_prefixes}||[$class->default_component_prefixes]};
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
has ctx => (is=>'ro', required=>1);

sub ACCEPT_CONTEXT {
  my ($factory, $c, @args) = @_;
  return $factory->create(@args, ctx=>$c);
}

sub create {
  my ($factory, @extra_args) = @_;
  my %merged_args = (%{$factory->{init_args}}, @extra_args);
  return $factory->{class}->new(
    %merged_args,
    dom => $factory->prepare_dom,
    components => $factory->prepare_components,
    component_handlers => $factory->prepare_component_handlers,
  );
}

sub prepare_dom { shift->{dom}->clone }

sub prepare_components { shift->{components} }

sub prepare_component_handlers {
  my ($factory, %merged_args) = @_;
  return $merged_args{component_handlers}||+{};
}

sub respond {
  my ($self, $status, $headers) = @_;
  for ($self->ctx->res) {
    $_->status($status) if $_->status != 200; # Catalyst sets 200
    $_->content_type('text/html') if !$_->content_type;
    $_->headers->push_header(@{$headers}) if $headers;
    $_->body($self->render);
  }
  return $self;
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

# Support old school Catalyst::Action::RenderView for example (
# you probably also want the ::ArgsFromStash role).

sub process {
  my ($self, $c, @args) = @_;
  $self->response(200, @args);
}

# helper methods

sub overlay_view {
  my ($self, $view_name, $dom_proto, @args) = @_;
  if($dom_proto->can('each')) {
    $dom_proto->each(sub {
      return $self->overlay_view($view_name, $_, @args);
    });
  } else {
    $dom_proto->overlay(sub {
      return $self->view($view_name, @args, content=>$_)
        ->get_processed_dom;
    });
  }
}

# proxy methods 

sub detach { shift->ctx->detach(@_) }

sub view { shift->ctx->view(@_) }

1;
