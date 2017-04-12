#!usr/bin/perl

use strict;
use warnings;
use XML::Twig

# The purpose of this app is to convert TBX-Basic files into the newest standard of TBX
# using the XML parser XML Twig. 
#
# There ability to convert TBX-Min files is also functional
#
# The App may be run silently with no commands or with prompts
#
# The order for command line input is perl <perlscript> <filename> <option1> <option2>
# Usable options: -s == Run silently


my $input_filehandle;
my $check = 0;
my $elt;


if (@ARGV > 1) {
	
	if ($ARGV[1] eq "-s") 
	{
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
	print "Usage: $0 <input file name> <options> \n";
	print "\tOPTIONS:\n";
	print "\t\t-s\tRun Silently with no User Interface prompts\n\n";
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
	
my $tbxMinFlag;
my $printfile;
my $twig_instance = XML::Twig->new(

pretty_print => 'indented',
twig_handlers => {
	
	# Changes for older TBX-Min files
	
	entry => sub { $_->set_tag( 'termEntry' ) },
	
	langGroup => sub { $_->set_tag( 'langSet' ) },
	
	termGroup => sub { $_->set_tag( 'termSec' ) },
	
	# Replace tags with updated names
				
	TBX => sub {	my ($twig,$elt) = @_;
					$tbxMinFlag = $elt->att("dialect");
					$_->set_tag( 'tbx' );
					$_->set_att( style => "DCT" ); 
					$_->change_att_name( 'dialect', 'type' );
				},
				
	tbxMin => sub {		my ($twig,$elt) = @_;
						$tbxMinFlag = $elt->att("dialect");
				
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


$twig_instance->parsefile($ARGV[0]);

if (@ARGV == 1)
{
	print "Would you like to save the output to a file? Press (y/n) to continue.\n";
	my $Continue = <STDIN>;
	chomp($Continue); 
	$Continue=~tr/A-Z/a-z/;	
	print "Starting file analysis:\n";
	if($Continue eq 'y')
	{
	
		if($tbxMinFlag eq 'TBX-Min')
		{
			$printfile = "converted_file.tbxm";
		}
		else
		{
			$printfile = "converted_file.tbx";
		}

		unless(open FILE, '>', $printfile)
		{
			die "\nUnable to create $printfile\n";
		}

		$twig_instance->print( \*FILE); 
	}
}
$twig_instance->flush;  

}
