#################### データ ####################
use strict;
use utf8;

package data;

### クラスデータ --------------------------------------------------
our @classes = (
  {'name' => 'ウォーリア' },
  {'name' => 'ハイランダー'},
  {'name' => 'フェンサー'},
  {'name' => 'ランサー'},
  {'name' => 'アーチャー'},
  {'name' => 'ガンスリンガー'},
  {'name' => 'クレリック'},
  {'name' => 'モンク'},
  {'name' => 'ウィザード'},
  {'name' => 'ニンジャ'},
);

### スタイルデータ --------------------------------------------------
our @styles = (
  {'name' => 'ブレイブ' },
  {'name' => 'マイスター' },
  {'name' => 'ノービス' },
  {'name' => 'リーダー' },
  {'name' => 'ヘルパー' },
  {'name' => 'フェイバリット' },
  {'name' => 'ローンウルフ' },
  {'name' => 'ブレイン' },
  {'name' => 'ストリーマー' },
  {'name' => 'ガジェッター' },
  {'name' => 'カジュアル' },
  {'name' => 'ハードコア' },
);

sub classNameList {
  my @list;
  foreach my $data (@classes){
    push(@list, $data->{'name'});
  }
  return @list;
}
sub styleNameList {
  my @list;
  foreach my $data (@styles){
    push(@list, $data->{'name'});
  }
  return @list;
}


1;