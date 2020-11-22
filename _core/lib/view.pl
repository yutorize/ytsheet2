################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";


our $file;
my $type;
our %conv_data = ();

if(param('id') ){
  ($file, $type) = getfile_open(param('id'));
}
elsif(param('url')){
  require $set::lib_convert;
  %conv_data = data_convert(param('url'));
  $type = $conv_data{'type'};
}

   if($type eq 'm'){ require $set::lib_view_mons; }
elsif($type eq 'i'){ require $set::lib_view_item; }
else               { require $set::lib_view_char; }

1;