package Catalyst::View::Template::Lace::Role::ArgsFromStash;

use Moo::Role;

around 'ACCEPT_CONTEXT', sub {
  my ($orig, $self, $c, @args) = @_;
  my @stash_args = %{$c->stash};
  return $self->$orig($c, @args, @stash_args);
};

1;

=head1 NAME

Catalyst::View::Template::Lace::Role::ArgsFromStash - fill init args from the stash

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
