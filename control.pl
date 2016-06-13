#!/usr/bin/perl 

use strict;
use warnings;

use Getopt::Std qw/getopts/;
use Data::Dumper qw/Dumper/;
use Cwd qw/cwd/;
use File::Basename qw/basename dirname/;

use lib qw/lib/;
use lib dirname($0) . '/lib';
use Wemo::Bridge qw//;

my %opts = ();
getopts('lo:d:f:t:', \%opts);
main(@ARGV);

sub main {
    my ($name) = @_;

    die "Need name\n" unless $opts{l} or $name;

    my $bridge = Wemo::Bridge->new();

    if ($opts{l}) {
        for my $light (@{$bridge->lights()}) {
            print "Light: ", $light->FriendlyName(), "\n";
            print "\tOn: ", $light->isOn() ? ' Yes' : 'No', "\n";
            print "\tLevel: ", $light->level(), "\n";
        }

        for my $group (@{$bridge->groups()}) {
            print "Group: ", $group->GroupName(), "\n";
        }

        exit 0;
    }

    my $device = $bridge->findLight(FriendlyName => $name) || $bridge->findGroup(GroupName => $name);

    my $dim = $opts{d};
    $device->dim($dim, $opts{t}) if defined $dim;

    if (defined $opts{o}) {
        $opts{o} ? $device->on() : $device->off();
    }

    if (defined $opts{f}) {
        $opts{f} < 0 ? $device->fadeout(-$opts{f}) : $device->fadein($opts{f});
    }
}
