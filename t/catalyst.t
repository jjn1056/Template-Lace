BEGIN {
  use FindBin;
  use lib "$FindBin::Bin/lib";
}

use Test::Most;
use Catalyst::Test 'MyApp';
use Mojo::DOM58;

{
  ok my $res = request '/list';
  ok my $dom = Mojo::DOM58->new($res->content);
  warn $res->content;
}

{
  ok my $res = request '/user';
  ok my $dom = Mojo::DOM58->new($res->content);
  warn $res->content;
}
done_testing;

__END__

{
  ok my $res = request '/summary/one';
  ok my $dom = Mojo::DOM58->new($res->content);
  #is $dom->at('title')->content, 'A Dark and Stormy Night...';
  #
  warn $res->content;
}



