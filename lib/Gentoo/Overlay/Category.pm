use 5.006;
use strict;
use warnings;

package Gentoo::Overlay::Category;

our $VERSION = '2.001003';

# ABSTRACT: A singular category in a repository;

# AUTHORITY

use Moo 1.006000 qw( has );
use MooseX::Has::Sugar qw( ro required coerce lazy lazy_build );
use Types::Standard qw( HashRef Str );
use Types::Path::Tiny qw( File Dir Path );
use MooX::ClassAttribute qw( class_has );
use MooX::HandlesVia;
use Gentoo::Overlay::Types qw( Gentoo__Overlay_CategoryName Gentoo__Overlay_Package Gentoo__Overlay_Overlay );
use Gentoo::Overlay::Exceptions qw( exception );
use namespace::clean -except => 'meta';

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

    isa => Dir, lazy, ro

L<MooseX::Types::Path::Tiny/Dir>

=cut

has name => ( isa => Gentoo__Overlay_CategoryName, required, ro );
has overlay => ( isa => Gentoo__Overlay_Overlay, required, ro, coerce );
has path => ( lazy, ro,
  isa     => Path,
  default => sub {
    my ($self) = shift;
    return $self->overlay->default_path( category => $self->name );
  },
);

=p_attr _packages

    isa => HashRef[ Gentoo__Overlay_Package ], lazy_build, ro

    accessors => _has_package , package_names,
                 packages, get_package

L</_has_package>

L</package_names>

L</packages>

L</get_package>

=cut

=p_attr_acc _has_package

    $category->_has_package('Moose');

L</_packages>

=cut

=attr_acc package_names

    for( $category->package_names ){
        print $_;
    }

L</_packages>

=cut

=attr_acc packages

    my %packages = $category->packages;

L</_packages>

=cut

=attr_acc get_package

    my $package = $category->get_package('Moose');

L</_packages>

=cut

has _packages => (
  isa => HashRef [Gentoo__Overlay_Package],
  lazy,
  builder => 1,
  ro,
  handles_via => 'Hash',
  handles     => {
    _has_package  => exists   =>,
    package_names => keys     =>,
    packages      => elements =>,
    get_package   => get      =>,
  },
);

=p_method _build__packages

Generates the package Hash-Table, by scanning the category directory.

L</_packages>

=cut

sub _build__packages {
  my ($self) = shift;
  require Gentoo::Overlay::Package;

  my $it = $self->path->iterator();
  my %out;
  while ( defined( my $entry = $it->() ) ) {
    my $package = $entry->basename;
    next if Gentoo::Overlay::Package->is_blacklisted($package);
    my $p = Gentoo::Overlay::Package->new(
      name     => $package,
      category => $self,
    );
    next unless $p->exists;
    $out{$package} = $p;
  }
  return \%out;
}

=pc_attr _scan_blacklist

Class-Wide list of blacklisted directory names.

    isa => HashRef[ Str ], ro, lazy

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

class_has _scan_blacklist => (
  isa => HashRef [Str],
  ro,
  lazy,
  default => sub {
    return { map { $_ => 1 } qw( metadata profiles distfiles eclass licenses packages scripts . .. ) };
  },
);

sub _scan_blacklisted {
  my ( $self, $what ) = @_;
  return exists $self->_scan_blacklist->{$what};
}

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

=method iterate

  $overlay->iterate( $what, sub {
      my ( $context_information ) = shift;

  } );

The iterate method provides a handy way to do walking across the whole tree stopping at each of a given type.

=over 4

=item * C<$what = 'packages'>

  $overlay->iterate( packages => sub {
      my ( $self, $c ) = shift;
      # $c->{package_name}  # String
      # $c->{package}       # Package Object
      # $c->{num_packages}  # How many packages are there to iterate
      # $c->{last_package}  # Index ID of the last package.
      # $c->{package_num}   # Index ID of the current package.
  } );


=item * C<$what = 'ebuilds'>

  $overlay->iterate( ebuilds => sub {
      my ( $self, $c ) = shift;
      # $c->{package_name}  # String
      # $c->{package}       # Package Object
      # $c->{num_packages}  # How many packages are there to iterate
      # $c->{last_package}  # Index ID of the last package.
      # $c->{package_num}   # Index ID of the current package.

      # $c->{ebuild_name}   # String
      # See ::Ebuild for the rest of the fields provided by the ebuild Iterator.
      # Very similar though.
  } );

=back

=cut

sub iterate {
  my ( $self, $what, $callback ) = @_;    ## no critic (Variables::ProhibitUnusedVarsStricter)
  my %method_map = (
    packages => _iterate_packages =>,
    ebuilds  => _iterate_ebuilds  =>,
  );
  if ( exists $method_map{$what} ) {
    goto $self->can( $method_map{$what} );
  }
  return exception(
    ident   => 'bad iteration method',
    message => 'The iteration method %{what_method}s is not a known way to iterate.',
    payload => { what_method => $what, },
  );
}

=p_method _iterate_packages

  $object->_iterate_packages( ignored_value => sub {  } );

Handles dispatch call for

  $object->iterate( packages => sub { } );

=cut

# packages = { /packages }
sub _iterate_packages {
  my ( $self, undef, $callback ) = @_;
  my %packages     = $self->packages();
  my $num_packages = scalar keys %packages;
  my $last_package = $num_packages - 1;
  my $offset       = 0;
  for my $pname ( sort keys %packages ) {
    local $_ = $packages{$pname};
    $self->$callback(
      {
        package_name => $pname,
        package      => $packages{$pname},
        num_packages => $num_packages,
        last_package => $last_package,
        package_num  => $offset,
      }
    );
    $offset++;
  }
  return;

}

=p_method _iterate_ebuilds

  $object->_iterate_ebuilds( ignored_value => sub {  } );

Handles dispatch call for

  $object->iterate( ebuilds => sub { } );

=cut

# ebuilds = { /packages/ebuilds }
sub _iterate_ebuilds {
  my ( $self, undef, $callback ) = @_;
  my $real_callback = sub {

    my (%pconfig) = %{ $_[1] };
    my $inner_callback = sub {
      my %econfig = %{ $_[1] };
      $self->$callback( { ( %pconfig, %econfig ) } );
    };
    $pconfig{package}->_iterate_ebuilds( 'ebuilds' => $inner_callback );
  };
  $self->_iterate_packages( packages => $real_callback );
  return;

}
no Moo;
1;

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
