#!/usr/bin/perl

$|++;

# prism-decode.pl - 802.11 protocol decoder for prismdump output. Either specify prismdump capture file or pipe prismdump
# output to script
# Anton T. Rager - 08/17/2001
# Bruce G. Barnett 03/03/2002

# Major changes in speed, functionality
# Options:
#     -v  = Verbose
#     -V  = VeryVerbose
#     -d  = debug
#     -D  = show data packets only
#     -e  = Show MAC layer information
#     -p  = profile/performance (debuggers only)
#     -b  = brief printout
#     -B  = very brief printout
#     -w  = print weak keys only
#     -s #   = print starting at packer number #

use strict;

my $numchars;
my $inchar;
my $x;
my $endpkt;
my $i;
my $frametype;
my $caplen;
my $caplen_val;
my $rptlen;
my $rpt_val;
my $big;
my $pcapformat;
my $pcap_hex;
my $flags;
my $packet;
my $packetcount=0;
my $ms="";
my $ms_val = 0;
my $sec="";
my $sec_val = 0;

my $bytecount = 0;
my $bytesinpacket;

my $src;
my $dst;
my $frag;
my $bssid;
my $ssid;
my $channel;
my $iv;
my @IV;
my ($sec,$min,$hour,$mday,$mon,$year, $wday,$yday,$isdst);
my $err;

# Command line arguments:
my $verbose = 0;
my $veryVerbose = 0;
my $brief = 1;
my $dataonly = 0;
my $debug = 0;
my $veryBrief = 0;
my $profile = 0;
my $weak = 0;
my $printmac = 0; #1 means print MAC-layer address

#my $startcount = 177411;
my $startcount = 1;

sub get1 { # Get 1 byte
  $bytecount++;
  $bytesinpacket--;
  return getc(INFILE);
}
sub Get1 { # Get a byte from the packet (a small buffer)
  # Like getc - but get the bytes from $packet;
  my $byte;
  if (length($packet)>0) {
	$byte=substr($packet,0,1);
	substr($packet,0,1) = "";
	$bytecount++;
	$bytesinpacket--;
	return $byte;
  } else {
	return undef;
  }
}
sub Get { # Like Get1 butr allows you to get any number of byets
  # Like getc - but get the bytes from $packet;
  my $bytes;
  my ($len) = @_;
  if (length($packet)>$len) {
	$bytes=substr($packet,0,$len);
	substr($packet,0,$len) = "";
	$bytecount +=$len;
	$bytesinpacket-=$len;
	return $bytes;
  } else {
	printf("Tried to return %d bytes, but found only %d bytes\n", $len, length($packet));
	$bytecount +=$len;
	$bytesinpacket=0;
	$bytes=$packet;
	$packet="";
	return $bytes;
  }
}
sub parse_header {
  # 1nd 4 bytes: #secs         	
  # 2st 4 bytes: #MS
  # 3rd 4 bytes: caplen
  # 4th 4 bytes: pktlen
  # use caplen value for readahead.
  $src="";
  $dst="";
  $packetcount++;

  $err=read(INFILE,$sec,4);
  $err=read(INFILE,$ms,4);
  #Get actual captured pkt len
  $err=read(INFILE,$caplen,4);
  $err=read(INFILE,$rptlen,4);
  # convert len from char to little endian long.
  if ($big) {
	$caplen_val=unpack('V*', $caplen);
	$rpt_val=unpack('V*', $rptlen);
	$ms_val = unpack('V*', $ms);
	$sec_val = unpack('V*', $sec);
  } else {
	$caplen_val=unpack('N*', $caplen);
	$rpt_val=unpack('N*', $rptlen);
	$ms_val = unpack('N*', $ms);
	$sec_val = unpack('N*', $sec);
  }
  ($sec,$min,$hour,$mday,$mon,$year, $wday,$yday,$isdst) = localtime($sec_val);
  while ($year > 100) {
	$year -= 100;
  }
  if ($packetcount>=$startcount) {
	0 && printf("%s %s %s %s\n",
		   $sec_val, $ms_val, $caplen_val, $rpt_val);
	$veryVerbose && printf("\n[%d] %02d/%02d/%02d %02d:%02d:%02d.%ld, caplen: %ld[%s], rpt: %ld[%s]\n",
		 $packetcount,
		 $mon,$mday,$year,$hour,$min,$sec, $ms_val,
		 $caplen_val,unpack("H*",$caplen),
		 $rpt_val,unpack("H*",$rptlen),
		);
	($brief && !$dataonly) && printf("\n[%d] %02d/%02d/%02d %02d:%02d:%02d.%ld, [%ld]",
		 $packetcount,
		 $mon,$mday,$year,$hour,$min,$sec, $ms_val,
		 $caplen_val
		);
  }
  if ($caplen_val>2000) {
	printf("\nSTRANGE DATA: [%d] %02d/%02d/%02d %02d:%02d:%02d.%ld caplen: %ld[%s], rpt: %ld[%s]\n",
		 $packetcount,
		 $mon,$mday,$year,$hour,$min,$sec, $ms_val,
		 $caplen_val,unpack("H*",$caplen),
		 $rpt_val,unpack("H*",$rptlen),
		);
	printf("SYNC ERROR\n");
	exit 1;
  }
  $bytesinpacket=$caplen_val;
  # Read all of thye bytes in the packet.
  $err=read(INFILE,$packet,$caplen_val);
  #printf(" packet[%d][%s]: %s\n", length($packet), $e, unpack("H*",$packet),);

}


sub printdata {

# print the encryted data
  my $x;
  $x=$bytesinpacket-3;
  my $data = "";
  $verbose && print("\n\tDATA: ");
#  (!$veryBrief) && print(" ",$x);
  my $i;
 if (!$veryBrief || $weak) {
   $data=Get($x);
   printf(" %s", unpack("H*",$data));
 }
}


sub getswitches {

# parse command line arguments
    while ($#ARGV > 0 && $ARGV[0] =~ /^-/) {
# verbose
	$ARGV[0] =~ /^-v/ && ($verbose++,$brief=0,shift(@ARGV),next);
# Veryverbose
	$ARGV[0] =~ /^-V/ && ($veryVerbose++,shift(@ARGV),next);
# debug  flag
	$ARGV[0] =~ /^-d/ && ($debug++,shift(@ARGV),next);
# DATA only  flag
	$ARGV[0] =~ /^-D/ && ($dataonly++,$verbose=0,$brief=0,shift(@ARGV),next);
# show MAC address  flag
	$ARGV[0] =~ /^-e/ && ($printmac++,shift(@ARGV),next);
# profile  flag
	$ARGV[0] =~ /^-p/ && ($profile++,$verbose=0,shift(@ARGV),next);
# brief  flag
	$ARGV[0] =~ /^-b/ && ($brief++,$veryBrief=0,$weak=0,$verbose=0,shift(@ARGV),next);
# Very Brief flag
	$ARGV[0] =~ /^-B/ && ($veryBrief++,$brief=0,$weak=0,shift(@ARGV),next);
# WEAK KEYS ONLY
	$ARGV[0] =~ /^-w/ && ($weak++,$veryBrief++,$brief=0,shift(@ARGV),next);
#start
	$ARGV[0] =~ /^-s/ && (shift(@ARGV),$startcount = shift(@ARGV),next);
	$ARGV[0] =~ /^-/ && (printf(STDERR "Ignoring option: '%s'\n", $ARGV[0]),next);
	last;
    }

}

&getswitches(); # get command line arguments

if ($profile) {
  eval "use Devel::DProf";
}

my $pcapfile=@ARGV[0];
if ($pcapfile) {
	if (!-f $pcapfile) {
		die("File not found\n");
	}
 	open(INFILE, $pcapfile);
} else {
	open(INFILE, "-");
}


# Look to see if valid pcap file and determine Endian-ness
for ($i=0; $i<4; $i++) {
	$inchar=&get1();
	$pcapformat=$pcapformat . $inchar;
}
$pcap_hex=unpack('H*', $pcapformat);
$verbose && print("\n\nPcap Header : $pcap_hex\n");

if ($pcap_hex eq "d4c3b2a1") {
	$verbose && print("Big Endian\n");
	$big=1;
} elsif ($pcap_hex eq "a1b2c3d4") {
	$verbose && print("Little Endian\n");
	$big=0;
} else {
	die("Not Pcap?\n");
}

my $header="";
# Jump over rest of file header
for ($i=0; $i<20; $i++) {
	$header.=&get1();

}
$verbose && printf("header: %s\n", unpack("h20",$header));
$inchar="";


&parse_header();

while (!eof(INFILE)) {

  if ($packetcount >= $startcount) {
	$verbose && print("\n\n802.11 Header:\n");
	$verbose && print("\n\tFrame CTRL: ");

	$frametype=ord(&Get1());
	$flags=ord(&Get1());

	#print("\n\tDuration: ");
	my $duration=Get(2);

	if ($frametype eq 0x80) {
		&grab_header;
	  $verbose && print("\n\tBeacon Frame:\n");
	  if (!$dataonly) {
		($printmac && !$verbose) && 	print(" $src > $dst");
		$brief && print(" Beacon");
		(!$dataonly) && &beacon();
	  };
	} elsif ($frametype eq 0x08) {
	  $dataonly && printf("\n[%d] %02d/%02d/%02d %02d:%02d:%02d.%ld, [%ld]",
		 $packetcount,
		 $mon,$mday,$year,$hour,$min,$sec, $ms_val,
		 $caplen_val
		);

	  &grab_header;
	  ($printmac && !$verbose) && 	print(" $src > $dst");
	  $verbose && print("\n\tData Frame:\n");
	  &dataframe();
	  ($veryBrief && !$weak) && print("\n");
	} elsif ($frametype eq 0x00) {
	  &grab_header;
	  if (!$dataonly) {
		($printmac && !$verbose) && 	print(" $src > $dst");
		$verbose && print("\n\tAssociation Request Frame:\n");
		$brief && print(" Association Request Frame");
		&asn_req();
	  }
	  #&readtoend();

	} elsif ($frametype eq 0x10) {
	  &grab_header;
	  if (!$dataonly) {
		($printmac && !$verbose) && 	print(" $src > $dst");
		$verbose && print("\n\tAssociation Response Frame:\n");
		$brief && print("Association Response Frame");
		&asn_rpl();
	  }
	} elsif ($frametype eq 0x40) {
	  &grab_header;
	  if (!$dataonly) {
		($printmac && !$verbose) && 	print(" $src > $dst");
		$verbose && print("\n\tProbe Request Frame:\n");
		$brief && print(" robe Request Frame");
		&probe_req();
	  }
	} elsif ($frametype eq 0x50) {
	  &grab_header;
	  if (!$dataonly) {
		($printmac && !$verbose) && 	print(" $src > $dst");
		$verbose && print("\n\tProbe Response Frame:\n");
		$brief && print(" Probe Response Frame");
		&probe_rpl();
	  }
	} elsif ($frametype eq 0xb0) {
	  &grab_header;
	  if (!$dataonly) {
		($printmac && !$verbose) && 	print(" $src > $dst");
		$verbose && print("\n\tAuthentication Frame:\n");
		$brief && print(" Authentication Frame");
		&auth();
	  }
	} elsif ($frametype eq 0xc0) {
	  &grab_header;
	  if (!$dataonly) {
		($printmac && !$verbose) && 	print(" $src > $dst");
		$verbose && print("\n\tDisAssociation Frame:\n");
		&de_asn ();
	  }
	} elsif ($frametype eq 0xd4) {
#	  &grab_header;
	  if (!$dataonly) {
#		($printmac && !$verbose) && 	print(" $src > $dst");
		$verbose && print("\n\tACK Frame - Skipping\n");
		$brief && print(" ACK Frame");
#	  &readtoend($caplen_val-5);
	  # ACK frame : no src, dst, bssid fields.
	  # ACK frame =  Type, flags, duration [2 bytes], rcv addr [6 bytes]
	  } 
	} else {
	  if (!$dataonly) {
		$verbose && print("\n\tOther Frame - Skipping\n");
		$brief && print(" Other");
	  }
#	  &readtoend($caplen_val-5);
	  # RTS - 0xb4
	  # ReAssociation Request -
	  # DeAuth -
	}
  }
  &parse_header();
}
printf(STDERR "%d packets examined\n", $packetcount);
exit;



sub beacon() {

#  &grab_header;
	&gen_header();

	my $fixed=unpack("H*",Get(10));
	$verbose && print("\nFixed Parameters:\t$fixed");
	my $capabil = unpack("H*",Get(2));

	$verbose && print("\n\tCapability Flags: \t$capabil");

	&tagparms();
	
}


sub dataframe(){

#  &grab_header;
	&gen_header();

	# ----- Start Reading Data: WEP 1st 3bytes IV, 4th should be 0, 5th should 1st encr output
	$verbose && print("\nIV:");
	$IV[0]=ord(Get1());
	$IV[1]=ord(Get1());
	$IV[2]=ord(Get1());
	$iv=sprintf("%02x%02x%02x",$IV[0],$IV[1],$IV[2]);
	($brief || $dataonly) && print(" IV: $iv");
	if ($weak) {
	  # only print if the iv has the following conditions:
	  if ($IV[0] >= 3 && $IV[0] < 8 && $IV[1] == 255) {
		print(" [$packetcount] IV: $iv");
		$inchar=ord(&Get1()); # get IV options
		&printdata();
		print("\n");
	  } # else not weak
	} elsif ($veryBrief) {
	  print(" [$packetcount] IV: $iv");
	  $inchar=ord(&Get1());
	} elsif ($brief) {
		$inchar=ord(&Get1()); # get IV options
		&printdata();
	} elsif ($verbose) {
	  print("\nIV Options: ");
	  $inchar=ord(&Get1());
	  printf("%02x", $inchar);	
	  &printdata();
	} elsif ($dataonly) {
	  $inchar=ord(&Get1());
	  &printdata();
	}


	#read to end of record [ff-ff-ff-ff -- then, read next record [jump ahead 16bytes?]
#	&readtoend($caplen_val-30);
}


sub asn_req () {

#  &grab_header;
	&gen_header();

	# fixed : capability [2B], Listen Int[2B]
	my $cap = unpack("H*",Get(2));
	$verbose && print("\n\tCapability Flags: $cap");
	my $listen = unpack("H*",Get(2));
	$verbose && print("\n\tListen Interval: $listen");
	&tagparms();
}

sub asn_rpl () {

#  &grab_header;
	&gen_header();

	# fixed : capability [2B], Status Code [2B], Association ID [2B]
	$verbose && print("\n\tCapability Flags: ");
	for ($i=0; $i<2; $i++) {
		$inchar=ord(&Get1());
		$verbose && printf("%02x", $inchar);
	}
	$verbose && print("\n\tStatus Code: ");
	for ($i=0; $i<2; $i++) {
		$inchar=ord(&Get1());
		$verbose && printf("%02x", $inchar);
	}
	$verbose && print("\n\tAssociation ID: ");
	for ($i=0; $i<2; $i++) {
		$inchar=ord(&Get1());
		$verbose && printf("%02x", $inchar);
	}
	&tagparms();
}

sub probe_req () {
#  &grab_header;
	&gen_header();
	&tagparms();
}

sub probe_rpl () {
#  &grab_header;
	&gen_header();
	
	# fixed : timestamp [8B], beacon int [2B], capability [2B]
	$verbose && print("\nFixed Parameters:\n");
	for ($i=0; $i<10; $i++) {
		$inchar=ord(&Get1());
		$verbose && printf("%02x", $inchar);
	}

	$verbose && print("\n\tCapability Flags: ");
	for ($i=0; $i<2; $i++) {
		$inchar=ord(&Get1());
		$verbose && printf("%02x", $inchar);
	}

	&tagparms();
}

sub auth () {

#  &grab_header;
	&gen_header();

	# fixed : Auth ALG [2B], Auth Seq [2B], Status Code [2B]
	$verbose && print("\n\tAuth ALG: ");
	for ($i=0; $i<2; $i++) {
		$inchar=ord(&Get1());
		$verbose && printf("%02x", $inchar);
	}
	$verbose && print("\n\tAuth Seq: ");
	for ($i=0; $i<2; $i++) {
		$inchar=ord(&Get1());
		$verbose && printf("%02x", $inchar);
	}
	$verbose && print("\n\tStatus Code: ");
	for ($i=0; $i<2; $i++) {
		$inchar=ord(&Get1());
		$verbose && printf("%02x", $inchar);
	}

	for ($i=0; $i<4; $i++) {
		$inchar=&Get1();
		#$verbose && printf("%02x", $inchar);
	}

}

sub de_asn () {
#  &grab_header;
	&gen_header();
	#fixed : Reason Code [2B]
	$verbose && print("\n\tReason Code: ");
	for ($i=0; $i<2; $i++) {
		$inchar=ord(&Get1());
		$verbose && printf("%02x", $inchar);
	}	
	for ($i=0; $i<4; $i++) {
		$inchar=&Get1();
		#printf("%02x", $inchar);
	}
}

sub grab_header() {
  $dst = unpack("H*",Get(6));
  $src = unpack("H*",Get(6));
  $bssid = unpack("H*",Get(6));
  $frag = unpack("H*",Get(2));
}

sub gen_header() {
#  grab_header;

  if ($verbose) {
	print("\n\tDest Addr: $dst");
	print("\n\tSrc Addr: $src");
	print("\n\tBSSID Addr: $bssid");
	print("\n\tFragment No.: $frag");
#  } elsif ($brief || $printmac) {
#	print(" $src > $dst");
  }
	if (0 && $printmac) {
	  
	  printf(" %s:%s:%s:%s:%s:%s ",
			 substr($src,0,2),
			 substr($src,2,2),
			 substr($src,4,2),
			 substr($src,6,2),
			 substr($src,8,2),
			 substr($src,10,2),
			);
	}
}

sub readtoend {

	# Nasty kludge to read to end of frame. End of frame is FF:FF:FF:FF.  Review 802.11 spec for better method
	# doesn't always work -- if data packet has FF:FF:FF:FF in it, next few decodes are f'd up.
        my @passed = @_;

	$verbose && print("Passed val : $passed[0]\n");
#	$endpkt=0;

	for ($i=0; $i<$passed[0]+1; $i++) {
		$inchar=&Get1();
	
	}	
	while (!$endpkt) {
	  $verbose && printf(",");
		$inchar=ord(&Get1());
		if ($inchar eq 255) {
			$inchar=ord(&Get1());	
			if ($inchar eq 255) {
				$inchar=ord(&Get1());		
				if ($inchar eq 255) {
					$inchar=ord(&Get1());		
					if ($inchar eq 255) {
						$endpkt=1;
					}
				}
			}
		}
	}
}

sub tagparms() {

  $ssid="";
  $channel="";
	$verbose && print("\nTagged Parameters: ");
	# Format is <tag><len><data....>
	$endpkt=0;
	while (!$endpkt ) {
		$inchar=ord(&Get1());
		if (!defined($inchar)) {
		  printf("Got end of packet!\n");
		  $endpkt++;
		} else {
		$veryVerbose && printf(" inchar:%d \n", $inchar);
		if ($inchar eq 0x00) {
			$inchar=ord(&Get1()); # Number of characters
			$numchars=$inchar;
			if ($numchars > 0 && $numchars < 1000) {
				$ssid=&Get($numchars);
				$verbose && print("\n\tSSID: $ssid"); # ASCII
				$brief && print(" SSID: $ssid");
			} else {
			  printf("[%d] [%d]: Strange value of SSID numchars - IGNORE\n", $packetcount,$numchars);
			  $endpkt=1;
			}
		} elsif ($inchar eq 0x01) {
			$numchars=ord(&Get1());
			$inchar=unpack("H*",Get($numchars));
			$verbose && print("\n\tSupported Rates: $inchar");
		} elsif ($inchar eq 0x03) {
			$verbose && print("\n\tChannel");
			$inchar=ord(&Get1());
			$numchars=$inchar;
			$verbose && printf("[%d]: ", $numchars);
			$channel = unpack("H*",Get($numchars));
			$verbose && printf("%s", $channel);
			$brief && print(" Ch: $channel");

		} elsif ($inchar eq 0x05) {
			$verbose && print("\n\tTIM: (Traffic Indication Map) ");
			$inchar=ord(&Get1());
			$numchars=$inchar;
			$verbose && printf("[%d]: ", $numchars);
			for ($x=0; $x < $numchars; $x++) {
				$inchar=ord(&Get1());	
				$verbose && printf("%02x", $inchar);
			}

		} elsif ($inchar eq 0x80) {
			$numchars=ord(&Get1());
			$verbose && printf("[%d]: ", $numchars);
			$inchar=unpack("H*",Get($numchars));
			$verbose && print("\n\tReserved Tag: $inchar");

		} elsif ($inchar eq 0xff) {
			$verbose && print("\n\tEnd Marker: ");
			$inchar=ord(&Get1());
			$numchars=$inchar;
			if ($numchars eq 255) {
				$numchars=2;
				$endpkt=1;
			}
			for ($x=1; $x < 2; $x++) {
				$inchar=ord(&Get1());	
				$verbose && printf("%02x [%d]", $inchar,$inchar);
			}
			# if the current bytecount is odd, I may have to get another byte
			if (($bytecount % 2) == 1 ) {
			  $verbose && printf(">> [%d][%d][%d] WARNING - may have to get another parameter\n",$packetcount, $bytecount,$bytesinpacket);
			} 
			if ($bytesinpacket==1) {
			  # one more byte left. Have to read in
			  $inchar=ord(&Get1());
			  $verbose && printf("%02x [%d]", $inchar,$inchar);
			}

		} else {
			$inchar=ord(&Get1());
			$numchars=$inchar;
			$verbose && printf("\n\tUnknown Tag[%d]: ", $numchars);
			if ($numchars > 0 && $numchars < 1000) {
			  for ($x=0; $x < $numchars; $x++) {
				$inchar=ord(&Get1());	
				$verbose && printf("%02x", $inchar);
			  }
			} else {
			  $verbose && printf("[%d] [%d]: Strange value of unknown tags numchars - IGNORE\n", $packetcount, $numchars);
				$endpkt=1;
			}
		}
		}
	}

}


