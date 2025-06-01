use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-MS #################################################################################

### ユニットステータス出力 --------------------------------------------------
sub createUnitStatus {
  my %pc = %{$_[0]};
  my @unitStatus = (
    { '耐久値' => $pc{endurance} },
  );
  
  foreach my $key (split ',', $pc{unitStatusNotOutput}){
    @unitStatus = grep { !exists $_->{$key} } @unitStatus;
  }

  foreach my $num (1..$pc{unitStatusNum}){
    next if !$pc{"unitStatus${num}Label"};
    push(@unitStatus, { $pc{"unitStatus${num}Label"} => $pc{"unitStatus${num}Value"} });
  }

  return \@unitStatus;
}

### バージョンアップデート --------------------------------------------------
sub data_update_chara {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  delete $pc{updateMessage};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  if($ver < 1.27007){
    foreach (1 .. 4){
      if(exists $data::pcMagiData{$pc{"magi${_}Name"}}){
        $pc{"magi${_}"} = $pc{"magi${_}Name"};
      }
      elsif($pc{"magi${_}Name"}) {
        $pc{"magi${_}"} = 'その他';
        $pc{"magi${_}NC"} = 1;
      }
    }
  }
  
  $pc{ver} = $main::ver;
  $pc{lasttimever} = $ver;
  return %pc;
}

### バージョンアップデート・クラン --------------------------------------------------
sub data_update_clan {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  delete $pc{updateMessage};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  if($ver < 1.27007){
    foreach (1 .. 5){
      if(exists $data::clanMagiData{$pc{"magi${_}Name"}}){
        $pc{"magi${_}"} = $pc{"magi${_}Name"};
      }
      elsif($pc{"magi${_}Name"}) {
        $pc{"magi${_}"} = 'その他';
        $pc{"magi${_}NC"} = 1;
      }
    }
  }
  $pc{ver} = $main::ver;
  $pc{lasttimever} = $ver;
  return %pc;
}

1;