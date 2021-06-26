#!/usr/bin/perl
use strict;

#Notification delay in ms
my $delay = 500;

my $notifyCmd = "notify-send -t $delay";   

my @vols = split(' ',`pulsemixer --get-volume`);
my $left = $vols[0];
my $right = $vols[1];

my $average = ($left+$right)/2;

`$notifyCmd "Volume $average%"`;
