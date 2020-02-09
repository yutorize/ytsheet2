#!/usr/local/bin/perl

use strict;
use utf8;


require './lib/config-default.pl';
require './config.cgi';
require './lib/subroutine.pl';
require './lib/oauth.pl';

print "Content-type: text/html\n";

my $token = &getAccessToken(param("code"));
my @userinfo = &getUserInfo($token);

if (! &isIdExist($userinfo[0]) ) {
  &registerUser(@userinfo);
}

my $token = &generateToken();
&registerToken($userinfo[0], $token);
print "Location: ./\n\n";
