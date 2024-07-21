#################### 種族 ####################
use strict;
use utf8;

package data;

### 種族データ --------------------------------------------------
our @races = (
  {name => 'ヒューマン' },
  {name => 'エルフ'     },
  {name => 'ドワーフ'   },
  {name => 'ティターン' },
  {name => 'センリ'     },
  {name => 'ピクシー'   },
);

sub raceNameList {
  my @list;
  foreach my $data (@races){
    push(@list, $data->{name});
  }
  return @list;
}


1;