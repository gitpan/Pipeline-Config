#!/usr/bin/perl

##
## Tests for Pipeline::Config
##

use blib;
use strict;
use warnings;

use Test::More qw( no_plan => 1 );

use Pipeline;

BEGIN { use_ok("Pipeline::Config") }

my $parser = new Pipeline::Config;
ok( $parser, 'new' ) || die "cannot continue\n";

$parser->debug(1);
my $pipe   = $parser->load( 't/conf/config.yaml' );

isa_ok( $pipe, 'Pipeline', 'load yaml config' );

if (isa_ok( my $subpipe = $pipe->segments->[-1], 'Pipeline', 'subpipe' )) {
    isa_ok( my $seg = $subpipe->segments->[-1], 'Test::Segment', 'last seg' );
    is( $seg->{foo}, 'bar', 'foo/bar set' );
}


use Data::Dumper;
print Dumper( $pipe );

package Test::Segment;
use base qw( Pipeline::Segment );
sub foo {
    my $self     = shift;
    $self->{foo} = shift;
 }
