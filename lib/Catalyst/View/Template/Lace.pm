package Catalyst::View::Template::Lace;

our $VERSION = '0.001';

use Moo;
use Module::Runtime;
use Catalyst::View::Template::Lace::Renderer;

extends 'Catalyst::View';

sub COMPONENT {
  my ($class, $app, $args) = @_;
  my $merged_args = $class->merge_config_hashes($class->config, $args);
  my $merged_component_handlers = $class->merge_config_hashes(
    (delete($merged_args->{component_handlers})||+{}),
    $class->view_components($app, $merged_args));

  my $adaptor = $args->{adaptor} || 'Catalyst::View::Template::Lace::Factory';

  return Module::Runtime::use_module($adaptor)->new(
    model_class=>$class,
    renderer_class=>'Catalyst::View::Template::Lace::Renderer',
    component_handlers=>$merged_component_handlers,
    init_args=>+{ %$merged_args, app=>$app },
  );
}

has ctx => (is=>'ro', required=>0);
has catalyst_component_name => (is=>'ro', required=>1);
has returns_status => (is=>'ro', predicate=>'has_returns_status');

sub view_components {
  my ($class, $app, $merged_args) = @_;
  return +{
    view => sub {
      my ($name, $args, %attrs) = @_;
      $name = ucfirst $name; #Maybe too simple
      return $app->view($name);
    },
  };
}

1;

=head1 NAME

Catalyst::View::Template::Lace - Adapt Template::Lace for Catalyst

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

    TBD

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Template::Lace>, L<Catalyst::View::Template::Pure>

=head1 COPYRIGHT & LICENSE
 
Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
