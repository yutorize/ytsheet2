#!/usr/local/bin/perl
use strict;
use warnings;
use utf8;
use open ":utf8";
use open ":std";
use CGI::Carp qw(fatalsToBrowser);
use CGI qw/:all/;
use File::Copy qw/move/;

opendir(my $DIR,"./data") or die;
my @backlist = readdir($DIR);
closedir($DIR);

 print "Content-Type: text/plain\n\n";
 foreach(@backlist){
   next if $_ !~ /\.cgi$/;
   print $_."\n";
   my ($name, undef) = split /\./;
   mkdir "./data/${name}", 0777 or die;
   move("./data/${name}.cgi","./data/${name}/data.cgi");
 }

 open (my $FH, "<", "charlist.cgi");
 foreach (<$FH>) {
   my (
     $id, $file, undef, $updatetime, $name, $player, $group,
     $exp, $honor, $race, $gender, $age, $faith,
     $classes, $session, $image, $tag, $hide, $fellow
   ) = (split /<>/, $_)[0..18];
   
   if($image){
     move("./image/${id}.${image}","./data/${file}/image.${image}");
     print "./image/${id}.${image}".'=>'."./data/${file}/image.${image}\n";
   }
 }
 close($FH);