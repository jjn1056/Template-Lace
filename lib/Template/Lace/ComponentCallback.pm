package Template::Lace::ComponentCallback;

use warnings;
use strict;
use Template::Lace::DOM;

sub new { return bless pop, shift }
sub cb { return shift->{cb} }
sub make_dom { return Template::Lace::DOM->new(pop) }
sub model_class { return ref(shift) }

sub create {
  my $self = shift;
  return bless +{ cb => $self, @_ }, ref($self);
}

sub get_processed_dom {
  my $self = shift;
  local $_ = $self;
  local %_ =  %$self;
  my $response = $self->{cb}->($self, %$self);
  return ref($response) ?
    $response :
    $self->make_dom($response);
}

1;

=head1 NAME

Template::Lace::ComponentCallback - Create a component easily from a coderef

=head1 SYNOPSIS

    component_handlers => {
      tag => {
        anchor => Template::Lace::ComponentCallback->new(sub {
          my ($self, %attrs) = @_;
          return "<a href='$_{href}'>$_{content}</a>"
        }) 
      }
    }

=head1 DESCRIPTION

Lets you make quick and dirty components from a coderef.  To make this even
faster and dirtier we localize $_ to $self and %_ to %attrs.

=head1 METHODS

This class defines the following public methods

sub make_dom

Create an instance of L<Template::Lace::DOM>.

=head1 SEE ALSO
 
L<Template::Lace>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut 
