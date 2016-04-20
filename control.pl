#!/usr/bin/perl 

use strict;
use warnings;

use Getopt::Std qw/getopts/;
use Data::Dumper qw/Dumper/;

use lib qw/lib/;
use Wemo::Bridge qw//;

my %opts = ();
getopts('o:d:f:t:', \%opts);
main(@ARGV);

sub main {
    my ($name) = @_;

    die "Need name\n" unless $name;

    my $bridge = Wemo::Bridge->new();

    for my $light (@{$bridge->lights()}) {
        if ($light->FriendlyName() eq $name) {
            my $dim = $opts{d};
            $light->dim($dim, $opts{t}) if defined $dim;

            if (defined $opts{o}) {
                $opts{o} ? $light->on() : $light->off();
            }

            if (defined $opts{f}) {
                $opts{f} < 0 ? $light->fadeout(-$opts{f}) : $light->fadein($opts{f});
            }
        }
    }

    for my $group (@{$bridge->groups()}) {
        if ($group->GroupName() eq $name) {
            my $dim = $opts{d};
            $group->dim($dim, $opts{t}) if defined $dim;

            if (defined $opts{f}) {
                $opts{f} < 0 ? $group->fadeout(-$opts{f}) : $group->fadein($opts{f});
            }

            if (defined $opts{o}) {
                $opts{o} ? $group->on() : $group->off();
            }
        }
    }
}
