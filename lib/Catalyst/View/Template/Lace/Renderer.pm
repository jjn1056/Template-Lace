package Catalyst::View::Template::Lace::Renderer;

use Moo;
use HTTP::Status ();

extends 'Template::Lace::Renderer';

around 'prepare_component_attrs', sub {
  my ($orig, $self, @args) = @_;
  my %attrs = $self->$orig(@args);
  $attrs{ctx} = $self->ctx;
  return %attrs;
};

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  my @returns_status = @{$args->{model}->returns_status||[]};
  $class->inject_http_status_helpers(@returns_status);
  return $args;
};



sub inject_http_status_helpers {
  my ($class, @returns_status) = @_;
  return unless @returns_status;
  foreach my $helper( grep { $_=~/^http/i} @HTTP::Status::EXPORT_OK) {
    my $subname = lc $helper;
    my $code = HTTP::Status->$helper;
    my $codename = "http_".$code;
    if(grep { $code == $_ } @returns_status) {
       eval "sub ${\$class}::${\$subname} { return shift->respond(HTTP::Status::$helper,\@_) }";
       eval "sub ${\$class}::${\$codename} { return shift->respond(HTTP::Status::$helper,\@_) }";
    }
  }
}
sub ctx { shift->model->ctx }

sub catalyst_component_name { shift->model->catalyst_component_name }

sub respond {
  my ($self, $status, $headers) = @_;
  $self->_profile(begin => "=> ".Catalyst::Utils::class2classsuffix($self->catalyst_component_name)."->respond($status)");
  for ($self->ctx->res) {
    $_->status($status) if $_->status != 200; # Catalyst sets 200
    $_->content_type('text/html') if !$_->content_type;
    $_->headers->push_header(@{$headers}) if $headers;
    $_->body($self->render);
  }
  $self->_profile(end => "=> ".Catalyst::Utils::class2classsuffix($self->catalyst_component_name)."->respond($status)");
  return $self;
}

sub _profile {
  my $self = shift;
  $self->ctx->stats->profile(@_)
    if $self->ctx->debug;
}

# Support old school Catalyst::Action::RenderView for example (
# you probably also want the ::ArgsFromStash role).

sub process {
  my ($self, $c, @args) = @_;
  $self->response(200, @args);
}

# helper methods

sub overlay_view {
  my ($self, $view_name, $dom_proto, @args) = @_;
  if( (ref($dom_proto)||'') eq 'CODE') {
    local $_ = $self->dom;
    @args = ($dom_proto->($self->dom), @args);
    $self->dom->overlay(sub {
      return $self->view($view_name, @args, content=>$_)
        ->get_processed_dom;
    });
  } elsif($dom_proto->can('each')) {
    $dom_proto->each(sub {
      return $self->overlay_view($view_name, $_, @args);
    });
  } else {
    $dom_proto->overlay(sub {
      return $self->view($view_name, @args, content=>$_)
        ->get_processed_dom;
    });
  }
  return $self;
}

sub fill_at {
  my ($self, $id) = @_;
  $self->dom
    ->find($id)
    ->each(sub { $_->fill($self) }); # nice shortcut but could be expensive
  return $self;
}

# proxy methods 

sub detach { shift->ctx->detach(@_) }

sub view { shift->ctx->view(@_) }

1;

=head1 NAME

Catalyst::View::Template::Lace::Renderer - Adapt Template::Lace for Catalyst

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

    TBD

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Template::Lace>, L<Catalyst::View::Template::Lace>

=head1 COPYRIGHT & LICENSE
 
Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
