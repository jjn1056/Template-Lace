package Catalyst::View::Template::Lace::Role::ViewComponents;

use Moo::Role;

around 'setup_component_info', sub {
  my ($orig, $class, @args) = @_;
  my %info = $class->$orig(@args);
  $info{view} = $class->setup_view_name($info{name})
    if $info{prefix} eq $class->view_prefix;
  return %info;
};

sub setup_view_name {
  my ($class, $name) = @_;
  return join '::', map { ucfirst $_ } split('-', $name);
}

sub view_prefix { 'view' }

around 'create_factory', sub {
  my ($orig, $class, @args) = @_;
  my $factory = $class->$orig(@args);
  $factory->{init_args}{component_handlers}{view} = sub {
    my ($self, $dom, $component_info, %attrs) = @_;
    $self->_profile(begin => "=> ViewComponent: $component_info->{view}");
    my $component_view = $self->view(
        $component_info->{view}, 
        %attrs,
        view=>$self, 
        container=> $self->components->{$component_info->{current_container_id}}{view_instance},
        content=>$dom);
    $self->components->{$attrs{uuid}}{view_instance} = $component_view;

    if($component_info->{current_container_id}) {
      push @{$self->components->{$component_info->{current_container_id}}{children}}, $component_view;
    }

    $self->_profile(end => "=> ViewComponent: $component_info->{view}");
  };
  return $factory;
};

after 'process_components', sub {
  my ($self, $dom) = @_;
  my @ordered_keys = @{$self->ordered_component_keys};
  foreach my $id(@ordered_keys) {
    if(my $component = $self->components->{$id}) {
      next unless $component->{view_instance};
      $self->finalize_process_component($dom, $component)
    }
  }
};

sub finalize_process_component {
  my ($self, $dom, $component) = @_;
  my $component_view = $component->{view_instance};

  if(my @children = @{$component->{children}||[]}) {
    $component_view->add_children(@children) if $component_view->can('add_children');
  }

  my $component_dom = $component_view->get_processed_dom;

  # Move all the scripts, styles and links to the head area
  $component_dom->find('link:not(head link)')->each(sub {
      $self->dom->append_link_uniquely($_->attr);
      $_->remove;
  });
  $component_dom->find('style:not(head style)')->each(sub {
      my $content = $_->content || '';
      $self->dom->append_style_uniquely(%{$_->attr}, content=>$content);
      $_->remove;
  });
  $component_dom->find('script:not(head script)')->each(sub {
      my $content = $_->content || '';
      $self->dom->append_script_uniquely(%{$_->attr}, content=>$content);
      $_->remove;
  });

  $dom->at("[uuid='$component->{key}']")->replace($component_dom); #ugg
}

around 'get_component_prefixes', sub {
  my ($orig, $class, @args) = @_;
  my @prefixes = $class->$orig(@args);
  return 'view', @prefixes;
};

around 'COMPONENT', sub {
  my ($orig, $class, $app, @args) = @_;
  my $factory = $class->$orig($app, @args);

  foreach my $key(keys %{$factory->{components}}) {
    my $info = $factory->{components}{$key};
    if(my $view = $info->{view}) {
      $view = $app->view($view);
      $view->finalize_view_component($factory, $info)
        if $view->can('finalize_view_component'); 
    }
  }
  return $factory;
};

1;

=head1 NAME

Catalyst::View::Template::Lace::Role::ViewComponents - Component factory for Views.

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

    TBD

=head1 SEE ALSO
 
L<Catalyst::View::Template::Lace>.

=head1 AUTHOR

Please See L<Catalyst::View::Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Catalyst::View::Template::Lace> for copyright and license information.

=cut
