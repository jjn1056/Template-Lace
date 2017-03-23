package Catalyst::View::Template::Lace::Role::ResponseHelpers;

use Moo::Role;
use HTTP::Status ();

around 'create_factory', sub {
  my ($orig, $class, $dom, $args) = @_;
  my $returns_status = delete($args->{returns_status});
  $class->inject_http_status_helpers(@{$returns_status||[]});
  return $class->$orig($dom, $args);
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

1;
