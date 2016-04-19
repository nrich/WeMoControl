package Wemo::Light;

use strict;
use warnings;

use Moo;
use Scalar::Util qw(looks_like_number reftype blessed);

use Data::Dumper qw/Dumper/;


has 'UPnP_Device' => (
    is      => 'ro',
    isa     => sub {
        die unless blessed($_[0]) eq 'Net::UPnP::Device';
    },
);

has 'FriendlyName' => (
    is      => 'ro',
);

has 'IconVersion' => (
    is      => 'ro',
    isa     => sub {die unless looks_like_number($_[0])},
);

has 'DeviceID' => (
    is      => 'ro',
);

has 'CapabilityIDs' => (
    is      => 'ro',
    coerce  => sub {
        my ($val) = @_;

        my $ref = reftype($_[0]) || '';

        if ($ref eq 'ARRAY') {
            return $_[0];
        } else {
            return [split ',', $_[0]];
        }
    },
);

has 'ModelCode' => (
    is      => 'ro',
);

has 'WeMoCertified' => (
    is      => 'ro',
);

has 'DeviceIndex' => (
    is      => 'ro',
    isa     => sub {die unless looks_like_number($_[0])},
);

has 'CurrentState' => (
    is      => 'ro',
    coerce  => sub {
        my ($val) = @_;

        my $ref = reftype($_[0]) || '';

        if ($ref eq 'ARRAY') {
            return $_[0];
        } else {
            return [split ',', $_[0]];
        }
    },
);


has 'FirmwareVersion' => (
    is      => 'ro',
    isa     => sub {die unless looks_like_number($_[0])},
);

has 'Manufacturer' => (
    is      => 'ro',
);

has 'productName' => (
    is      => 'ro',
    isa     => sub {
        die "Only Lighting product suported" unless $_[0] eq 'Lighting';
    },
);

sub _setStatus {
    my ($self, $capability, $value) = @_;

    my $dev = $self->UPnP_Device();

    my $args = {
        IsGroupAction => 'NO',
        DeviceID => $self->DeviceID(),
        CapabilityID => $capability,
        CapabilityValue => $value,
    };

    my $status = sprintf "&lt;?xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;?&gt;&lt;DeviceStatus&gt;&lt;IsGroupAction&gt;NO&lt;/IsGroupAction&gt;&lt;DeviceID available=&quot;YES&quot;&gt;%s&lt;/DeviceID&gt;&lt;CapabilityID&gt;%s&lt;/CapabilityID&gt;&lt;CapabilityValue&gt;%s&lt;/CapabilityValue&gt;&lt;/DeviceStatus&gt;", $self->DeviceID(), $capability, $value;

    my $service = $dev->getservicebyname('urn:Belkin:service:bridge:1');
    my $action_res = $service->postcontrol('SetDeviceStatus', {DeviceStatusList => $status});
}

sub _toggleSocket {
    my ($self, $on) = @_;

    my $dev = $self->UPnP_Device();

    my $service = $dev->getservicebyname('urn:Belkin:service:basicevent:1');
    my $action_res = $service->postcontrol('SetBinaryState', {BinaryState => $on});

    print STDERR Dumper $action_res;
}

sub on {
    my ($self) = @_;

    $self->_setStatus('10006', 1);
}

sub off {
    my ($self) = @_;

    $self->_setStatus('10006', 0);
}

sub dim {
    my ($self, $value) = @_;

    die "Invalid dimmer value: $value" if not looks_like_number($value) or $value < 0 or $value > 255;

    $self->_setStatus('10008', "$value:0");
}

sub FromXmlNode {
    my ($node, $dev) = @_;

    my %args = (UPnP_Device => $dev);
    for my $n ($node->find('./*')->get_nodelist()) {
        my $key = $n->localname();
        my $value = $n->textContent();

        $args{$key} = $value;
    }

    return Wemo::Light->new(%args);
}

1;
