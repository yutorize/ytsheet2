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

if ( ($set::oauth_service eq 'Discord') && (@set::oauth_discord_login_servers) ) {
  if ( &isDiscordServerIncluded($token, @userinfo) ) {
    # 指定したサーバに所属している  
  } else {
    &error("サーバに所属していないため利用できません");
    exit;
  }
}


if (! &isIdExist($userinfo[0]) ) {
  &registerUser(@userinfo);
}

my $token = &generateToken();
print &registerToken($userinfo[0], $token);
print "Location: ./\n\n";
