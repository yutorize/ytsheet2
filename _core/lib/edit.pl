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

## 画像欄
sub image_form {
  return <<"HTML";
    <div id="image-custom" style="display:none">
      <div class="image-custom-view-area">
        <div></div><div></div><div></div>
        <div></div>
        <div id="image-custom-view">
          @{[ input "imagePositionY",'range','imagePosition','' ]}
          @{[ input "imagePositionX",'range','imagePosition','' ]}
        </div>
        <div></div>
        <div></div><div></div><div></div>
      </div>
      <div class="image-custom-form">
        <p>
          縦基準位置:<span id="image-positionY-view"></span> ／
          横基準位置:<span id="image-positionX-view"></span>
        </p>
        <p>
          表示方式：<select name="imageFit" oninput="imagePosition()">
          <option value="cover"   @{[$pc{'imageFit'} eq 'cover'  ?'selected':'']}>枠いっぱいに表示（最低限のトリミング）
          <option value="contain" @{[$pc{'imageFit'} eq 'contain'?'selected':'']}>全体表示（トリミングしない）
          <option value="percentX" @{[$pc{'imageFit'} eq 'percentX'?'selected':'']}>拡大率を指定（横基準）
          <option value="percentY" @{[$pc{'imageFit'} eq 'percentY'?'selected':'']}>拡大率を指定（縦基準）
          <option value="unset"   @{[$pc{'imageFit'} eq 'unset'  ?'selected':'']}>拡大縮小せず表示（ドット絵等向き）
          </select><br>
        </p>
        <p id="image-percent-config">
          拡大率：@{[ input "imagePercent",'number','imagePosition','style="width:4em;"' ]}%<br>
          <input type="range" id="image-percent-bar" min="10" max="1000" oninput="imagePercentBarChange(this.value)" style="width:100%;"><br>
          （「拡大率を指定」時／100で幅ピッタリ）<br>
        </p>
        <p class="center"><a class="button" onclick="imagePositionClose()">トリミング位置のカスタマイズを閉じる</a><p>
      </div>
    </div>
HTML
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