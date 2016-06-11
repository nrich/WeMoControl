#!/usr/bin/perl

use strict;
use warnings;

use Dancer2;
use Dancer2::Plugin::Ajax;
use Dancer2::Serializer::JSON;

use Data::Dumper qw/Dumper/;
use File::Temp qw//;
use List::MoreUtils qw(zip);

use lib qw/lib/;
use Wemo::Bridge qw//;

set serializer => 'JSON';

my $events = [
    {name => 'on', label => 'Turn On', commands => ['-o 1 -d 255']},
    {name => 'off' => label => 'Turn Off', commands => ['-o 0']},
    {name => 'in120' => label => 'Fade In (2 Minutes)', commands => ['-o 1 -d 1', '-t 120 -d 255']},
    {name => 'in300' => label => 'Fade In (5 Minutes)', commands => ['-o 1 -d 1', '-t 300 -d 255']},
    {name => 'out120' => label => 'Fade Out (2 Minutes)', commands => ['-o 1 -d 255', '-t 120 -d 0']},
    {name => 'out300' => label => 'Fade Out (5 Minutes)', commands => ['-o 1 -d 255', '-t 300 -d 0']},
];

ajax '/loadPage' => sub {
    my $bridge = Wemo::Bridge->new();

    my @devices = ();
    for my $light (@{$bridge->lights()}) {
        push @devices, {
            type => 'light',
            name => $light->FriendlyName(),
        };
    }

    for my $group (@{$bridge->groups()}) {
        push @devices, {
            type => 'group',
            name => $group->GroupName(),
        };
    }

    my @rules = ();
    my $entries = export_cron_entries();
    for my $cron (@$entries) {
        push @rules, cron_to_rule($cron);
    }

    return {
        rules => \@rules,
        events => $events,
        devices => \@devices,
    };
};

ajax '/save' => sub {
    my $rules = from_json(params->{'rules'});

    my @entries = ();
    for my $rule (@$rules) {
        my $cron = rule_to_cron($rule);
        push @entries, $cron;
    }

    import_cron_entries(\@entries);

    return {
        result => 'OK',
    };
};

get '/scheduler' => sub {
    template 'scheduler';
};

get '/' => sub {
    redirect '/scheduler';
};

dance();

sub rule_to_cron {
    my ($rule) = @_;

    my $device = $rule->{device};
    my @event = grep {$_->{name} eq $rule->{event}} @$events;

    my $commandline = join ';', map {"/home/nrich/WeMoControl/control.pl $_ $device"} @{$event[0]->{commands}};

    my $cron = {
        m => $rule->{minute},
        h => $rule->{period} eq 'PM' ? $rule->{hour} += 12 : $rule->{hour},
        dom => '*',
        mon => '*',
        dow => join (',', @{$rule->{days}}),
        command => "$commandline #$event[0]->{name} $device",
    };

    return $cron;
}

sub cron_to_rule {
    my ($cron) = @_;

    my $command = $cron->{command};
    chomp $command;

    my ($eventname, $device) = $command =~ /#([\S]+)\s([\S]+)$/g;

    my $rule = {
        minute => $cron->{m},
        hour => $cron->{h} > 12 ? $cron->{h} - 12 : $cron->{h},
        period => $cron->{h} > 12 ? 'PM' : 'AM',
        days => [split(',', $cron->{dow})],
        event => $eventname,
        device => $device,
    };

    return $rule;
}

sub import_cron_entries {
    my ($entries) = @_;

    my $fh = File::Temp->new();
    for my $cron (@$entries) {
        my %a = %$cron;
        print $fh join(' ', @a{qw/m h dom mon dow command/}), "\n";
    }

    system qw/crontab/, $fh->filename;
}

sub export_cron_entries {
    my @entries = ();

    open my $fh, '-|', 'crontab -l' or die "Could not open crontab: $!\n";
    my @header = (qw/m h dom mon dow command/);
    while (my $line = <$fh>) {
        my @data = split' ', $line, 6;
        my $cron = {zip @header, @data};
        push @entries, $cron;
    }
    close $fh;

    return \@entries;
}
