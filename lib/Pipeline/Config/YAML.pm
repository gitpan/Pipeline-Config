package Pipeline::Config::YAML;

use strict;
use warnings::register;

use Error;
use Pipeline;
use Pipeline::Config::LoadError;
use Scalar::Util qw( blessed );
use YAML qw( LoadFile Dump );

use base qw( Pipeline::Base );

our $VERSION = (split(/ /, ' $Revision: 1.5 $ '))[2];

sub init {
    my $self = shift;
    $self->{search} = Pipeline::Config::YAML::Search->new;
}

sub load {
    my $self = shift;

    $self->{file} = shift;

    $self->emit( "loading $self->{file}" );
    my $config = LoadFile( $self->{file} );

    return $self->parse( $config );
}

sub parse {
    my $self   = shift;
    my $config = shift;

    $self->{indent} ++;
    $self->emit( "parsing config" );

    $self->{pipe} = new Pipeline;
    $self->parse_hash( $config );

    $self->{indent} --;

    return $self->{pipe};
}

sub parse_hash {
    my $self    = shift;
    my $hash    = shift;
    my $context = shift;

    throw Pipeline::Config::LoadError( "[$hash] is not a hash! context: [$context]!" )
      unless UNIVERSAL::isa( $hash, 'HASH' );

    $self->{indent} ++;
    $self->emit( "parsing hash\t($context)" );

    foreach my $key (keys %$hash) {
	my $context2 = $self->get_context( $key, $context );
	my $val      = $hash->{$key};
	my $type     = ref($val);

	if ($type) {
	    my $parse_method = 'parse_' . lc( $type );
	    $self->$parse_method( $val, $context2 );
	} else {
	    $self->parse_text( $val, $context2 );
	}
    }

    $self->{indent} --;
}

sub parse_array {
    my $self    = shift;
    my $list    = shift;
    my $context = shift;

    throw Pipeline::Config::LoadError( "[$list] is not a list! context: [$context]" )
      unless UNIVERSAL::isa( $list, 'ARRAY' );

    $self->{indent} ++;
    $self->emit( "parsing list\t($context)" );

    foreach my $val (@$list) {
	if (my $type = ref($val)) {
	    my $parse_method = 'parse_' . lc( $type );
	    $self->$parse_method( $val, $context );
	} else {
	    $self->parse_text( $val, $context );
	}
    }

    $self->{indent} --;
}

sub parse_text {
    my $self    = shift;
    my $text    = shift;
    my $context = shift;

    $self->{indent} ++;
    $self->emit( "$text\t($context)" );

    if (blessed( $context )) {
	if ($context->isa( 'Pipeline::Config::YAML::Search' )) {
	    push @{ $context->{packages} }, $text;
	} elsif ($context->isa( 'Pipeline' )) {
	    $context->add_segment( $self->create_segment( $text ) );
	} else {
	    $self->emit( "unknown context: $context" );
	}
    } elsif (ref($context) eq 'CODE') {
	&$context( $text );
    } else {
	$self->emit( "unknown context: $context" );
    }

    $self->{indent} --;

    return $self;
}

sub get_context {
    my $self    = shift;
    my $text    = shift;
    my $context = shift;

    $self->{indent} ++;
    $self->emit( "getting context for $text\t($context)" );

    my $new_context;
    if ($text =~ /^search.packages$/i) {
	$new_context = $self->{search};
    } elsif ($text =~ /^pipeline$/i) {
	$new_context = $self->{pipe};
    } elsif ($text =~ /^(.+) pipe$/i) {
	$new_context = $self->create_pipe($1);
	if (blessed( $context ) and $context->isa( 'Pipeline' )) {
	    $context->add_segment( $new_context );
	}
    } else {
	if (blessed( $context )) {
	    if ($context->isa( 'Pipeline' )) {
		$new_context = $self->create_segment($text);
		$context->add_segment( $new_context );
	    } elsif ($context->isa( 'Pipeline::Segment' )) {
		$new_context = sub { $context->$text( @_ ) };
	    } else {
		$new_context = $text;
	    }
	} else {
	    $new_context = $text;
	}
    }

    return $new_context;
}

sub create_pipe {
    my $self       = shift;
    my $pipe_class = shift;
    # TODO: load $pipe_class, or create it
    return Pipeline->new;
}

sub create_segment {
    my $self      = shift;
    my $seg_class = shift;
    my @args      = @_;

    $self->{indent} ++;
    $self->emit( "creating new $seg_class" );

    unless (UNIVERSAL::can( $seg_class, 'new' )) {
	eval "require $seg_class";
	throw Pipeline::Config::LoadError( "Error loading class [$seg_class]: $@" ) if ($@);
    }

    $self->{indent} --;
    return $seg_class->new( @args );
}

sub emit {
    my $self = shift;
    $self->SUPER::emit( ' ' x ($self->{indent}*2) . join('', @_) );
}


package Pipeline::Config::YAML::Search;

use base qw( Pipeline::Base );

1;

__END__
