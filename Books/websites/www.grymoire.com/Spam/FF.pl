#!/usr/bin/perl -w --
# FF.pl - Find Friends of spam sites
# Rev 5
# Thu Nov 28 11:02:49 EST 2002
# Tue Feb 18 07:48:05 EST 2003 - added scanning of redirects
# Mon Jul 12 09:57:51 EDT 2004 - Updates and bug fixes.
# Mon Jul 26 20:21:00 EDT 2004 - Updates and bug fixes.
#
# Written by Bruce Barnett 
# Using code from Chip Rosenthal <chip <@at@>unicom.com>
#
# e=Mail Contact: 
#                   ff01 < @at@> grymoire.com <= Harvesters enjoy!
#                   Then increase the 2-digit number before the '@'
#                   
#
# 
# Usage: FF - Find Friends
#             give FF a list of hostnames from standard input
#             The input is a list of hostnames, URL's or both.
#             FF then reads each one, and looks up name servers, mail servers, 
#             aliases, and real names. It looks at URL's. It also follows 
#             these recursively, finding hostnames in URL's, and repeating 
#             the steps. When it stops, it sorts the results by IP address and
#             reports if the address is blocklisted.
#             This program is designed to find out who is supporting a 
#             spammer or set of spammers. In other words, if an ISP is 
#             spam friendly, this tool makes it easier to identify the ISP.
#             
# Examples
#
#   echo www.spammer.com | FF.pl
#   echo http://www.spammer.com/Mortgage/index.html | FF.pl
#
#   FF.pl list_o_porn_sites
#
#   FF.pl <list_o_porn_sites
#
# Options
#   -x   = same as -m -u -n -a -b
#   -v   = Verbose
#   -d   = Debug
#   -#   = How deep to explore - Number of loops
#          -0 means don't fetch the URL's, and get the URL's inside the URL's

#   -w# = How wide to explore - How many address/name servers/mail
#         servers to include when more than one is available. That is, one
#         domain may have 10 mail servers. Shall we examine all 10?

# ------------------
#   The next options have the convention:
#            capital letters turns off the feature
#            lower case letters turn the feature ON
#   You can use the long or short form of the option
#   -blk and -b are the same
# -----------------
#   -mx  = Explore MX records
#   -m   = Explore MX records
#   -MX  = Don't Explore MX records
#   -M   = Don't Explore MX records

#   -ns  = Explore Name Server records
#   -n   = Explore Name Server records
#   -NS  = Don't Explore Name Server records
#   -N   = Don't Explore NameServer records

#   -a   = Do reverse lookup
#   -A   = DON'T do reverse lookup

#   -blk = Lookup blocklist
#   -b   = Lookup blocklist
#   -BLK = Don't Lookup blocklist
#   -B   = Don't Lookup blocklist

#   -url = Lookup URL
#   -u   = Lookup URL
#   -URL = Don't Lookup URL
#   -U   = Don't Lookup URL

#
# Notes: The host names don't have to be one per line.
# You can rename this executable to be "FF" if you like
#
# FF finds the IP address, Name Servers, and Mail servers of each
# host.  It then 'recurses' through the newly found systems, and
# repeats the process Thus it finds all "related" sites.  Lastly - it
# sorts the output by IP address so you can spot clusters of related
# machines. If many URL's share an IP block, this will become apparent
# when the output is reported.
#
# Features:

#       * if you have a file called ~/.ff containing domains, these
#          will not be searched. These are "respectable" domains, such as
#          perl.org, w3.org, etc.
#
#       *  If a blocklist is too slow to respond, an error is reported, and 
#          that blocklist is ignored for the next query.
#
# This program is Copyright 2002-2004
# You may use it freely and modify it. Please leave my name in as the creator

# TODO:
#      if I get a signal (INT) do a quick interrupt and printout what I know
#      ignore addresses in the private network space.
#      it doesn't look up the IP Block owner
#
#      if spammer uses redirect to hide, show all of the redirects

#      Use http://whois.webhosting.info/IP.ADD.RE.SS to find all names at an IP address
eval 'use Net::DNS;'; # You have to get this from CPAN - it's not standard
eval 'use LWP;';
eval 'use  LWP::UserAgent';
#use Devel::DProf;

use  IO::Select;
use Net::hostent;
use Net::Ping;
use Socket;
use Carp;
use strict;
use POSIX qw(strftime);
use Data::Dumper;
$| = 1;


my (
    $line,	# Line read from STDIN
    %hosts,	# list of hosts
    %urls,	# list of URLs
    $url,
    %url_2_pages, 	# List of pages this url points to
    %ipaddresses,	# list of IP addresses seen
    %domains,	# list of domains
    $h,		# Host in the loop
    $addr,		# address  in the loop
    %host_2_mx, # Host to MX
    %domain_2_ns, # host to ns reference
    %domain_invalid, # list of invalid domains
    %host_2_ip, # hostname(alias) to IP addresses
    %ip_2_ohost, # IP addresses to official hostname
    %ip_2_alias, # IP addresses to alias hostname
    @mx, 	# list of MX hosts
    $mx, 	# single MX host
    @ns, 	# list of name servers
    $ns, 	# single name server
    $done,	# true when done
    $more,	# true when more to do
    $domain,	# domain of host
    $level,	# how far I have traveled so far
    $cwidth,    # current width
    $program,	# program name
    $ua,	# User Agent
    $req,	# Request
    $rep,	# Response
    @server_list,
    $zone, 
    $query, 
    @result, 
    $ex,
    %ignore, # ignore these domains...
	$HOME, # home directory
    %unavailable_server_list, # returns true  if server is missing/ignore.
	$num_ips, # number of IPS
	$num_hosts, # number of hosts
	$num_urls, # numer of URLS

);
my ( # switch options
    $verbose,	# verbose mode. 1 is verbose, 0 is silent
    $debug,	# debug mode (1 = on)
    $depth,	# how deep to travel, 0 = infinity
    $width,     # how wide to explore, 0 - widest
    $do_ns,
    $do_block,
    $do_mx,
    $do_rever,
    $do_url,
    $ShowAddrFlag,
	$timeout,
);

my %ZoneTags = (

        # See <http://www.unicom.com/sw/#blq> for latest version of this info
###
		#
		# The "default" tag is used if no other is given.  Originally,
		# the default query was to "rbl".  That's been deprecated since
		# the MAPS RBL is no longer public.  I've selected a small number
		# of lists to use as the default.  Of course, you are free to
		# change it if you don't like my selection.
		#
		#"default"=> "rbl",
#		"default"=> [qw(sbl rsl pdl opm relays)],
#spamhaus
		"default"=> [qw(sbl xbl spamcop rsl pdl opm spews dsbl ordb cbl )],
		###
		#
		# Spamhaus Block List <http://www.spamhaus.org/SBL/>
		#
		"sbl"=> "sbl.spamhaus.org",
		"xbl"=> "xbl.spamhaus.org",
			###
		#
		# Relay Stop List <http://relays.visi.com/>
		#
		"rsl"=> "relays.visi.com",
			###
		#
		# Pan-American Dailup List <http://www.pan-am.ca/pdl/>
		#
		"pdl"=> "dialups.visi.com",
			###
		#
		# Open Relay Database <http://www.ordb.org/>
		#
		"ordb"=> "relays.ordb.org",
			###
		#
		# Not Just Another Bogus List <http://njabl.org/>
		#
		"njabl"=> "dnsbl.njabl.org",
			###
		#
		# Extreme Spam Blocking List <http://www.selwerd.cx/xbl/>
		#
#		"xbl"=> "xbl.selwerd.cx",
			###
		#
		# <http://www.five-ten-sg.com/blackhole.php>
		"fiveten"=> "blackholes.five-ten-sg.com",
			###
		#
		# SpamCop Block List <http://spamcop.net/bl.shtml>
		#
		"spamcop"=> "bl.spamcop.net",
			###
		#
		# Habeas Infringers List <http://www.habeas.com/services/infringers.htm>
		#
		"hil"=> "hil.habeas.com",
		###
		#
		# RFC-Ignorant ipwhois list  <http://www.rfc-ignorant.org/policy-ipwhois.php>
		#
		"rfci"=> "ipwhois.rfc-ignorant.org",
		###
		#
		# Open Proxy Monitor List <http://www.blitzed.org/opm/>
		#
		"opm-wingate"=> "wingate.opm.blitzed.org",
		"opm-socks"=> "socks.opm.blitzed.org",
		"opm-http"=> "http.opm.blitzed.org",
		"opm"=> "opm.blitzed.org",
		"opm-all"=> [qw(opm opm-wingate opm-socks opm-http)],
			###
		"spews"=> "spews.rbldns0.sorb.net",
		"spews-a"=> "spews.rbldns0.sorbs.net",
		"spews1"=> "l1.spews.dnsbl.sorbs.net",
		"spews2"=> "l2.spews.dnsbl.sorbs.net",
		"sorbs"=> "dnsbl.sorbs.net",
		"sorbrelays"=> "relays.dnsbl.sorbs.net", # proxies/relays
		"dynablock"=> "dynablock.njabl.org",
		"cbl"=> "cbl.abuseat.org",
		"ahbl"=> "dnsbl.ahbl.org",
		"cn-kr"=> "cn-kr.blackholes.us",
		###
		#
		# Distributed Server Boycott List <http://dsbl.org/>
		#
		"dsbl-list"=> "list.dsbl.org",
		"dsbl-multihop"=> "multihop.dsbl.org",
		"dsbl-unconfirmed" => "unconfirmed.dsbl.org",
		"dsbl"=> [qw(dsbl-list dsbl-multihop dsbl-unconfirmed)],
			###
		#
		# IDs for zones hosted by mail-abuse.org (MAPS)
		#
#		"rbl+"=> "rbl-plus.mail-abuse.org",
		"rbl"=> "blackholes.mail-abuse.org",
		"dul"=> "dialups.mail-abuse.org",
		"rss"=> "relays.mail-abuse.org",
		# alias for back-compatibility with original name
		# *** this tag deprecated as of 24-Feb-2002
		"rrss"=> "rss",
			# aggregate of all MAPS zones
		"maps"=> [qw(rbl dul rss)],
			###
		#
		# "all" aggregate - query all lists.
		#
		"all" => [qw(sbl rsl pdl ordb njabl xbl spamcop hil rfci opm-all  dsbl maps spews1 spews2 sorbs sorbrelays cbl ahbl bsbl-list spews dynablock maps)]
#


);

# default command line values - adjust to yout liking....
$verbose  = 0;
$debug    = 0;
$do_block = 1;
$do_mx    = 0;
$do_ns    = 0;
$do_rever = 1;
$width    = 0;
$depth    = 2;
$level    = 0;
$do_url    = 1;
$ShowAddrFlag = 0;
$timeout = 5;

sub sortip {
  # sort by IP address
  my ($a1,$a2,$a3,$a4,$a5) = $a =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)\s+(\S)/;
  my ($b1,$b2,$b3,$b4,$b5) = $b =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)\s+(\S)/;
#  printf(STDERR "%s === %s\n", $a5, $b5);
    $a1 <=> $b1
      ||
    $a2 <=> $b2
      ||
    $a3 <=> $b3
      ||
   $a4 <=> $b4
     ||
   $a5 <=> $b5
     ;
}
sub newdomain {
  my ($h) = @_;
  if (defined($h)) {
	my $domain = get_domain($h);
  
	if (defined($domain)) {
	  $domains{$domain}++;
	  if ($debug && $verbose && $domains{$domain}==1) {
		printf("For host %s, new domain is %s\n", $h, $domain);
	  }
	} elsif ($h =~ /\d+\.\d+\.\d+\.\d+/) {
	  # quad IP
	}
  }
}
sub get_domain {
  my ($host) = @_;
  my $domain;

  if (defined($host) && ($host =~ /[a-zA-Z]/)) {
	if ($host =~ /\.*([a-zA-Z0-9-]+\.[a-zA-Z]+)\.*$/) {  # get the domain part - only does top 2 levels

	  $domain = $1;
	  $domain = lc $domain;
	  $domain .= "." unless ($domain =~ /\.$/);
	  return $domain;
	} 
  }
  return undef;
}
sub gethost_from_url {
  my ($url) = @_;
  my $host;
  my $urlpart;
  # Return the hostname part of the URL
  return undef if (!defined($url));
  ($host,$url) = splithosturl($url);
  return $host;
}
sub newhost {
  # Add a new host to list, if new, then we have to do more work
  my ($host) = @_;
  $host = lc $host;
  (0 || ($debug>1) && $verbose ) && printf(STDERR "calling newhost(%s)\n", $host);
  

  # do I ignore it

  if ($host =~ /[a-zA-Z]/) { # has to have at least one letter
	my $maindomain = get_domain($host);
	if (!defined($maindomain)) {
      $verbose && printf("Host '%s'  has unknown domain \n", $host);
	} elsif ($ignore{$maindomain}) {
	  return;
	} else {
	  newdomain($maindomain);
	}
    if (!defined($hosts{$host})) {
      $hosts{$host} = 0; # First time seeing this host
      $more++;
      $verbose && printf("New host added '%s', %d more to do ( %s )\n", $host, $more, 
						 (defined($num_hosts) ? "$num_hosts" : "")
						);
    } else {
      # printf("Old Host: %s\n", $host);
    }
  } elsif ($host =~ /\d+\.\d+\.\d+\.\d+/) {
    $hosts{$host} = 0;
  } elsif (!defined($host)) {
  } elsif (length($host)==0) {
  } else {
    printf(STDERR "Ignoring invalid hostname: '%s'\n", $host);
  }
}
sub newurl {
  # Add a new URL to list, if new, then we have to do more work
  my ($url) = @_;
  
  newhost(gethost_from_url($url));
  return if (ignore($url));
  $verbose && $debug && printf("Url '%s' is NOT ignored\n", $url);
  if ($url =~ /^https*:\/\//) {
    if (!defined($urls{$url})) {
	  ( $verbose ) && printf("Url '%s' not defined\n", $url);
      # Skip certain kinds of URL's
      if ($url =~ /\.jpg$/i) {
      } elsif  ($url =~ /\.gif$/i) {
      } else {
		if ($level <= $depth) {
		  $urls{$url} = 0; # First time seeing this host
		  $more++;
		  if ($verbose) {
			if ($debug) {
			  printf("New url added '%s', more: %d [level: %d, depth: %d]\n", $url, $more, $level, $depth);
			} else {
			  printf("New url added '%s', %d more to go (%s%s%s)\n", $url, $more, 
					 (defined($num_ips) ? "ips: $num_ips" : ""), 
					 (defined($num_hosts) ? " hosts: $num_hosts" : ""), 
					 (defined($num_urls) ? " urls: $num_urls" : ""));
			}
		  }
		}
	  }
    } else {
      # printf("Old url: %s\n", $url);
    }
  } else {
    printf(STDERR "Invalid url: '%s'\n", $url);
    croak "invalid url";
  }
  # If host not defined, add it to list
  if ($url =~ /https*:\/\/.*@([0-9a-zA-Z_.-]+)\//) {
	# Handle the case of http://www.usbank.com@193.251.140.195/us/
#    newhost($1);
  } elsif ($url =~ /https*:\/\/([0-9a-zA-Z_.-]+)\//) {
    newhost($1);
  }
}

sub url_2_page {
  # Add a reference from a URL to a second URL
  my ($main, $called) = @_;
  my $found;
  # A new URL was found
  $debug && printf("Calling url_2_pages(%s,%s)\n", $main, $called);
# if the domain is ignored, don't store it
  

	if ($called !~ /^https*:\/\//) {
	(0 || ($verbose && $debug)) && printf(STDERR "url_2_pages:: prepending '%s' to '%s'\n", $main, $called);
	  $called = "$main/$called";
	} 
  if ($called =~ /^https*:\/\/[^\/]+$/) {
	(0 || ($verbose && $debug)) && printf(STDERR "url_2_pages:: appending / to url '%s'\n", $called);
	  $called = "$called/";
	} 

  my $host = gethost_from_url($called);
  if (!defined($host)) {
	printf(STDERR "Host undefined in url: '%s'\n", $called);croak;
  }
  my $domain=get_domain($host);
  if (!defined($domain)) {
	$verbose && printf(STDERR "Domain undefined in url: '%s'\n", $called);
  }
  if (defined($domain) && length($domain) && !ignore($domain)) {
	$verbose && $debug && printf(STDERR "url_2_pages:: domain '%s' not ignored\n", $domain);
	return if ($called =~ /\.gif$/i);
	return if ($called =~ /\.jpg$/i);
	&newurl($called); # add it
	# Now check the reference list
	if (!defined($url_2_pages{$main})) {
	  # just add it
	  $url_2_pages{$main} = $called;
	  $debug && printf("url_2_pages{%s}= '%s'\n", $main, $called);
	} else {
	  # see if it's already added
	  my @picks = split(/\t/, $url_2_pages{$main});
	  my $pick;
	  $found = 0;
	  for $pick (@picks) {
		if ($pick eq $called) {
		  $found++;
		  next;
		} else {
		  #
		}
	  }
	  if (!$found) {
#		printf("adding to url_2_pages{%s}+= '%s'\n", $main, $called);
		$url_2_pages{$main} .= "\t$called";
	  }
	}
  } else {
	if (defined($domain) && $verbose ) { printf(STDERR "Domain '%s' ignored - skipping %d\n", $domain,$ignore{$domain});}
  }
#  printf("url_2_pages{%s} = %s\n", $main, $url_2_pages{$main});
}
sub associate_host_ipaddr {
  # Associate a host with official IP address
  # Host may have many IP addresses
  # But each IP address can only have one host
  my ($host,$addr) = @_;
  $host = lc $host;
  if ($host !~ /\./) {
    printf(STDERR "associate_host_ipaddr got strange input: associate_host_ipaddr(%s,%s)\n", $host,$addr);
  } else {
  
    $ipaddresses{$addr}++;
    if (defined($host) && $host =~ /-1/) {
      $ip_2_ohost{$addr} = -1; # Mark it undefined
    } else {
      $host = lc $host;
      newhost($host);
      if (defined($host) && defined($addr) && !defined($ip_2_ohost{$addr})) {
	$ip_2_ohost{$addr} = $host; # First time seeing this host
      } elsif ($host eq $ip_2_ohost{$addr}) {
	# this is okay. Just a duplicate
      } elsif ($ip_2_ohost{$addr} =~ /-1/) {
	# We knew it existed, and have to add the address. Just what we expected
	$ip_2_ohost{$addr} = lc $host;
      } elsif (length($ip_2_ohost{$addr}) == 0) { #
	# We knew it existed, and have to add the address. Just what we expected
	$ip_2_ohost{$addr} = lc $host;
      } else {
	printf(STDERR "Warning, for IP address %s, official hostname was %s, wanted to change to %s\n",
	       $addr, $ip_2_ohost{$addr}, $host);
      }
    }
  }
}
sub addhost_2_ipaddress {
  # Add a new host ->IP address to alias list
  # Note that one host may have several IP addresses
  # and one address may have several hostnames
  my ($host,$addr) = @_;
  
  $host = lc $host;
  $host =~ s/\.$//;
  (0 || ($verbose && $debug)) && printf(STDERR "addhost_2_ipaddress(%s,%s)\n", $host, $addr);
  
  return if ($addr =~  /127\.0\.0\.1/); # avoid spammer tricks
  $ipaddresses{$addr}++;
  newhost($host);

  #printf(STDERR "BGB %s is on %s\n", $host, $addr);
  # add name->ip entry
  $host_2_ip{$host}=$addr; # This is a problem - only one value here
  # But that's okay. We just want to know if there is an address.
  if ($do_rever) {
    my $hst;
    if (!defined($ip_2_ohost{$addr})) {
      my ($newname, $aliases, $addrtype, $length, @addrs);
      my @a = ($addr =~ m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
      # Old code - without Net::hostent
#      if (($newname, $aliases, $addrtype, $length, @addrs) = gethostbyaddr(pack('C4',@a),  Socket::AF_INET()) ) {
#	associate_host_ipaddr($newname,$addr);
#      } else {
#	$ip_2_ohost{$addr} = -1; # can't resolve it
#      }
      $hst = gethostbyaddr(pack('C4',@a));
      if (!defined($hst)) {
		$ip_2_ohost{$addr} = -1; # can't resolve it	
      } else {
		my $thost = $hst->name;
		$thost = lc $thost;
		associate_host_ipaddr($thost,$addr); # Official assignment based on rDNS
      }
    }
    # add ip->alias entry - but only if it's NOT the official name
  } 
  if (defined($ip_2_ohost{$addr}) && ($ip_2_ohost{$addr} eq $host)) {
    # done
  } elsif (!defined($ip_2_alias{$addr})) {
    $ip_2_alias{$addr} = $host; # First time seeing this host
    $debug && $verbose && printf("NEW: ip_2_alias{%s} = %s\n", $addr, $ip_2_alias{$addr});
  } else {
    $debug && $verbose && printf("ADDING %s to : ip_2_alias{%s} = %s\n", $host, $addr, $ip_2_alias{$addr});   
    my (@addrs) = split(/,/, $ip_2_alias{$addr});
    my $add;
    my $hasit;
    foreach $add (@addrs) {
      $add = lc $add;
      (lc $host eq $add) && $hasit++;
    }
    if (!$hasit) {
      $ip_2_alias{$addr} .= ",$host";
      ($debug) && printf("ip_2_alias[%s]{%s} .= %s\n", $ip_2_ohost{$addr}, $addr, $ip_2_alias{$addr});
    }
  }
}

#
# munge_server_spec - given a $server_spec (which consists of a list of
# block list server zones and IDs), generate the @server_list (which is
# a formal list of block list server zones).
#
sub munge_server_spec
{
	warn q[usage: munge_server_spec($$server_spec)]
		unless (@_ == 1);
	my $server_spec = shift;
	my @server_list_result = ( );
	my @spec_queue;
	my %did_server;
	my $t;

	@spec_queue = split(/[\s,]+/, $server_spec);
	while (@spec_queue > 0) {

		# grab next entry from the specification
		$_ = shift(@spec_queue);

		# if it might be a DNS zone then add it to our list
		if ((length($_)>0) && /\./) {
			push(@server_list_result, $_)
				if (! $did_server{$_}++);
			next;
		}

		# see if it is a tag we recognize
		if (defined($ZoneTags{$_})) {
		  $t = $ZoneTags{$_};

		  # tags may refer to a single entry or an aggregate of entries
		  if (ref($t) eq "ARRAY") {
			unshift(@spec_queue, @{$t});
		  } else {
			unshift(@spec_queue, $t);
		  }
		}

	}

	return @server_list_result;
}



#
# canonicalize_query() - Given a $query of some form (either a hostname
# or hostaddr) produce a list of ($hostname, $hostaddr) pairs.  The list
# typically will have only a single entry.  The exception is if a hostname
# resolves to multiple addresses.
#
sub canonicalize_query
{
	warn q[usage: canonicalize_query($query)]
		unless (@_ == 1);
	my $query = shift;
	my($addr, $name, $h);
	my @ret = ();

	if ($query =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
		# query specified as an address
		$addr = $query;
		$h = gethostbyaddr(inet_aton($addr));
		$name = ($h ? $h->name : undef);
		$name = lc $name;
		push(@ret, {'NAME' => $name, 'ADDR' => $addr});
	} else {
		# query specified as a hostname
		$name = $query;
		# put dot on end to avoid searchlist
		#$name .= "."
		#  unless ($name =~ /\.$/);
		$h = gethostbyname($name)
			or warn "$0: gethostbyname($name) failed\n";
		foreach $addr (@{$h->addr_list}) {
			push(@ret, {'NAME' => $name, 'ADDR' => inet_ntoa($addr)});
		}
	}

	return @ret;
}


#
# query_zone() - Query for $addr within the block list published at $zone.
#
sub query_zone
{
	warn q[usage: query_zone($addr, $zone)]
		unless (@_ == 2);
	my($addr, $zone) = @_;

	# put dot on end to avoid searchlist
	$zone .= "."
		unless ($zone =~ /\.$/);

	$addr =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/
		or warn "$0: bad address \"$addr\"\n";
	return gethostbyname("$4.$3.$2.$1.$zone");
}
sub do_block {
  warn q[usage: do_block($ipaddr)]
    unless (@_ == 1);
  my ($addr) = @_;
  my $result;
  my $query;
  my @query_list = canonicalize_query($addr);
  foreach $zone (@server_list) {
	next if (defined($unavailable_server_list{$zone}));
	$verbose && ($debug>1) && printf(STDERR "Zone: $zone\n");
    foreach $query (@query_list) {
	  my $starttime=time();
      $h = query_zone($query->{ADDR}, $zone);
	  # set unavailable_server to true if it took too long to do
	  if ((time()-$starttime) > $timeout) {
		printf(STDERR "Zone $zone (query: %s) took %6.2f seconds, making unavailable\n", $query->{ADDR}, time-$starttime);
		$unavailable_server_list{$zone}++;
	  }
      if (defined($h)) {
		$result .= " $zone";
      }
    }
  }
  if ($result) {
    printf("%s LISTED by %s\n", 
	   $addr,
	   $result);
  }
}
sub getswitches {	# get command line arguments
  # parse arguments
  my ($usage) = 0;
  while ($#ARGV>=0 && $ARGV[0] =~ /^-/) {
    my ($arg) = shift(@ARGV);
    $arg =~ /^-v$/ && ($verbose++,next);
    $arg =~ /^-(\d+)$/ && ($depth=$1,next);
    $arg =~ /^-w(\d+)$/ && ($width=$1,next);
    $arg =~ /^-d$/ && ($debug++,next);
    $arg =~ /^-d([0-9]+)$/ && ($debug=$1,next); # Support -d#
    $arg =~ /^-d=([0-9]+)$/ && ($debug=$1,next); # Support -d#
    $arg =~ /^-T=([0-9]+)$/ && ($timeout=$1,next); # Support -T=#
    $arg =~ /^-T([0-9]+)$/ && ($timeout=$1,next); # Support -T#
    $arg =~ /^-blk$/ && ($do_block++,next);
    $arg =~ /^-bl$/ && ($do_block++,next);
    $arg =~ /^-b$/ && ($do_block++,next);
    $arg =~ /^-BLK$/ && ($do_block=0,next);
    $arg =~ /^-B$/ && ($do_block=0,next);
    $arg =~ /^-url$/ && ($do_url++,next);
    $arg =~ /^-u$/ && ($do_url++,next);
    $arg =~ /^-URL$/ && ($do_url=0,next);
    $arg =~ /^-U$/ && ($do_url=0,next);
    $arg =~ /^-mx$/ && ($do_mx++,next);
    $arg =~ /^-m$/ && ($do_mx++,next);
    $arg =~ /^-MX$/ && ($do_mx=0,next);
    $arg =~ /^-M$/ && ($do_mx=0,next);
    $arg =~ /^-ns$/ && ($do_ns++,next);
    $arg =~ /^-n$/ && ($do_ns++,next);
    $arg =~ /^-NS$/ && ($do_ns=0,next);
    $arg =~ /^-N$/ && ($do_ns=0,next);
    $arg =~ /^-a$/ && ($do_rever++,next);
    $arg =~ /^-A$/ && ($do_rever=0,next);
    $arg =~ /^-x$/ && ($do_rever++,$do_mx++,$do_ns++,$do_url++,$do_block++,next);
    $arg =~ /^-/ && 
      (printf(STDERR "Ignoring unknown option '%s'\n", $arg),$usage++,next);
    last;
  }
  while ($#ARGV >=0) {
    printf(STDERR "Ignoring argument %s\n", $ARGV[0]);
    shift (@ARGV);
    $usage++;
  }
  if ($usage) {
    printf(STDERR "Usage: %s [-vd] [-options] [-#] [-w#] \n", $0);
    printf(STDERR "\t\tIn general, capital letters implies DON'T do the option.\n");
    printf(STDERR "\t-x   => same as -a -m -n -u -b (MX/NS/URL/Domains/RBL's) \n");
    printf(STDERR "\t-v   => Enable Verbose mode\n");
    printf(STDERR "\t-d   => Enable Debug mode\n");
    printf(STDERR "\t-#   => Number indicates depth of search\n");
    printf(STDERR "\t-w#  => Number indicates width of search\n");

    printf(STDERR "\t-m   => Explore MX records\n");
    printf(STDERR "\t-M   => DON'T Explore MX records\n");

    printf(STDERR "\t-n   => Explore NameServer records\n");
    printf(STDERR "\t-N   => DON'T Explore NameServer records\n");

    printf(STDERR "\t-a   => Find offical addresses\n");
    printf(STDERR "\t-A   => DON'T find official addresses\n");

    printf(STDERR "\t-blk => Lookup blocklists\n");
    printf(STDERR "\t-b   => Lookup blocklists\n");
    printf(STDERR "\t-BLK => DONT'T Lookup blocklists\n");
    printf(STDERR "\t-B   => DON'T Lookup blocklists\n");

    printf(STDERR "\t-url => Lookup URL links\n");
    printf(STDERR "\t-u   => Lookup URL links\n");
    printf(STDERR "\t-URL => DON'T Lookup URL links\n");
    printf(STDERR "\t-U   => DON'T Lookup URL links\n");
    printf(STDERR "\t-T#   => Set timeout on blocklists to be #\n");


    exit 1;
  }
}	  
sub ignore {
  # return true if I should ignore this URL
  my ($url) = @_;
  my $host = gethost_from_url($url);
  my $domain;

#  printf(STDERR "host: '%s'\n", $host);
  if (defined($host) && (length($host)>1)) {
	$domain= get_domain($host);
	if (defined($domain)) {
	  $domain .= "." unless ($domain =~ /\.$/);
	  (0 || $debug>2) && printf(STDERR "IGNORE? Host: %s, domain: '%s', url: '%s', ignored: %d\n", $host, $domain,$url,$ignore{$domain});

	}
  }

#  if (defined($domain) && ($domain =~ /./) && (defined($ignore{$domain}))
  return 0 if (!defined($domain));
  return 0 if  ($domain =~ /^$/) ;
  return 1 if  (defined($ignore{$domain}));
  return 0;
}
sub init {
# initialize things
  $HOME=$ENV{"HOME"};
  if ( -f "$HOME/.ff" ){

	$verbose && ($debug>1) && printf(STDERR "opening %s/.ff\n", $HOME);
	open(MYFF,"$HOME/.ff");
	while (<MYFF>) {
	  chomp;
	  $_ .= "." unless /\.$/;
	  $ignore{$_}++;
	  $verbose && ($debug>1) && printf(STDERR "Ignore %s\n", $_);
	}
  }
  close(MYFF);
}
sub main {
  # Set up a resolver for future



  printf("#FF results as of %s\n", 
                    (strftime "%a %b %e %H:%M:%S %Y", localtime));
  $|=1;
  &getswitches();
  &init();

  $debug && printf("Level: %d\n", $depth);
  if ($do_block) {
    @server_list = munge_server_spec("all");
#    @server_list = munge_server_spec("default");
  }
  my $res = new Net::DNS::Resolver;
  $res->tcp_timeout(1);
  $res->retry(1);
  $res->recurse(1);
  if ($verbose && ($debug>1)) {
	$res->debug(1);
  } else {
	$res->debug(0);
  }
  $res->defnames(0);

  $ua = LWP::UserAgent->new(
							timeout=>5,
#							max_redirect=>0
							);

  # Now read STDIN to get a list of hosts and/or web pages to check
  while (defined($line=<>)) {
    chomp $line;
    my (@list) = split(' ', $line);
#	$line =~ s/%([0-9a-fA-F][0-9a-fA-F])/pack("c",hex($1))/ge;
#	print("Line: $line\n");
    my $l;
    foreach $l (@list) {
	  # Things might be just a host name, or a URL
      if ($l =~ /https*:\/\//) { # looks like a URL
		$l =~ s/.*"(https*:[^"]*)"/$1/; # trim it down
		$l=&cleanurl($l); # clean up URL
		$verbose && $debug && printf(STDERR "l: %s\n", $l);
		my ($hostpart,$urlpart) = &splithosturl($l);
		if (defined($hostpart)) {
		  $verbose && $debug && printf(STDERR "newurl1: '%s'\n", $l);
		  &newurl($l);
		} else {
		  $verbose && $debug && printf(STDERR "url: '%s' missing host\n", $l);
		}
      } elsif ($l =~ /^[a-zA-Z0-9.-]+\.[a-zA-Z]+$/) { # looks like a hostname
		newhost($l); 
		# if URL seaching is done, then 
		if ($do_url) {
		  newurl("http://$l/");
		}
      } else {
		  printf(STDERR "can't parse '%s'\n", $l);
	  }
    }
  }
  $done = 0;
  while (!$done) {
    $level++; # Increase search level by 1
    $verbose && $debug && printf(STDERR "Starting loop %d\n", $level);
	$num_ips=%ip_2_ohost;
	$num_hosts=%hosts;
	$num_urls=%urls;
    $more = 0;
    if ($do_rever) {
      foreach $addr (keys %ip_2_ohost) {
		my $hst;
		my $a;
		my ($name, $aliases, $addrtype, $length, @addrs);
		if (defined($ip_2_ohost{$addr})) {
		  $debug && printf("Checking address $addr: %s\n", $ip_2_ohost{$addr});
		  my @a = ($addr =~ m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
#
#	  if (($name, $aliases, $addrtype, $length, @addrs) = gethostbyaddr(pack('C4',@a),  Socket::AF_INET()) ) {
#	    ($verbose) && printf("Addr: %s, name: %s, aliases: %s\n", $addr, $name, $aliases);
		  $hst = gethostbyaddr(pack('C4',@a));
		  if (!defined($hst)) {
			$verbose && printf(STDERR "cannot reverse lookup '$addr'\n");
	    
			$ip_2_ohost{$addr} = -1; # can't resolve it	
		  } else {
			$cwidth=0;
			foreach $a (@{$hst->aliases}) {
			  $cwidth++;
			  $debug && printf("*** addr: %s, host: %s, alias: %s\n", $addr, $hst->name, $a);
			  if ($width==0 || $cwidth <=$width) {
		
				addhost_2_ipaddress($hst->name,$a);	   
			  }
	      
			}
		  }
		}
      }
    }
    foreach $h (keys %hosts) { # look at by list of hosts
	  my $ipaddress_only=0;
	  $h =~ s/\.$//;
	  if ($verbose && ($debug>1)) {printf(STDERR "Looking at host %s\n", $h);}
	  if ($hosts{$h} == 0) { # first time I've seen this host.
		if ($h =~ /[a-zA-Z]/) {
		  $domain=get_domain($h);
		  if (defined($domain) ) {
			newdomain($domain);
		  }
		} else {
		  $ipaddress_only++;
		  $ipaddresses{$h}++
		}
#		if (!$ipaddress_only && $do_mx && !defined($host_2_mx{$h} && length($host_2_mx{$h}))) { # Do I have the MX records for this host?
		if (!$ipaddress_only && $do_mx && !defined($host_2_mx{$h} )) { # Do I have the MX records for this host?
		  $verbose && printf(STDERR "Doing MX on %s\n", $domain);
		  @mx = mx($domain);
		  $host_2_mx{$h}="";
		  $cwidth=0;
		  foreach $mx (@mx) {
			$cwidth++;
			($verbose) && printf("MX for %s (%s) is %s\n", $h, $domain, $mx->exchange);
			if ($width==0 || $cwidth <=$width) {
			  newhost($mx->exchange);
			  if (lc $mx->exchange ne $h) {
				if (defined($host_2_mx{$h}) && (length($host_2_mx{$h})>1)) {
				  $host_2_mx{$h} .= "," . lc $mx->exchange; 
		
				} else {
				  $host_2_mx{$h} = lc $mx->exchange; # NOTE This only gets the first one
				}
			  }
			}
		  }
		}
		if (!$ipaddress_only && $do_ns && defined($domain) && !defined($domain_2_ns{$domain}) && !defined($domain_invalid{$domain})) {	 # do I have the name servers?
	  $res->defnames(0);
	  $verbose && $debug && printf(STDERR "DNS? NS: $domain\n"); 
	  my $query = $res->query($domain,"NS");
	  if ($query) {
	    $cwidth=0;
	    foreach $ns ($query->answer) {
	      if (($ns->type eq "NS") && defined($ns->nsdname)) {
			if ($ns->nsdname !~ /\./) {
			  printf( STDERR "NS for %s (%s) is invalid - no dot in name: %s\n", $h, $domain, $ns->nsdname);			  
			  $domain_invalid{$domain}++;
			} else {
			  ($verbose) && printf( STDERR "NS for %s (%s) is %s\n", $h, $domain, $ns->nsdname);
			}
		  }
	      if (!defined($domain_invalid{$domain})) {
			if ($ns->type eq "NS") {
			  $cwidth++;
			  if ($width==0 || $cwidth <=$width) {
				newhost($ns->nsdname);
				if (defined($domain_2_ns{$domain})) {
				  $domain_2_ns{$domain} .= "," . lc $ns->nsdname; # This gets the 2nd, etc.
				} else {
				  $domain_2_ns{$domain} = lc $ns->nsdname; # This only gets the first one
				  ($verbose && $debug) && printf(STDERR "Adding domain_2_ns{$domain}=%s\n",$ns->nsdname);
				  
				}
			  }
			} else {
			  $verbose && $debug && printf(STDERR "Doing DNS lookup on %s, got answer type %s\n", $domain,$ns->type);
			}
		  } else {
			# invalid name server
		  }
	    }
	  } else {
		if ($res->errorstring !~ /NOERROR/) {
           print "query status on domain: ", $domain, "->", $res->errorstring, "\n";
           if ($res->errorstring =~ /REFUSED/) {
			 # ignore this domain.
			 $domain_2_ns{$domain}=""; #defined but null - so don't ask again;
		   } elsif  ($res->errorstring =~ /SERVFAIL/) {
			 # ??? what do I do with this?
			 $domain_2_ns{$domain}=""; #defined but null - so don't ask again;
		   } elsif  ($res->errorstring =~ /NXDOMAIN/) {
			 # this means name error - i.e. a bad domain
			 $domain_2_ns{$domain}=""; #defined but null - so don't ask again;
		   }
		 }
	  }
	}
	$h = lc $h;
	if (!$ipaddress_only && !defined($host_2_ip{$h})) {	 # get the IP address - NOTE - only gets one
	  $h .= "."
		unless ($h =~ /\.$/);
	  my $query = $res->search($h);
	  if ($query) {
	    $cwidth=0;
		($debug) && printf(STDERR "XXX query returns %s and %s\n", $query->header, $query->answer);
	    foreach $ns ($query->answer) {
	      $cwidth++;
	      if ($ns->type eq "A") {
			if ($width  == 0 || $cwidth <= $width) {
			  addhost_2_ipaddress($h,$ns->address);
			}
		  } elsif ($ns->type eq "CNAME") {

			my $cname;
			$verbose && printf(STDERR "Address query on host $h returned type CNAME '%s'\n",$ns->string);			
			if ($ns->string =~ /\S+\s+\d+\s+IN\s+CNAME\s+(\S+)\.\s*$/) {
			  $cname = $1;
			  newhost($cname);
			  $verbose && printf(STDERR "Host $h is alias for %s\n",$cname);			
			  # Now look up address
			  my $query2 = $res->search($cname);
			  my $ns1;
			  if (defined($query2)) {
				foreach $ns1 ($query2->answer) {
				  if ($ns->type eq "A") {
					$verbose && printf(STDERR "Host %s(%s) has address %s\n", $h, $cname,$ns1->address);
					addhost_2_ipaddress($h,$ns1->address);
					addhost_2_ipaddress($cname,$ns1->address);
				  }
				}
			  } # else undefined - skip
			} else {
			  $verbose && printf(STDERR "Host $h has strange CNAME value: %s\n",$ns->string);			
			}
			
	      } else {
			printf(STDERR "Address query on host $h returned type %s\n",$ns->type);
		  }
	    }
	  } else {

		  if ($verbose) {
			if (!defined($query)) {
			  printf(STDERR "Host '$h' returns undefined query\n");
			  $query = $res->query($h,"A");
			  if ($query) {
				printf("Query->print %s\n","");
				($query->answer)[0]->print;
				my $p = Net::Ping->new();
				if ($p->ping($h)) {
				  printf(STDERR "Host $h returns undefined query but PING works!!! STRANGE\n");				
				}
				my $ptcp = Net::Ping->new("tcp",2);
				if ($ptcp->ping($h)) {
				  printf(STDERR "Host $h returns undefined query but PING(tcp) works!!! STRANGE\n");				
				}
			  } else {
				printf("Cannot get A record for host '%s'\n", $h);
			  }
			} else {
			  printf("Dumper: %s\n", Dumper($query));
			  if (defined(($query->answer))) {
				($query->answer)[0]->print;
			  }
			  $query = $res->query($h,"A");
			  if ($query) {
				($query->answer)[0]->print;
			  }
			}
		  }
		$verbose && printf(STDERR "Host $h doesn't seem to have an address\n");
	  }
	  $hosts{$h}++; # done with this host
	}
      }
    }
	# Now do any URL's that have not been explored
	$verbose && printf("Check new URLS (loop %d of %d)\n", $level, $depth);
    if ($do_url && ($level <= $depth)) {
      my $i;
      my $ans;
      my @a;
      foreach $url (keys %urls) {      
		my $trimurl = $url;
		$trimurl =~ s,/[a-zA-Z0-9\.#\&\?\=\,-]*$,,;
		$debug && printf(STDERR "URL: '%s' Trimurl: '%s'\n", $url, $trimurl);
		# Look up all URL's in the page this URL points to.
#		$url=safeurl($url); # make it safe
		if (!defined($url_2_pages{$url})) {
		  # Have to look at page
		  $ans = "";
		  $verbose && printf("GET '%s'\n", $url);
	  
		  $req = HTTP::Request->new(GET=>$url);
		  
#		  my $redir=$ua->requests_redirectable();
# should this do something
		  my $res = $ua->request($req);
		  if ($res->is_success) {
			my $content = $res->content;
			$content =~ s/%([0-9a-fA-F][0-9a-fA-F])/pack("c",hex($1))/ge;
			if ($debug>3) {
			  printf(STDERR "Content:: '%s'\n", $res->content);	      
			}
			#$content =~ s/href/\nhref/g;

			if ($content =~ /http-equiv=\"*refresh.*\"[\d]*;URL=([^\"]*)\"/) {
#			  printf(STDERR "HERE1\n");
			  &url_2_page($url,$1);
			} elsif (!(($content =~ /head/i) || ($content =~ /html/i)))  {
			  if (length($content)==0) {
				# okay
			  } else {
				$verbose && $debug && printf(STDERR "This URL (missing head/html) looks too strange to check out:: '%s'\n", substr($content,0,300));	      
#			  exit;
			  }
			} else {
			  # Look inside the URL to find more references
#			  @a = split(/[\s<>]/, $content);
			  @a = split(/[ 	<>]/, $content);
			  foreach $i (@a) {
				(0 || ($debug>3) && (length($i)>1)) && printf(STDERR "Looking at '%s'\n", $i);
				my $orig_i = $i;
				if ($i =~ /href=\'mailto:([a-zA-Z0-9]+)\@([^\']*)\'/i) {
				  0 && printf("url %s contains: %s@%s\n", $url,$1,$2);
				  newhost($2);
				  # The next one deals with relative references
				} elsif ($i =~ /href=\'([a-zA-Z0-9.][^'\/]*)\'/i) {
				  (0 || $verbose) && printf("Relative reference i0: %s/%s\n", $trimurl, $1);
				  newurl("$trimurl/$1");
				  # another relative reference
				} elsif ($i =~ /href=\"([a-zA-Z0-9.][^"\/\?]*)\"/i) {
				  (0 || $verbose && $debug) && printf("relative reference i1: '%s'/'%s' ('%s')\n", $trimurl, $1,$i);
				  newurl("$trimurl/$1");
#<frame src="/kpcjb/?cmpid=790&affid=5536" #
				} elsif ($i =~ /src=\"(\/[a-zA-Z0-9.][^"]*)\"/i) {
				  (0 || $verbose && $debug) && printf("src reference s1: %s%s\n", $trimurl, $1);
				  newurl("$trimurl$1");
#				} elsif ($i =~ /https*:\/\/[0-9a-zA-Z_.-]+\//i) {
				} elsif ($i =~ /http-equiv=/i) {
				  # skipping
				} elsif ($i =~ /https*:\/\/[0-9a-zA-Z]/i) {
				  (0 || $verbose && $debug) && printf("found some sort of http reference: %s\n", $i);

				  find_url_in_string($url, $i);
				} else {
				  $i =~ s/%([0-9a-fA-F][0-9a-fA-F])/pack("c",hex($1))/ge;
				  if (0 && $i =~ /VALUE=.*http/i) {
					(0 || $debug && $verbose) && printf(STDERR "While looking at URL $url, Recursing on string '%s'\n", $i);
					find_url_in_string($url, $i);
				  } elsif ($i =~ /http/) {
					(0 || $debug && $verbose) && printf(STDERR "While looking at url $url, Recursing on string '%s'\n", $i);
					find_url_in_string($url, $i);
				  }
				}
			  }
			}
		  } elsif ($res->is_redirect) {
			printf(STDERR "URL '%s' fails with redirect: %s\n", $url,$res->code);
		  } elsif ($res->is_error) {
			$debug && $verbose && printf("URL[1] '%s' fails: %s\n", $url,$res->code);
#	    $url_2_pages{$url} = "ERROR " . $res->status_line ;
		  } else {
			$debug && $verbose && printf("URL[2] '%s' fails: %s\n", $url,$res->code);
#	    $url_2_pages{$url} = "UNDEFINED\n";
		  }
		} else {
		  ($debug>2) && printf("URL '%s' defined, contains: %s\n", $url, $url_2_pages{$url});
		}
		if (defined($url_2_pages{$url})) {
		  # printf("URL '%s' contains: %s\n", $url, $url_2_pages{$url});
		} else {
		  #	  printf("URL '%s' undefined\n", $url);
		}
      }
    }
    ($depth >= 0) && ($level > $depth) && $done++;
    (!$more) &&  $done++;
  }
}

#  if ($url =~ /https*:\/\/.*@([a-zA-Z][a-zA-Z.0-9_-]+)\//) {
#    $host=$1;
#  } elsif ($url =~ /https*:\/\/([a-zA-Z][a-zA-Z.0-9_-]+)\//) {
#    $host=$1;
#  } elsif ($url =~ /https*:\/\/([a-zA-Z][a-zA-Z.0-9_-]+):\d+\//) {
#    $host=$1;
#
#
#  } elsif ($url =~ /https*:\/\/([a-zA-Z][a-zA-Z.0-9_-]+)\//) {
#    $host=$1;
#  } elsif ($url =~ /https*:\/\/([a-zA-Z][a-zA-Z.0-9_-]+)$/) {
#    $host=$1;
#  } elsif ($url =~ /https*:\/\/([0-9.]+)\//) {
#	# dotted quad
#  } elsif ($url =~ /https*:\/\/([0-9.]+)$/) {
#	# dotted quad
#  } elsif ($url =~ /https*:\/\/.*@([0-9.]+)$/) {
#	# dotted quad
#  } elsif ($url =~ /https*:\/\/.*@([0-9.]+)\//) {
#	# dotted quad
#  } elsif ($url =~ /^([a-zA-Z][a-zA-Z0-9.-]*)$/) {
#	$host = $1;
#  } elsif ($url =~ /^([0-9]+[a-zA-Z][a-zA-Z0-9.-]*)$/) {
#	$host = $1;
#  } elsif ($url =~ /^([0-9]+[a-zA-Z-][a-zA-Z0-9.-]*)$/) {
#	$host = $1;
#  } elsif ($url =~ /^([0-9]+\.[a-zA-Z][a-zA-Z]*)$/) {
#	$host = $1;
#  } elsif ($url =~ /^https*:\/\/([0-9]+[a-zA-Z-][a-zA-Z0-9.-]*)$/) {
#	$host = $1;
#  } elsif ($url =~ /^https*:\/\/([0-9]+[a-zA-Z-][a-zA-Z0-9.-]*)/) {
#	$host = $1;
#  } elsif ($url =~ /^https*:\/\/([a-zA-Z][a-zA-Z0-9.-]*)/) {
#	$host = $1;
#  } elsif ($url =~ /^https*:\/\/([0-9][0-9]*\.[a-zA-Z][a-zA-Z0-9.-]*)/) {
#	$host = $1;
#  } else {
#	printf(STDERR "I don't know how to get the hostname from url '%s'\n", $url);
#  }

sub splithosturl {
  # split URL into hostpart and URL part
  my ($string) = @_;
  my ($host,$url);
  my $orig=$string;
# Dumb spammer had
# http://http://www.hottestrevues.com/candy.htm
# http://64.233.179.104http://www.google.com/search?q=cache:Jqz_ApASVhQJ:www.tvn.cl/+Chile&hl=en&ie=UTF-8
  $string =~ s,^http://http://,http://,;
  while ($string =~ /^https*:(.*)/)  {
	$string = $1;
  }
  if ($string =~ /\/\/([^\/]+)\/(.*)/) {
       $host=$1;
       $url = $2; 
     } elsif ($string =~ /\/\/([^\/]+)\?(.*)/) {
       $host=$1;
       $url = $2; 
	 } elsif ($string =~ /\/\/([^\/]+)$/) {
	   $host=$1;
	 } elsif  ($string =~ /([\w\.]+)\.$/) {
	   $host=$1;
	 } elsif  ($string =~ /([\w\.]+)$/) {
	   $host=$1;
     } elsif ($string =~ /\/\//) {
	   $host=undef;
	 } else {
	   printf(STDERR "Cannot parse URL[1]: '%s'\n", $string);
	   croak;
	 }
  if (defined($host)) {
	if ($host =~ /.*@(.*)/)  {
	  $host = $1;
	}
	if ($host =~ /(.*):\d+/) {
	  $host = $1;
	}
	if ($host =~ /(.*)\?.*/) {
	  $host = $1;
	}
	if ($host =~ /(.*)\'/) { #src="http://media.fastclick.net')
	  $host = $1;
	}
	if ($host =~ /(.*)\)/) { #src="http://media.fastclick.net')
	  $host = $1;
	}
  }
  if (defined($url)) {
	if ($url =~ /(.*)\#.*$/) {
	  $url = $1;
	}
  }
  if ($verbose && $debug && defined($string) && defined($host) && defined($url)) {
	if (length($string)>(length($host)+length($url)+8)) {
	  printf(STDERR "'%s' trimmed to HTTP://'%s'/'%s'\n", 
			 $string,$host,$url);
	} else {
	  # printf(STDERR "HTTP://'%s'/'%s'\n",   $host,$url);
	}
  }
  if (defined($host)) {
	if ($host =~ /^javascript/) {
	  # skip
	} elsif ($host =~ /[^\w\.-]/) {
	  printf(STDERR "Host has bad character: '%s', orig: '%s'\n", $host, $orig);	
	  $host="example.com";
	  #croak;
	}
  }
  return($host,$url);
}
sub cleanurl {
  my ($url) = @_;
  my ($orig) = $url;
  $url =~ s/%([0-9a-fA-F][0-9a-fA-F])/pack("c",hex($1))/ge;
  $url =~ s:/./:/:g;
  $url =~ s/#.*$//;
  if ($url =~ /(https*:\/\/[\w.]+$)/) {
	$url = "$url/";
  }
  if ($url ne $orig) {
	printf(STDERR "URL '%s' changed to '%s'\n",$orig, $url);
  }
  return $url;
}
sub safeurl {
  my ($url) = @_;
#   $url =~ s/\014/%0C/;
#	$url =~ s/%([0-9a-fA-F][0-9a-fA-F])/pack("c",hex($1))/ge;
  return $url;
}
sub find_url_in_string {
  my ($url, $string) = @_;
  # Given $url that contains string $string, if I find a HTTP reference, then 
  # add it to the list of url's to check
  my $i = $string;
  if ($i =~ /.*>(https*:\/\/[^<]+)</i) {
	$i = $1;
  }
  if ($i =~ /.*"(https*:\/\/[^"]+)"/i) {
	$i = $1;
  }
  if ($i =~ /.*'(https*:\/\/[^']+)'/i) {
	$i = $1;
  }
  if ($i =~ /href=\"(https*:\/\/[^"]+)\"/i) {
	$i = $1;
	(0 || $verbose) && printf("Found : %s\n", $i);
  }
# <a href="/ 
#            http://resources.powweb.com">
  if ($i =~ /(https*:\/\/[^"]+)\"/i) {
	$i = $1;
	(0 || $verbose) && printf("Found : %s\n", $i);
  }

  if ($i =~ /\'\+document\.domain\+\'/) {
	# Extract domain
	  #printf(STDERR "found document.domain\n");
	my $domain;
	my $newi;
	if ($url =~ /http:\/\/([a-zA-Z0-9.-]+)/) {
	  $domain = $1;
	  $newi = $i;
	  $newi =~ s/\'\+document\.domain\+\'/$domain/;
	  #printf(STDERR "old i: $i, new i: $newi\n");
	  $i = $newi;
	} else {
	  #printf(STDERR "url is %s\n", $url);
    }
  }
  (0 || $verbose) && printf("Looking>> at : %s\n", $i);
  if ($i =~ /^https*:\/\//) {
	&url_2_page($url,$i);
  } elsif ($i =~ /^href=(https*:\/\/.+)/) {
	&url_2_page($url,$1);
  } elsif ($i =~ /^href=(\"https*:\/\/.+)\"/) {
	&url_2_page($url,$1);
  } elsif ($i =~ /src=(https*:\/\/[^ 	]*)[ 	]/) {
	&url_2_page($url,$1);
  } elsif ($i =~ /src=(https*:\/\/[^ 	]*)$/) {
	&url_2_page($url,$1);
  } elsif ($i =~ /src=[\'\"](https*:\/\/[^\"\']+)[\'\"]/) {
	&url_2_page($url,$1);
  } elsif ($i =~ /src=[\'\"](https*:\/\/[^\"\']+)[\'\"]/) {
	&url_2_page($url,$1);
  } else {
	$verbose && printf(STDERR "This URL part looks too strange to check out:: '%s', while on page '%s'\n", $i, $url);
  }
}
sub printthem { # New version
  my @strings;
  my $s;
  my $address;
  my @aliases;
  my $alias;
  my $hostname;
#  printf("#%-17s %27s %25s %25s\n", "IP Address", "Host name", "Name Server", "Mail Server");
  foreach $h (keys %ipaddresses) {
    if (defined($ip_2_ohost{$h})) {
      if ($ip_2_ohost{$h} =~ /-1/ ) {
		push(@strings,sprintf("%-17s ?",$h));
      } else {
		push(@strings,sprintf("%-17s %s",$h,$ip_2_ohost{$h}));
      }
    } else {
	push(@strings,sprintf("%-17s ???????",$h));
    }
  }
  foreach $s (sort sortip @strings) {
    $domain="";
    if ($s =~ /^(\S+)\s+(\S+)$/) {
      $address = $1;
      $hostname=$2;
      if ($hostname =~ /([^.]+\.[^.]+)$/) {
		$domain = $1;
      }
      if ($do_block) {
		do_block($address);
      }
      printf("%-17s %25s ", $address, $hostname);
      if (defined($host_2_mx{$hostname}) && (length($host_2_mx{$hostname})>1)) {
		printf("\tMX: %s", $host_2_mx{$hostname});
      }
    } else {
      printf("%s ", $s);
    }
    
    printf("\n");

    # Now print aliases

	if (!defined($address)) {
	  printf(STDERR "Warning, address for '%s' was undefined\n", $s);
	} else {
	  if (defined($ip_2_alias{$address})) {
      
		(@aliases) = split(/,/, $ip_2_alias{$address});
		foreach $alias (sort @aliases) {
		  $alias =~ s/^\s+//;
		  printf("%17s %25s", "  | alias:", $alias);
		  if (defined($host_2_mx{$alias}) && (length($host_2_mx{$alias})>1)) {
			printf("\tMX: %s", $host_2_mx{$alias});
		  }
		  printf("\n");
		}
	  }
	}    
  }
  foreach $domain (sort keys %domain_2_ns) {
      printf("%s Name servers:\t%s\n", $domain, $domain_2_ns{$domain});
  }
  foreach $url (sort keys %url_2_pages) {
	
      printf("%s contains\n\t%s\n", $url, join("\n\t",split(/[\t]/, $url_2_pages{$url})));    
  }
  
}
&main();
&printthem();
exit 0;
