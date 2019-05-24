#!/usr/bin/perl -w
# 2007XMLextract.pl - Metadata extractor perl script for Office 2007 documents
#
# License and legal stuff:
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Original Author: Larry Pesce (larry@pauldotcom.com)
# Modifications: Bruce Barnett http://www.grymoire.com/Security
#
#  - Revision History -
# .001 - Larry -Initial revision
# .002 - Bruce Barnett. Added Archive::Zip. 
# .003 - Bruce Barnett. Handle multiple files and -v.-d options. 
#
#  - Usage - 
#
# perl ./2007XMLextract.pl [-v] [-d] file.docx [file2.docx file3.docx...]
# where
#               -v == verbose (prints each metatag)
#               -d == debug
# This program 
#    1) extracts the docProps/core.xml file form an Office 2007 documents
#       and temporarily stores it in the file core.xml
#    2) Opens the core.xml file, and extracts following data elements
#            dc:creator (Creator)
#            cp:lastModifiedBy (LastModified)
#    3) stores the values and goes to the next file
#    4) At the end, print out all of the unique names found
#

#use lib qw(.); 

use strict;
use Archive::Zip;
use XML::DOM;
use Getopt::Long;
# list of metadata tags we wish to extract. Feel free to add more
my @metadata = ("dc:creator", "cp:lastModifiedBy");
my $i; # Temporary variable

my $xmlfile="core.xml"; # Temporary file
my %names; # list of names found in metafile

my $verbose;
my $debug;
my $file;

GetOptions("verbose" => \$verbose, #--verbose
	       "debug"   => \$debug,   #--debug
	   );

if ($#ARGV <0) {
    printf(STDERR "Usage: $0 [-v] [-d] filename [filenames....]\n");
    exit(1);
  }


foreach $file (@ARGV) {
    $debug && printf("file: '%s'\n", $file);

    my $zip = Archive::Zip->new( $file );
    if (!defined($zip)) {
	  printf(STDERR "unable to open ZIP file '%s'\n", $file);
    } else {
# Extract the core.xml file from the ZIP archive
	  $zip->extractMember("docProps/core.xml",$xmlfile);

	  my $parser = XML::DOM::Parser->new();

# open the newly extracted XML file
	  my $doc = $parser->parsefile($xmlfile);

# look at each of the metadata tags
	  foreach my $coreProperties ($doc->getElementsByTagName('cp:coreProperties')){
		#store the name found in the %names hash table;
    
	    foreach $i (@metadata) {
		  $debug && printf("Getting metadata: '%s'\n", $i);
		  $names{$coreProperties->getElementsByTagName($i)->item(0)
				 ->getFirstChild->getNodeValue}++;
		  $verbose && printf(STDERR "%s:%s=%s\n", 
							 $file, 
							 $i, 
							 $coreProperties->getElementsByTagName($i)->item(0)
							 ->getFirstChild->getNodeValue,
							);
		}
	  }
	  $doc->dispose;
    }
    unlink($xmlfile); # Remove temporary file
}
#Since it's a hash table, we don't need to sort|uniq the values
# We just need to extract the names
for $i (keys %names) {
    printf("%s\n", $i);
}


