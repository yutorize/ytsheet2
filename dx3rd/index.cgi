#!/usr/bin/perl
####################################
##     ゆとシートⅡ for DX3rd     ##
##          by ゆとらいず工房     ##
##    https://yutorize.2-d.jp     ##
####################################
use strict;
#use warnings;
use utf8;
use open ":utf8";
binmode STDOUT, ':utf8';
use CGI::Carp qw(fatalsToBrowser);
use CGI qw/:all/;
use Fcntl;

### 設定読込 #########################################################################################
our $core_dir = '../_core';
use lib '../_core/module';

require $core_dir.'/lib/dx3/config-default.pl';
require './config.cgi';
require $core_dir.'/lib/subroutine.pl';
require $core_dir.'/lib/dx3/subroutine-dx3.pl';

require $core_dir.'/lib/junction.pl';

exit;