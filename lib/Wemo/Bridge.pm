package Wemo::Bridge;

use strict;
use warnings;

use Moo;
use Scalar::Util qw(looks_like_number reftype blessed);
use Net::UPnP::ControlPoint qw//;
use XML::LibXML qw//;

use Data::Dumper qw/Dumper/;

has 'UPnP_Control' => (
    is      => 'ro',
    isa     => sub {
        die unless blessed($_[0]) eq 'Net::UPnP::ControlPoint';
    },
    default => sub {
        return Net::UPnP::ControlPoint->new();
    },
);

has 'lights' => (
    is      => 'rw',
);

has 'groups' => (
    is      => 'rw',
);

sub _init {
    my ($self, $timeout, $retry) = @_;

    $timeout ||= 1;
    $retry ||= 0;

    my $control = $self->UPnP_Control();
    
    my @bridges = ();
    for my $attempt (0 .. $retry) {
        @bridges = $control->search(st =>'urn:Belkin:device:bridge:1', mx => $timeout);
        last if @bridges;
        print STDERR "Retrying...\n";
    }

    foreach my $bridge (@bridges) {
	next unless $bridge->getmanufacturer() =~ /belkin/i;

        my $udn = $bridge->getudn();

        my $service = $bridge->getservicebyname('urn:Belkin:service:bridge:1');
        die "Service not found" unless $service;

        my $devices = $service->postcontrol('GetEndDevices', {ReqListType => 'PAIRED_LIST', DevUDN => $udn});
        unless ($devices->getstatuscode() == 200) {
            die $devices->getstatuscode();
        }

        my $args = $devices->getargumentlist();
        my $parser = XML::LibXML->new();

        my $doc = $parser->parse_string($args->{DeviceLists});

        my @lights = ();
        for my $node ($doc->find('/DeviceLists/DeviceList/DeviceInfos/*')->get_nodelist()) {
            require Wemo::Light;
            my $light = Wemo::Light::FromXmlNode($node, $bridge);
            push @lights, $light;
        }

        my @groups = ();
        for my $node ($doc->find('/DeviceLists/DeviceList/GroupInfos/*')->get_nodelist()) {
            require Wemo::LightGroup;
            my $group = Wemo::LightGroup::FromXmlNode($node, $bridge);
            push @groups, $group;
        }

        $self->lights(\@lights);
        $self->groups(\@groups);
    }
}

sub _search {
    my ($self, $propname, $value, $devices) = @_;

    for my $device (@$devices) {
        if ($device->$propname eq $value) {
            return $device;
        }
    }

    return undef;
}

sub findLight {
    my ($self, $propname, $value) = @_;

    return $self->_search($propname, $value, $self->lights());
}

sub findGroup {
    my ($self, $propname, $value) = @_;

    return $self->_search($propname, $value, $self->groups());
}

sub BUILD {
    my ($self, $args) = @_;

    $self->_init($args->{timeout}, $args->{retry}) unless $args->{no_init};
}

1;
