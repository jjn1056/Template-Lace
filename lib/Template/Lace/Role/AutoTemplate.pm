package Template::Lace::Role::AutoTemplate;

use Moo::Role;
use File::Spec;

sub get_path_to_template {
  my ($class) = @_;
  my @parts = split("::", $class);
  my $filename = lc(pop @parts);
  my $path = "$class.pm";
  $path =~s/::/\//g;
  my $inc = $INC{$path};
  my $base = $inc;
  $base =~s/$path$//g;
  return my $template_path = File::Spec->catfile($base, @parts, $filename.'.html');
}

sub get_home_path {
  return Catalyst::Utils::home(shift)
    || die "Can't figure out the home directory!";
}

sub slurp_template_from {
  my ($class, $template_path) = @_;
  open(my $fh, '<', $template_path)
    || die "can't open '$template_path': $@";
  local $/; my $slurped = $fh->getline;
  close($fh);
  return $slurped;
}

around 'template', sub {
  my ($orig, $class, @args) = @_;
  if(my $template = $class->$orig(@args)) {
    return $template;
  } else {
    my $template_path = $class->get_path_to_template;
    return $class->slurp_template_from($template_path);
  }
};

1;

=head1 NAME

Template::Lace::Role::AutoTemplate - More easily find your template

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

    TBD

=head1 SEE ALSO
 
L<Template::Pure>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut 
