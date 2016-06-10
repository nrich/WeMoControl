#!/usr/bin/perl

use strict;
use warnings;

use Dancer2;
use Dancer2::Plugin::Ajax;

set serializer => 'JSON';

get '/' => sub {
    template 'index';
};

dance();
