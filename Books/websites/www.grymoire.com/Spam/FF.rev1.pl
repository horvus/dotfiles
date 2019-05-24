#!/usr/bin/perl
# FF.pl - Find Friends
# Wed Feb 27 07:14:24 EST 2002
# Written by Bruce Barnett 
# e Mail Contact: 
#                   ff01 <at> grymoire.com
#                   Then increase the 2-digit number before the '@'
#                   Let's see what the harvesters do with this one!
#
#  Note - I've written better code
# 
# Usage: give FF a list of hostnames from standard input
# Examples
#
#   echo www.spammer.com | FF.pl
#
#   FF.pl list_o_porn_sites
#
#   FF.pl <list_o_porn_sites
#
# The host names don't have to be one per line.
# You can rename it to be "FF" if you like
#
# FF finds the IP address, Name Servers, and Mail servers of each host.
# It then 'recurses' through the newly found systems, and repeats the process
# Thus it finds all "related" sites.
# Lastly - it sorts the output by IP address so you can spot clusters of related machines
#
# This is useful to find related spam systems.
# Bugs - it only lists the first IP address
#        It only shows the first name server/mail server
#           The other ones are added to the list, 
#           so it may be hard to see how machines are related
# This program is Copyright 2002
# You may use it freely and modify it. Please leave my name in as the creator

use Net::DNS; # You have to get this from CPAN - it's not standard
use strict;


my (
    $line,	# Line read from STDIN
    %hosts,	# list of hosts
    $h,		# Host in the loop
    %host_2_mx, # Host to MX
    %host_2_ns, # host to ns reference
    %host_2_ip, # IP addresses
    @mx, 	# list of MX hosts
    $mx, 	# single MX host
    @ns, 	# list of name servers
    $ns, 	# single name server
    $done,	# true when done
    $more,	# true when more to do
    $domain,	# domain of host
    $verbose,
);

$verbose=0;

sub sortip {
  # sort by IP address
  my ($a1,$a2,$a3,$a4) = $a =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
  my ($b1,$b2,$b3,$b4) = $b =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;

    $a1 <=> $b1
      ||
    $a2 <=> $b2
      ||
    $a3 <=> $b3
      ||
   $a4 <=> $b4;
}
sub newhost {
  # Add a new host to list, if new, then we have to do more work
  my ($host) = @_;
  $host = lc $host;

  if (!defined($hosts{$host})) {
    $hosts{$host} = 0; # First time seeing this host
    $more++;
    $verbose && printf("New host '%s', more: %d\n", $host, $more);
  } else {
    # printf("Old Host: %s\n", $host);
  }
}

sub main {
  # Set up a resolver for future
  my $res = new Net::DNS::Resolver;

  # Now read STDIN
  while (defined($line=<>)) {
    chomp $line;
    my (@list) = split(' ', $line);
    my $l;
    foreach $l (@list) {
      if ($l =~ /[a-zA-Z0-9]+\.[a-zA-Z]/) { # looks like a hostname
	newhost($l); 
      }
    }
  }
  $done = 0;
  while (!$done) {
    $more = 0;
    foreach $h (keys %hosts) { # look at by list of hosts
      if ($hosts{$h} == 0) {
	$verbose && printf("Host: %s\n", $h);
	if ($h =~ /\.*([a-zA-Z0-9-]+\.[a-zA-Z]+)$/) {  # get the domain part - only does top 2 levels
	  $domain = $1;
#	  printf("For host %s, is domain %s\n", $h, $domain);
	} else {
	  printf(STDERR "Cannot find domain from host %s\n", $h);
	}
	if (!defined($host_2_mx{$h})) { # Do I have the MX records for this host?
	  @mx = mx($domain);
	  foreach $mx (@mx) {
	    ($verbose) && printf("MX for %s (%s) is %s\n", $h, $domain, $mx->exchange);
	    newhost($mx->exchange);
	    $host_2_mx{$h} = $mx->exchange; # This only gets the first one
	  }
	}
	if (!defined($host_2_ns{$h})) {	 # do I have the name servers?
	  my $query = $res->query($domain,"NS");
	  if ($query) {
	    foreach $ns ($query->answer) {
	      $verbose && printf("NS for %s (%s) is %s\n", $h, $domain, $ns->nsdname);
	      if ($ns->type eq "NS") {
		newhost($ns->nsdname);
		$host_2_ns{$h} = $ns->nsdname; # This only gets the first one
	      }
	    }
	  }
	}
	if (!defined($host_2_ip{$h})) {	 # get the IP address - NOTE - only gets one
	  my $query = $res->search($h);
	  if ($query) {
	    foreach $ns ($query->answer) {
	      if ($ns->type eq "A") {
		$host_2_ip{$h}=$ns->address;
	      }
	    }
	  }
	  $hosts{$h}++; # done with this host
	}
      }
    }
    (!$more) &&  $done++;
  }
}

sub printthem {
  my @strings;
  printf("#%-20s %25s %25s %25s\n", "IP Address", "Host name", "Name Server", "Mail Server");
  foreach $h (keys %hosts) {
    push(@strings,sprintf("%-20s %25s %25s %25s\n", 
			  defined($host_2_ip{$h}) ? $host_2_ip{$h} : "?", 
			  $h, 
			  defined($host_2_ns{$h}) ? $host_2_ns{$h} : "?", 
			  defined($host_2_mx{$h}) ? $host_2_mx{$h} : "?"
			 ));
  }
  print join ("", sort sortip @strings);
}
&main();
&printthem();
exit 0;
