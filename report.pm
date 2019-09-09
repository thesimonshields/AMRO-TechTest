#!/usr/bin/perl
# Author:Simon Shields
# 6th September 2019
#####################################################
#
# System A has produced the file Input.txt, which is a Fixed Width text file that contains the Future Transactions done by client 1234 and 4321.
# 
# Requirements:
# The Business user would like to see the Total Transaction Amount of each unique product they have done for the day
# The Business user would like a program that can read in the Input file and generate a daily summary report
# The Daily summary report should be in CSV format (called Output.csv) with the following specifications
# 
# The CSV has the following Headers
# - Client_Information
# - Product_Information
# - Total_Transaction_Amount
# 
# Client_Information should be a combination of the CLIENT TYPE, CLIENT NUMBER, ACCOUNT NUMBER, SUBACCOUNT NUMBER fields from Input file
# Product_Information should be a combination of the EXCHANGE CODE, PRODUCT GROUP CODE, SYMBOL, EXPIRATION DATE
# Total_Transaction_Amount should be a Net Total of the (QUANTITY LONG - QUANTITY SHORT) values for each client per product
# 
# Notes: Each Record in the input file represents ONE Transaction from the client for a particular product. Please focus on code re-usability. 
# 
# Please submit the following:
# 1. Documentation should include, instruction on how to run the software and any troubleshooting.
# 2. Complete Perl code with unit tests.
# 3. Log file
# 4. Output.csv
# 
# 
# We will be looking at coding style, solution design and reusability.
#
#####################################################

package report ;

use Time::Local ;
use Getopt::Long ;
use CGI ;
use Data::Dumper;

sub new;
sub help;
sub initialize;
sub getparams;
sub parsefieldnames ;
sub showfielddefinitions ;
sub parsedatafile ;
sub showrecords ;
sub parsecsvspec ;
sub gathercsvdata ;
sub outputcsvdata ;
sub openlogfile;
sub logentry;
sub closelogfile;
sub showfinaltotals;

my $VERSION="version 1.01 6Sep2019" ;

sub new
{
	my $proto = shift ;
	my $params = shift ;
	my $class = ref($proto) || $proto;
	my $me = {};
	bless $me, $class;

	$me->initialize();

	return $me;
} # end of new


sub initialize
{
	my $me = shift;
	$me->{debug} = 0;
	$me->{fnfile} = "fieldnames.txt";
	$me->{datafile} = 'Input (2) (2).txt' ;
	$me->{csvspecfile} = "csv-spec.txt";
	$me->{csvsep} = ',';
	$me->{outputfile} = "Output.csv" ;
	$me->{logfile} = "report.log" ;
	$me->{output2both} = 0;
	$me->{Total_Transaction_Amount} = {};
	$me->{version} = $VERSION ;

	return ;
}

sub version 
{ 
	my $me = shift;
	
	printf ("%s\n", $me->{version});

	return $me->{version};
}

sub getparams
{
	my $me = shift;
	my %opts = () ;

	GetOptions(\%opts,
		"help",
		"version",
		"showfielddefs",
		"showrecords",
		"showrecordscsv",
		"output2both",
		"showfinaltotals",
		"dumpvars",
		"debug:i",
		"csvsep:s",
		"fieldnamefile:s",
		"inputdatafile:s",
		"csvspecfile:s",
		"logfile:s",
		"outputfile:s"
	);

	my $cgi = new CGI ;
	my %cgp = $cgi->Vars;
	
	$me->{options}{help} = $opts{help} if $opts{help};
	$me->{options}{dumpvars} = $opts{dumpvars} if $opts{dumpvars};
	$me->{options}{version} = $opts{version} if $opts{version};
	$me->{options}{output2both} = $opts{output2both} if $opts{output2both};
	$me->{options}{debug} = $opts{debug} if $opts{debug};
	$me->{options}{csvsep} = $opts{csvsep} if $opts{csvsep};
	$me->{options}{showrecords} = $opts{showrecords} if $opts{showrecords};
	$me->{options}{showrecordscsv} = $opts{showrecordscsv} if $opts{showrecordscsv};
	$me->{options}{showfinaltotals} = $opts{showfinaltotals} if $opts{showfinaltotals};
	$me->{options}{showfielddefs} = $opts{showfielddefs} if $opts{showfielddefs};
	$me->{options}{fieldnamefile} = $opts{fieldnamefile} if $opts{fieldnamefile};
	$me->{options}{inputdatafile} = $opts{inputdatafile} if $opts{inputdatafile};
	$me->{options}{outputfile} = $opts{outputfile} if $opts{outputfile};
	$me->{options}{csvspecfile} = $opts{csvspecfile} if $opts{csvspecfile};
	$me->{options}{logfile} = $opts{logfile} if $opts{logfile};

	$me->{options}{help} = $cgp{help} if $cgp{help};
	$me->{options}{dumpvars} = $cgp{dumpvars} if $cgp{dumpvars};
	$me->{options}{version} = $cgp{version} if $cgp{version};
	$me->{options}{debug} = $cgp{debug} if $cgp{debug};
	$me->{options}{csvsep} = $cgp{csvsep} if $cgp{csvsep};
	$me->{options}{output2both} = $cgp{output2both} if $cgp{output2both};
	$me->{options}{showrecords} = $cgp{showrecords} if $cgp{showrecords};
	$me->{options}{showrecordscsv} = $cgp{showrecordscsv} if $cgp{showrecordscsv};
	$me->{options}{showfinaltotals} = $cgp{showfinaltotals} if $cgp{showfinaltotals};
	$me->{options}{showfielddefs} = $cgp{showfielddefs} if $cgp{showfielddefs};
	$me->{options}{fieldnamefile} = $cgp{fieldnamefile} if $cgp{fieldnamefile};
	$me->{options}{inputdatafile} = $cgp{inputdatafile} if $cgp{inputdatafile};
	$me->{options}{outputfile} = $cgp{outputfile} if $cgp{outputfile};
	$me->{options}{csvspecfile} = $cgp{csvspecfile} if $cgp{csvspecfile};
	$me->{options}{logfile} = $cgp{logfile} if $cgp{logfile};

	$me->{csvsep} = $me->{options}{csvsep} if $me->{options}{csvsep} ;
	if ($me->{options}{fieldnamefile} && -f $me->{options}{fieldnamefile}) {
		$me->{fnfile} = $me->{options}{fieldnamefile} ;
	}
	if ($me->{options}{inputdatafile} && -f $me->{options}{inputdatafile}) {
		$me->{datafile} = $me->{options}{inputdatafile} ;
	}
	if ($me->{options}{csvspecfile} && -f $me->{options}{csvspecfile}) {
		$me->{csvspecfile} = $me->{options}{inputcsvspecfile} ;
	}
	if ($me->{options}{output2both}) {
		$me->{output2both} = 1;
	}
	if ($me->{options}{logfile}) {
		$me->{logfile} = $me->{options}{logfile} ;
	}

	return ;
}

sub help
{
	my $me = shift;
	system 'perldoc report.pm' ;

	return 0;
}

sub parsefieldnames
{
	my $me = shift;
	my $fields = {};
	$me->{fields} = $fields;
	$fields->{_list} = [];
	my $fnfile = $me->{fnfile} ;
	my @e = ();
	my $posi=0;

	$me->logentry("entering parsefieldnames");
	open(FNFILE,"< $fnfile") || do { 
		warn "warning:Can't open fieldnames file=$fnfile for reading : $!\n" ; 
		$me->logentry("exiting parsefieldnames after failing to open fnfile [$fnfile] : $!");
		return -1 ;
	};

	while (<FNFILE>) 
	{
		chomp;
		@e = split(/,/, $_);
		$fields->{$e[0]}{len} = $e[1];
		$fields->{$e[0]}{start} = $posi;
		$fields->{$e[0]}{finish} = $posi + $e[1] - 1;
		push(@{$fields->{_list}}, $e[0]) ;
		$posi += $e[1];
	}

	close (FNFILE);
	$me->logentry("exiting parsefieldnames");

	return 0 ;
}

sub showfielddefinitions
{
	my $me = shift;
	my $fields = $me->{fields};

	$me->logentry("entering showfielddefinitions");
	print "fieldname, len, start, finish\n";
	foreach my $fn (@{$fields->{_list}})
	{
		my $field = $fields->{$fn};
		printf("%s,%d,%d,%d\n", $fn, $field->{len}, $field->{start}, $field->{finish});
	}
	$me->logentry("exiting showfielddefinitions");

	return 0;
}

sub parsedatafile
{
	my $me = shift;
	my $fields = $me->{fields};
	my $datafile = $me->{datafile} ;

	$me->logentry("entering parsedatafile");
	open(DATAFILE, "< $datafile") || do {
		warn "warning:Can't open datafile=$datafile for reading : $!\n" ; 
		$me->logentry("exiting parsedatafile after failing to open datafile [$datafile] : $!");
		return -1;
	};

	my $records = [];
	$me->{records} = $records ;

	while (<DATAFILE>)
	{
		chomp;
		$_ =~ s/\cM//g;
		my $record = {};
		$record->{_list} = [];
		foreach my $fn (@{$fields->{_list}})
		{
			my $field = $fields->{$fn};
			$record->{$fn} = substr($_, $field->{start}, $field->{len}) ;
			push(@{$record->{_list}},  $record->{$fn}) ;
		}
		push(@{$records}, $record) ;
	}
	close (DATAFILE);

	$me->logentry("exiting parsedatafile");
	return 0;
}

sub showrecords
{
	my $me = shift;
	my $csv = shift;
	my $csvsep = $me->{csvsep};
	my $recno=1;
	my $records = $me->{records} ;
	my $fields = $me->{fields} ;

	$me->logentry("entering showrecords " . $csv);
	if ($csv) {
		print join($csvsep, @{$fields->{_list}}), "\n";
	}
	foreach $record (@{$records}) 
	{
		if ($csv) {
			print join($csvsep, @{$record->{_list}}), "\n";
		} else {
			foreach my $fn (@{$fields->{_list}})
			{
				printf("recno %d %s=%s\n", $recno, $fn, $record->{$fn}) ;
			}
		}
		$recno++;
	}
	$me->logentry("exiting showrecords");

	return 0;
}

sub parsecsvspec
{
	my $me = shift;
	my $records = $me->{records} ;
	my $fields = $me->{fields} ;
	my $csvspecfile = $me->{csvspecfile} ;

	$me->logentry("entering parsecsvspec");
	open(CSVSPEC,"< $csvspecfile") || do {
		my $warnmsg = sprintf( "warning:Can't open csvspecfile=$csvspecfile for reading : $!\n" ); 
		warn $warnmsg;
		$me->logentry("parsecsvspec:" . $warnmsg);

		return -1 ;
	};

	my $csvspec = {};
	$csvspec->{_list} = [];
	$me->{csvspec} = $csvspec ;

	while (<CSVSPEC>) 
	{
		chomp ;
		my @e = split(/=/,$_) ;
		push(@{$csvspec->{_list}}, $e[0]) ;
		$csvspec->{$e[0]} = [];
		if ($e[1] =~ /,/) {
			foreach $fn (split(/,/,$e[1])) {
				push(@{$csvspec->{$e[0]}}, $fn ) ;
			}
		} else {
			push(@{$csvspec->{$e[0]}}, $e[1] ) ;
		}
	}
	close(CSVSPEC);
	my $keyfields = $csvspec->{Total_Transaction_Keyfields} ;
	foreach my $record (@{$records}) 
	{
		my $totaltransactionamt_key = '';
		foreach my $keyfield (@{$keyfields}) {
			$totaltransactionamt_key .= $record->{$keyfield} ;
		}
		$me->{Total_Transaction_Amount}{$totaltransactionamt_key} = 0;
	}
	$me->logentry("exiting parsecsvspec");

	return 0;
}

sub gathercsvdata
{
	my $me = shift;
	my $records = $me->{records} ;
	my $fields = $me->{fields} ;
	my $csvspec = $me->{csvspec} ;
	my $debug = $me->{debug} ;

	$me->logentry("entering gathercsvdata");
	my $csvrecords = [];
	$me->{csvrecords} = $csvrecords ;

	my $recno=1;
	my $csvsep = $me->{csvsep};
	my $keyfields = $csvspec->{Total_Transaction_Keyfields} ;

	foreach my $record (@{$records}) 
	{
		my $csvrecord = {};
		foreach my $csvfn (@{$csvspec->{_list}}[0..$#{$csvspec->{_list}}-3]) {
			$csvrecord->{$csvfn} = '';
			foreach my $fn (@{$csvspec->{$csvfn}}) {
				$csvrecord->{$csvfn} .= $record->{$fn} ;
				if ($debug==3) {
					warn("debug=%d csvfn=%s fn=%s v=%s\n", $debug,$csvfn,$fn,$record->{$fn}) ;
				}
			}
		}

		my $fn = $csvspec->{Total_Transaction_Amount}[0] ;
		$csvrecord->{Total_Transaction_Amount} = $record->{$fn} ;
		foreach $fn (@{$csvspec->{Total_Transaction_Amount}}[1..$#{$csvspec->{Total_Transaction_Amount}}]) 
		{
			if ($csvspec->{operation}[0] eq 'subtract') { 
				$csvrecord->{Total_Transaction_Amount} -= $record->{$fn} ;
			} else {
				$csvrecord->{Total_Transaction_Amount} += $record->{$fn} ;
			}
		}
		my $totaltransactionamt_key = '';
		foreach my $keyfield (@{$keyfields}) {
			$totaltransactionamt_key .= $record->{$keyfield} ;
		}
		$me->{Total_Transaction_Amount}{$totaltransactionamt_key} += $csvrecord->{Total_Transaction_Amount} ;
		$csvrecord->{Total_Transaction_Amount} = $me->{Total_Transaction_Amount}{$totaltransactionamt_key} ;
		$csvrecord->{csvline} = '';
		foreach $csvfn (@{$csvspec->{_list}}[0..$#{$csvspec->{_list}}-2]) {
			$csvrecord->{csvline} .= $csvrecord->{$csvfn} . $csvsep;
			if ($debug==1) {
				warn("csvfn=%s = %s\n", $csvfn, $csvrecord->{$csvfn} ) ;
			}
		}
		chop $csvrecord->{csvline} ;
		push(@{$csvrecords}, $csvrecord) ;
		if ($debug==2) {
			warn("%d %s\n", $recno, $csvrecord->{csvline} ) ;
		}

		$recno++;
	}

	$me->logentry("exiting gathercsvdata");
	return 0;
} # end of sub gathercsvdata

sub outputcsvdata
{
	my $me = shift;
	my $csvspec = $me->{csvspec} ;
	my $csvrecords = $me->{csvrecords} ;
	my $outputfile = $me->{outputfile} ;
	my $csvsep = $me->{csvsep} ;
	my $output = '';
	
	$me->logentry("entering outputcsvdata");
	$output = sprintf("%s\n", join($csvsep,@{$csvspec->{_list}}[0..$#{$csvspec->{_list}}-2])) ;
	# print csv data
	my $recno=1;
	foreach my $csvrecord (sort { $a->{Client_Information} . $a->{Product_Information} cmp $b->{Client_Information} . $b->{Product_Information}} @{$csvrecords}) 
	{
#		$output .= sprintf("%d %s\n", $recno++, $csvrecord->{csvline} ) ;
		$output .= sprintf("%s\n", $csvrecord->{csvline} ) ;
	}
	if (open(OFILE,"> $outputfile")) {
		print OFILE $output ;
		close(OFILE);

		if ($me->{output2both}) {
			print $output ;
		}
	} else {
		warn "warning:Can't open outputfile=$outputfile for writing : $!\n" ; 
		print $output ;
	}
	$me->logentry("exiting outputcsvdata");

	return 0;
}

sub openlogfile
{
	my $me = shift;
	my $logfile = $me->{logfile};
	
	$me->{nologfile} = 0;
	open( LOGFILE, "> $logfile") || do {
		warn "Can't open the log file $logfile $!\n" ;
		$me->{nologfile} = 1;
	} ;
	
	return 0;
}

sub logentry
{
	my $me = shift;
	my $msg = shift;
	my @date = localtime time ;
	my $prepmsg = sprintf ("%4d%02d%02d-%02d%02d%02d:-%s\n",1900+$date[5],$date[4]+1,$date[3],$date[2],$date[1],$date[0],$msg) ;

	if (! $me->{nologfile}) {
		print LOGFILE $prepmsg ;
	}

	return 0;
}

sub closelogfile
{
	my $me = shift;

	if (! $me->{nologfile}) {
		close(LOGFILE) ;
	}
	
	return 0;
}

sub showfinaltotals
{
	my $me = shift;
	my $csvsep = $me->{csvsep} ;

	my $finaltotals =<<EOF ;
Final Total Transaction Amounts
EOF
	$finaltotals .= join($csvsep, sort keys %{$me->{Total_Transaction_Amount}}) . "\n" ;
	foreach my $k (sort keys %{$me->{Total_Transaction_Amount}}) {
		$finaltotals .= $me->{Total_Transaction_Amount}{$k} . $csvsep ;
	}
	chop $finaltotals ;
	$finaltotals .= "\n" ;
	$me->{finaltotals} = $finaltotals ;
	print $finaltotals ;

	return 0;
}

=pod

=head1 NAME:

AMRO Technical Test Program PACKAGE report.pm

=head1 PREAMBLE:

This program creates a csv file according to the requirements specified in the csv specification text file and from fixed string length data file and field names specification file. 

=head1 PROGRAM SPECIFICATIONS

 System A has produced the file Input.txt, which is a Fixed Width text file that contains the Future Transactions done by client 1234 and 4321.
 
 Requirements:
 The Business user would like to see the Total Transaction Amount of each unique product they have done for the day
 The Business user would like a program that can read in the Input file and generate a daily summary report
 The Daily summary report should be in CSV format (called Output.csv) with the following specifications
 
 The CSV has the following Headers
 - Client_Information
 - Product_Information
 - Total_Transaction_Amount
 
 Client_Information should be a combination of the CLIENT TYPE, CLIENT NUMBER, ACCOUNT NUMBER, SUBACCOUNT NUMBER fields from Input file
 Product_Information should be a combination of the EXCHANGE CODE, PRODUCT GROUP CODE, SYMBOL, EXPIRATION DATE
 Total_Transaction_Amount should be a Net Total of the (QUANTITY LONG - QUANTITY SHORT) values for each client per product
 
 Notes: Each Record in the input file represents ONE Transaction from the client for a particular product. Please focus on code re-usability. 
 
 Please submit the following:
 1. Documentation should include, instruction on how to run the software and any troubleshooting.
 2. Complete Perl code with unit tests.
 3. Log file
 4. Output.csv
 
 
 We will be looking at coding style, solution design and reusability.


=head1 AUTHOR

 Simon Shields
 thesimonshields@gmail.com
 0491 269 068

=head1 VERSION

1.01 6Sep2019

=head1 OPTIONS

=over 3

=item 1. 

B<-help> - print this help information to stdout and quit,

=item 2. 

B<-version> - print the software version information to stdout and quit,

=item 3.

B<-showfielddefs> - print field definitions to stdout after the field definitions file has been parsed.
Do this to check that any changes made to the field definitions file have been correctly parsed. Then exit the program.

=item 4.

B<-showrecords> - print field names and values to stdout for every record in the data file parsed using the
field definitions in the field definitions text file in Name equals Value Pairs (NVP) format. Then exit the program.

=item 5.

B<-showrecordscsv> - print field names and values to stdout for every record in the data file parsed using the
field definitions in the field definitions text file in CSV format. Then exit the program.

=item 6.

B<-output2both> - Output the final csv file to stdout as well as the output file.

=item 7.

B<-showfinaltotals> - print Final Total_Transaction_Amount's and keys, on separate line, to stdout
after the csv data has been output.

=item 8.

B<-dumpvars> - Use this option for debugging purposes to see what the values in the programs associative arrays
are to help establish the veracity of the programs integrity and locate process errors. Dumps the contents
of the program to stdout after processing is complete.

=item 9.

B<-debug> I<[1|2|3]> - expects an integer value. Only 1,2 or 3 will produce output 

=over 3

=item 1.

B<-debug 1> - prints csv fieldname's and value being gathered during the I<gathercsvdata> process,

=item 2.

B<-debug 2> - prints csv record number and line output being gathered during the I<gathercsvdata> process,

=item 3. 

B<-debug 3> - prints csv fieldname, record fieldname and record value being gathered during the I<gathercsvdata> process,

=back

=item 9.

B<-csvsep [,]> -expects a character the default is a coma I<,>. It is the csv field separator character for output only.
The program assumes a ',' for the csv input files.

=item 10.

B<-fieldnamefile> I<[fieldnames.txt]> - expects a string, the default is I<fieldnames.txt>. It is the text file
containing the fieldnames and the lengths of their values in order in csv comma separated variable, format.

=item 11.

B<-inputdatafile> I<[Input (2) (2).txt]> - expects a string, the default is I<Input (2) (2).txt>. It is the data file
containing all the records with the field values to be parsed and consolidated into csv fields and output in csv
format.

=item 12.

B<-csvspecfile> I<[csv-spec.txt]> - expects a string, the default is I<csv-spec.txt>. 

=item 13.

B<-logfile> I<[report.log]> - expects a string, the default is I<report.log>. It is the program's log file which is
rewritten every time the program runs. The log file will contain any error messages if the program exits early
which will occur if any of it's input files can't be read or opened for reading or it's output files can't be 
opened for writing. All modules that are invoked are logged on entry and exit with a date and time stamp.

=item 14.

B<-outputfile> I<Output.csv> - expects a string,the default is I<Output.csv>, and is the name of the output
file to contain the csv records created by the program.


=back

=head1 MODULES

=head2 I<sub new>

When a new I<report> object is created this process blesses the B<$me> variable
which contains all the programs private variables to be shared by processes in the
report class or package. It initializes those variables with their default values.


=head2 I<sub initialize>

This process initializes all the default values. 

=head2 I<sub version>

Prints programs version details to stdout and returns the version information to the calling process

=head2 I<sub getparams>

Processes the command line or CGI parameter values and puts the results in the I<$me-{options}> associative array.
Input files for reading are checked for existence using the I<-f> perl file internal operator before being accepted
into the I<options> associative array.

=head2 I<sub help>

runs B<perldoc report.pm> displaying this file.

=head2 I<sub parsefieldnames>

Creates log entries on entering and leaving the module.
Splits fields in the fieldnames specification file for each line using a comma as the separator. Stores the field name,length and
calculated start and finish string positions in the I<$me-{fields}> associative array.
Stores the field names in an array in their file order in the I<$me-{fields}{_list}> variable.

=head2 I<sub showfielddefinitions>

Creates log entries on entering and leaving the module. Displays the contents of the I<$me-{fields}> associative array.

=head2 I<sub parsedatafile>

Creates log entries on entering and leaving the module.
Uses I<$me-{fields}> associated array created in the previous process and the contents of the data file to fill the new associative
array  I<$me-{records}> with the data file broken into individual fields and their associative values.

=head2 I<sub showrecords>

Prints the contents of the I<$me-{records}> associative array created in the I<sub parsedatafile> process. It has 1 possible parameter B<csv>. If B<csv> is I<0> records are displayed in NVP (Name equals Value pairs format) otherwise records are shown in CSV format.

=head2 I<sub parsecsvspec>

Fills the new associative array I<$me-{csvspecfile}> with the information encapsulated in the csv specifications file.
The csv specifications file is formatted as follows

 csvfieldname1=datafieldname1,datafieldname2,.....
 csvfieldname2=datafieldname1,datafieldname2,.....
 csvfieldname3=datafieldname1,datafieldname2,.....
 ...
 Total_Transaction_Amount=datafieldname1,datafieldname2,.....
 operation=I<[subtract|add]>
 Total_Transaction_Keyfields=datafieldname1,datafieldname2,.....

The B<operation> value tells the program how to calculate the B<Total_Transaction_Amount> for each data record. If  B<operation>
is I<subtract> then B<Total_Transaction_Amount> = datafieldname1+datafieldname2+datafieldname3.... if B<operation> is not I<subtract>
then B<Total_Transaction_Amount> = datafieldname1-datafieldname2-datafieldname3....

The specifications dictate B<Total_Transaction_Amount> is the sum for client and product. It doesn't specify which data fields to
distinguish client and product so these data fields were chosen by default but can be modified B<CLIENT_NUMBER,PRODUCT_GROUP_CODE,SYMBOL>.

Thus the B<Total_Transaction_Amount> key definition is specified in the B<Total_Transaction_Keyfields> value which by default is
B<CLIENT_NUMBER,PRODUCT_GROUP_CODE,SYMBOL>.

The summation variables are initialized to 0 by runnung through all the records and finding the set of unique keys.

=head2 I<sub gathercsvdata>

This process gather's the information gleaned from the other subroutines to format the report output for all the data records in
I<$me-{records}>.

The report output is stored in the I<$me-{csvrecords}> associative array.

=head2 I<sub outputcsvdata>

Uses  I<$me-{csvrecords}> associative array sorted on B<Client_Information> and B<Product_Information> to format the output string and B<output> the string 
to the B<output file> default I<Output.csv> and stdout if requested via the B<-output2both>
command line option.

=head2 I<sub openlogfile>

opens the log file default I<report.log>. Log file handle is I<LOGFILE>.

=head2 I<sub logentry>

Creates an entry in the log file with a date time stamp. 

E.g. 
 20190907-202520:-start report
 YYYYMMDD-HHMMSS:- I<Message sent as a parameter>

=head2 I<sub closelogfile>

Closes the log file called from the master program 

e.g.
my $report = new report ;
$report->closelogfile() ;


=head2 I<sub showfinaltotals>

Show the summed Total Transaction Amounts based on the data records selected as the key
fields to delineate client and product.

e.g.

 Final Total Transaction Amounts
 CL  123400020001SGX FUNK    20100910,CL  123400030001CME FUN1    20100910,CL  123400030001CME FUNK.   20100910,CL  432100020001SGX FUNK    20100910,CL  432100030001CME FUN1    20100910
 -52,285,-215,46,-79

=head1 I<FILE FORMATS>

=head2 I<INPUT FILES>

=over 3

=item 1.

B<inputdatafile> - Must be a fixed length text file where each line has one record composed of fixed length fields without any field separating characters.
Especially no B<Ctrl> characters.

=item 2.

B<fieldnamefile> - Must be in data field order (the order fields appear in each record in the fixed length data file) comma separated variable B<csv> format, the first field is the name of the data field the second is it's length.

e.g.

 RECORD_CODE,3
 CLIENT_TYPE,4
 CLIENT_NUMBER,4

=item 3.

B<csvspecfile> - It contains the names of the csv fields and what data field values each csv field will be composed of. It also specifies how the 
B<Total_Transaction_Amount> is to be computed (what data fields to add or subtract per data record) and what
data fields are used to create the key field based on the client and product. 
The key field by default is set by default to all the fields for client and product.
 I<CLIENT_TYPE,CLIENT_NUMBER,ACCOUNT_NUMBER,SUBACCOUNT_NUMBER,EXCHANGE_CODE,PRODUCT_GROUP_CODE,SYMBOL,EXPIRATION_DATE>. 

This is defined in the specifications as follows :-

B<Total_Transaction_Amount should be a Net Total of the (QUANTITY LONG - QUANTITY SHORT) values for each> I<client> per I<product>.

The key field needs to include all the fields for Client and product.

e.g.

 Client_Information=CLIENT_TYPE,CLIENT_NUMBER,ACCOUNT_NUMBER,SUBACCOUNT_NUMBER
 Product_Information=EXCHANGE_CODE,PRODUCT_GROUP_CODE,SYMBOL,EXPIRATION_DATE
 Total_Transaction_Amount=QUANTITY_LONG,QUANTITY_SHORT
 operation=subtract
 Total_Transaction_Keyfields=CLIENT_TYPE,CLIENT_NUMBER,ACCOUNT_NUMBER,SUBACCOUNT_NUMBER,EXCHANGE_CODE,PRODUCT_GROUP_CODE,SYMBOL,EXPIRATION_DATE


=back

=head2 I<OUTPUT FILES>

=over 3

=item 1.

B<logfile> - Is a text file containing log entries made by the program reporting it's
execution process. Each line is date and time stamped. The data/time stamp is separated
by a B<:> with the message text.

e.g.
 20190907-204753:-start report
 20190907-204753:-entering parsefieldnames

=item 2.

B<outputfile> - This file contains the program's Daily summary report as specified in the above 
B<PROGRAM SPECIFICATIONS> above. A B<CSV> formatted file default name of B<Output.csv> with the headers
 - Client_Information
 - Product_Information
 - Total_Transaction_Amount

e.g.

 Client_Information,Product_Information,Total_Transaction_Amount
 1 CL  432100020001,SGX FUNK    20100910,1
 2 CL  432100020001,SGX FUNK    20100910,2
 3 CL  432100020001,SGX FUNK    20100910,3

=back

=head1 I<TROUBLESHOOTING>

=over 3

=item 1.

Clean data files of escape and control characters particularly B<Ctrl-M> which often appears in Windows based text files.

=item 2.

Do a I<dos2unix> conversion converting carriage return line feed end of line characters to line feeds only.

=item 3.

Make sure file format's specified in I<file format file> is accurate for the data file.

=item 4.

Fieldname's cannot be called B<_list>

=back

=head1 I<RESERVED WORDS>

B<Words used in the program's data strctures.>

=over 3

=item 1. B<_list> - used in data structures B<records, fields>

=item 2. B<operation> - used in B<sub gathercsvdata>

=item 3. B<subtract> - used in B<sub gathercsvdata>

=item 4. B<Total_Transaction_Amount> - used in B<sub parsecsvspec>

=item 5. B<Total_Transaction_Keyfields> - used in B<sub parsecsvspec>

=item 6. B<Client_Information>, B<Product_Information> used to sort the final output in B<sub outputcsvdata>.

=back

=head1 I<DEPENDENCIES>

Uses Time::Local, Getopt::Long, CGI and Data::Dumper.


=cut


1;
