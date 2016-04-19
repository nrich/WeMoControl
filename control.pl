#!/usr/bin/perl 

use strict;
use warnings;

use Getopt::Std qw/getopts/;
use Data::Dumper qw/Dumper/;

use Net::UPnP::ControlPoint qw//;
use XML::LibXML qw//;

use lib qw/lib/;
use Wemo::Bridge qw//;

my %opts = ();
getopts('o:d:', \%opts);
main(@ARGV);

sub main {
    my ($name) = @_;

    die "Need name\n" unless $name;

    my $bridge = Wemo::Bridge->new();

    for my $light (@{$bridge->lights()}) {
        if ($light->FriendlyName() eq $name) {
            $opts{o} ? $light->on() : $light->off();

            my $dim = $opts{d};

            $light->dim($dim) if defined $dim;
        }
    }

    for my $group (@{$bridge->groups()}) {
        if ($group->GroupName() eq $name) {
            $opts{o} ? $group->on() : $group->off();

            my $dim = $opts{d};

            $group->dim($dim) if defined $dim;
        }
    }
}
