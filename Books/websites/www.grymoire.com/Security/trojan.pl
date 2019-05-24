##!/bin/sh -- 					# wish I were -*-Perl-*-
##eval 'exec perl -S $0 ${1+"$@"}'
##    if !$$;
##!/bin/perl

# execute by typing:
#
#       perl trojan.pl
#
# Look for trojan horses...

# A trojan horse looks like a regular program. 
# however, if you execute it, the program may set up a back door to 
# your account, or modify one of your files, etc.
#
# This script reports on the different ways someone can drop a trojan hourse
# in your searchpath.
#
# It does not check for set UID or GID programs on your file system, 
# and does not check NFS permissions of directories.
# It only checks for executables in your searchpath, and reports who and how
# someone can create a trojan horse. 
#
# This program also provides a measurement of how vunerable you are to a
# trojan horse. 
#
# Bruce Barnett <barnett@crd.ge.com>
# Copyright 1994 GE
# All commercial Rights reserved
# 
# @(#)trojan.pl	1.13 02/26/01
#
# usage:
# 
#	perl trojan.pl [options]
#
#	where options are any combination of the following
#	-b	- brief report. Don't show reasons or executables
#	-a	- analyze all files. Normally when a file is world writable,
#			don't check for group or user writable
#			the -a means look at all problems, and not the first
#	-w	- just report on world writable problems (no group or user)
#	-g	- report on group writable problems ( sets -w, no user)
#	-u	- report on world, group and user writable problems (Default)
#	-A	- report all files that cause a problem with a group writable
#  		  permission, not just the first one
#
# for debugging purposes, and for more information, try the following options
#	-v	- verbose
#	-d	- debug
#
#	Examples
#	trojan.pl		- reports world, group and user problems
#			  shows reasons for problem
#	trojan.pl -b		- reports world, group and user problems
#			  Doesn't show reasons
#	trojan.pl -b -a	- reports world, group and user problems
#			  Doesn't show reasons
#			  reports on ALL  world, group and user 
#			  writable problems
#	trojan.pl -b -a -A	- reports world, group and user problems
#			  Doesn't show reasons
#			  reports on ALL  world, group and user 
#			  writable problems
#			  Also reports all files that cause group write access
#
#
#	trojan.pl -w 		- reports world writable problems and reasons
#	trojan.pl -g 		- reports world + group writable problems and reasons

#	you probably want to start with trojan.pl -b 
#	and fix some of those problems first
#	If you don't understand why it's a problem, omit the -b option

#	A malicious cracker will often use your co-workers accounts
# 	as a stepping stone to getting root (or bin, daemon, sys, etc.) 
#       access. Therefore you have to trust that none of the people who 
#	could drop a trojan horse in front of you have had their accounts 
#       compromised. If you don't trust them, then don't allow their 
#	binaries in your searchpath.
#
use strict;

my $not_a_csh_script = 0;	# this is used in case someone tries
# $not_a_csh_script && exit;	# this prevents a warning with perl -w
				# "csh trojan.pl"
# command line OPTIONS
my $all = 0;			# print out a more detailed report, (all tests)
my $report_all = 0;			# report all files, not just the first one
my $do_world = 1;			# print out world writable items
my $do_group = 1;			# print out group writable items
my $do_user = 1;			# print out user specific info
my $do_missing = 0;			# print out user specific info
my $brief = 0;			# a short report

my $verbose=0;			# print more information
my $debug = 0;			# 



# VARIABLES
my $dot = 0;	# have I seen the "." directory in the path yet?
my $programsafterdot = 0;		# how many files were found after the dot?
my $TotalFiles = 0;			# total programs or files found in the $PATH directories
my $FilesAfterGroupWritable = 0;	# files found after a group writable directory found
my $GroupWritableDirectoryFound = 0;	# boolean, true if a group writable diectory found
my $FilesAfterWorldWritable = 0;	# files found after a world writable directory found
my $WorldWritableDirectoryFound = 0;	# boolean, true if a world writable diectory found
my $world_writable_programs = 0;
my $group_writable_programs = 0;
my $ProgramsInSomeDir = 0;
my %user;
my %usercount;
my %group_writable;
my %group;
my %groupcount;
my %world_writable;
my %did_checkup_dir;
my %ProgramsInDir;
my %ingroup;
my %dummy;
my %inuid;
my %inuser;
my %user_to_passwd;
my %gid_to_name;

my $WorldWritableProgramsByDirectory;
my $GroupWritableProgramsByDirectory;
my $NumberOfProgramsOwnerByOtherUsers;
my $found;


# constants

my $SEARCHPATH=1;
my $NOSEARCHPATH=0;
# PERL variables
$| = 1;				# write to pipes immediately

my $revision = "1.13";		# SCCS fills 1.13 in
my $program = "trojan.pl";		# SCCS fills trojan.pl in
my $beta;
if ($program =~ /.M./) {	# does it match the trojan.pl SCCS string?
    $program = "Trojan";	# yes, fill in the name of the program
}
if ($revision =~ /%/) {		# is '%' part of the revision
    $beta = 1;			# A beta version
} else {
    $beta = 0;
}

printf("%s, %s, a study in trust...\n",
       $program, 
       $beta ? "Beta release" : "Revision $revision");
&getswitches();
&main();
&report();
exit 0;

# --- SUBROUTINES ---

sub getswitches {
  # parse arguments
  my ($usage) = 0;
  while ($#ARGV>=0 && $ARGV[0] =~ /^-/) {
    my ($arg) = shift(@ARGV);
    $arg =~ /^-v$/ && ($verbose++,next);
    $arg =~ /^-d$/ && ($debug++,next);
    $arg =~ /^-a$/ && ($all++,next);
    $arg =~ /^-A$/ && ($report_all++,next);
    $arg =~ /^-b$/ && ($brief++,next);
    $arg =~ /^-m$/ && ($do_missing++,$do_group=0,$do_user=0,$do_world=0,next);
    $arg =~ /^-w$/ && ($do_world++,$do_group=0,$do_user=0,$do_missing=0,next);
    $arg =~ /^-g$/ && ($do_group++,$do_world=0,$do_user=0,$do_missing=0,next);
    $arg =~ /^-u$/ && ($do_user++,$do_world=0,$do_group=0,$do_missing=0,next);
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
    printf(STDERR "Usage: %s [-vdaAbwgu]\n", $program);
    printf(STDERR "\t-v => Verbose\n");
    printf(STDERR "\t-d => Debug\n");
    printf(STDERR "\t-a => Analyse all files, ALL reasons\n");
    printf(STDERR "\t-A => Show ALL files, not just the first example\n");
    printf(STDERR "\t-b => Brief report, don't show reasons\n");
    printf(STDERR "\t-m => Just report MISSING links\n");
    printf(STDERR "\t-w => Just report WORLD writable files\n");
    printf(STDERR "\t-g => Just report GROUP writable files\n");
    printf(STDERR "\t-u => Report world, group and user writable files\n");
    exit 1;
  }
}
sub main {
    &getusers();
    &getgroups();
    &dotrojans();
}
sub dotrojans {
  my ($dir, $reason, $link, $oldlink, $newlink);
  
    &checkrootdir();
    my @dirs = split(/:/,$ENV{'PATH'});
    foreach $dir (@dirs) {
	$debug && $verbose && printf("%s: \n",$dir);
	$reason = "$dir is in your searchpath";
	if ($dir eq ".") {
	    $dot++;
	    $dir = `pwd`;
	    chop $dir;
	}
	if ( -l $dir) {
	    $link = readlink($dir);
	    $debug && printf("$dir points to  $link\n");
	    $reason .= " AND $dir -> $link";
	    if ($link !~ /^\// ) {
		# a relative link
		$link = &resolve($dir,$link);
		$reason .= " ($link) ";
	    }
	    &checkupdir($link,$reason,$SEARCHPATH);
	    while ( -l $link ) {
		$oldlink = $link;
		$link = readlink($oldlink); #
		if ($link !~ /^\// ) {
		    # a relative link
		    $newlink = &resolve($dir,$link);
		    $reason .= " ($newlink) ";
		}
		$reason .= "$oldlink -> $link AND"; 
		&checkupdir($link,$reason,$SEARCHPATH);
	    }
	    if ( -d $link ) {
		&checkdir($link, $reason);
		&checkupdir($link,$reason,$SEARCHPATH);
		&checkexecsindir($link, $reason);
		
		
	    }
	} elsif ( -d $dir ) {
	    &checkdir($dir, $reason);
	    &checkupdir($dir,$reason,$SEARCHPATH);
	    &checkexecsindir($dir, $reason);
	}
	
    }
}
sub checkdir {
    # check the directory itself - it was in the searchpath
    my ($dir, $reason) = @_;
    # does the directory exist?
    if ( -l $dir ) {
	printf(STDERR "ERROR: I am testing $dir and it is a link.\n");
    } elsif ( -d $dir ) {
	&testdir($dir,$reason);
    } else {
	printf(STDERR "Missing Directory in searchpath : %s\n", $dir);
    }
}
sub testdir {
    # check the directory itself
    my ($dir,$reason) = @_;
    my ($hit) = 0;
    # does the directory exist?
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,
     $size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($dir);
    if ($mode & 002) {
	$hit = 1;
	$WorldWritableDirectoryFound = 1;
	&addworld_directory("$reason AND $dir is WORLD writable", $dir);
    }
    # if group writable AND (not world writable or all)
    if ((!$hit || $all) && ($mode & 020)) {
	$hit = 1;	    
	$GroupWritableDirectoryFound = 1;
	&addgroup_directory($gid,"$reason AND directory $dir is group writable",
			    $dir);
    }
    if (!$hit || $all) {
	&adduser($uid,"$reason AND directory $dir writable by owner"); # owner can write to directory
    }
}	
sub checkexecsindir {
    # check each executable in the directory
    my ($dir, $problem) = @_;
    my ($hit, $file);
    my ($program, $link, $myproblem, $newdir);
    $verbose && printf("check execs in dir $dir, reason: $problem\n");
    opendir(D, $dir) || return 0;
    while ($file = readdir(D)) {
	$myproblem = $problem;
	(($file eq ".") || ($file eq "..")) && next;
	$TotalFiles++;	# increase number of files found
	$GroupWritableDirectoryFound && $FilesAfterGroupWritable++;
	$WorldWritableDirectoryFound && $FilesAfterWorldWritable++;
	# this is either a file, a directory, or a symbolic link.
	# if a directory, then don't worry about it.
	$program = "$dir/$file";
	# if file, only worry about it if it's executable,
	
	if ( -l $program) {
	    # this is a link. Does it point to a file or to a directory?
	    # the file in the searchpath is a symbolic link
	    # if it points to a directory, then check who owns the directory
	    #   it is pointing to
	    while ( -l $program ) {
		$link = readlink($program);	
		$myproblem .= " AND $program -> $link";
		if ($link !~ /^\// ) {
		    # a relative link
		    $link = &resolve($program,$link);
		    $myproblem .= " ($link) ";
		}
		$debug && printf("Problem is now: %s, new program is %s\n", 
				 $myproblem, $link);
		my $newdir = $link;
		$newdir =~ s,/[^/]+$,,;	# remove the executable from the path, and check the directory
		$debug && printf("YES: The directory to check now is %s\n",
				 $newdir);
		&ProgramUsesDir($newdir);
		&checkupdir($newdir, "$myproblem ", $NOSEARCHPATH);
		$program = $link;
	    }
	    # no longer a link, it might be a file of directory
	    # get the stat on the final file
	    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,
	     $size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($link);
	    if (!defined($dev)) {
		# find where it's pointing
		if ($brief) {
		  if ($do_missing) {
		   printf("%s/%s\n", 
				 $dir,$file);
		  }
		}
		 else {
		   printf("Warning: symbolic link %s/%s pointing to missing file: %s\n", 
				 $dir,$file, $link);
		}
		&checkmissingdir($link,$program);
	    } elsif ( -d $link ) {
		# a symbolic link points to a directory.
		# this is only a problem if the directory pointing to is inside
		# a directory that can be modified
		$verbose && printf("\n$dir/$file points to directory $link\n");
		$newdir = $link;
		$newdir =~ s,/[^/]+$,,;
		$verbose && printf("HEY: $link is a directory, and $newdir should be checked\n");
		&checkupdir($newdir, "$dir/$file -> $link AND ",$NOSEARCHPATH);
	    } else {
#		printf("$program points to file $link\n");
		$hit = 0;
		
		if ($mode & 0111) { # is this file executable?
		    ($hit = ($mode & 002)) && &addworld_file("$dir/$file -> $link AND $link is WORLD writable", "$dir/$file");
		    ($hit = ($mode & 020)) && ($all || !$hit)  && &addgroup_file($gid,"file $dir/$file -> $link AND $link is group writable", "$dir/$file");
		}
		($all || !$hit) && &adduser($uid,"file $dir/$file -> $link modifiable by owner");	# owner can modify the target file, and make it executable if it isn't
		# also check by going up the tree of the executable
		$newdir = $link;
		$newdir =~ s,/[^/]+$,,;
		
		$debug && printf("YO: link: $link, newdir: $newdir, calling checkupdir\n");
		&ProgramUsesDir($newdir);
		&checkupdir($newdir, "$dir/$file -> $link AND ",$NOSEARCHPATH);	# did I do this twice?
	    }
	    #
	    # if it is a file, check the permission of the file
	    #
	} elsif ( -d "$dir/$file" ) { # Not a link, maybe a directory?
	    # yes a directory in our search path. Does this mean anything?
	    # I guess not. We already go up the directory path
	    
	} else { # not a link or directory - a file
	    # stat the file

	    &ProgramUsesDir($dir);
	    &testfile("$dir/$file", "$dir/$file executable in path");
	}
    }
    close(D);
}

sub testfile {
    my ($file,$reason) = @_;
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,
     $size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
    my $hit = 0;
    if ($mode & 0111) { # is this file executable?
#	printf("Executable $dir/$file seen\n");
	# increase the number of programs seen
	# if the "." directory has been seen, then
	# this program can be trojanized
	$dot && $programsafterdot++;
	
	if ($mode & 002) {
	    # world writable
	    $hit = 1;
	    &addworld_file("$reason AND $file is WORLD writable", "$file");
	}
	# if group writable AND (not world writable or all)
	if ((!$hit || $all) && ($mode & 020)) {
	    $hit = 1;	    
	    &addgroup_file($gid,"$reason AND file $file is group writable", "$file");
	}
    }
    # it doesn't matter if the file is executable or not, 
    # the owner can make it executable
    ($all || !$hit) && &adduser($uid,"$reason AND file $file modifiable by owner");
}


sub adduser {
    my ($user,$dir) = @_;
    if (defined($user{$user})) {
	if ($report_all) {
	    ($user != "0" && $user != $< ) && printf("user %s can do it because of %s\n", $user, $dir);
	} else {
	    $debug && $verbose && printf("user %s can do it because of %s\n", $user, $dir);
	}

	# add it to the list
	$user{$user} .= "\n$dir";
	$usercount{$user}++;
	
    } else {
	$user{$user} = $dir;
	$usercount{$user} = 1;
	$verbose && printf("user %s can do it because of %s\n", $user, $dir);
    }
}
sub addgroup_directory {
    my ($gid,$reason,$dir) = @_;
#    $GroupWritableDirectoryFound = 1;
    if (!defined($group_writable{$dir})) {
	&addgroup($gid, $reason, $dir);
	$group_writable{$dir} = 1;
    } else {
	$group_writable{$dir}++ ;
	$verbose && printf("Directory '$dir' found again\n");
    }
}
sub addgroup_file {
    my ($gid, $reason,$file) = @_;
    $verbose && printf("Group Writable program, gid: %d, file: %s, reasons: %s\n",
		       $gid, $file, $reason);
    $group_writable_programs++;
    &addgroup($gid, "File $reason", $file);
}
sub addgroup {
    my ($gid,$reason) = @_;
    
    if (defined($group{$gid})) {
	if ($report_all) {
	    $all && printf("group %s can do it because of %s\n", $gid, $reason);
	} else {
	    $all && $verbose && printf("group %s can do it because of %s\n", $gid, $reason);

	}
	# add it to the list
	$group{$gid} .= "\n$reason";
	$groupcount{$gid}++;
    } else {
	$group{$gid} = $reason;
	$groupcount{$gid} = 1;
	$verbose && printf("group %s can do it because of %s\n", $gid, $reason);
    }
}
sub addworld_directory {
    my ($reason,$dir) = @_;
#    $WorldWritableDirectoryFound = 1;
    if (!defined($world_writable{$dir})) {
	&addworld($reason);
	$world_writable{$dir} = 1;
    } else {
	$world_writable{$dir}++ ;
	$verbose && printf("Directory '$dir' found again\n");
    }
}
sub addworld_file {
    my ($reason,$file) = @_;
    $world_writable_programs++;
    &addworld("File $reason");
}
sub addworld {
    my ($reason) = @_;
    $reason =~ s/-\>/\n\t\t->/g;
    $reason =~ s/AND/\n\t\tAND/g;
    # remember world writable directories
    
    !$brief && printf("ANYONE can do it because of %s\n", $reason);
}
sub checkupdir {
    # check the paths leading to the directory
    my ($dir, $reason,$onpath) = @_;
    # $onpath is true if this directory is on the searchpath, else false
    if (defined($did_checkup_dir{$dir})) {
	$debug && printf("already checked updir %s\n", $dir); 
	return 0;		# did it
    } else {
	$did_checkup_dir{$dir} = 1;
    }
    if ($dir eq "." ) {
	die " I should not see a dot in $dir while  in checkupdir";
    } elsif ( $dir =~ /^\.\// ) {
	die " I should not see a ./ in $dir while  in checkupdir";
    } elsif ( $dir =~ /\/\.\.\// ) {
	die " I should not see a /../ in $dir while  in checkupdir";
    } elsif ( $dir =~ /^\.\.\// ) {
	die " I should not see a ../ in $dir while  in checkupdir";
    }
    $verbose && printf("checking up dir %s, reason: %s\n",
		       $dir, $reason);
    # $dir is the file we are checking, and $reason is why (i.e. "a/b -> /c and")
#    $origfile = $dir;
    while ($dir ne "") {
	#remove the last path
	1 && $verbose && printf("checkupdir: checking %s\n", $dir);
	if ( -d $dir ) {
	    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,
	     $size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$dir");
	    my $hit = 0;
	    if ($hit = ($mode & 002)) {
		$onpath && ($WorldWritableDirectoryFound = 1);
		&addworld_directory("$reason AND $dir is WORLD writable", $dir);
	    }
	    if ($hit = ($mode & 020)) {
		$onpath && ($GroupWritableDirectoryFound = 1);
		($all || !$hit) && &addgroup_directory($gid,"$reason $dir is group writable", $dir);
	    }
	    ($all || !$hit) && &adduser($uid,"$reason $dir is writable by owner");	# owner can write to directory
	} elsif ( ! -e $dir ) {
	    !$brief && printf(STDERR "WARNING: non-existing directory used: $dir\n");
	} else {
	    !$brief && printf(STDERR "WARNING: non-directory used: $dir\n");
	}
	$dir =~ s,/[^/]*$,,;	# remove last directory from path
    }
}
sub checkrootdir {
    # check the paths leading to the directory
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,
     $size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("/");
    my $hit = 0;
    ($hit = ($mode & 002)) && &addworld_directory("'/' is WORLD writable", "/");
    ($hit = ($mode & 020)) && ($all || !$hit) && &addgroup_directory($gid,"Directory '/' is group writable", "/");
    ($all || !$hit) && &adduser($uid,"Directory '/' is writable by owner");	# owner can write to directory
}
sub checkmissingdir {
    # this argument is a file that is missing
    # check to see if each directory up the ladder
    # has permission problems.
    my ($file, $where) = @_;
	my $hit;
    my $origfile = $file;
    while ($file =~ s,/[^/]*$,, && $file ne "") {
	#remove the last path
	$debug && $verbose && printf("checking %s\n", $file);
	if ( -d $file ) {
	    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,
	     $size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$file");
	    $hit = 0;
	    ($hit = ($mode & 002)) && &addworld_directory("$where -> $origfile AND $file is WORLD writable", $file);
	    ($hit = ($mode & 020)) && ($all || !$hit) && &addgroup_directory($gid,"$where -> $origfile AND $file is group writable", $file);
	    ($all || !$hit) && &adduser($uid,"$where -> $origfile AND directory $file is writable by owner");	# owner can write to directory
	}
    }
}
sub report {
# final report
  my ($d,  $g, $members, $name, $files, $m, $u, $file, $gid, $oldlink);
  if ($debug || $verbose ) {
	printf("Options: ");
	$brief && printf("brief ");
	$all && printf("all  ");
	$do_world && printf("do_world ");
	$do_group && printf("do_group ");
	$do_user && printf("do_user ");
	$debug && printf("debug ");
	$verbose && printf("verbose ");
	printf("\n");
  }
    $WorldWritableProgramsByDirectory = 0;
    foreach $d (keys %world_writable) {
	printf("World writable directory %s makes %d files vulnerable\n",
	       $d, $ProgramsInDir{$d});
	$WorldWritableProgramsByDirectory += $ProgramsInDir{$d};
    }
    # now for each group
    if ($do_group) {
	$GroupWritableProgramsByDirectory = 0;
	foreach $d (keys %group_writable) {
	    printf("Group writable directory %s makes %d  files vulnerable\n",
		   $d,  $ProgramsInDir{$d});
	    $GroupWritableProgramsByDirectory += $ProgramsInDir{$d};
	}
	foreach $g (keys %group) {
	    $members = $ingroup{$g};
	    $name = $gid_to_name{$g};
	    $files = $group{$g};
	    $files =~ s/\n/\n\t/g;
	    $files =~ s/AND/AND\n\t\t/g;
	    # truncate all files but the first
	    if (!$brief) {
	    	printf("\nGroup %s can do it %d ways: \n\t%s\n",
		       $name, $groupcount{$g}, $files);
	    	if ($do_user) {
		    if (defined($members)) {
			printf("\tmembers of this group are:\n");
			undef(%dummy);
			foreach $m (split(/ /,$members)) {
			    if (!defined($dummy{$m})) {
				printf("\t\t%s\n", $m);	    
				$dummy{$m}=1;
			    }
			}
		    }
		}
	    }
	}
    }
# now look for each user
    if ($do_user) {
	$NumberOfProgramsOwnerByOtherUsers = 0;
	foreach $u (keys %user) {
	    $name = $inuid{$u};
	    $files = $user{$u};
	    if (!defined($name)) {
		printf("UNKNOWN USER, UID = %d, ", $u);
	    } else {
		if (defined($user_to_passwd{$name})) {
		    printf("User %s, UID: %d, ",
			   $name, $u);
		} elsif ($name =~ / /) {
		    # more than one person has this UID...
		    printf("Users %s, UID: %d, ",
			   $name, $u);
		} else {
		    printf("Users %s, UID: %d, ",
			   $name, $u);
		}
	    }
	    if ($u == 0) {
		printf("owns %d file, but you should be able to trust root",
		       $usercount{$u});
	    } elsif ($u == $>) {
		printf("owns %d file, (but you should be able to trust yourself :-)",
		       $usercount{$u});
	    } else {
		# truncate all files but the first
		($file) = split("\n", $files);
		printf("owns %d file%s",
		       $usercount{$u}, 
		       ($usercount{$u} == 1) ? "" : "s");
		!$brief && printf(", Example %s",
				  $file);
		$NumberOfProgramsOwnerByOtherUsers +=$usercount{$u};
	    }
	    printf("\n");
	}
    }
#    printf("Number of executable programs: %d\n", $programs);
    printf(" ---- Score (lower percentages are better) ----\n");
    
    $ProgramsInSomeDir = $TotalFiles;
    printf("Number of programs/files in searchpath: %d\n", $ProgramsInSomeDir);
    $do_user && printf("Number of programs writable by others (excluding root and self): %d (%4.2f%%)\n", 
		       $NumberOfProgramsOwnerByOtherUsers,
		       ( $NumberOfProgramsOwnerByOtherUsers/$ProgramsInSomeDir)*100 );
    if ($do_group) {
	printf("Number of group writable programs: %d (%4.2f%%)\n", 
	       $group_writable_programs, 
	       ($group_writable_programs/$ProgramsInSomeDir)*100 );
	$debug && printf("Number of executables in group writable directories: %d (%4.2f%%)\n", 
	       $GroupWritableProgramsByDirectory,
	       ( $GroupWritableProgramsByDirectory /$ProgramsInSomeDir)*100 );
    }
    printf("Number of world writable programs: %d (%4.2f%%)\n", 
	   $world_writable_programs, 
	   ($world_writable_programs/$ProgramsInSomeDir)*100 );
    $debug && printf("Number of executables in world writable directories: %d (%4.2f%%)\n", 
	   $WorldWritableProgramsByDirectory,
	   ( $WorldWritableProgramsByDirectory /$ProgramsInSomeDir)*100 );
    if ($dot) {
	printf("You have included '.' (current working directory) in your searchpath\n");
	if ($programsafterdot) {
	    
	    printf("%d files out of %d executable files (%4.2f%%) can be intercepted by a trojan horse depending on your current directory\n",
		   $programsafterdot, $ProgramsInSomeDir, ($programsafterdot/$ProgramsInSomeDir)*100.0);
	    printf("You are 100%% susceptible to a misspelled program in your current directory (e.g. 'mroe')\n");
	}
    }
    if ($WorldWritableDirectoryFound) {
	printf("%6.2f%% of your files (%d out of %d) may be intercepted because of world writable directories\n",
	($FilesAfterWorldWritable/$TotalFiles)*100,
	$FilesAfterWorldWritable,
	$TotalFiles);
    }
    if ($GroupWritableDirectoryFound) {
	printf("%6.2f%% of your files (%d out of %d) may be intercepted because of group writable directories\n",
	($FilesAfterGroupWritable/$TotalFiles)*100,
	$FilesAfterGroupWritable,
	$TotalFiles);
    }
    printf("----\n");
    printf("You may also want to check for set user or set group commands, using..\n");
    printf("\tfind / -type f -perm -4000 -print\n");
    printf("\tfind / -type f -perm -2000 -print\n");
    printf("... but this will take a while.\n");
    printf("You must also trust the systems that provide you with NFS directories\n");
	   


    
}


sub getusers {
    my ($login,$passwd,$uid,$gid);
	my (@list);
# learn about all of the users via the /etc/passwd file
    setpwent();			# # initialize the passwd scan
    while (@list = getpwent) {	# fetch the next entry
	($login,$passwd,$uid,$gid) = @list[0,1,2,3]; #grab the first 4 fields
	if ($debug && (($uid == 2) || ($uid == 3) || ($gid == 2) || ($gid == 3))) {
	    printf("User %s, UID: %d, GID: %d\n", $login, $uid, $gid);
	}
	&add_to_group($gid,$login);	# list of people who belong to the group
	&add_to_uid($uid,$login);	# list of accounts who have the same UID
	
	if (length($passwd) == 13) {
	    $user_to_passwd{$login} = $passwd; # do they have a password?
	} else {
#	    printf("user %s doesn't have a password\n", $login);
#	    printf("length of password %s is %d\n", $passwd, length($passwd));
	}
    }
    endpwent();			# end the scan
}
sub getgroups {
# learn about all of the groups via the /etc/group file
    my ($login,$passwd,$uid,$members, @list, $gid, $m, $u, $oldlink);
    setgrent();			# # initialize the group scan
    while (@list = getgrent()) {	# fetch the next entry
	($login,$passwd,$gid,$members) = @list[0,1,2,3]; #grab the first 4 fields
	if ($debug && (($gid == 2) || ($gid == 3))) {
	    printf("Group %s, GID: %d\n", $login, $gid);
	}
	if (!defined($gid_to_name{$gid})) {
	    $gid_to_name{$gid} = $login;
	} else {
	    # group already defined
	    if ($gid_to_name{$gid} ne $login)  {
		$verbose && printf("Group ID #%d, name: %s, also called %s - ignoring new name\n",
		       $gid, $gid_to_name{$gid}, $login);
	    }
	}

	# each of the members should be added to the group list
	foreach $m (split(/ /,$members)) {
	    0 && $debug &&  printf("adding %s to group %s(%d)\n",
				$m, $login, $gid);
	    &add_to_group($gid,$m);	# list of people who belong to the group
	}
	if (defined($passwd) && length($passwd) == 13) {
#	    $group_to_passwd{$login} = $passwd; # do they have a password?
	} else {
#	    printf("group %s doesn't have a password\n", $login);
#	    printf("length of password %s is %d\n", $passwd, length($passwd));
	}
    }
    endgrent();			# end the scan
    
}
sub add_to_group {
    my  ($gid,$login) = @_;	# list of people who belong to the group
    # add user $login to group $gid
    if (defined($ingroup{$gid})) {
	$ingroup{$gid} .= " $login";
    } else {
	$ingroup{$gid} = "$login";
    }
}
sub add_to_uid {
    my ($uid,$login) = @_;	# list of accounts who have the same UID
# create map of UID -> USERS
	my $u;
	
	
    if (defined($inuid{$uid})) {
	# check to see if name is in the list
	$found = 0;
	foreach $u (split(/ /,$inuid{$uid})) {
	    ($u eq $login) && $found++;
	}
	(!$found) && ($inuid{$uid} .= " $login");
    } else {
	$inuid{$uid} = "$login";
    }
# check for map of user -<> UIDs.
#; if more than one, error
    if (defined($inuser{$login})) {
	if ($uid != $inuser{$login}) {
	    
	    $inuser{$login} .= " $uid";
	    printf(STDERR " User %s (UID: %d) has duplicate UID's : %s\n", $login, $uid, $inuser{$login});
	} else {
	    # saw this user twice, but the UID was the same
	}
    } else {
	$inuser{$login} = "$uid";
    }
    
}
sub resolve {			# resolve symbolic/soft links
    my ($current,$link) = @_;
    my ($newlink,$newcurrent);
	my $oldlink;
    # we are faces with a relative symbolic link
    # that is, the firct character of $link is NOT a '/'
    # the following table is in a spefcial format that will allow
    # testing of each case. This is why there are so many cases
    # I have a script that extracts these tests and 
    # verifies the input and output
    # the test conditions are included in the source code, but the
    # program that extracts these values and constructs the test case is
    # in a seperate file
    # how it works is that the currect directory is assumed to be column 1
    # the symbolic link is column 2
    # the results should match column 3
# START TEST
    # Current	Link		Output

# test variations of "/" as left
#;#	/	../		/
#;#	/	../../		/
#;#	/	../x/y		/x/y
#;#	/	../../x/y	/x/y
#;#	/	.		/
#;#	/	./x		/x
#;#	/	./x/y		/x/y
#;#	/./	.		/
#;#	/./	./x		/x
#;#	/./	./x/y		/x/y

#;#	/a/b	x/y		/a/x/y
#;#	/a	x		/x
#;#	/a	x/y		/x/y

#;#	/a/b/c	.		/a/b
#;#	/a/b/c	./x		/a/b/x
#;#	/a/b/c	../x		/a/x
#;#	/a/b/c	./../x		/a/x
#;#	/a/b/c	../../x		/x
#;#     /a/c/b  ./../x          /a/x

# END TEST

    $newlink = "";
    if ($current =~ /^\.\.\// ) {
	die "ERROR : left side can't start with ../";
    } elsif ($current =~ /^\.\// ) {
	die "ERROR : left side can't start with ./";
    } elsif ($current =~ /^[^\/]/ ) {
	die "ERROR : left side can't start with non-/";
    }

    if ($link =~ /^\.\.\//) {	# ../
	#resolve relative link -> ../
	
	# remove last two items on current
	$newcurrent = $current;
	# change /a/b/c/d to /a/b
	$newcurrent =~ s,[^\/]+\/[^\/]+$,,;

	# remove ../ from ../xxxx
	$newlink = $link;
	$newlink =~ s,^\.\.\/,,;

	# combine two pieces
	$newlink = "$newcurrent$newlink";

	# there may still be a ../ in there
	# change x/v/../ to nothing
	$newlink =~ s,[^\/]+\/\.\.,,g;

	$debug && printf("RESOLVE: $current -> $link is now $newlink\n");
    } elsif ($link eq "." ) { # 
	#resolve relative link -> .
	# remove last part of path
	$newcurrent = $current;
	# change /a/b/c/d to /a/b/c
	$newcurrent =~ s,\/[^\/]+$,,; # /a/b/c -> /a/b

	$newlink = "$newcurrent";
	$debug && printf("RESOLVE: $current -> $link is now $newlink\n");
    } elsif ($link =~ /^\.\//) { # starts with ./
	#resolve relative link -> ./usr
	# remove last part of path
	$newcurrent = $current;
	# change /a/b/c/d to /a/b/c
	$newcurrent =~ s,\/[^\/]+$,,;

	# remove ./ from ./xxxx
	$newlink = $link;
	$newlink =~ s,^\.\/,,;	# ./xyz -> xyz

	# combine two pieces
	$newlink = "$newcurrent/$newlink";

	$debug && printf("RESOLVE: $current -> $link is now $newlink\n");
    } elsif ($link =~ /^[^\/]/) { # starts with aaa/
	#resolve relative link -> usr/
	# remove last part of path
	$newcurrent = $current;
	# change /a/b/c/d to /a/b/c
	$newcurrent =~ s,\/[^\/]+$,,; # /a/b/c -> /a/b

	$newlink = $link;

	# combine two pieces
	$newlink = "$newcurrent/$newlink";
	$debug && printf("RESOLVE: $current -> $link is now $newlink\n");
    } else {
	printf(STDERR "$current/$link becomes ?????\n");
    }

    $oldlink = "";
    while ($newlink ne $oldlink) { # repeat until no change
	$oldlink = $newlink;	#
	$debug && printf("RESOLVE: looping to fix $current -> $link which is now $newlink\n");

	# change /./ to /
	# John P. Rouillard <rouilj@terminus.cs.umb.edu> 
	$newlink =~ s,\/\.\/,\/,g;
	    
	# change X//Y to X/Y
	$newlink =~ s,\/\/,\/,g;

	# change A/B/../X to A/X
	$newlink =~ s,[^/]+\/\.\.,,g;

	# change ^/../ to /
	$newlink =~ s,^\/\.\.\/,\/,g;
	

	# change X/./Y to X/Y
	$newlink =~ s,/\./,\/,g;	

    }    

    if ($newlink !~ /^\//) {
	die "return value from RESOLVE ($newlink) invalid, input: ($current, $link)";
    } elsif ($newlink =~ /\/\.\.\//) {
	die "return value from RESOLVE ($newlink) invalid, input: ($current, $link)";
    } elsif ($newlink =~ /\/\.\//) {
	die "return value from RESOLVE ($newlink) invalid, input: ($current, $link)";
    }
    return $newlink;
} # end resolve
sub ProgramUsesDir {
# this procedure is called once for each program.
# this input is a directory
    my ($dir) = @_;
    if ( ! -d $dir ) {
	if (! -e $dir ) {
	    # file doesn't exist
	    return;
	} else {
	    die  "Directory $dir  NOT a directory, serious bug, aborting";
	}
    }
    $ProgramsInSomeDir++;
    if (defined($ProgramsInDir{$dir})) {
	$ProgramsInDir{$dir}++; 
    } else {
	$ProgramsInDir{$dir} = 1;
    }

# now do the same thing with each step up the directory tree
    while ($dir ne "/") {
	$dir =~ s,\/[^\/]*$,,;	# Chris.Rouch@wg.estec.esa.nl found this bug
	if ($dir eq "") {
	    $dir = "/";
	}
	if (defined($ProgramsInDir{$dir})) {
	    $ProgramsInDir{$dir}++; 
	} else {
	    $ProgramsInDir{$dir} = 1;
	}

    }

}
