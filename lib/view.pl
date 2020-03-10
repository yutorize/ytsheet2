################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

(our $file, my $type) = getfile_open(param('id'));
   if($type eq 'm'){ require $set::lib_view_mons; }
elsif($type eq 'i'){ require $set::lib_view_item; }
else               { require $set::lib_view_char; }

1;