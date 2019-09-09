#!/usr/bin/perl

use report;

my $me = new report ;
$me->getparams();
$me->openlogfile();
$me->logentry("start report");

if ($me->{options}{version}) {
	$me->version();
	exit 0;
}
if ($me->{options}{help}) {
	$me->help();
	$me->logentry("help completed exiting program");
	exit 0;
}
exit 1 if $me->parsefieldnames() < 0 ;
if ($me->{options}{showfielddefs}) {
	$me->showfielddefinitions() ;
	exit 0;
}
exit 2 if $me->parsedatafile() < 0;
if ($me->{options}{showrecords}) {
	$me->showrecords(0);
	exit 0;
}
if ($me->{options}{showrecordscsv}) {
	$me->showrecords("csv");
	exit 0;
}
exit 3 if $me->parsecsvspec() < 0;
$me->gathercsvdata();
$me->outputcsvdata();
if ($me->{options}{showfinaltotals}) {
	$me->showfinaltotals() ;
}
if ($me->{options}{dumpvars}) {
	print $me->Dumper($me) ;
}
$me->logentry("end report");
$me->closelogfile() ;

exit 0;


=pod

=head1 NAME:

AMRO Technical Test Program report.pl

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

=head1 MAIN

Calls I<new report> I<see MODULES sub new> then

It executes all the modules in order to produce the required program output.

It runs the processes that establish parameter directions. I<getparams>

It initializes all necessary variables. I<initialize>

It starts the logging process. I<openlogfile>.

and closes the log file with I<closelogfile> before exiting.

=head1 MODULES

=head2 I<sub new>

When a new I<report> object is created this process blesses the B<$me> variable
which contains all the programs private variables to be shared by processes in the
report class or package.  It initializes those variables with their default values.

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

Uses report.pm which uses Time::Local, Getopt::Long, CGI and Data::Dumper.

=cut


