package Template::Lace;

our $VERSION = '0.001';

1;

=head1 NAME

Template::Lace - Logic-less and strongly typed templates, with components

=head1 SYNOPSIS

    TBD

=head1 DISCLAIMER

L<Template::Lace> is a toolkit for building HTML pages using logic-less and componentized
templates.  As such this distribution is currently not aimed at standalone use but rather
exists as all the reusable bits that fell out when I refactored L<Catalyst::View::Template::Lace>.
Currently this toolkit then exists to support the L<Catalyst> View and as a result documentation
here is high level and API level.  If you want to integrate L<Template::Lace> into other
web frameworks you might wish to review L<Catalyst::View::Template::Lace> for a possible
approach.

=head1 DESCRIPTION

L<Template::Lace> is a toolkit that makes it possible to bind HTML templates to plain old Perl
classes as long as they provide a defined interface (provided by L<Template::Lace::ModelRole>
but again you don't have to use L<Moo> as long as you conform to the minimal interface). These
templates are fully HTML markup only; they contain no display logic, only valid HTML and component
declarations.  We use L<Template::Lace::DOM> (which is a subclass of L<Mojo::DOM58>) to alter the 
template for presentation at request time.  L<Template::Lace::DOM> provides an API to transform
the template into HTML using instance data and method provided by the class.

When you have a Perl class that does L<Template::Lace::ModelRole> we call that a 'Model' class
Here's an example of a very simple Model class:

    package  MyApp::Template::User;

    use Moo;
    with 'Template::Lace::ModelRole';

    has [qw/age name motto/] => (is=>'ro', required=>1);

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->dl('#user', +{
        age=>$self->age,
        name=>$self->name,
        motto=>$self->motto});
    }

    sub template { q[
      <html>
        <head>
          <title>User Info</title>
        </head>
          <body>
            <dl id='user'>
              <dt>Name</dt>
              <dd id='name'> -NAME- </dd>
              <dt>Age</dt>
              <dd id='age'> -AGE- </dd>
              <dt>Motto</dt>
              <dd id='motto'> -MOTTO- </dd>
            </dl>
          </body>
      </html>
    ]}

    1;

In this example the Model class defines two methods, C<process_dom> and C<template>.  Any Perl class
can be used as Model class as long as it provides these methods (as well as a stub for C<prepare_dom>
which will we discuss later; or just consume L<Template::Lace::ModelRole>.)  The C<template> method
just needs to return a string.  It should contain your desired HTML markup.  The C<process_dom> method
is an instance method on your class, and it gets both C<$self> and C<$dom>, where C<$dom> is a
DOM representation of your template (via L<Template::Lace::DOM>).  Anything you want to change about
the template should be done via the L<Template::Lace::DOM> API.  This is a subclass of L<Mojo::DOM58>
a Jquery like API for transforming HTML.  Our custom subclass contains some additional helper methods
to make common types of transforms easier.  For example here we use the custom helper C<dl> to find
a C<dl> tag by its id and then populate its data by matching hash keys to tag ids.

So how do you get a rendered template out of a Model class?  That's the job of two additional
classes, L<Template::Lace::Factory> and L<Template::Lace::Renderer> (with a tag team by 
L<Template::Lace::Components> should your template contain components; to be discussed later).

L<Template::Lace::Factory> wraps your model class and inspects it to create an initial DOM representation
of the template (as well as it prepares a component hierarchy, should you have components).  Most
simply it looks like this:

    my $factory = Template::Lace::Factory->new(
      model_class=>'MyApp::Template::User');

Next you call the C<create> method on the C<$factory> instance with the initial arguments you want to
pass to the Model.  Create doesn't return the Model directly, but instead returns an instance of
L<Template::Lace::Renderer> which is wrapping the model:

    my $renderer = $factory->create(
      age=>42,
      name=>'John',
      motto=>'Life in the Fast Lane!');

Those initial arguments are passed to the model and used to create an instance of the model.  But the
wrapping C<$renderer> exposes methods that are used to do the actual transformation.  For example

    print $renderer->render;

Would return:

    <html>
      <head>
        <title>
          User Info
        </title>
      </head>
      <body id="body">
        <dl id="user">
          <dt>
            Name
          </dt>
          <dd id="name">
            John
          </dd>
          <dt>
            Age
          </dt>
          <dd id="age">
            42
          </dd>
          <dt>
            Motto
          </dt>
          <dd id="motto">
            Why Not?
          </dd>
        </dl>
      </body>
    </html>

And that is the basics of it!  Once you have a C<$factory> you can call C<create> on it as many times
as you like to make different versions of the rendered page.

=head1 PREPARING THE DOM

Sometimes a Model may wish to make some modifications to its DOM once at setup time.  For
example you might add some debugging information to the header.  Although you can do this
in C<process_dom> it might seem wasteful if the change isn't dynamic, or bound to something
that can change for each request.  In this case your Model may add a class method C<prepare_dom>
which gets access to the DOM of the template during its initial setup.  Any changes you make
at this point will become cloned for all subsequent requests.  For example:

    package  MyApp::Template::List;

    use Moo;
    with 'Template::Lace::ModelRole',
      'Template::Lace::Model::AutoTemplate';

    has [qw/form items copywrite/] => (is=>'ro', required=>1);

    sub time { return scalar localtime }

    sub prepare_dom {
      my ($class, $dom, $merged_args) = @_;

      # Add some meta-data
      $dom->at('head')
        ->prepend_content("<meta startup='${\$self->time}'>");
    }

    sub process_dom {
      my ($self, $dom) = @_;
      $dom->ol('#todos', $self->items);
    }

In this case we'd add a startup timestand to the header area of the template, which might be
useful for debugging for example.

This example also used the role L<Template::Lace::Model::AutoTemplate> which allows you to
pull your template from a standalone file using a simple naming convention.  When your
templates are larger and more complex, or when you have HTML designer that prefers standalone
templates instead of ones mixed into Perl code, you can use this role to achieve that.  See
the docs in L<Template::Lace::Model::AutoTemplate> for more.

=head1 COMPONENTS

Most template systems have a mechanism to make it possible to divide your template into
discrete, re-usable chunks.  L<Template::Lace> provides this via Components.  Components are
custom tags embedded into your template, usually with some markup which allows you to control
the passing of information into the component from the Model class.  In your template you
would declare a component like this:

    <prefix-name
        attr1=>'literal value'
        attr2=>'$.foo'
        attr3=>\'title:content'>
      [some addtional content such as HTML markup and text]
    </prefix-name>

A component doesn't have to contain anything (like the <br/> or <hr/> tag) in which case
its just:

    <prefix-name
        attr1=>'literal value'
        attr2=>'$.foo'
        attr3=>\'title:content' />
    
Here's an example:

    <view-footer copydate='$.copywrite' />

And another example:

    <lace-form
        method="post" 
        action="$.post_url">
      <input type='text' name='user' />
      <input type='text' name='age' />
      <input type='text' name='motto' />
      <input type='submit' />
    </lace-form>

Canonically a component is a tag in the form of '$prefix-$name' (like <prefix-name ...>)
and typically will contain HTML attributes (like 'attr1="Literal"') and it may also
have content, as in "<lace-form><input type="submit"/></lace-form>".  When you render
a template containing components, any HTML attributes will be converted to a real value
and passed to the component as initialization arguments.  There are three different
ways your attributes will be processed:

=over4

=item literal values

Example: <prefix-name attr='1994'/>

When a value is a simple literal that value is passed as is.

=item a path from the model instance

Example: <prefix-name attr='$.foo'/>

This returns the value of "$self->foo", where $self is the model instance that the factory
created.  You can follow a data path similarly to Template Toolkit, for example:

    <prefix-name attr="$.foo.bar.baz" />

Would be the value of "$self->foo->bar->baz" (or possibly $self->foo->{bar}{baz} since we
follow either a method name or the key of a hash).  Currently we do not follow arrayrefs.

You'll probably use this quite often to pass instance information to your component.  If
the path does not exist that will return a run time error.

=item a CSS match 

Examples: <prefix-name title=\'title:content' css=\'@link' />

When the value of the attribute begins with a '\' that means we want to get the value of
a CSS match to the current DOM.  In Perl when a variable starts with a '\' the means its
a reference; so you can think of this as a reference to a point in the current DOM.

In general the value here is just a normal CSS match specification (see L<Mojo::DOM58> for
details on the match specifications supported).  However we have added two minor bits to
how L<Mojo::DOM58> works to make some types matching easier.  First, if a match specification
ends in ':content' that means 'match the content, not the full node'.  In the example case
"title=\'title:content'" that would get the text value of the title tag.  Second, in the case
where you want the match to return a collection of nodes all matching the specification, you
would prepend a '@' to the front of it (think in Perl @variable means an array variable). In
the given example "css=\'@link'" we want the attribute 'css' to be a collection of all the
linked stylesheets in the current DOM.

You will use this type of value when you are making components that do complex layout
and overlays of the current DOM (such as when you are creating a master layout page for
your website).

=back

In addition to any attributes you pass to a component via a declaration as described above
all components could get some of the following automatic atttributes:

=over 4

=item content

If the component has content as in the following example

    <prefix-name
        attr1=>'literal value'
        attr2=>'$.foo'
        attr3=>\'title:content'>
      [some addtional content such as HTML markup and text]
    </prefix-name>

That content will be sent to the component under the 'content' attribute

=item parent

If the component is a subcomponent it will receive the instance model of its
parent as the 'parent' attribute

=item model

All components get the 'model' attribute, which is the model instance that contains
the template in which they appear.  I would use this carefully since I think that
you would prefer to pass information from the model to the component via attributes.

=back

Components can be an instance of any class that does C<create> and C<process_dom>
but generally you will make your components out of other L<Template::Lace> models
since that provides the most features and template reusability. Components are added to
the Factory at the time you construct it:

    my $factory = Template::Lace::Factory->new(
      model_class=>'Local::Template::List',
      component_handlers=>+{
        layout => sub {
          my ($name, $args, %attrs) = @_;
          $name = ucfirst $name;
          return Template::Lace::Factory->new(model_class=>"Local::Template::$name");
        },
        lace => {
          form => Template::Lace::Factory->new(model_class=>'Local::Template::Form'),
          input => Template::Lace::Factory->new(model_class=>'Local::Template::Input'),
        },
      },
    );

Components are added as a hashref of data associated with the 'component_handlers'
initialization argument for the class L<Template::Lace::Factory>.  You can either
attach a component to a full 'prefix-name' pair, as in the exmples for 'form' and
'input', or you can create a component 'generator' for an entire prefix by associating
the prefix with a coderef which is responsible for returning a component based on the
actual name.  

When the factory is created, it delegates the job of walking the DOM we made from the Model's
template and creating a hierarchy of components actually found.  All found components need to
match something in 'component_handlers' or they will be silently ignored (this is a feature
since if you are using client side web components you would want those to be passed on
without note).  When we call C<create> on the factory we initialize the component
hierarchy by calling C<create> on each factory component present and then when we render
the template we render each component and replace the full component node with th results
of the rendering.

Here's a full example of a template that is a TODO list which contains a list of 
items 'TODO' as well as a form 


-- advananced simple modesl that do create and process_dom

=head1 IMPORTANT NOTE REGARDING VALID HTML

Please note that L<Mojo::DOM58> tends to enforce rule regarding valid HTML5.  For example, you
cannot nest a block level element inside a 'P' element.  This might at times lead to some
surprising results in your output.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Mojo::DOM58>, L<HTML::Zoom>.  Both of these are approaches to programmatically examining and
altering a DOM.

L<Template::Semantic> is a similar system that uses XPATH instead of a CSS inspired matching
specification.  It has more dependencies (including L<XML::LibXML> and doesn't separate the actual
template data from the directives.  You might find this more simple approach appealing, 
so its worth alook.

L<HTML::Seamstress> Seems to also be prior art along these lines but I have trouble following
the code and it seems not active.  Might be worth looking at at least for ideas!

L<Template::Lace> A previous work of my along the same lines but based on pure.js 
L<http://beebole.com/pure/>.

L<PLift>, uses L<XML::LibXML>.

L<Catalyst::View::Template::Lace> Catalyst adaptor for this with some L<Catalyst> specific
enhancements.
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2017, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
