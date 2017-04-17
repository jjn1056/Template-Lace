package Catalyst::View::Template::Lace::PerContext;

use Moo;
extends 'Catalyst::View::Template::Lace::Factory';
use Scalar::Util ();

around 'ACCEPT_CONTEXT', sub {
  my ($orig, $self, $c, @args) = @_;
  my $key = Scalar::Util::refaddr($self) || $self;
  return $c->stash->{"__Lace_${key}"} ||= do {
    $self->$orig($c, @args);
  };
};

1;

=head1 NAME

Catalyst::View::Template::Lace::Role::PerContext - One view per request/context

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
