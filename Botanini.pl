#!/usr/bin/perl

use strict;
use Net::IRC;
use Mysql;
use Data::Dumper;
use Text::Iconv;

#my $nick = 'Botanini';
my $nick = 'UTF-8';


my $irc = new Net::IRC;
my $db = Mysql->connect('localhost', 'botanini', 'root', 'qzwxecasdqeadzcwsx');
$db->selectdb('botanini');
$db->query('SET NAMES "Big5"');
my $conn = $irc->newconn(
	Nick    => $nick,
	Server  => 'irc.tw.freebsd.org',
	Port    =>  6667,
	Username => $nick);

my $result;
my @channellist;

my $utf8big5 = Text::Iconv->new('UTF-8', 'Big5');
my $big5utf8 = Text::Iconv->new('Big5', 'UTF-8');

sub on_connect {
	my @tmp;
	my @w;
	my $self = shift;
	while(my $channel=shift @ARGV){
		$self->join('#'.$channel);
		@tmp=split(/ +/,$channel);
		push @channellist,shift @tmp;
		@w=$self->who('#'.$channel);
		shift @w;
		Dumper(shift @w);
	}
}

sub maxima{
	my $msg = trim(shift);
	$msg.=';';
	$msg =~ s/;+$/;/;
	my $cmd = 'echo "'.$msg.'" | maxima --very-quiet | col -x';
	my $ret = readpipe($cmd);
	my @lines = split(/\n+/,$ret);
	my $sct=-1;
	my @nlines=@lines;
	foreach (@nlines){
		$_ =~ s/^( *).*$/\1/;
		if($sct==-1 || length($_)<$sct){
			$sct=length($_);
		}
	}
	foreach(@lines){
		$_ =~ s/^ {$sct}//;
	}
	$ret=join("\n",@lines);
	if($ret=~/(Incorrect|error)/){
		return 0;
	}
	$result=$ret;
	return 1;
}

sub trim {
	my $str = shift;
	$str =~ s/^\s*//;
	$str =~ s/[\r\n\t !?\.,]*$//;
	return $str;
}

sub sql_escape{
	my $str = shift;
	$str=$db->quote($str);
	$str =~ s/([%_])/\\$1/;
	return $str;
}

sub recall {
	my $channel = shift;
	my $msg = trim(shift);
	my $pat=&sql_escape($msg);
	$pat =~ s/(.)$/%$1/;
	my %rec;
	$channel =~ s/^#//;
	my $sql='SELECT * FROM `history` WHERE `channel`="'.lc($channel).'" AND `text` LIKE '.$pat.' ORDER BY `id` DESC';
	my $res=$db->query($sql);
	if(%rec=$res->fetchhash){
		$result=$rec{'text'};
	}
	return 1;
}

sub statistic {
	my $channel = shift;
	my $msg = trim(shift);
	my %rec;
	my %stat;
	my @ret;
	my $pat=&sql_escape($msg);
	$pat =~ s/(.)$/%$1/;
	$pat =~ s/^(.)/$1%/;
	my $sql='SELECT * FROM `history` WHERE `channel`="'.lc($channel).'" AND `text` LIKE '.$pat;
	my $res=$db->query($sql);
	while(%rec=$res->fetchhash){
		++$stat{$rec{'nick'}};
	}
	foreach my $k (sort {$stat{$a} cmp $stat{$b} } keys %stat){
		unshift @ret, $k.'('.$stat{$k}.')';
	}
	$result = join ' > ',@ret;
}

sub memory {
	my $channel = shift;
	my $nick = shift;
	my $fulltext = shift;
	my $text = trim($fulltext);
	my $type;
	$channel =~ s/^#//;
	my $sql='INSERT INTO `history` (`channel`,`time`,`nick`,`text`,`fulltext`';
	my $sql2.=') VALUES ("'.lc($channel).'","'.time().'",'.$db->quote($nick).','.$db->quote($text).','.$db->quote($fulltext);
	if($type=shift){
		$sql.=',`type`';
		$sql2.=',"'.$type.'"';
	}
	$sql.=$sql2.')';
	$db->query($sql);
}

sub on_talk {
	$result='';
	my $self = shift;
	my $event = shift;
	my $channel = $event->{to}[0];
	my $omsg = join(' ',$event->args);
	my $msg = trim($omsg);
#	if($msg !~ m/^$nick/){
#		&memory($channel, $event->nick, $omsg,'msg');
#		return;
#	}
#	if($event->nick eq 'nfsnfs'){
#		$self->privmsg($channel,'nfsnfs> '.$utf8big5->convert($omsg));
#	}
	if($omsg=~/^big52utf-?8/i){
		$self->privmsg($channel,$big5utf8->convert($omsg));
	}
	return;
	$msg =~ s/^$nick *:?\s*//;
	$msg = trim($msg);
	my $ret;
	if($msg =~ /^calc/){
		$msg =~ s/^calc//;
		&maxima($msg);
	}elsif($msg =~ /^stat/){
		$msg =~ s/^stat//;
		&statistic($channel,$msg);
	}elsif($msg =~ /^ping /){
		$result='pong';
	}else{
		&recall($channel,$msg);
	}
	&memory($channel, $event->nick, $omsg,'msg');
	foreach(split(/\n+/,$result)){
		&memory($channel, $nick, $event->nick.': '.$_,'msg');		
		$self->privmsg($channel,$event->nick.': '.$_);
	}
}

sub on_action {
	my $self = shift;
	my $event = shift;	
	my $channel = $event->{to}[0];
	my $omsg=join(' ',$event->args);
#	&memory($event->{to}[0],$event->nick, join(' ',$event->args),'me');
        if($event->nick eq 'nfsnfs'){
                $self->privmsg($channel,$utf8big5->convert($omsg));
        }else{
                return;
        }
}

sub on_quit {
	my $self = shift;
	my $event = shift;
	&memory($event->{to}[0],$event->nick,$event->userhost."\t".join(' ',$event->args),'quit');
}

sub on_leave {
	my $self = shift;
	my $event = shift;
	&memory($event->{to}[0],$event->nick,$event->userhost."\t".join(' ',$event->args),'leave');
}

sub on_join {
	my $self = shift;
	my $event = shift;
	&memory($event->{to}[0],$event->nick,$event->userhost,'join');
}

sub on_topic {
	my $self = shift;
	my $event = shift;
	if(trim($event->{to}[0]) eq ''){
		&memory($event->{args}[1],'-',$event->{args}[2],'topic');
	}else{
		&memory($event->{to}[0],$event->nick,join(' ',$event->args),'topic');
	}
}

sub on_mode {
	my $self = shift;
	my $event = shift;
	&memory($event->{to}[0],$event->nick,join(' ',$event->args),'mode');
}

sub on_nick {
	my $self = shift;
	my $event = shift;
	foreach(@channellist){
		&memory($_,$event->nick,join(' ',$event->args),'nick');
	}
}

$conn->add_global_handler('376', \&on_connect);
$conn->add_handler('public', \&on_talk);
$conn->add_handler('caction', \&on_action);
$conn->add_handler('quit', \&on_quit);
$conn->add_handler('part', \&on_leave);
$conn->add_handler('join', \&on_join);
$conn->add_handler('topic', \&on_topic);
$conn->add_handler('mode', \&on_mode);
$conn->add_handler('nick', \&on_nick);

$irc->start;
