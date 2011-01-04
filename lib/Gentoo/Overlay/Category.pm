use strict;
use warnings;

package Gentoo::Overlay::Category;

# ABSTRACT: A singular category in a repository;

=head1 SYNOPSIS

Still limited functionality, more to come.

    my $category = ::Overlay::Category->new(
        name => 'dev-perl',
        overlay => '/usr/portage' ,
    );

    my $category = ::Overlay::Category->new(
        name => 'dev-perl',
        overlay => $overlay_object ,
    );

    $category->exists()  # is the category there, is it a directory?

    $category->pretty_name()  #  dev-perl/::gentoo

    $category->path()  # /usr/portage/dev-perl

    ::Overlay::Category->is_blacklisted('..') # is '..' a blacklisted category


=cut

use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Path::Class qw( File Dir );
use MooseX::ClassAttribute;
use Gentoo::Overlay::Types qw( :all );
use IO::Dir;
use namespace::autoclean;

=attr name

The classes short name

    isa => Gentoo__Overlay_CategoryName, required, ro

L<< C<CategoryName>|Gentoo::Overlay::Types/Gentoo__Overlay_CategoryName >>

=cut

=attr overlay

The overlay it is in.

    isa => Gentoo__Overlay_Overlay, required, coerce

L<Gentoo::Overlay::Types/Gentoo__Overlay_Overlay>

=cut

=attr path

The full path to the category

    isa => Dir, lazy_build, ro

L<MooseX::Types::Path::Class/Dir>

=cut

has name => isa => Gentoo__Overlay_CategoryName, required, ro;
has overlay => isa => Gentoo__Overlay_Overlay, required, ro, coerce;
has path => isa => Dir,
  lazy, ro, default => sub {
  my ($self) = shift;
  return $self->overlay->default_path( category => $self->name );
  };

=p_attr _packages

=cut

has _packages => isa => HashRef [Gentoo__Overlay_Package],
  lazy_build, ro,
  traits  => [qw( Hash )],
  handles => {
  _has_package  => exists   =>,
  package_names => keys     =>,
  packages      => elements =>,
  get_package   => get      =>,
  };

sub _build__packages {
  my ($self) = shift;
  require Gentoo::Overlay::Package;
  ## no critic ( ProhibitTies )
  tie my %dir, 'IO::Dir', $self->path->stringify;
  my %out;
  for ( sort keys %dir ) {
    next if Gentoo::Overlay::Package->is_blacklisted($_);
    my $p = Gentoo::Overlay::Package->new(
      name     => $_,
      category => $self,
    );
    next unless $p->exists;
    $out{$_} = $p;
  }
  return \%out;
}

=pc_attr _scan_blacklist

Class-Wide list of blacklisted directory names.

    isa => HashRef[ Str ], ro, lazy_build,

    accessors => _scan_blacklisted

L</_scan_blacklisted>

L<< C<MooseX::Types::Moose>|MooseX::Types::Moose >>

=cut

=pc_attr_acc _scan_blacklisted

is C<$arg> blacklisted in the Class Wide Blacklist?

    ::Category->_scan_blacklisted( $arg )
       ->
    exists ::Category->_scan_blacklist->{$arg}


L</_scan_blacklist>

=cut

class_has _scan_blacklist => isa => HashRef [Str],
  ro, lazy,
  traits  => [qw( Hash )],
  handles => { _scan_blacklisted => exists =>, },
  default => sub {
  return { map { $_ => 1 } qw( metadata profiles distfiles eclass licenses packages scripts . .. ) };
  };

=method exists

Does the category exist, and is it a directory?

    $category->exists();

=cut

## no critic ( ProhibitBuiltinHomonyms )
sub exists {
  my $self = shift;
  return if not -e $self->path;
  return if not -d $self->path;
  return 1;
}

=method is_blacklisted

Does the category name appear on a blacklist meaning auto-scan should ignore this?

    ::Category->is_blacklisted('..') # true

    ::Category->is_blacklisted('metadata') # true

=cut

sub is_blacklisted {
  my ( $self, $name ) = @_;
  if ( not defined $name ) {
    $name = $self->name;
  }
  return $self->_scan_blacklisted($name);
}

=method pretty_name

A pretty form of the name.

    $category->pretty_name  # dev-perl/::gentoo

=cut

sub pretty_name {
  my $self = shift;
  return $self->name . '/::' . $self->overlay->name;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
