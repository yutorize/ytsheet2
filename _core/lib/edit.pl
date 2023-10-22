################## 更新フォーム ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

our $LOGIN_ID = check;

our $mode = $::in{mode};
$::in{log} ||= $::in{backup};

if($set::user_reqd && !$LOGIN_ID){ error('ログインしていません。'); }
### 個別処理 --------------------------------------------------
my $type = $::in{type};
my $file; my $author;
our %conv_data = ();

if($mode eq 'edit'){
  (undef, undef, $file, $type, my $user) = getfile($::in{id},$::in{pass},$LOGIN_ID);
  $file = ($user ? "_${user}/" : 'anonymous/') . $file;
}
elsif($mode eq 'copy'){
  ($file, $type, $author) = (getfile_open($::in{id}))[0..2];
}
elsif($mode eq 'convert'){
  if($::in{url}){
    require $set::lib_convert;
    %conv_data = dataConvert($::in{url});
    $type = $conv_data{type};
  }
  elsif($::in{file}){
    use JSON::PP;
    my $data; my $buffer; my $i;
    while(my $bytesread = read(param('file'), $buffer, 2048)) {
      if(!$i && $buffer !~ /^{/){ error '有効なJSONデータではありません。' }
      $data .= $buffer;
      $i++;
    }
    %conv_data =  %{ decode_json( $data) };
    $type = $conv_data{type};
  }
  else {
    error('URLが入力されていない、または、ファイルが選択されていません。');
  }
}
if(!$LOGIN_ID && $mode =~ /^(?:blanksheet|copy|convert)$/){
  my $max_files = 32000;
  my $data_dir;
  if   ($set::game eq 'sw2' && $type eq 'm'){ $data_dir = $set::mons_dir; }
  elsif($set::game eq 'sw2' && $type eq 'i'){ $data_dir = $set::item_dir; }
  elsif($set::game eq 'sw2' && $type eq 'a'){ $data_dir = $set::arts_dir; }
  elsif($set::game eq 'ms'  && $type eq 'c'){ $data_dir = $set::clan_dir; }
  else { $data_dir = $set::char_dir; }
  opendir my $dh, "${data_dir}anonymous/";
  my $num_files = () = readdir($dh);
  if($num_files-2 >= $max_files){
    error("登録数上限です。($num_files/$max_files)<br>アカウントに紐づけないデータは、これ以上登録できないため、アカウント登録・ログインをしてから作成を行ってください。");
  }
}

if   ($set::game eq 'sw2' && $type eq 'm'){ require $set::lib_edit_mons; }
elsif($set::game eq 'sw2' && $type eq 'i'){ require $set::lib_edit_item; }
elsif($set::game eq 'sw2' && $type eq 'a'){ require $set::lib_edit_arts; }
elsif($set::game eq 'ms'  && $type eq 'c'){ require $set::lib_edit_clan; }
else               { require $set::lib_edit_char; }

### 共通サブルーチン --------------------------------------------------
## データ読み込み
sub pcDataGet {
  my $mode = shift;
  my %pc;
  my $message;
  my $datadir = 
    ($set::game eq 'sw2' && $type eq 'm') ? $set::mons_dir : 
    ($set::game eq 'sw2' && $type eq 'i') ? $set::item_dir : 
    ($set::game eq 'sw2' && $type eq 'a') ? $set::arts_dir : 
    ($set::game eq 'ms'  && $type eq 'c') ? $set::clan_dir : 
    $set::char_dir;
  # 保存 / 編集 / 複製 / コンバート
  if($mode eq 'edit'){
    my $datatype = ($::in{log}) ? 'logs' : 'data';
    my $hit = 0;
    open my $IN, '<', "${datadir}${file}/${datatype}.cgi" or &loginError;
    while (<$IN>){
      if($datatype eq 'logs'){
        if (index($_, "=$::in{log}=") == 0){ $hit = 1; next; }
        if (index($_, "=") == 0 && $hit){ last; }
        if (!$hit) { next; }
      }
      chomp $_;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = $value;
    }
    close($IN);
    if($datatype eq 'logs' && !$hit){ error("過去ログ（$::in{log}）が見つかりません。"); }
    
    if($::in{log}){
      ($pc{protect}, $pc{forbidden}) = protectTypeGet("${datadir}${file}/data.cgi");
      $message = $pc{updateTime}.' 時点のバックアップデータから編集しています。';
    }
    $pc{imageURL} = $pc{image} ? "./?id=$::in{id}&mode=image&cache=$pc{imageUpdate}" : '';
  }
  elsif($mode eq 'copy'){
    my $datatype = ($::in{log}) ? 'logs' : 'data';
    my $hit = 0;
    open my $IN, '<', "${datadir}${file}/${datatype}.cgi" or error 'データがありません。';
    while (<$IN>){
      if($datatype eq 'logs'){
        if (index($_, "=$::in{log}:") == 0){ $hit = 1; next; }
        if (index($_, "=") == 0 && $hit){ last; }
        if (!$hit) { next; }
      }
      chomp $_;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = $value;
    }
    close($IN);
    if($datatype eq 'logs' && !$hit){ error("過去ログ（$::in{log}）が見つかりません。"); }
    
    if($pc{forbidden}){
      if($::in{log}){
        ($pc{protect}, $pc{forbidden}) = protectTypeGet("${datadir}${file}/data.cgi");
      }
      unless(
        ($pc{protect} eq 'none') || 
        ($author && ($author eq $LOGIN_ID || $set::masterid eq $LOGIN_ID))
      ){
        error("閲覧・編集権限がありません。");
      }
    }

    delete $pc{image};
    delete $pc{protect};

    $message  = '「<a href="./?id='.$::in{id}.'" target="_blank"><!NAME></a>」';
    $message .= 'の<br><a href="./?id='.$::in{id}.'&log='.$::in{log}.'" target="_blank">'.$pc{updateTime}.'</a> 時点のバックアップデータ' if $::in{log};
    $message .= 'を<br>コピーして新規作成します。<br>（まだ保存はされていません）';
  }
  elsif($mode eq 'convert'){
    %pc = %::conv_data;
    delete $pc{image};
    delete $pc{imageURL};
    delete $pc{protect};
    $message = '「<a href="'.$::in{url}.'" target="_blank"><!NAME></a>」をコンバートして新規作成します。<br>（まだ保存はされていません）';
  }
  ##
  return (\%pc, $mode, $file, $message)
}
## トークン生成
sub tokenMake {
  my $token = random_id(12);

  my $mask = umask 0;
  sysopen (my $FH, $set::tokenfile, O_WRONLY | O_APPEND | O_CREAT, 0666);
  print $FH $token."<>".(time + 60*60*24*7)."<>\n";
  close($FH);
  
  return $token;
}

## ログインエラー
sub loginError {
  our $login_error = 'パスワードが間違っているか、<br>編集権限がありません。';
  require $set::lib_view;
  exit;
}

## Javascript用共通変数
sub commonJSVariable {
  return <<"HTML";
  const base64Mode = @{[ $set::base64mode || 0 ]};
HTML
}

## 簡略化系
sub input {
  my ($name, $type, $oninput, $other) = @_;
  if($oninput && $oninput !~ /\(.*?\)$/){ $oninput .= '()'; }
  '<input'.
  ' type="'.($type?$type:'text').'"'.
  ' name="'.$name.'"'.
  ' value="'.($_[1] eq 'checkbox' ? 1 : $::pc{$name}).'"'.
  ($other?" $other":"").
  ($type eq 'checkbox' && $::pc{$name}?" checked":"").
  ($oninput?' oninput="'.$oninput.'"':"").
  '>';
}
sub checkbox {
  my ($name, $text, $oninput, $other) = @_;
  if($oninput && $oninput !~ /\(.*?\)$/){ $oninput .= '()'; }
  '<label class="check-button">'.
  '<input type="checkbox"'.
  ' name="'.$name.'"'.
  ' value="1"'.
  ($::pc{$name}?" checked":"").
  ($oninput?' oninput="'.$oninput.'"':"").
  ($other?" $other":"").
  '>'.
  ($text?'<span>'.$text.'</span>':'').
  '</label>';
}
sub radio {
  my $name = shift;
  my $oninput = shift;
  my $value = shift;
  my $text = shift;
  if($oninput && $oninput !~ /\(.*?\)$/){ $oninput .= '()'; }
  '<label class="radio-button">'.
  '<input type="radio"'.
  ' name="'.$name.'"'.
  ' value="'.$value.'"'.
  ($::pc{$name} eq $value?" checked":"").
  ($oninput?' oninput="'.$oninput.'"':"").
  '>'.
  ($text?'<span>'.$text.'</span>':'').
  '</label>';
}
sub radios {
  my $name = shift;
  my $oninput = shift;
  if($oninput && $oninput !~ /\(.*?\)$/){ $oninput .= '()'; }
  my $out;
  foreach (@_) {
    my $value = $_;
    my $view;
    if($value =~ s/=>(.*?)$//){ $view = $1 } else { $view = $value }
    $out .= '<label class="radio-button">'.
    '<input type="radio"'.
    ' name="'.$name.'"'.
    ' value="'.$value.'"'.
    ($::pc{$name} eq $value?" checked":"").
    ($oninput?' oninput="'.$oninput.'"':"").
    '><span>'.$view.'</span></label>';
  }
  return $out;
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
  my $text = '<div class="select-input"><select name="'.$name.'" oninput="selectInputCheck(\''.$name.'\',this);'.$func.'">'.option($name, @_);
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

## 画像欄
sub imageForm {
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
          <option value="cover"   @{[$::pc{imageFit} eq 'cover'  ?'selected':'']}>自動的に最低限のトリミング（表示域いっぱいに表示）
          <option value="contain" @{[$::pc{imageFit} eq 'contain'?'selected':'']}>トリミングしない（必ず画像全体を収める）
          <option value="percentX" @{[$::pc{imageFit} eq 'percentX'?'selected':'']}>任意のトリミング／横幅を基準
          <option value="percentY" @{[$::pc{imageFit} eq 'percentY'?'selected':'']}>任意のトリミング／縦幅を基準
          <option value="unset"   @{[$::pc{imageFit} eq 'unset'  ?'selected':'']}>拡大縮小せず表示（ドット絵など向き）
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
          <textarea name="words" style="width:100%;height:3.6em;" onchange="wordsPreView();" placeholder="「任意の台詞」">$::pc{words}</textarea>
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

## チャットパレット
sub chatPaletteForm {
  my $palette;
  my %opt = (
    tool => [
      '=>ゆとチャadv.',
      'tekey=>Tekey',
      'bcdice=>その他(BCDice使用)',
    ],
    buff => 1,
    @_,
  );
  $palette .= "$_\n" foreach(paletteProperties('',$::in{type}));
  return <<"HTML";
    <section id="section-palette" style="display:none;">
      <div class="box">
        <h2>チャットパレット</h2>
        <p>
          手動パレットの配置:<select name="paletteInsertType" style="width: auto;">
            <option value="exchange" @{[ $::pc{paletteInsertType} eq 'exchange'?'selected':'' ]}>プリセットと入れ替える</option>
            <option value="begin"    @{[ $::pc{paletteInsertType} eq 'begin'   ?'selected':'' ]}>プリセットの手前に挿入</option>
            <option value="end"      @{[ $::pc{paletteInsertType} eq 'end'     ?'selected':'' ]}>プリセットの直後に挿入</option>
          </select>
        </p>
        <textarea name="chatPalette" style="height:20em" placeholder="例）&#13;&#10;2d6+{冒険者}+{器用}&#13;&#10;&#13;&#10;※入力がない場合、プリセットが自動的に反映されます。">$::pc{chatPalette}</textarea>
        
        <div class="palette-column">
        <h2>デフォルト変数 （自動的に末尾に出力されます）</h2>
        <textarea id="paletteDefaultProperties" readonly style="height:20em">$palette</textarea>
          <p>
            @{[ checkbox 'chatPalettePropertiesAll','全てのデフォルト変数を出力する','setChatPalette' ]} <br>
          （デフォルトだと、未使用の変数は出力されません）
          </p>
        </div>
        <div class="palette-column">
          <h2>プリセット （見本またはコピーペースト用）</h2>
          <textarea id="palettePreset" readonly style="height:20em"></textarea>
          <p>
            @{[ checkbox 'paletteUseVar','デフォルト変数を使う','setChatPalette' ]}
            @{[ $opt{buff} ? checkbox('paletteUseBuff','バフデバフ用変数を使う','setChatPalette') : '' ]}<br>
            @{[ checkbox 'paletteRemoveTags','ルビなどテキスト装飾の構文を取り除く','setChatPalette' ]} 
          </p>
          <dl>
            <dt>使用するオンセツール
            <dd class="left">@{[ radios 'paletteTool','setChatPalette',@{$opt{tool}} ]}
          </dl>
        </div>
      </div>
    </section>
HTML
}

## カラーカスタム欄
sub colorCostomForm {
  return <<"HTML";
      <section id="section-color" style="display:none;">
      <h2>シートのカラー設定</h2>
      <div class="box-union">
        <div class="box color-custom">
          <h2>メインカラー</h2>
          <table>
          <tr class="color-range-H"><th>色相</th><td><input type="range" name="colorHeadBgH" min="0" max="360" value="$::pc{colorHeadBgH}" oninput="changeColor();"></td><td id="colorHeadBgHValue">$::pc{colorHeadBgH}</td></tr>
          <tr class="color-range-S"><th>彩度</th><td><input type="range" name="colorHeadBgS" min="0" max="100" value="$::pc{colorHeadBgS}" oninput="changeColor();"></td><td id="colorHeadBgSValue">$::pc{colorHeadBgS}</td></tr>
          <tr class="color-range-L"><th>輝度</th><td><input type="range" name="colorHeadBgL" min="0" max="100" value="$::pc{colorHeadBgL}" oninput="changeColor();"></td><td id="colorHeadBgLValue">$::pc{colorHeadBgL}</td></tr>
          </table>
        </div>
        <div class="box color-custom">
          <h2>サブカラー</h2>
          <table>
          <tr class="color-range-H"><th>色相</th><td><input type="range" name="colorBaseBgH"  min="0" max="360" value="$::pc{colorBaseBgH}" oninput="changeColor();"></td><td id="colorBaseBgHValue">$::pc{colorBaseBgH}</td></tr>
          <tr class="color-range-S"><th>色の濃さ</th><td><input type="range" name="colorBaseBgS"  min="0" max="100" value="$::pc{colorBaseBgS}" oninput="changeColor();"></td><td id="colorBaseBgSValue">$::pc{colorBaseBgS}</td></tr>
          </table>
          <hr>
          <p class="right"><span class="button" onclick="setDefaultColor();">デフォルトに戻す</span></p>
        </div>
      </div>
      <div class="color-sample">
        <div class="light color-set">
          <div class="name">色見本</div>
          <div class="box">
            <table class="data-table">
              <thead><tr><th>データ表組み</th><th>項目1</th><th>項目2</th></tr></thead>
              <tbody>
                <tr><td>ＡＡＡ</td><td>+1</td><td>+0</td></tr>
                <tr><td>ＢＢＢ</td><td>+2</td><td>+0</td></tr>
              </tbody>
            </table>
          </div>
          <div class="box">
            <h2>大見出し</h2>
            <h3>中見出し</h3>
            <h4>小見出し</h4>
            <table class="note-table">
              <thead><tr><th>テーブルヘッダ</th><td></td></tr></thead>
              <tbody><tr><th>テーブル見出し</th><td>テーブルセル</td></tr></tbody>
            </table>
            <p>
              <a class="link">未読リンク</a> <a class="visited">既読リンク</a>
            </p>
          </div>
        </div>
        <div class="night">
          <div class="name color-set">色見本</div>
          <div class="box color-set">
            <table class="data-table">
              <thead><tr><th>データ表組み</th><th>項目1</th><th>項目2</th></tr></thead>
              <tbody>
                <tr><td>ＡＡＡ</td><td>+1</td><td>+0</td></tr>
                <tr><td>ＢＢＢ</td><td>+2</td><td>+0</td></tr>
              </tbody>
            </table>
          </div>
          <div class="box color-set">
            <h2>大見出し</h2>
            <h3>中見出し</h3>
            <h4>小見出し</h4>
            <table class="note-table">
              <thead><tr><th>テーブルヘッダ</th><td></td></tr></thead>
              <tbody><tr><th>テーブル見出し</th><td>テーブルセル</td></tr></tbody>
            </table>
            <p>
              <a class="link">未読リンク</a> <a class="visited">既読リンク</a>
            </p>
          </div>
        </div>
      </div>
      </section>
HTML
}

## テキスト整形ルール
sub textRuleArea {
  my $system_rule = shift;
  my $multiline = shift;
  return <<"HTML";
    <aside id="text-rule" class="sticky-footer" style="display:none">
      <h2>テキスト装飾・整形ルール</h2>
      <i class="close-button" onclick="view('text-rule')"></i>
      <div>
        以下の書式で記入することで、テキスト装飾・整形が行なえます。<br>
        太字　：<code>''テキスト''</code>：<b>テキスト</b><br>
        斜体　：<code>'''テキスト'''</code>：<span class="oblique">テキスト</span><br>
        打消線：<code>%%テキスト%%</code>：<span class="strike">テキスト</span><br>
        下線　：<code>__テキスト__</code>：<span class="underline">テキスト</span><br>
        ルビ　：<code>|テキスト《てきすと》</code>：<ruby>テキスト<rt>てきすと</rt></ruby><br>
        傍点　：<code>《《テキスト》》</code>：<span class="text-em">テキスト</span><br>
        透明　：<code>{{テキスト}}</code>：<span style="color:transparent">テキスト</span>（ドラッグ反転で見える）<br>
        リンク：<code>[[テキスト>URL]]</code><br>
        別のゆとシートへのリンク：<code>[テキスト#シートのID]</code><br>
        <br>
        ${system_rule}
        <hr class="dotted">
        ※以下は一部の複数行の欄でのみ有効です。<br>
        （有効な欄：${multiline}）<br>
        大見出し：行頭に<code>*</code>：1行目に記述すると項目の見出しを差し替え<br>
        中見出し：行頭に<code>**</code><br>
        小見出し：行頭に<code>***</code><br>
        左寄せ　：行頭に<code>LEFT:</code>：以降のテキストがすべて左寄せになります。<br>
        中央寄せ：行頭に<code>CENTER:</code>：以降のテキストがすべて中央寄せになります。<br>
        右寄せ　：行頭に<code>RIGHT:</code>：以降のテキストがすべて右寄せになります。<br>
        横罫線（直線）：<code>----</code>（4つ以上のハイフン）<br>
        横罫線（点線）：<code> * * * *</code>（4つ以上の「スペース＋アスタリスク」）<br>
        横罫線（破線）：<code> - - - -</code>（4つ以上の「スペース＋ハイフン」）<br>
        表組み　　：<code>|テキスト|テキスト|</code>：表組み（テーブル）を作成します。<br>
        　　　　　　<code>|~テキスト|</code>のようにセル頭に~で見出しセルになります。<br>
        　　　　　　<code>|&gt;|テキスト|</code>のように&gt;単独で右のセルと結合します。<br>
        　　　　　　<code>|~|</code>のように~単独で上のセルと結合します。<br>
        定義リスト：<code>:項目名|説明文</code><br>
        　　　　　　<code>:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;|説明文2行目</code> 項目名を記入しないか、半角スペースで埋めると上と結合します。<br>
        折り畳み：行頭に<code>[>]項目名</code>：以降のテキストがすべて折り畳みになります。<br>
        　　　　　項目名を省略すると、自動的に「詳細」になります。<br>
        折り畳み終了：行頭に<code>[---]</code>：（ハイフンは3つ以上任意）<br>
        　　　　　　　省略すると、以後のテキストが全て折りたたまれます。<br>
        コメントアウト：行頭に<code>//</code>：記述した行を非表示にします。
      </div>
    </aside>
HTML
}

1;