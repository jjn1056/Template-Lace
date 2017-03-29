use strict;
use warnings;
package Template::Lace::DOM;

use base 'Mojo::DOM';
use Storable ();
use Scalar::Util;

# General Helpers
#
sub clone {
  return Storable::dclone(shift);
}

sub overlay {
  my ($self, $cb, @args) = @_;
  local $_ = $self;
  my $overlay_dom = $cb->($self, @args);
  $self->replace($overlay_dom);
}

sub wrap_at_content {
  my ($self, $new) = @_;
  $self->overlay(sub {
    $new->at('#content')
      ->replace($self);
  });
}

sub repeat {
  my ($self, $cb, @items) = @_;
  my $index = 0;
  my @nodes = map {
    my $cloned_dom = $self->clone;
    $index++;
    $cb->($cloned_dom, $_, $index);
    $cloned_dom;
  } @items;

  # Might be a faster way to do this...
  $self->parent->append_content($_) for @nodes;
  $self->remove;
  return $self;
}

sub smart_content {
  my ($self, $data) =@_;
  if($self->tag eq 'input') {
    $self->attr(value=>$data);
  } else {
    $self->content($data);
  }
  return $self;
}

sub fill {
  my ($self, $data, $is_loop) = @_;
  if(ref \$data eq 'SCALAR') {
    $self->smart_content($data);
  } elsif(ref $data eq 'CODE') {
    local $_ = $self;
    $data->($self);
  } elsif(ref $data eq 'ARRAY') {
    $self->repeat(sub {
      my ($dom, $datum, $index) = @_;
      $dom->fill($datum, 1);
    }, @$data);
  } elsif(ref $data eq 'HASH') {
    foreach my $match (keys %{$data}) {
      if(!$is_loop) {
        my $dom = $self->at("#$match");
        $dom->fill($data->{$match}, $is_loop) if $dom;
      }
      $self->find(".$match")->each(sub {
          my ($dom, $count) = @_;
          $dom->fill($data->{$match}, $is_loop);
      });
    }
  } elsif(Scalar::Util::blessed $data) {
    my @fields = $data->meta->get_attribute_list;
    foreach my $match (@fields) {
      if(!$is_loop) {
        my $dom = $self->at("#$match");
        $dom->fill($data->$match, $is_loop) if $dom;
      }
      $self->find(".$match")->each(sub {
          my ($dom, $count) = @_;
          $dom->fill($data->$match, $is_loop);
      });
    }
  } else {
    die "method 'fill' does not recognize these arguments.";
  }
}

sub append_style_uniquely {
  my $dom = shift;
  my %attrs = ref($_[0]) ? %{$_[0]} : @_;
  my $content = delete($attrs{content}) || '';
  my $head = $dom->at('head');
  unless($head->at(qq{style[id="${\do { $attrs{id}||'' }}"]})) {
    my $attr_string = join ' ', map { "$_='$attrs{$_}'" } keys %attrs;
    $head->append_content("<style $attr_string>$content</style>");
  }
  return $dom;
}

sub append_script_uniquely {
  my $dom = shift;
  my %attrs = ref($_[0]) ? %{$_[0]} : @_;
  my $content = delete($attrs{content}) || '';
  my $head = $dom->at('head');
  unless(
    $head->at(qq{script[src="${\do { $attrs{src}||'' }}"]})
    || $head->at(qq{script[id="${\do { $attrs{id}||'' }}"]})
  ) {
    my $attr_string = join ' ', map { "$_='$attrs{$_}'" } keys %attrs;
    $head->append_content("<script $attr_string>$content</script>");
  }
  return $dom;
}

sub append_link_uniquely {
  my $dom = shift;
  my %attrs = ref($_[0]) ? %{$_[0]} : @_;
  my $head = $dom->at('head');
  unless($head->at(qq{link[href="$attrs{href}"]})) {
    my $attr_string = join ' ', map { "$_='$attrs{$_}'" } keys %attrs;
    $head->append_content("<link $attr_string />");
  }
  return $dom;
}

# attribute helpers (tag specific or otherwise

sub attribute_helper {
  my ($self, $attr, @args) = @_;
  $self->attr($attr, @args);
  return $self;
}

sub target { shift->attribute_helper('target', @_) }
sub src { shift->attribute_helper('src', @_) }
sub href { shift->attribute_helper('href', @_) }
sub id { shift->attribute_helper('id', @_) }
sub class { shift->attribute_helper('class', @_) }

# unique tag helpers

sub unique_tag_helper {
  my ($self, $tag, $proto) = @_;
  my $dom = $self->at($tag);
  if(ref $proto eq 'CODE') {
    local $_ = $dom;
    $proto->($dom);
  } elsif(ref $proto) {
    $dom->fill($proto);
  } else {
    $dom->smart_content($proto);
  }
  return $self;
}

sub title { shift->unique_tag_helper('title', @_) }
sub body { shift->unique_tag_helper('body', @_) }
sub head { shift->unique_tag_helper('head', @_) }

# element helpers

sub tag_helper_by_id {
  my ($self, $tag, $id, $proto) = @_;
  return $self->unique_tag_helper("$tag$id", $proto);
}

sub list_helper_by_id {
  my ($self, $tag, $id, $proto) = @_;
  my $target = ref($proto) eq 'ARRAY' ? "$tag$id li" : "$tag$id";
  return $self->unique_tag_helper($target, $proto);
}

sub form { shift->tag_helper_by_id('form', @_) }
sub ul { shift->list_helper_by_id('ul', @_) }
sub ol { shift->list_helper_by_id('ol', @_) }
sub dl { shift->tag_helper_by_id('dl', @_) }

1;

=head1 NAME

Template::Lace::DOM - DOM searching and tranformation engine

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
