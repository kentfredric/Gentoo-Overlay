use strict;
use warnings;

package Gentoo::Overlay::Types;

BEGIN {
  $Gentoo::Overlay::Types::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Overlay::Types::VERSION = '1.0.2';
}

# ABSTRACT: Gentoo Overlay types.

use MooseX::Types -declare => [
  qw(
    Gentoo__Overlay_Overlay
    Gentoo__Overlay_Category
    Gentoo__Overlay_Ebuild
    Gentoo__Overlay_Package
    Gentoo__Overlay_CategoryName
    Gentoo__Overlay_EbuildName
    Gentoo__Overlay_PackageName
    Gentoo__Overlay_RepositoryName
    )
];
use MooseX::Types::Moose qw( :all );

class_type Gentoo__Overlay_Overlay, { class => 'Gentoo::Overlay' };
coerce Gentoo__Overlay_Overlay, from Str, via {
  require Gentoo::Overlay;
  return Gentoo::Overlay->new( path => $_ );
};

class_type Gentoo__Overlay_Category, { class => 'Gentoo::Overlay::Category' };

class_type Gentoo__Overlay_Ebuild, { class => 'Gentoo::Overlay::Ebuild' };

class_type Gentoo__Overlay_Package, { class => 'Gentoo::Overlay::Package' };

subtype Gentoo__Overlay_CategoryName, as Str, where {
## no critic ( RegularExpressions )
  $_ =~ qr/^[a-zA-Z0-9+_.-]+$/
    && $_ !~ qr/^[-.]/;
};

subtype Gentoo__Overlay_EbuildName, as Str, where {
  ## no critic ( RegularExpressions )
       $_ =~ qr/^[A-Za-z0-9+_.-]+$/
    && $_ !~ qr/^-/
    && $_ !~ qr/-$/
    && $_ =~ qr/\.ebuild$/;
};

subtype Gentoo__Overlay_PackageName, as Str, where {
  ## no critic ( RegularExpressions )
       $_ =~ qr/^[A-Za-z0-9+_-]+$/
    && $_ !~ qr/^-/
    && $_ !~ qr/-$/
    && $_ !~ qr/-\d+$/;
};

subtype Gentoo__Overlay_RepositoryName, as Str, where {
## no critic ( RegularExpressions )

  $_ =~ qr/^[A-Za-z0-9_-]+$/
    && $_ !~ qr/^-/;
};

1;

__END__

=pod

=head1 NAME

Gentoo::Overlay::Types - Gentoo Overlay types.

=head1 VERSION

version 1.0.2

=head1 TYPES

=head2 Gentoo__Overlay_Overlay

    class_type Gentoo::Overlay

    coerces from Str

=head2 Gentoo__Overlay_Category

    class_type Gentoo::Overlay::Category

=head2 Gentoo__Overlay_Ebuild

    class_type Gentoo::Overlay::Ebuild

=head2 Gentoo__Overlay_Package

    class_type Gentoo::Overlay::Package

=head2 Gentoo__Overlay_CategoryName

    Str matching         ^[A-Za-z0-9+_.-]+$
        and not matching ^[-.]

I<A category name may contain any of the characters [A-Za-z0-9+_.-]. It must not begin with a hyphen or a dot.>

=head2 Gentoo__Overlay_EbuildName

    Str matching ^[A-Za-z0-9+_.-]+$
        and not matching ^-
        and not matching -$
        and matching \.ebuild$

I<An ebuild name may contain any of the characters [A-Za-z0-9+_.-]. It must not begin with a hyphen, and must not end in a hyphen.>

=head2 Gentoo__Overlay_PackageName

    Str matching ^[A-Za-z0-9+_-]+$
        and not matching ^-
        and not matching -$
        and not matching -\d+$

I<A package name may contain any of the characters [A-Za-z0-9+_-]. It must not begin with a hyphen, and must not end in a hyphen followed by one or more digits.>

=head2 Gentoo__Overlay_RepositoryName

    Str matching ^[A-Za-z0-9_-]+$
        and not matching ^-

I<A repository name may contain any of the characters [A-Za-z0-9_-]. It must not begin with a hyphen.>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
