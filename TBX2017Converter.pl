#!usr/bin/perl

use strict;
use warnings;
use XML::Twig

# The purpose of this app is to convert TBX-Basic files into the newest standard of TBX
# using the XML parser XML Twig. 
#
# There ability to convert TBX-Min files is also currently implemented and undergoing testing.
#
# The App may be run silently with no commands or with prompts
#
# The order for command line input is perl <perlscript> <filename> <option1> <option2>
# Usable options: -s -> Run silently, -tbxm -> file is a .tbxm file (must be used with the -s option)
#

# Option to run silently or with command prompt interface


my $input_filehandle;
my $dialect;
my $check = 0;
my $elt;


if (@ARGV > 1) {
	
	if ($ARGV[1] eq "-s") 
	{
		$dialect = $ARGV[2];
		my $input_filehandle = get_filehandle($ARGV[0]);
		mode2($input_filehandle);
	}
	else 
	{
		print_instructions();
	}
}
elsif (@ARGV == 1)
{
	my $input_filehandle = get_filehandle($ARGV[0]);
	mode1($input_filehandle);	
	
	print "The conversion is complete!\n"
}
else 
{
	print_instructions();
}

sub get_filehandle
{
	my ($input) = @_;
    my $fh;
	
	open $fh, '<', $input;

    return $fh;
}

sub print_instructions
{
	print "Usage: $0 <input file name> <options> <options>\n";
	print "\tOPTIONS:\n";
	print "\t\t-s\tRun Silently with no User Interface prompts\n\t\t-tbxm\tConvert a TBX-Min file\n\n";
	exit();
}
### Run with prompts
sub mode1 
{
	my ($fh) = @_;
	
	while(1) {

		print "Press (y) to continue.\n";
		my $Continue = <STDIN>;
		chomp($Continue); 
		$Continue=~tr/A-Z/a-z/;

		unless($Continue eq 'y') {next}

		last
	}

	print "What type of file is being converted? Please enter tbx or tbxm: ";
	$dialect = "-" . <STDIN>;
	
	print "Starting file analysis:\n";
	program_bulk($fh);
}

# Run Silently
sub mode2  
{
	my ($fh) = @_;
	program_bulk($fh);
}

# Function for the rest of the program
sub program_bulk
{
	
	
my $printfile;
my $twig_instance = XML::Twig->new(

pretty_print => 'indented',
twig_handlers => {
	
	# Changes for older TBX-Min files
	
	entry => sub { $_->set_tag( 'termEntry' ) },
	
	langGroup => sub { $_->set_tag( 'langSet' ) },
	
	termGroup => sub { $_->set_tag( 'termSec' ) }, #Skip <tig>, straight to new standard
	
	# Replace tags with updated names
				
	TBX => sub {	$_->set_att( style => "DCT" ); 
					$_->change_att_name( 'dialect', 'type' );
				},
				
	martif => sub { $_->set_tag( 'tbx' );
					$_->set_att( style => "DCA" ); 
				},
	
	martifHeader => sub { $_->set_tag( 'tbxHeader' ) },
	
	bpt => sub { $_->set_tag( 'sc' ) },
	
	ept => sub { $_->set_tag( 'ec' ) },
	
	termEntry => sub { $_->set_tag( 'conceptEntry' ) },
	
	langSet => sub { $_->set_tag( 'langSec' ) },
	
	tig => sub { $_->set_tag( 'termSec' ) },
	
	termCompList => sub { $_->set_tag( 'termCompSec' ) },
	
	refObjectList => sub { $_->set_tag( 'refObjectSec' ) },
	
	termComptListSpec => sub { $_->set_tag( 'termCompSecSpec' ) },
	
	# Remove old tags that are no longer used
	
	term => sub {
		    my ($twig, $elt) = @_;
	            my $parent = $elt->parent('ntig');
				
				if(defined($parent))
				{
	            $elt->cut();
	            $elt->paste($parent);  
				}
			},
				
	ntig => sub { $_->set_tag( 'termSec' ) },			
				
	termGrp => sub { $_->delete() },				
	
},

);



$printfile = "converted_termbase.tbx";
if($dialect eq '-tbxm')
{
	$printfile = "converted_termbase.tbxm";
}


unless(open FILE, '>', $printfile) {
	die "\nUnable to create $printfile\n";
}


$twig_instance->parsefile($ARGV[0]);
$twig_instance->print( \*FILE); 
$twig_instance->flush;  

}
