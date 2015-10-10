#!/usr/bin/perl
use strict;

#Notification delay in ms
my $delay = 2000;

#Hash of card names that should not be used for output (only the key matter, any value will do)
my %vetoCardNames = ('HDA Intel HDMI'=>1);



my $cardNumber = -1;
my $cardShortName = "";
my $cardLongName = "";
my $activeCard = -1;

my %cards = ();

sub showActiveCardPopup(){
    my $message = "";
    foreach my $card (sort(keys(%cards))){
	my $name =$cards{$card};
	
	if ($card == $activeCard){
	    $message .= "<b>->$name</b>\n";
	    print "Switched to: $name\n";
	}
	else {
	    $message .= ".. $name\n";
	}
    }
    if ($message eq ""){
	$message = "No soundcards";
    }
    `notify-send -t $delay "Active Soundcard Changed" "$message"`;
}

sub processData {
    if (defined($vetoCardNames{$cardShortName})){ return; }
    $cards{$cardNumber} = "$cardShortName";
}

my @cardData = split(/\n/, `pactl list sinks`);
foreach my $line (@cardData){
    if ($line =~ /^Sink \#(\d+)/){
	my $number = $1;
	if ($cardNumber != -1){
	    processData();
	}
	$cardNumber = $number;
	$cardShortName = "";
	$cardLongName = "";
    }
    elsif ($line =~ /alsa.card_name\s*=\s*"(.*)"/){
	$cardShortName = $1;
    }
    elsif ($line =~ /Description:\s*([^\n]+)/){
	$cardLongName = $1;
    }
    elsif ($line =~ /State:\s+RUNNING/){
	$activeCard = int($cardNumber);
    }
}
if ($cardNumber != -1){
    processData();
}


if ($activeCard == -1){
    `notify-send -t $delay "Active Soundcard Not Found" "Unable to change active card as it could not be found."`;
    die("Unable to find card to switch from\n");
}

#Find new active card
my @cardList = sort(keys(%cards));
my $newCard = 0;
for (my $i = 0; $i<scalar(@cardList)-1; $i++) {
    if ($activeCard==$cardList[$i]){
	$newCard=$i+1;
    }
}
$newCard = int($cardList[$newCard]);

#Switch to new active card
my @appsData = split(/\n/, `pactl list short sink-inputs`);
foreach my $appLine (@appsData){
    if ($appLine =~ /^(\d+)/){
	my $id = int($1);
	`pactl move-sink-input $id $newCard`;
    }
}
`pactl set-default-sink $newCard`;
$activeCard = $newCard;

showActiveCardPopup();
