package Template::Lace::ModelRole;

use Moo::Role;

sub template {
  my ($class) = @_;
  return;
}

sub prepare_dom {
  my ($class, $dom) = @_;
}


sub process_dom {
  my ($self, $dom) = @_;
}

1;

=head1 NAME

Template::Lace::ModelRole

=head1 SYNOPSIS

    package MyApp::User;

    use Moo;
    with 'Template::Lace::ModelRole';


=head1 DESCRIPTION

The minimal interface that a model class must provide.

=head1 SEE ALSO
 
L<Template::Lace>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut 
