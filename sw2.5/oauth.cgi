#!/usr/bin/perl

use strict;
use utf8;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw/:all/;

our $core_dir = '../_core';
use lib '../_core/module';

require $core_dir.'/lib/sw2/config-default.pl';
require './config.cgi';
require $core_dir.'/lib/subroutine.pl';
require $core_dir.'/lib/oauth.pl';

print "Content-type: text/html\n";

my $token = &getAccessToken(param("code"));

if ($token) {
  my @userinfo = &getUserInfo($token);

  if ( ($set::oauth_service eq 'Discord') && (@set::oauth_discord_login_servers) ) {
    if ( &isDiscordServerIncluded($token, @set::oauth_discord_login_servers) ) {
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
} else {
  &error("ログインに失敗しました。やり直してみてください");
}


