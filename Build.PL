#!/usr/bin/perl

=head1 NAME

Build.PL - Build script generator for Pipeline::Config

=head1 SYNOPSIS

 perl Build.PL
 ./Build test
 ./Build install

=cut

use lib 'lib';
use strict;
use warnings;
use File::Spec;
use Module::Build;

my $build = Module::Build->new
  (
   module_name        => 'Pipeline::Config',
   dist_version_from  => 'lib/Pipeline/Config.pm',
   create_makefile_pl => 'passthrough',
   license            => 'perl',
   build_requires     => {
			  'Test::More' => '0.01',
			  'Module::Build' => '0.19',
		         },
   recommends         => {
			  'YAML'              => '0.35',
		         },
  );

$build->create_build_script;


__END__

=head1 VERSION

$Id: Build.PL,v 1.1 2003/07/31 10:33:33 spurkis Exp $

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=cut

