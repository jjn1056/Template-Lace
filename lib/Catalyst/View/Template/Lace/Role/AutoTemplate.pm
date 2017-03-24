package Catalyst::View::Template::Lace::Role::AutoTemplate;

use Moo::Role;
use Catalyst::Utils ();
use File::Spec;

sub get_path_to_template {
  my ($class) = @_;
  my @parts = split("::", $class);
  my $filename = lc(pop @parts);
  my $home = $class->get_home_path;
  return File::Spec->catfile($home, 'lib', @parts, $filename.'.html');
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
