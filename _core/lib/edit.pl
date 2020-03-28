################## 更新フォーム ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use Encode;

our $mode = param('mode');
our $message;
our %pc;



if($set::user_reqd && !check){ error('ログインしていません。'); }
### 個別処理 --------------------------------------------------
if   (param('type') eq 'm'){ require $set::lib_edit_mons; }
elsif(param('type') eq 'i'){ require $set::lib_edit_item; }
else                       { require $set::lib_edit_char; }

### 共通サブルーチン --------------------------------------------------
## トークン生成
sub token_make {
  my $token = random_id(12);

  my $mask = umask 0;
  sysopen (my $FH, $set::tokenfile, O_WRONLY | O_APPEND | O_CREAT, 0666);
  print $FH $token."<>".(time + 60*60*24*7)."<>\n";
  close($FH);
  
  return $token;
}

## ログインエラー
sub login_error {
  our $login_error = 'パスワードが間違っているか、<br>編集権限がありません。';
  require $set::lib_view;
  exit;
}

## 簡略化系
sub input {
  my ($name, $type, $oniput, $other) = @_;
  if($oniput && $oniput !~ /\(.*?\)$/){ $oniput .= '()'; }
  '<input'.
  ' type="'.($type?$type:'text').'"'.
  ' name="'.$name.'"'.
  ' value="'.($_[1] eq 'checkbox' ? 1 : $pc{$name}).'"'.
  ($other?" $other":"").
  ($type eq 'checkbox' && $pc{$name}?" checked":"").
  ($oniput?' oninput="'.$oniput.'"':"").
  '>';
}
sub option {
  my $name = shift;
  my $text = '<option value="">';
  foreach my $i (@_) {
    my $value = $i;
    my $view;
    if($value =~ s/\|\<(.*?)\>$//){ $view = $1 } else { $view = $value }
    $text .= '<option value="'.$value.'"'.($pc{$name} eq $value ? ' selected':'').'>'.$view
  }
  return $text;
}
sub display {
  $_[0] ? ($_[1] ? " style=\"display:$_[1]\"" : '') : ' style="display:none"'
}

1;