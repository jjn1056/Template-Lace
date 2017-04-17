package Template::Lace::Factory::InferInitArgsRole;

use Moo::Role;
use Scalar::Util;

has 'fields' => (
  is=>'ro',
  required=>1,
  default=>sub {[]});

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $args = $class->$orig(@args);
  $args->{fields} = $class->find_fields($args->{model_class});
  return $args;
};

# Might need something better here eventually.  Not sure
# we want to allow to infer any init argument, just the 
# ones aimed to be in the render of the template.  might
# need a 'has_content', 'has_node', etc?

# Please Note obviously this requires Moose

sub find_fields {
  my ($class, $model_class) = @_;
  return map { $_->init_arg } 
    grep { $_->has_init_arg }
    grep { $_->name ne 'ctx' }
    grep { $_->name ne 'catalyst_component_name' }
    ($model_class->meta->get_all_attributes);
}

around 'prepare_args', sub {
  my ($orig, $self, @args) = @_;
  my %args = $self->infer_args_from(@args);
  return $self->$orig(%args);
};

sub infer_args_from {
  my $self = shift;
  my %args = ();
  my @fields = @{$self->fields};

  # If the first argment is an object or a hashref then
  # we inspect it and unroll any matching fields.  This
  # is to allow a more ease of use for the view call (and
  # it enables a few other things ).

  if(Scalar::Util::blessed($_[0])) {
    my $init_object = shift @_;
    %args = map { $_ => $init_object->$_ } 
      grep { $init_object->can($_) }
      @fields;
  }

  return (%args, @_);
}

1;

=head1 NAME

Template::Lace::Factory::InferInitArgsRole - fill init args by inspecting an object

=head1 SYNOPSIS

Create a template class:

   package  MyApp::View::User;

    use Moo;
    extends 'Catalyst::View::Template::Lace';
    with 'Catalyst::View::Template::Lace::Role::ArgsFromStash',

    has [qw/age name motto/] => (is=>'ro', required=>1);

    sub template {q[
      <html>
        <head>
          <title>User Info</title>
        </head>
        <body>
          <dl id='user'>
            <dt>Name</dt>
            <dd id='name'>NAME</dd>
            <dt>Age</dt>
            <dd id='age'>AGE</dd>
            <dt>Motto</dt>
            <dd id='motto'>MOTTO</dd>
          </dl>
        </body>
      </html>
    ]}

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->dl('#user', +{
        age=>$self->age,
        name=>$self->name,
        motto=>$self->motto
      });
    }

    1;

Create an object;


Create and render an instance:

    my $factory = MyApp::Template::List
      ->create_factory;

    my $html = $factory->create(items=>['Walk dogs', 'Buy Milk'])
      ->render;

=head1 DESCRIPTION

Allows you to fill your template arguments from an object, possibily saving you some
tedious typing (at the possible expense of understanding).

=head1 SEE ALSO
 
L<Template::Pure>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut 
