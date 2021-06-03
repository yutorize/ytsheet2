################## 更新フォーム ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

our $LOGIN_ID = check;

our $mode = $::in{'mode'};

if($set::user_reqd && !check){ error('ログインしていません。'); }
### 個別処理 --------------------------------------------------
my $type = $::in{'type'};
our %conv_data = ();
if($::in{'url'}){
  require $set::lib_convert;
  %conv_data = data_convert($::in{'url'});
  $type = $conv_data{'type'};
}

if   ($type eq 'm'){ require $set::lib_edit_mons; }
elsif($type eq 'i'){ require $set::lib_edit_item; }
else               { require $set::lib_edit_char; }

### 共通サブルーチン --------------------------------------------------
## データ読み込み
sub pcDataGet {
  my $mode = shift;
  my %pc;
  my $file;
  my $message;
  my $datadir = ($type eq 'm') ? $set::mons_dir : ($type eq 'i') ? $set::item_dir : $set::char_dir;
  # エラー
  if($main::make_error) {
    $mode = ($mode eq 'save') ? 'edit' : 'blanksheet';
    for (param()){ $pc{$_} = param($_); }
    $message = $::make_error;
  }
  # 保存 / 編集 / 複製 / コンバート
  elsif($mode eq 'edit' || $mode eq 'save'){
    if($mode eq 'save'){
      $mode = 'edit';
      $message .= 'データを更新しました。<a href="./?id='.$::in{'id'}.'">⇒シートを確認する</a>';
    }
    (undef, undef, $file, undef) = getfile($::in{'id'},$::in{'pass'},$LOGIN_ID);
    my $datafile = $::in{'backup'} ? "${datadir}${file}/backup/$::in{'backup'}.cgi" : "${datadir}${file}/data.cgi";
    open my $IN, '<', $datafile or &login_error;
    $_ =~ s/^(.+?)<>(.*)\n$/$pc{$1} = $2;/egi while <$IN>;
    close($IN);
    if($::in{'backup'}){
      ($pc{'protect'}, $pc{'forbidden'}) = protectTypeGet("${datadir}${file}/data.cgi");
      $message = $pc{'updateTime'}.' 時点のバックアップデータから編集しています。';
    }
  }
  elsif($mode eq 'copy'){
    $file = (getfile_open($::in{'id'}))[0];
    my $datafile = $::in{'backup'} ? "${datadir}${file}/backup/$::in{'backup'}.cgi" : "${datadir}${file}/data.cgi";
    open my $IN, '<', $datafile or error 'データがありません。';
    $_ =~ s/^(.+?)<>(.*)\n$/$pc{$1} = $2;/egi while <$IN>;
    close($IN);

    delete $pc{'image'};
    $pc{'protect'} = 'password';

    $message  = '「<a href="./?id='.$::in{'id'}.'" target="_blank"><!NAME></a>」';
    $message .= 'の<br><a href="./?id='.$::in{'id'}.'&backup='.$::in{'backup'}.'" target="_blank">'.$pc{'updateTime'}.'</a> 時点のバックアップデータ' if $::in{'backup'};
    $message .= 'を<br>コピーして新規作成します。<br>（まだ保存はされていません）';
  }
  elsif($mode eq 'convert'){
    %pc = %::conv_data;
    delete $pc{'image'};
    $pc{'protect'} = 'password';
    $message = '「<a href="'.$::in{'url'}.'" target="_blank"><!NAME></a>」をコンバートして新規作成します。<br>（まだ保存はされていません）';
  }
  return (\%pc, $mode, $file, $message)
}
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
    <div class="box" id="image" style="max-height:550px;">
      <h2>キャラクター画像</h2>
      <p>
        <a class="button" onclick="imagePositionView();wordsPreView()">画像とセリフの設定</a>
      </p>
      <p>
        <input type="checkbox" name="imageDelete" value="1"> 画像を削除する
        @{[input('image','hidden')]}
      </p>
    </div>
    @{[ input('imageUpdate', 'hidden') ]}
    
    <div id="image-custom" style="display:none">
      <div class="image-custom-view-area">
        <div id="image-custom-frame-S1" class="image-custom-frame"><div class="image-custom-view"
 class="image-custom-view"><b>横幅が狭い時</b></div></div>
        <div id="image-custom-frame-S2" class="image-custom-frame"><div class="image-custom-view"
 class="image-custom-view"><b>縦幅が狭い時</b></div></div>
        <div id="image-custom-frame-M" class="image-custom-frame"><div class="image-custom-view"
 class="image-custom-view"><b>標準の比率　<small>※縦横比は適宜変動します</small></b><div class="words" id="words-preview"></div><div id="image-copyright-preview"></div></div>
          @{[ input "imagePositionY",'range','imagePosition','' ]}
          @{[ input "imagePositionX",'range','imagePosition','' ]}
        </div>
      </div>
      <div class="image-custom-form">
        <h3>画像選択</h3>
        <p>
          プレビューエリアに画像ファイルをドロップ、<br>
          または
          <input type="file" accept="image/*" name="imageFile" onchange="imagePreView(this.files[0])"><br>
          ※ @{[ int($set::image_maxsize / 1024) ]}KBまでのJPG/PNG/GIF
        </p>
        <script>
          document.getElementById('image-custom').addEventListener('dragover',function(e){
            e.preventDefault();
          });
          document.getElementById('image-custom').addEventListener('drop',function(e){
            e.preventDefault();
          });
          document.querySelector('.image-custom-view-area').addEventListener('drop', function (e) {
            const obj = document.querySelector("[name='imageFile']");
            obj.files = e.dataTransfer.files;
            imagePreView(obj.files[0]);
          });
        </script>
        <h3>画像レイアウト</h3>
        <p>
          <b>縦基準位置</b>:<span id="image-positionY-view"></span> ／
          <b>横基準位置</b>:<span id="image-positionX-view"></span><br>
        </p>
        <p>
          <b>表示（トリミング）方式</b>：<br><select name="imageFit" oninput="imagePosition()">
          <option value="cover"   @{[$::pc{'imageFit'} eq 'cover'  ?'selected':'']}>自動的に最低限のトリミング（表示域いっぱいに表示）
          <option value="contain" @{[$::pc{'imageFit'} eq 'contain'?'selected':'']}>トリミングしない（必ず画像全体を収める）
          <option value="percentX" @{[$::pc{'imageFit'} eq 'percentX'?'selected':'']}>任意のトリミング／横幅を基準
          <option value="percentY" @{[$::pc{'imageFit'} eq 'percentY'?'selected':'']}>任意のトリミング／縦幅を基準
          <option value="unset"   @{[$::pc{'imageFit'} eq 'unset'  ?'selected':'']}>拡大縮小せず表示（ドット絵など向き）
          </select><br>
          <small>※いずれの設定でも、クリックすると画像全体が表示されます。</small>
        </p>
        <p id="image-percent-config">
          <b>拡大率</b>：@{[ input "imagePercent",'number','imagePosition','style="width:4em;"' ]}%<br>
          <input type="range" id="image-percent-bar" min="10" max="1000" oninput="imagePercentBarChange(this.value)" style="width:100%;"><br>
          （100%で幅ピッタリ）<br>
        </p>
        <h3>画像の注釈</h3>
        <p>
          <b>作者名や権利表示：</b><br>
          @{[ input 'imageCopyright','text ','wordsPreView','placeholder="(C)画像の作者名" style="width:70%;"' ]}<br>
        </p>
        <p>
          <b>URL（作者のWebサイトなどあれば）：</b><br>
          @{[ input 'imageCopyrightURL','url ','wordsPreView','placeholder="https://..." style="width:90%;"' ]}<br>
        </p>
        <h3>画像に重ねるセリフ</h3>
        <p>
          <textarea name="words" style="width:100%;height:3.6em;" onchange="wordsPreView();" placeholder="「任意の台詞」">$::pc{'words'}</textarea>
        </p>
        <p>
          <b>セリフの配置</b>：
          <select name="wordsX" oninput="wordsPreView();">@{[ option 'wordsX','右','左' ]}</select>
          <select name="wordsY" oninput="wordsPreView();">@{[ option 'wordsY','上','下' ]}</select>
        </p>
      </div>
      <div class="image-custom-form close-button">
        <a class="button" onclick="imagePositionClose()">画像とセリフの設定を閉じる</a>
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
  ' value="'.($_[1] eq 'checkbox' ? 1 : $::pc{$name}).'"'.
  ($other?" $other":"").
  ($type eq 'checkbox' && $::pc{$name}?" checked":"").
  ($oniput?' oninput="'.$oniput.'"':"").
  '>';
}
sub option {
  my $name = shift;
  my $text = '<option value="">';
  foreach my $i (@_) {
    my $value = $i;
    my $view;
    my $label = 0;
    if($value =~ s/^label=//){
      $text .= '</optgroup>' if $label;
      $text .= '<optgroup label="'.$value.'">';
      $label = 1;
    }
    else {
      if($value =~ s/\|\<(.*?)\>$//){ $view = $1 } else { $view = $value }
      $text .= '<option value="'.$value.'"'.($::pc{$name} eq $value ? ' selected':'').'>'.$view;
    }
  }
  return $text;
}
sub display {
  $_[0] ? ($_[1] ? " style=\"display:$_[1]\"" : '') : ' style="display:none"'
}

1;