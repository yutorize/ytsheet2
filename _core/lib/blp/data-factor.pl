#################### データ ####################
use strict;
use utf8;

package data;

### ファクターデータ --------------------------------------------------
our %factors = (
  '人間' => {
    core => [
      { '義士' => {stt1 => 4, stt2 => 5} },
      { '讐人' => {stt1 => 3, stt2 => 6} },
      { '傀儡' => {stt1 => 5, stt2 => 4} },
      { '金愚' => {stt1 => 7, stt2 => 2} },
      { '研人' => {stt1 => 2, stt2 => 7} },
      { '求道' => {stt1 => 6, stt2 => 3} },
    ],
    style => [
      { '監者' => {stt1 => 4, stt2 => 5} },
      { '戦衛' => {stt1 => 6, stt2 => 3} },
      { '狩人' => {stt1 => 5, stt2 => 4} },
      { '謀智' => {stt1 => 2, stt2 => 7} },
      { '術師' => {stt1 => 5, stt2 => 4} },
      { '資道' => {stt1 => 7, stt2 => 2} },
    ],
  },
  '吸血鬼' => {
    core => [
      { '源祖' => {stt1 => 4, stt2 => 5} },
      { '貴種' => {stt1 => 5, stt2 => 4} },
      { '夜者' => {stt1 => 6, stt2 => 3} },
      { '半鬼' => {stt1 => 2, stt2 => 7} },
      { '屍鬼' => {stt1 => 8, stt2 => 1} },
      { '綺獣' => {stt1 => 4, stt2 => 5} },
    ],
    style => [
      { '舞人' => {stt1 => 6, stt2 => 3} },
      { '戦鬼' => {stt1 => 7, stt2 => 2} },
      { '奏者' => {stt1 => 3, stt2 => 6} },
      { '火華' => {stt1 => 4, stt2 => 5} },
      { '群団' => {stt1 => 6, stt2 => 3} },
      { '界律' => {stt1 => 2, stt2 => 7} },
    ],
  },
);

our %factor_list;
our %factor_data;
foreach my $factor (keys %factors){
  foreach my $type (keys %{$factors{$factor}}){
    my @list;
    foreach my $data (@{$factors{$factor}{$type}}){
      my $name = (keys %{$data})[0];
      push(@list, $name);
      $factor_data{$name} = $data->{$name};
    }
    $factor_list{$factor}{$type} = \@list;
  }
}

1;