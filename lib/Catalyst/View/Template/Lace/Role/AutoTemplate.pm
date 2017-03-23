package Catalyst::View::Template::Lace::Role::AutoTemplate;

use Moo::Role;
use Catalyst::Utils ();
use File::Spec;

sub template {
  my $class = shift;
  my @parts = split("::", $class);
  my $filename = lc(pop @parts);
  my $home = Catalyst::Utils::home($class)
    || die "Can't figure out the home directory!";

  my $template_path = File::Spec->catfile($home, 'lib', @parts, $filename.'.html');

  open(my $fh, '<', $template_path)
    || die "can't open '$template_path': $@";
  local $/; my $slurped = $fh->getline;
  close($fh);

  return $slurped;
}


1;
