################## 更新フォーム ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

our $LOGIN_ID = check;

our $mode = $::in{'mode'};
$::in{'log'} ||= $::in{'backup'};

if($set::user_reqd && !check){ error('ログインしていません。'); }
### 個別処理 --------------------------------------------------
my $type = $::in{'type'};
our %conv_data = ();
if($mode eq 'convert'){
  if($::in{'url'}){
    require $set::lib_convert;
    %conv_data = dataConvert($::in{'url'});
    $type = $conv_data{'type'};
  }
  elsif($::in{'file'}){
    use JSON::PP;
    my $file; my $buffer; my $i;
    while(my $bytesread = read(param('file'), $buffer, 2048)) {
      if(!$i && $buffer !~ /^{/){ error '有効なJSONデータではありません。' }
      $file .= $buffer;
      $i++;
    }
    %conv_data =  %{ decode_json( $file) };
    $type = $conv_data{'type'};
  }
  else {
    error('URLが入力されていない、または、ファイルが選択されていません。');
  }
}

if   ($type eq 'm'){ require $set::lib_edit_mons; }
elsif($type eq 'i'){ require $set::lib_edit_item; }
elsif($type eq 'a'){ require $set::lib_edit_arts; }
else               { require $set::lib_edit_char; }

### 共通サブルーチン --------------------------------------------------
## データ読み込み
sub pcDataGet {
  my $mode = shift;
  my %pc;
  my $file;
  my $message;
  my $datadir = ($type eq 'm') ? $set::mons_dir : ($type eq 'i') ? $set::item_dir : ($type eq 'a') ? $set::arts_dir : $set::char_dir;
  # エラー
  if($main::make_error) {
    $mode = ($mode eq 'save') ? 'edit' : 'blanksheet';
    for (param()){ $pc{$_} = decode('utf8', param($_)); }
    $message = $::make_error;
  }
  # 保存 / 編集 / 複製 / コンバート
  elsif($mode eq 'edit' || $mode eq 'save'){
    if($mode eq 'save'){
      $mode = 'edit';
      $message .= 'データを更新しました。<a href="./?id='.$::in{'id'}.'">⇒シートを確認する</a>';
    }
    (undef, undef, $file, undef, my $user) = getfile($::in{'id'},$::in{'pass'},$LOGIN_ID);
    $file = $user ? '_'.$user.'/'.$file : $file;

    my $datatype = ($::in{'log'}) ? 'logs' : 'data';
    my $hit = 0;
    open my $IN, '<', "${datadir}${file}/${datatype}.cgi" or &login_error;
    while (<$IN>){
      if($datatype eq 'logs'){
        if (index($_, "=$::in{'log'}=") == 0){ $hit = 1; next; }
        if (index($_, "=") == 0 && $hit){ last; }
        if (!$hit) { next; }
      }
      chomp $_;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = $value;
    }
    close($IN);
    if($datatype eq 'logs' && !$hit){ error("過去ログ（$::in{'log'}）が見つかりません。"); }
    
    if($::in{'log'}){
      ($pc{'protect'}, $pc{'forbidden'}) = protectTypeGet("${datadir}${file}/data.cgi");
      $message = $pc{'updateTime'}.' 時点のバックアップデータから編集しています。';
    }
  }
  elsif($mode eq 'copy'){
    $file = (getfile_open($::in{'id'}))[0];
    my $datatype = ($::in{'log'}) ? 'logs' : 'data';
    my $hit = 0;
    open my $IN, '<', "${datadir}${file}/${datatype}.cgi" or error 'データがありません。';
    while (<$IN>){
      if($datatype eq 'logs'){
        if (index($_, "=$::in{'log'}:") == 0){ $hit = 1; next; }
        if (index($_, "=") == 0 && $hit){ last; }
        if (!$hit) { next; }
      }
      chomp $_;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = $value;
    }
    close($IN);
    if($datatype eq 'logs' && !$hit){ error("過去ログ（$::in{'log'}）が見つかりません。"); }

    delete $pc{'image'};
    $pc{'protect'} = 'password';

    $message  = '「<a href="./?id='.$::in{'id'}.'" target="_blank"><!NAME></a>」';
    $message .= 'の<br><a href="./?id='.$::in{'id'}.'&log='.$::in{'log'}.'" target="_blank">'.$pc{'updateTime'}.'</a> 時点のバックアップデータ' if $::in{'log'};
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
  my $imgurl = shift;
  my $image_maxsize_view = $set::image_maxsize >= 1048576 ? sprintf("%.3g",$set::image_maxsize/1048576).'MB' : sprintf("%.3g",$set::image_maxsize/1024).'KB';
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
        <div id="image-custom-frame-S1" class="image-custom-frame"><div class="image-custom-view"><b>横幅が狭い時</b></div></div>
        <div id="image-custom-frame-S2" class="image-custom-frame"><div class="image-custom-view"><b>縦幅が狭い時</b></div></div>
        <div id="image-custom-frame-M"  class="image-custom-frame"><div class="image-custom-view"><b>標準の比率　<small>※縦横比は適宜変動します</small></b><div class="words" id="words-preview"></div><div id="image-copyright-preview"></div></div>
          @{[ input "imagePositionY",'range','imagePosition','step="0.001"' ]}
          @{[ input "imagePositionX",'range','imagePosition','step="0.001"' ]}
        </div>
      </div>
      <div class="image-custom-form">
        $set::img_notice
        <h3>画像選択</h3>
        <p>
          プレビューエリアに画像ファイルをドロップ、<br>
          または
          <input type="file" accept="image/*" name="imageFile" onchange="imagePreView(this.files[0], $set::image_maxsize || 0)"><br>
          ※ ファイルサイズ @{[ $image_maxsize_view ]} までの JPG/PNG/GIF/WebP
          <small>（サイズを超過する場合、自動的にWebP形式に変換し、その上でまだ超過している場合は縮小処理が行われます）</small>
          <input type="hidden" name="imageCompressed">
          <input type="hidden" name="imageCompressedType">
        </p>
        <script>
          const imageType = 'character';
          // ドラッグ＆ドロップで画像アップ
          document.getElementById('image-custom').addEventListener('dragover',function(e){
            e.preventDefault();
          });
          document.getElementById('image-custom').addEventListener('drop',function(e){
            e.preventDefault();
          });
          document.querySelector('.image-custom-view-area').addEventListener('drop', function (e) {
            const obj = document.querySelector("[name='imageFile']");
            obj.files = e.dataTransfer.files;
            imagePreView(obj.files[0], $set::image_maxsize || 0);
          });

          // ホイールで拡大率調整
          const mainArea = document.querySelector('#image-custom-frame-M .image-custom-view');
          document.querySelector('.image-custom-view-area').addEventListener('wheel', function (e) {
            e.preventDefault();
          });
          mainArea.addEventListener('wheel', function (e) {
            const obj = form.imagePercent;
            if     (e.deltaY > 0){ obj.value = Number(obj.value)+10 }
            else if(e.deltaY < 0){ obj.value = Number(obj.value)-10 }
            if(obj.value < 0){ obj.value = 0 }
            imageDragPointSet();
            imagePosition();
          });
          
          // ドラッグで位置調整
          let imgURL = "${imgurl}";
          let pointWidth  = 1;
          let pointHeight = 1;
          mainArea.addEventListener('mousedown' , function (e) { imageDragStart(e); });
          mainArea.addEventListener('mousemove' , function (e) { imageDragMove(e);  });
          mainArea.addEventListener('mouseup'   , function (e) { imageDragEnd();    });
          mainArea.addEventListener('mouseleave', function (e) { imageDragEnd();   });
          mainArea.addEventListener('touchstart', function (e) { imageDragStart(e); });
          mainArea.addEventListener('touchmove' , function (e) { imageDragMove(e);  });
          mainArea.addEventListener('touchend'  , function (e) { imageDragEnd();   });
        </script>
        <h3>画像レイアウト</h3>
        <p>
          <b>縦基準位置</b>:<span id="image-positionY-view"></span> ／
          <b>横基準位置</b>:<span id="image-positionX-view"></span><br>
        </p>
        <p>
          <b>表示（トリミング）方式</b>：<br><select name="imageFit" oninput="imageDragPointSet();imagePosition()">
          <option value="cover"   @{[$::pc{'imageFit'} eq 'cover'  ?'selected':'']}>自動的に最低限のトリミング（表示域いっぱいに表示）
          <option value="contain" @{[$::pc{'imageFit'} eq 'contain'?'selected':'']}>トリミングしない（必ず画像全体を収める）
          <option value="percentX" @{[$::pc{'imageFit'} eq 'percentX'?'selected':'']}>任意のトリミング／横幅を基準
          <option value="percentY" @{[$::pc{'imageFit'} eq 'percentY'?'selected':'']}>任意のトリミング／縦幅を基準
          <option value="unset"   @{[$::pc{'imageFit'} eq 'unset'  ?'selected':'']}>拡大縮小せず表示（ドット絵など向き）
          </select><br>
          <small>※いずれの設定でも、クリックすると画像全体が表示されます。</small>
        </p>
        <p id="image-percent-config">
          <b>拡大率</b>：@{[ input "imagePercent",'number','imageDragPointSet();imagePosition','min="0"  style="width:4em;"' ]}%<br>
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
    if($value =~ s/^def=//){
      if($value =~ s/\|\<(.*?)\>$//){ $view = $1 } else { $view = $value }
      $text = '<option value="">'.$view;
    }
    elsif($value =~ s/^label=//){
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
sub selectInput {
  my $name = shift;
  my $func = shift;
  if($func && $func !~ /\(.*?\)$/){ $func .= '()'; }
  my $text = '<div class="select-input"><select name="'.$name.'" oninput="selectInputCheck(\''.$name.'\',this);'.$func.'"">'.option($name, @_);
  $text .= '<option value="free">その他（自由記入）'; 
  my $hit = 0;
  foreach my $value (@_) { if($::pc{$name} eq $value){ $hit = 1; last; } }
  if($::pc{$name} && !$hit){ $text .= '<option value="'.$::pc{$name}.'" selected>'.$::pc{$name}; }
  $text .= '</select>';
  $text .= '<input type="text" name="'.$name.'Free" list="list-'.$name.'"></div>';
  return $text;
}
sub display {
  $_[0] ? ($_[1] ? " style=\"display:$_[1]\"" : '') : ' style="display:none"'
}

1;