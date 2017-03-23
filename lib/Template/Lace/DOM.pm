use strict;
use warnings;
package Template::Lace::DOM;

use base 'Mojo::DOM';
use Storable ();

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

sub target {
  my ($self, @args) = @_;
  warn "setting 'target' attribute on tag ${\$self->tag} is not valid"
    unless $self->tag eq 'form';
  $self->attr('target', @args);
  return $self;
}

sub title {
  my ($self, $content) = @_;
  $self->at('title')->content($content);
  return $self;
}

sub form {
  my ($self, $id, $cb) = @_;
  my $form = $self->at("form$id") || die "no form with id of $id";
  local $_ = $form;
  $cb->($form);
  return $self;
}

sub body {
  my ($self, $cb) = @_;
  my $dom = $self->at('body');
  local $_ = $dom;
  $cb->($dom);
  return $self;
}

sub head {
  my ($self, $cb) = @_;
  my $dom = $self->at('head');
  local $_ = $dom;
  $cb->($dom);
  return $self;
}

sub ul {
  my ($self, $id, $proto) = @_;
  my $ul = $self->at("ul$id") || die "no ul with id of $id";
  local $_ = $ul;
  if(ref $proto eq 'CODE') {
    $proto->($ul);
  } elsif(ref $proto) {
    $_->at('li')->fill($proto);
  }
  return $self;
}

sub ol {
  my ($self, $id, $proto) = @_;
  my $ol = $self->at("ol$id") || die "no ol with id of $id";
  local $_ = $ol;
  if(ref $proto eq 'CODE') {
    $proto->($ol);
  } elsif(ref $proto) {
    $_->at('li')->fill($proto);
  }
  return $self;
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
  } else {
    die "method 'fill' needs to be an array reference or hash reference";
  }
}

1;


__END__

  ### Helper suggestion
  #$dom->fill_content($data);

{
  name => 'john',
  age => 25,
  location => [qw/nyc austin/]
  friends => [
    {
      name => 'paul',
      age => 35,
    },
    {
      name => 'mary',
      age => 35,
    },
  ]
}

[
  {
    name => 'john',
    age => 25,
  },
  {
    name => 'john',
    age => 25,
  }
]

