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
classes (although we will canonically use L<Moo> in these examples, L<Moo> is not a requirement
just a suggestion).  These templates are fully HTML markup only; they contain no display logic,
only valid HTML and component declarations.  We use L<Template::Lace::DOM> (which is a subclass
of L<Mojo::DOM58>) to alter the template for presentation at request time.  L<Template::Lace::DOM>
provides an API to transform the template.  We call this a Model class.  For a Perl class to be
considered Model class it should provide the interface defined by L<Template::Lace::ModelRole>.
Generally if you are using L<Moo> or L<Moose> you should consume this role (athough strictly
speaking that isn't necessary as long as your class provides the minimal interface.)  Here's
an example of a very simple Model class:

    package  MyApp::View::User;

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
just needs to return a string.  It should contain your desired markup.  The C<process_dom> method
is an instance method on your class, and it gets both C<$self> and C<$dom>, where C<$dom> is a
DOM representation of your template (via L<Template::Lace::DOM>).  Anything you want to change about
the template should be done via the L<Template::Lace::DOM> API.  This is a subclass of L<Mojo::DOM58>
a Jquery like API for transforming HTML.  Our custom subclass contains some additional helper methods
to make common types of transforms easier.  For example here we use the custom helper C<dl> to find
a C<dl> tag by its id and then populate its data by matching hash keys to tag ids.

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
