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
    my ($self) = @_;

    my $control = $self->UPnP_Control();
    
    my @bridges = $control->search(st =>'urn:Belkin:device:bridge:1', mx => 1);

    foreach my $bridge (@bridges) {
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
            require Wemo::Group;
            my $group = Wemo::Group::FromXmlNode($node, $bridge);
            push @groups, $group;
        }

        $self->lights(\@lights);
        $self->groups(\@groups);
    }
}

sub BUILD {
    my ($self, $args) = @_;

    $self->_init(); 
}

1;
