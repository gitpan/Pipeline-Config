use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME          => "Pipeline-Config",
	      VERSION_FROM  => "lib/Pipeline/Config.pm",
	      ABSTRACT_FROM => "lib/Pipeline/Config.pm",
	      PREREQ_PM     => {
			        'Test::More'      => '0.01',
			        'Pipeline'        => '3.01',
			       },
	     );


package MY;

# Enable "make cover" target
sub postamble {
    my $cover_header = 
	"\n" .
	"# --- Customized Makefile.PL test coverage section:\n" .
	"cover:\n";
    if ($^O =~ /win32/i) {
	return $cover_header .
	    "\techo last time I checked, Devel::Cover was not available on Win32\n" .
	    "\n";
    } else {
	return $cover_header .
	    "\t\$(RM_RF) cover_db\n" .
	    "\tPERL5OPT=-MDevel::Cover \$(MAKE) test || true\n" .
	    "\tcover -report html cover_db > /dev/null\n" .
	    "\n";
    }
}

