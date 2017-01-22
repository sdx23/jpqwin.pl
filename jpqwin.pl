#
# print join-, part- and quit- messages to window named "jpq"
# inspired by Timo Sirainens hilightwin.pl
#
#

use Irssi;
use POSIX;
use vars qw($VERSION %IRSSI); 

$VERSION = "0.20";
%IRSSI = (
    authors     => "Max \'sdx23\' Voit",
    contact     => "max.voit+dvis@with-eyes.net",
    name        => "jpqwin",
    description => "Print join-, part-, quit-messages to window named \"jpq\"",
    license     => "GPLv2",
    url         => "http://irssi.org/",
    changed     => "Fri April 10 14:47 CEST 2009"
);

my $lasttext = '';
my $lastjoiner = '';
my $lastjoin = '';

sub sig_printtext {
    my ($dest, $text, $stripped) = @_;

    if( ($dest->{level} & MSGLEVEL_JOINS) ||
        ($dest->{level} & MSGLEVEL_PARTS) ||
        (($dest->{level} & MSGLEVEL_NICKS) && Irssi::settings_get_bool('jpqwin_nicks')) || 
        ($dest->{level} & MSGLEVEL_QUITS) ) {

        $window = Irssi::window_find_name('jpq');
		return if(!$window);
        
		if($dest->{level} & MSGLEVEL_JOINS && Irssi::settings_get_bool('jpqwin_sjoins')){

			$text =~ /(.+) has joined/;
			$joiner = $1;
			if(($joiner eq $lastjoiner) && ($text ne $lastjoin)){
				# avoid "multijoining" the same channel ( "... has joined #test, #test, #test")

				# delte last line
				my $line = $window->view()->get_bookmark('ljoin');
	            $window->view()->remove_line($line) if defined $line;
				# create new line in $text
				$text =~ /has joined(.+)/;
				$text = $lastjoin.','.$1;
			} else {
				$lastjoiner = $joiner;
			}
			$lastjoin = $text;
		}

		

        $text = strftime(
            Irssi::settings_get_str('timestamp_format')." ",
            localtime
        ).$text;

		if (Irssi::settings_get_bool('jpqwin_showtag')) {
			my $tag = $dest->{server}->{tag};
			if (Irssi::settings_get_bool('jpqwin_append')) {
           		$text = $text.' on '.$tag;
			}
			if (! Irssi::settings_get_bool('jpqwin_append')) {
           		$text = $tag.": ".$text;
			}
        }

		# kill multiple lines
		if( $text ne $lasttext ){
        	$window->print($text, MSGLEVEL_NEVER);
			$window->view()->set_bookmark_bottom('ljoin') if ( $dest->{level} & MSGLEVEL_JOINS );
		}
	
		$lasttext = $text;

		# stop signal if configured to
		if(Irssi::settings_get_bool('jpqwin_stopsig') == 1){
			Irssi::signal_stop();
		}
    }
}

# main

$window = Irssi::window_find_name('jpq');
Irssi::print("Could not find a window named 'jpq'. Create one using '/window new [hidden or split]' and '/window name jpq'") if (!$window);

Irssi::settings_add_bool('jpqwin','jpqwin_stopsig',1);	# Stop signal -> message is displayed only in jpq-window
Irssi::settings_add_bool('jpqwin','jpqwin_showtag',1);	# Show servertag
Irssi::settings_add_bool('jpqwin','jpqwin_append',1);	# 	at the end / in front of the message
Irssi::settings_add_bool('jpqwin','jpqwin_nicks',1);	# Take care of nickchange-messages as well
Irssi::settings_add_bool('jpqwin','jpqwin_sjoins',1);	# Display joins as one line

Irssi::signal_add('print text', 'sig_printtext');

# vim:set ts=4 sw=4 et:
