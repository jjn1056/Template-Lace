package Template::Lace;

our $VERSION = '0.001';

1;

=head1 NAME

Template::Lace - Logic-less and strongly typed templates, with components

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

    TBD

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
