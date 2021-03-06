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
getopts('lo:d:f:t:r:', \%opts);
main(@ARGV);

sub main {
    my ($name) = @_;

    die "Need name\n" unless $opts{l} or $name;

    my $retry = $opts{r} || 0;
    die "Too many retry attempts specified\n" if $retry > 10;

    my $bridge = Wemo::Bridge->new({timeout => 1, retry => $retry});

    if ($opts{l}) {
        for my $light (@{$bridge->lights()}) {
            print "Light: '", $light->FriendlyName(), "'\n";
            print "\tOn: ", $light->isOn() ? 'Yes' : 'No', "\n";
            print "\tLevel: ", $light->level(), "\n";
            print "\tFirmware: ", $light->FirmwareVersion(), "\n";
            print "\tIcon: ", $light->IconVersion(), "\n";
        }

        for my $group (@{$bridge->groups()}) {
            print "Group: ", $group->GroupName(), "\n";
            print "\tOn: ", $group->isOn() ? 'Yes' : 'No', "\n";
            print "\tLevel: ", $group->level(), "\n";

            for my $light (@{$group->Devices()}) {
                print "\tLight: '", $light->FriendlyName(), "'\n";
                print "\t\tOn: ", $light->isOn() ? 'Yes' : 'No', "\n";
                print "\t\tLevel: ", $light->level(), "\n";
                print "\t\tFirmware: ", $light->FirmwareVersion(), "\n";
                print "\t\tIcon: ", $light->IconVersion(), "\n";
            }
        }

        exit 0;
    }

    my $device = $bridge->findLight(FriendlyName => $name) || $bridge->findGroup(GroupName => $name);

    my $dim = $opts{d};

    for my $attempt (0 .. $retry) {
        eval {
            $device->dim($dim, $opts{t}) if defined $dim;

            if (defined $opts{o}) {
                $opts{o} ? $device->on() : $device->off();
            }

            if (defined $opts{f}) {
                $opts{f} < 0 ? $device->fadeout(-$opts{f}) : $device->fadein($opts{f});
            }
        };

        if ($@ && $retry) {
            sleep $attempt + 1;
        } else {
            last;
        }
    }
}
