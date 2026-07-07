################## 更新フォーム ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use JSON::PP;

our $LOGIN_ID = check;

our $mode = $::in{mode};
$::in{log} ||= $::in{backup};

if($set::user_reqd && !$LOGIN_ID){ error('401:ログインしていません。'); }
### type判別 --------------------------------------------------
my $type = $::in{type};

my $file; my $author;
our %conv_data = ();

if($mode eq 'edit'){
  ($file, $type, my $user) = authSheet($::in{id},$::in{pass},$LOGIN_ID);
  unless($file){ loginError(); }
  $file = ($user ? "_${user}/" : 'anonymous/') . $file;
}
elsif($mode eq 'copy'){
  ($file, $type, $author) = (findSheet($::in{id}))[0..2];
}
elsif($mode eq 'convert'){
  if($::in{url}){
    eval { require $set::lib_convert; };
    %conv_data = importSheetData($::in{url});
    $type = $conv_data{type};
  }
  elsif($::in{file}){
    my $data; my $buffer; my $i;
    while(my $bytesread = read(param('file'), $buffer, 2048)) {
      if(!$i && $buffer !~ /^{/){ error '400:有効なJSONデータではありません。' }
      $data .= $buffer;
      $i++;
    }
    %conv_data =  %{ decode_json($data) };
    $type = $conv_data{type};
  }
  elsif($::in{json}){
    %conv_data =  %{ decode_json($::in{json}) };
    $type = $conv_data{type};
  }
  elsif($::in{backupJSON}){
    %conv_data =  %{ decode_json($::in{backupJSON} ) };
    $type = $conv_data{type};
  }
  else {
    error('400:URLが入力されていない、または、ファイルが選択されていません。');
  }
}

changeFileByType($type);

### キャパシティチェック --------------------------------------------------
my $attentionOfCapacity;
if(!$LOGIN_ID && $mode =~ /^(?:blanksheet|copy|convert)$/){
  my $max_files = 32000;
  opendir my $dh, "${set::char_dir}anonymous/";
  my $num_files = () = readdir($dh);
  $num_files += -2;
  if($num_files >= $max_files){
    error("503:現在、サーバーの許容量の都合により、ユーザーアカウントに紐づけされていないシートを新規作成できません。<br>アカウント登録・ログインをしてから作成を行ってください。<br>（現在の非紐付けシート総数: $num_files/$max_files 件）");
  }
  elsif ($num_files >= $max_files - 100){
    $attentionOfCapacity = "<div class='attention left'>　ユーザーアカウントに紐づけされていないシートの数が許容上限近くです。（この画面を開いた時点の件数／上限件数: $num_files／$max_files）<br>　アカウントを作成・ログインしてから新規作成を行うことを推奨します。<br><br>　この新規シートを作成（編集）しているあいだに、（別のユーザーの新規保存によって）シートの件数が増加し上限に達すると、このシートの新規保存ができなくなる（エラーになる）ため、注意してください。<br>（一度新規保存した後は、上限に達していても、同シートの再編集・再保存は可能です）<br></div>";
  }
}

### 各ゲームシステム処理 --------------------------------------------------
require $set::lib_edit_char;

### 共通サブルーチン #################################################################################
### 簡略化系 --------------------------------------------------
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
sub textarea {
  my ($name, $oninput, $other) = @_;
  if($oninput && $oninput !~ /\(.*?\)$/){ $oninput .= '()'; }
  '<textarea'.
      ' name="'.$name.'"'.
      ($other?" $other":"").
      ($oninput?' oninput="'.$oninput.'"':"").
      '>' . $::pc{$name} . '</textarea>';
}
sub checkbox {
  my ($name, $text, $oninput, $other) = @_;
  if($oninput && $oninput !~ /\(.*?\);?$/){ $oninput .= '()'; }
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
  my $deselectable;
  if($oninput =~ s/^deselectable,?//){ $deselectable = 1; }
  if($oninput && $oninput !~ /\(.*?\);?$/){ $oninput .= '()'; }
  '<label class="radio-button">'.
  '<input type="radio"'.
  ' name="'.$name.'"'.
  ' value="'.$value.'"'.
  ($::pc{$name} eq $value?" checked":"").
  ($oninput?' oninput="'.$oninput.'"':"").
  ($deselectable?' class="deselectable"':"").
  '>'.
  ($text?'<span>'.$text.'</span>':'').
  '</label>';
}
sub radios {
  my $name = shift;
  my $oninput = shift;
  my $deselectable;
  if($oninput =~ s/^deselectable,?//){ $deselectable = 1; }
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
    ($deselectable?' class="deselectable"':"").
    '><span>'.$view.'</span></label>';
  }
  return $out;
}
sub option {
  my $name = shift;
  my $HTML = '<option value="">';
  my $selected = $::pc{$name};
  foreach my $i (@_) {
    my $value;
    my $text;
    my $attr;
    if(ref $i eq 'HASH'){
      $value = $i->{value} // '';
      $text  = $i->{text}  // '';
      $attr  = $i->{attr} ? " $i->{attr}" : '';
      if($i->{label}){ $value = "LABEL=$i->{label}" }
      if($i->{close}){ $value = "GROUPCLOSE" }
    }
    else { $value = $i }

    if($value =~ /^LABEL=(.+)$/){
      $HTML .= qq|<optgroup label="$1"$attr>|;
      next;
    }
    elsif($value eq 'GROUPCLOSE') {
      $HTML .= '</optgroup>';
      next;
    }
    elsif($value =~ s/^DEF=//){
      $selected ||= $value;
      $HTML =~ s/^<option value="">//;
    }

    if($value =~ s/=>(.*?)$//){ $text = $1 }
    else { $text = $value }

    $HTML .= qq|<option value="$value"$attr|
      . ($selected eq $value ? ' selected' : '')
      . ">$text";
  }

  return $HTML;
}
sub selectBox {
  my $name = shift;
  my $func = shift;
  if($func && $func !~ /\(.*?\);?$/){ $func .= '()'; }
  my $text = '<select name="'.$name.'" oninput="'.$func.'">'.option($name, @_).'</select>';
  return $text;
}
sub selectInput {
  my $name = shift;
  my $func = shift;
  if($func && $func !~ /\(.*?\);?$/){ $func .= '()'; }
  my $text = '<div class="select-input"><select name="'.$name.'" oninput="selectInputCheck(this);'.$func.'">'.option($name, @_);
  $text .= '<option value="free">その他（自由記入）';
  unless($text =~ /value="\Q$::pc{$name}\E"/){ $text .= '<option value="'.$::pc{$name}.'" selected>'.$::pc{$name}; }
  $text .= '</select>';
  $text .= '<input type="text" name="'.$name.'Free" list="list-'.$name.'"></div>';
  return $text;
}
sub display {
  $_[0] ? ($_[1] ? " style=\"display:$_[1]\"" : '') : ' style="display:none"'
}

### ログインエラー --------------------------------------------------
sub loginError {
  our $login_error = 'パスワードが間違っているか、<br>編集権限がありません。';
  require $set::lib_view;
  exit;
}

### データ読み込み --------------------------------------------------
sub loadSheetData {
  my %pc;
  my $message;
  my $sheetDir =  $set::char_dir.$file;
  # 保存 / 編集 / 複製 / コンバート
  if($mode eq 'edit'){
    my $datatype = ($::in{log}) ? 'logs' : 'data';
    foreach (readSheetRecordLines $set::char_dir, $file, $datatype, $::in{log}){
      chomp $_;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = $value if $value ne '';
    }

    if($::in{log}){
      ($pc{protect}, $pc{forbidden}) = getProtectType("${sheetDir}/data.cgi");
      $message = $pc{updateTime}.' 時点のバックアップデータから編集しています。';
    }
    $pc{mainImage} ||= 1;
  }
  elsif($mode eq 'copy'){
    my $datatype = ($::in{log}) ? 'logs' : 'data';
    foreach (readSheetRecordLines $set::char_dir, $file, $datatype, $::in{log}){
      chomp $_;
      my ($key, $value) = split(/<>/, $_, 2);
      $pc{$key} = $value;
    }

    if($pc{forbidden}){
      if($::in{log}){
        ($pc{protect}, $pc{forbidden}) = getProtectType("${sheetDir}/data.cgi");
      }
      unless(
        ($pc{protect} eq 'none') ||
        ($author && ($author eq $LOGIN_ID || $set::masterid eq $LOGIN_ID))
      ){
        error("403:閲覧・編集権限がありません。");
      }
    }

    deleteImageData(\%pc);
    delete $pc{protect};

    $message  = '<div class="data-imported">';
    $message .= '「<a href="./?id='.$::in{id}.'" target="_blank"><!NAME></a>」';
    $message .= 'の<br><a href="./?id='.$::in{id}.'&log='.$::in{log}.'" target="_blank">'.$pc{updateTime}.'</a> 時点のバックアップデータ' if $::in{log};
    $message .= 'を<br>コピーして新規作成します。<br>（まだ保存はされていません）';
    $message .= '</div>';
  }
  elsif($mode eq 'convert'){
    %pc = %::conv_data;
    deleteImageData(\%pc);
    delete $pc{imageURL};
    delete $pc{protect};
    $_ =~ s/"/&quot;/g foreach(values %pc);
    if($::in{backupJSON}){
      $message = '<span class="data-imported backup-loaded">入力途中の新規シートを復元しました</span>';
    }
    else {
      $message = '<div class="data-imported">「<a href="'.$::in{url}.'" target="_blank"><!NAME></a>」をコンバートして新規作成します。<br>（まだ保存はされていません）</div>';
    }
  }

  if($attentionOfCapacity){
    $message = $attentionOfCapacity .($message?'<hr>':''). $message
  }
  ##
  return (\%pc, $file, $message)
}

### トークン生成 --------------------------------------------------
sub tokenMake {
  my $token = randomId(12);

  sysopen (my $FH, $set::tokenfile, O_WRONLY | O_APPEND | O_CREAT);
  print $FH $token."<>".(time + 60*60*24*7)."<>\n";
  close($FH);

  return $token;
}

### 画像データ削除 --------------------------------------------------
sub deleteImageData {
  my ($pc) = @_;
  for my $imageNo (1 .. ($set::image_maxcount || 1)){
    my $suffix = imageSuffix($imageNo);
    delete $pc->{"image$suffix"};
    delete $pc->{"imageUpdate$suffix"};
    delete $pc->{"imageURL$suffix"};
  }
  delete $pc->{mainImage};
}

### 新規作成系モード判定 --------------------------------------------------
sub isNewSheet {
  return $mode =~ /^(?:blanksheet|copy|convert)$/ ? 1 : 0;
}

### 共通初期値 --------------------------------------------------
## 画像
sub setDefaultImageStyle {
  my ($pc) = @_;
  $pc->{imageFit} = ($pc->{imageFit} eq 'percent') ? 'percentX' : $pc->{imageFit};
  $pc->{imagePercent}   //= '200';
  $pc->{imagePositionX} //= '50';
  $pc->{imagePositionY} //= '50';
}
## セリフ
sub setDefaultWordsPosition {
  my ($pc) = @_;
  $pc->{wordsX} ||= '右';
  $pc->{wordsY} ||= '上';
}

### カスタマイズされた初期値の反映 --------------------------------------------------
sub applyCustomizedInitialValues {
  my %pc = %{shift;};
  my $_type = shift;
  $_type //= $pc{type};
  $_type //= '';

  if (%set::customizedInitialValues && $set::customizedInitialValues{$_type}) {
    my %values = %{$set::customizedInitialValues{$_type}};

    foreach (keys %values) {
      $pc{$_} = $values{$_};
    }
  }

  return %pc;
}

### メッセージの <!NAME> 展開 --------------------------------------------------
sub applyMessageName {
  my ($message, $name) = @_;
  return $message if !$message;
  $name ||= '無題';
  $name = removeTags unescapeTags($name);
  $message =~ s/<!NAME>/$name/g;
  return $message;
}

### 編集画面の共通開始骨格（head〜form開始） --------------------------------------------------
sub renderEditPageStart {
  my (%opt) = @_;
  my $title      = $opt{title}      // '編集';
  my $headerMenu = $opt{headerMenu} // '';
  my $extraCss   = $opt{extraCss}   // '';
  my $extraJsTop = $opt{extraJsTop} // '';
  my $extraJsMid = $opt{extraJsMid} // '';

  my $systemId = $set::system_id || $set::game;
  my $type = $::pc{type} // $::in{type} // '';
  my $sheetType = $set::lib_type{$type}{sheetType} || 'chara';
  my $base64Mode = $set::base64mode || 0;

  return <<~"HTML";
  Content-Type: text/html; charset=utf-8\n
  <!DOCTYPE html>
  <html lang="ja">
  <head>
    <meta charset="UTF-8">
    <meta name="robots" content="noindex">
    <meta name="viewport" content="width=device-width,initial-scale=1.0">
    <title>@{[ $::in{mode} eq 'edit' ? "編集：$title" : '新規作成']} - $set::title</title>
    <link rel="stylesheet" media="all" href="$::core_dir/skin/_common/css/base.css?$::ver">
    <link rel="stylesheet" media="all" href="$::core_dir/skin/_common/css/sheet.css?$::ver">
    <link rel="stylesheet" media="all" href="$::core_dir/skin/$set::game/css/theme.css?$::ver">
    <link rel="stylesheet" media="all" href="$::core_dir/skin/$set::game/css/$sheetType.css?$::ver">
    <link rel="stylesheet" media="all" href="$::core_dir/skin/_common/css/edit.css?$::ver">
    <link rel="stylesheet" media="all" href="$::core_dir/skin/$set::game/css/edit.css?$::ver">
    $extraCss
    <script src="$::core_dir/skin/_common/js/lib/Sortable.min.js"></script>
    <script src="$::core_dir/skin/_common/js/lib/compressor.min.js"></script>
    $extraJsTop
    @{[ $set::lib_js_consts ? qq|<script src="./?mode=js-consts&ver=$::ver"></script>| : '' ]}
    <script src="$::core_dir/lib/edit.js?$::ver" defer></script>
    <script src="$::core_dir/lib/$set::game/edit-$sheetType.js?$::ver" defer></script>
    $extraJsMid
    <script src="$::core_dir/skin/_common/js/common.js?$::ver"></script>
    <script>const base64Mode = $base64Mode;</script>
  </head>
  <body id="edit" data-system="$systemId" @{[ $sheetType ? qq|data-sheet-type="$sheetType"| : '' ]}>
    <div id="loading"><div id="loading-animation"></div></div>
    <header>
      <h1>$set::title</h1>
    </header>
    <main>
      <article>
        <form name="sheet" method="post" action="./" enctype="multipart/form-data">
          <input type="hidden" name="ver" value="$::ver">
          <input type="hidden" name="mode" value="@{[ $::in{mode} eq 'edit' ? 'save' : 'make' ]}">
          <input type="hidden" name="type" value="$type">
          @{[ $::isNewSheet ? qq|<input type="hidden" name="_token" value="|.tokenMake().'">' : '' ]}
  HTML
}

### 編集画面の共通終端（form〜html終了） --------------------------------------------------
sub renderEditPageEnd {
  my (%opt) = @_;
  my $notes = $opt{notes} // '';
  my $extraHtml = $opt{extraHtml} // '';
  return <<~"HTML";
          @{[ renderDecorationForm() ]}
          @{[ input 'birthTime','hidden' ]}
          <input type="hidden" name="id" value="$::in{id}">
        </form>
        @{[ renderDeleteForm() ]}
      </article>
      <aside id="text-rule" class="sticky-footer" style="display:none">
        <h2>
          テキスト装飾・整形ルール
          <small>（<a href="./?mode=edit-help@{[ $type ? "&type=$type" : '' ]}" target="_blank">⇒別ウィンドウで開く</a>）</small>
        </h2>
        <i class="close-button" onclick="view('text-rule')"></i>
        <div>
        @{[ renderTextRule() ]}
        </div>
      </aside>
    </main>
    <footer>
      <p class="notes">$notes</p>
      <p class="copyright">©<a href="https://yutorize.work">ゆとらいず工房</a>「ゆとシートⅡ」ver.${main::ver}</p>
    </footer>
    $extraHtml
  </body>
  </html>
  HTML
}

### 編集画面ヘッダメニュー --------------------------------------------------
sub renderEditHeaderMenu {
  my (%opt) = @_;
  my $tabsHtml = $opt{tabsHtml} // '';
  my $logQ = $::in{log} ? "&log=$::in{log}" : '';

  return <<~"HTML";
    <div id="header-menu">
      <h2><span></span></h2>
      <ul class="menu-items">
        $tabsHtml
        <li onclick="sectionSelect('color');" class="color-icon" title="シートデザインカスタム">
        <li onclick="view('text-rule')" class="help-icon" title="テキスト整形ルール">
        <li onclick="toggleNightMode()" class="nightmode-button">
        <li class="buttons">
          <ul>
            <li @{[ display ($::in{mode} eq 'edit') ]} class="view-icon" title="閲覧画面"><a href="./?id=$::in{id}"></a>
            <li onclick="exportAsJson()" class="download-icon" title="JSONデータを保存">
            <li @{[ display ($::in{mode} eq 'edit') ]} class="copy" onclick="window.open('./?mode=copy&id=$::in{id}$logQ');">複製
            <li class="submit" onclick="formSubmit()" title="Ctrl+S">保存
          </ul>
        </li>
      </ul>
      <div id="save-state"></div>
    </div>
  HTML
}

### 編集保護設定ブロック --------------------------------------------------
sub renderProtectBlock {
  my (%opt) = @_;

  my $html = '';

  # 作成・編集をログインユーザーに限定している場合、保護設定欄は非表示でprotect=accountで固定
  if($set::user_reqd){
    $html .= qq|<input type="hidden" name="protect" value="account">\n|;
    $html .= qq|<input type="hidden" name="protectOld" value="$::pc{protect}">\n|;
    $html .= qq|<input type="hidden" name="pass" value="$::in{pass}">\n|;
    return $html;
  }
  # 登録キーの入力欄（設定している場合）
  if($set::registerkey && $::isNewSheet){
    $html .= qq|登録キー：<input type="text" name="registerkey" required>\n|;
  }
  # 通常の表示
  $html .= qq|<details class="box" id="edit-protect" @{[$::in{mode} eq 'edit' ? '' : 'open']}>\n|;
  $html .= qq|<summary>編集保護設定</summary>\n|;
  $html .= qq|<fieldset id="edit-protect-view"><input type="hidden" name="protectOld" value="$::pc{protect}">\n|;

  if($LOGIN_ID){
    $html .= qq|<input type="radio" name="protect" value="account"|.($::pc{protect} eq 'account' ? ' checked' : '').qq|> アカウントに紐付ける（ログイン中のみ編集可能になります）<br>\n|;
  }

  $html .= qq|<input type="radio" name="protect" value="password"|.($::pc{protect} eq 'password' ? ' checked' : '').qq|> パスワードで保護 |;
  if($::in{mode} eq 'edit' && $::pc{protect} eq 'password'){
    $html .= qq|<input type="hidden" name="pass" value="$::in{pass}"><br>\n|;
  }
  else {
    $html .= qq|<input type="password" name="pass"><br>\n|;
  }

  $html .= qq|<input type="radio" name="protect" value="none"|.($::pc{protect} eq 'none' ? ' checked' : '').qq|> 保護しない（誰でも編集できるようになります）\n|;
  $html .= qq|</fieldset>\n|;
  $html .= qq|</details>\n|;

  return $html;
}

### 閲覧可否設定ブロック --------------------------------------------------
sub renderVisibilityBlock {
  return <<~"HTML";
    <dl class="box" id="hide-options">
      <dt>閲覧可否設定
      <dd id="forbidden-checkbox">
        <select name="forbidden">
          <option value="">内容を全て開示
          <option value="battle" @{[ $::pc{forbidden} eq 'battle' ? 'selected' : '' ]}>データ・数値のみ秘匿
          <option value="all"    @{[ $::pc{forbidden} eq 'all'    ? 'selected' : '' ]}>内容を全て秘匿
        </select>
      <dd id="hide-checkbox">
        <select name="hide">
          <option value="">一覧に表示
          <option value="1" @{[ $::pc{hide} ? 'selected' : '' ]}>一覧には非表示
        </select>
      <dd>※「一覧に非表示」でもタグ検索結果・マイリストには表示されます
    </dl>
  HTML
}

### グループ欄 --------------------------------------------------
sub renderGroupOptions {
  my $html;
  foreach (@set::groups){
    my $id   = @$_[0];
    my $name = @$_[2];
    my $exclusive = @$_[4];
    next if($exclusive && (!$LOGIN_ID || $LOGIN_ID !~ /^($exclusive)$/));
    $html .= '<option value="'.$id.'"'.($::pc{group} eq $id ? ' selected': '').'>'.$name.'</option>';
  }
  return $html;
}
### 行テンプレート --------------------------------------------------
sub renderTemplateLoop {
  my ($data, $callback) = @_;
  my ($id, $placeholder, $numKey, $startNum);
  if(ref $data eq 'HASH'){
    $id          = $data->{id};
    $numKey      = $data->{numKey} // undef;
    $placeholder = $data->{placeholder} // undef;
    $startNum    = $data->{startNum} // undef;
  }
  else {
    $id = $data;
  }
  $numKey      //= kebabToCamel($id).'Num';
  $placeholder //= 'TMPL';
  $startNum    //= 1;

  my $html;
  foreach my $num ($placeholder, $startNum .. $::pc{$numKey}) {
    $html .= qq|<template id="$id-template">| if $num eq $placeholder;
    $html .= $callback->($num);
    $html .= '</template>' if $num eq $placeholder;
  }
  return $html;
}
sub renderAddDelButtons {
  my ($id, $arg, $numKey) = @_;
  $numKey //= kebabToCamel($id).'Num';
  my $key = ucfirst(kebabToCamel($id));
  return '<div class="add-del-button">'
    . qq|<a onclick="add$key($arg)">▼</a>|
    . qq|<a onclick="del$key($arg)">▲</a>|
    . '</div>'
    . input($numKey, 'hidden');
}
### 画像欄 --------------------------------------------------
sub renderImageForm {
  my $imageMaxSize = $set::image_maxsize || 0;
  my $imageMaxSizeView = $imageMaxSize >= 1048576 ? sprintf("%.3g",$imageMaxSize/1048576).'MB' : sprintf("%.3g",$imageMaxSize/1024).'KB';
  my $imageMaxCount = $set::image_maxcount || 1;
  $::pc{mainImage} ||= 1;
  my $mainSuffix = imageSuffix($::pc{mainImage});
  my %imageURLs;
  my $imageURLsJS;
  foreach my $n (1 .. $imageMaxCount){
    my $suffix = ($n == 1) ? '' : $n;
    if($::pc{'image'.$suffix}){
      $imageURLs{$n} = "./?id=$::in{id}&mode=image&imageNo=$n&cache=$::pc{'imageUpdate'.$suffix}";
    }
    else {
      $imageURLs{$n} = "";
    }
    $imageURLsJS  .= qq|$n: "$imageURLs{$n}",|;
  }
  my $emptyImageURL = 'data:image/webp;base64,UklGRhgBAABXRUJQVlA4TAwBAAAvY8AYEBK3AdCGzf//5MJWAqx0r7yycNzc9ooFE8BBxtnHwG0jRVk+zOIj9h90eIABiDAr7IeFiTK24obPYciHZ18Bdyuo04LtXSSCdIohUjoFmhlB/CQCxiQjwAJ3hQpeChq11stDUBEdKxnqUi057iYUU0KWBl80RQiUAksAKuIStE6qUEo5QLOLSA5Av/MKXJeQjtFUeyiDFr2UH2EUJc9cFvrgHaGMGqOPc5PHKPN7ggEBj8r7UiWN3YnLd/tLKlkBfh5NvAZ2pIS9q5NaDtFHexmu57gG3P+eoltDoPVL2XW7QYnGOxl+EZGi8RJ3ivqDcPJbGV0m7182Dl2EaaULsEyzqfb/08MC';
  return <<~"HTML";
    <div class="box" id="image" style="max-height:550px;">
      <h2>キャラクター画像</h2>
      <p>
        <a class="button" onclick="imagePositionView();wordsPreView()">画像とセリフの設定</a>
      </p>
    </div>

    <div id="image-custom" style="display:none">
      <div class="image-custom-view-area">
        <div id="image-custom-frame-S" class="image-custom-frame"><div class="image-custom-view"><b>横幅が狭い時</b></div></div>
        <div id="image-custom-frame-O" class="image-custom-frame"><div class="image-custom-view"><b>OGP <small>※シートURLをSNS等に貼った際に表示</small></b></div></div>
        <div id="image-custom-frame-M" class="image-custom-frame"><div class="image-custom-view"><b>標準の比率 <small>※縦横比は適宜変動します</small></b><div class="words" id="words-preview"></div><div id="image-copyright-preview"></div></div>
          @{[ input "editingImagePositionY",'range','imagePosition','step="0.001"' ]}
          @{[ input "editingImagePositionX",'range','imagePosition','step="0.001"' ]}
        </div>
      </div>
      <div class="image-custom-form">
        $set::img_notice
        <h3>画像選択</h3>
        <p>
          プレビューエリアに画像ファイルをドロップ、<br>
          または画像を選択<br>
        </p>
          @{[
            join '', map {
              my $n = $_;
              qq#<div><label>画像@{[$n||1]}: <input type="file" accept="image/*" name="imageFile$n" onchange="imagePreView(this.files[0], $imageMaxSize, $n)"></label></div>#
            } '', 2 .. $imageMaxCount
          ]}
        <p>
          ※ ファイルサイズ @{[ $imageMaxSizeView ]} までの JPG/PNG/GIF/WebP
          <small>（サイズを超過する場合、自動的にWebP形式に変換し、その上でまだ超過している場合は縮小処理が行われます）</small>
        </p>
        <div id="image-select-buttons">
          @{[
            join '', map {
              my $n = $_;
              my $suffix = imageSuffix($n);
              my $selected = ($::pc{mainImage} eq $n) ? 'selected' : '';
              <<~"HTM";
                <div class="image-select-block" data-num="$n">
                  @{[ input "image$suffix",'hidden','','class="image-ext"' ]}
                  @{[ input "imageUpdate$suffix",'hidden' ]}
                  @{[ checkbox "imageDelete$suffix","削除" ]}
                  <label class="image-select" onclick="switchImageLayoutConfig($n)">
                    <span>画像$n</span>
                    <span class="check"></span>
                    <img src="@{[ $imageURLs{$n} || $emptyImageURL ]}" style="width:100px;height:100px;object-fit:contain;" data-num="$n" class="$selected">
                  </label>
                  @{[ radio "mainImage", "checkMainImage($n)", $n, 'メイン画像' ]}
                  @{[ checkbox "imageHide$suffix", '非表示' ]}
                </div>
              HTM
            } 1 .. $imageMaxCount
          ]}
        </div>
        <ul class="annotate">
          <li>画像を複数登録している場合、<b>メイン画像</b>に設定した画像が、シートの最初の表示やOGPに使用されます。<br>
              それ以外の画像は、シート内の切り替えボタンで表示されます。
          <li>画像を<b>非表示</b>に設定した場合、シートの表示やOGPには使用されません。（画像へのアクセス自体は可能です）
        </ul>
        <script>
          const imageType = 'character';
          const imageUpdate = '$::pc{imageUpdate}';
          const savedImageURLs = { $imageURLsJS };
          const emptyImageURL = '$emptyImageURL';
          // ドラッグ＆ドロップで画像アップ
          document.getElementById('image-custom').addEventListener('dragover',function(e){
            e.preventDefault();
          });
          document.getElementById('image-custom').addEventListener('drop',function(e){
            e.preventDefault();
          });
          document.querySelector('.image-custom-view-area').addEventListener('drop', function (e) {
            const imageNo = editingImageNo || Number(form.mainImage?.value || 1);
            const suffix = imageSuffix(imageNo);
            const obj = document.querySelector(`[name='imageFile\${suffix}']`);

            if(!obj){ return; }

            obj.files = e.dataTransfer.files;
            imagePreView(obj.files[0], $imageMaxSize, imageNo);
          });

          // ホイールで拡大率調整
          const mainArea = document.querySelector('#image-custom-frame-M .image-custom-view');
          document.querySelector('.image-custom-view-area').addEventListener('wheel', function (e) {
            e.preventDefault();
          });
          mainArea.addEventListener('wheel', function (e) {
            const obj = form.editingImagePercent;
            if     (e.deltaY > 0){ obj.value = Number(obj.value)+10 }
            else if(e.deltaY < 0){ obj.value = Number(obj.value)-10 }
            if(obj.value < 0){ obj.value = 0 }
            imageDragPointSet();
            imagePosition();
          });

          // ドラッグで位置調整
          let pointWidth  = 1;
          let pointHeight = 1;
          mainArea.addEventListener('mousedown' , function (e) { imageDragStart(e); });
          mainArea.addEventListener('mousemove' , function (e) { imageDragMove(e);  });
          mainArea.addEventListener('mouseup'   , function (e) { imageDragEnd();    });
          mainArea.addEventListener('mouseleave', function (e) { imageDragEnd();    });
          mainArea.addEventListener('touchstart', function (e) { imageDragStart(e); });
          mainArea.addEventListener('touchmove' , function (e) { imageDragMove(e);  });
          mainArea.addEventListener('touchend'  , function (e) { imageDragEnd();    });
        </script>
        <h3>画像レイアウト</h3>
        <p>
          <b>縦基準位置</b>:<input type="number" id="image-positionY" step="0.1" min="0" max="100" onchange="imagePositionNumberToRange()">%<br>
          <b>横基準位置</b>:<input type="number" id="image-positionX" step="0.1" min="0" max="100" onchange="imagePositionNumberToRange()">%<br>
        </p>
        <p>
          <b>表示（トリミング）方式</b>：<br><select name="editingImageFit" oninput="imageDragPointSet();imagePosition()">
          <option value="cover"    @{[$::pc{editingImageFit} eq 'cover'   ?'selected':'']}>自動的に最低限のトリミング（表示域いっぱいに表示）
          <option value="contain"  @{[$::pc{editingImageFit} eq 'contain' ?'selected':'']}>トリミングしない（必ず画像全体を収める）
          <option value="percentX" @{[$::pc{editingImageFit} eq 'percentX'?'selected':'']}>任意のトリミング／横幅を基準
          <option value="percentY" @{[$::pc{editingImageFit} eq 'percentY'?'selected':'']}>任意のトリミング／縦幅を基準
          <option value="unset"    @{[$::pc{editingImageFit} eq 'unset'   ?'selected':'']}>拡大縮小せず表示（ドット絵など向き）
          </select><br>
          <small>※いずれの設定でも、クリックすると画像全体が表示されます。</small>
        </p>
        <p id="image-percent-config">
          <b>拡大率</b>：@{[ input "editingImagePercent",'number','imageDragPointSet();imagePosition','min="0"  style="width:4em;"' ]}%<br>
          <input type="range" id="image-percent-bar" min="10" max="1000" oninput="imagePercentBarChange(this.value)" style="width:100%;"><br>
          （100%で幅ピッタリ）<br>
        </p>
        <h3>画像の注釈</h3>
        <p>
          <b>作者名や権利表示：</b><br>
          @{[ input 'editingImageCopyright','text ','wordsPreView','placeholder="(C)画像の作者名" style="width:70%;"' ]}<br>
        </p>
        <p>
          <b>URL（作者のWebサイトなどあれば）：</b><br>
          @{[ input 'editingImageCopyrightURL','url ','wordsPreView','placeholder="https://..." style="width:90%;"' ]}<br>
        </p>
        <h3>画像に重ねるセリフ</h3>
        <p>
          <textarea name="editingWords" style="width:100%;height:3.6em;" onchange="wordsPreView();" placeholder="「任意の台詞」">$::pc{words}</textarea>
        </p>
        <p>
          <b>セリフの配置</b>：
          <select name="editingWordsX" oninput="wordsPreView();">@{[ option 'editingWordsX','右','左' ]}</select>
          <select name="editingWordsY" oninput="wordsPreView();">@{[ option 'editingWordsY','上','下' ]}</select>
        </p>
      </div>
      <div class="image-custom-form close-button">
        <a class="button" onclick="imagePositionClose()">画像とセリフの設定を閉じる</a>
      </div>
      @{[
        join '', map {
          my $n = $_;
          input("imageFit$n",'hidden')
          . input("imagePercent$n",'hidden')
          . input("imagePositionX$n",'hidden')
          . input("imagePositionY$n",'hidden')
          . input("imageCopyright$n",'hidden')
          . input("imageCopyrightURL$n",'hidden')
          . input("words$n",'hidden')
          . input("wordsX$n",'hidden')
          . input("wordsY$n",'hidden')
        } '',2 .. $imageMaxCount
      ]}
    </div>
  HTML
}

### チャットパレット --------------------------------------------------
sub renderChatPaletteForm {
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

  $::pc{unitStatusNum} ||= 3;
  my $status;
  foreach ('TMPL',1..$::pc{unitStatusNum}) {
    $status .= '<tr id="unit-status'.$_.'">';
    $status .= '<td class="handle">';
    $status .= '<td>'.input("unitStatus${_}Label",'','','placeholder="ラベル"');
    $status .= '<td>'.input("unitStatus${_}Value",'','','placeholder="値"');
    $status = '<template id="unit-status-template">'.$status.'</template>' if $_ eq 'TMPL';
  }

  return <<~"HTML";
    <section id="section-palette" style="display:none;">
      <div class="box" id="unit-setting">
        <h2>ユニット(コマ)の設定</h2>
        <div class="annotate">各オンラインセッションツールに出力するユニット(コマ)に反映されます。</div>
        <dl>
          <dt>表示名
          <dd>@{[ input 'namePlate','','changeNamePlate','placeholder="ニックネーム、ファーストネームなど"' ]} <small>※コマ出力時、こちらの入力が名前として優先されます。名前が長いキャラなどに</small>
          <dt>発言者色
          <dd>@{[ input 'nameColor','','changeNamePlate' ]} <small>※#から始まる6桁のカラーコードで記入してください。</small>
            <div id="name-plate-view">表示例：
              <span class="ytcha"></span> ／
              <span class="tekey"></span> ／
              <span class="ccfol"></span> ／
              <span class="udona"></span>
            </div>
          <dt>ステータス<br>
          <dd>
            @{[ input 'unitStatusNotOutput','hidden' ]}
            @{[ input 'unitStatusNum','hidden' ]}
            <table id="unit-status">
              <tbody id="unit-status-default" class="highlight-hovered-row">
              <tbody id="unit-status-optional">$status
              <tfoot><tr><td colspan="3" class="add-del-button"><a onclick="addUnitStatus()">▼</a><a onclick="delUnitStatus()">▲</a></div>
            </table>
            <ul class="annotate">
              <li>デフォルトのステータス出力の他に、任意で項目を追加できます。<br>
                また、使わないステータスを出力しないことも選択できます。
              <li>最大値が必要な場合は <code>100/100</code> のように記入してください。
              <li>ツールによっては値に数値しか許容されないため、注意してください。
            </ul>
        </dl>
      </div>
      <div class="box-union">
        <div class="box" id="chatpalette">
          <h2>チャットパレット</h2>
          <div class="annotate">
            ユニット(コマ)のチャットパレットに、ここで設定・入力した内容が自動的に反映されます。<br>
            何も設定しない場合、デフォルト設定のプリセットの内容が反映されます。
          </div>
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
              <small>※デフォルトだと、未使用の変数は出力されません</small>
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
              <dd class="left">
                @{[ radios 'paletteTool','setChatPalette',@{$opt{tool}} ]}<br>
                <small>※プリセットの内容がツールに合わせたものに切り替わります。<br>　なお、コマ出力の際にはここでの変更に関わらず、自動的に出力先のツールに合わせたものになります。</small>
            </dl>
          </div>
        </div>
        @{[ renderChatPaletteFormOptional() ]}
        <div class="box" id="chatpalette-description">
          <h2>チャットパレットとは？</h2>
          <p>
            「チャットパレット」は、現行の多くのオンラインセッションツールに搭載されている、特定のメッセージやコマンドを簡単に入力できるようにするための機能です。<br>
            　セッション中に頻繁に使用するテキストやダイスコマンド、スキルの使用やキャラクターの行動宣言などを事前に登録しておき、クリック／ダブルクリックで即座にチャット欄に呼び出す／送信することができます。<br>
          </p>
          <p>
            　UIや細かな挙動はツールごとに異なりますが、行単位で区切られるのと、<code>//変数名=値</code><code>{変数名}</code>の記述を用いる変数機能があることは共通しています。<br>
          </p>
        </div>
      </div>
    </section>
  HTML
  sub renderChatPaletteFormOptional {}
}


### シート装飾欄 --------------------------------------------------
sub renderDecorationForm {
  return <<~"HTML";
    <section id="section-color" style="display:none;">
      <h2>シートの装飾設定</h2>
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
        <div class="box font-custom">
          <h2>名称欄のフォント</h2>
          <fieldset>
            <label class="check-button"><input type="radio" name="nameFont" value=""@{[ $::pc{nameFont} eq '' ? ' checked':''] } oninput="changeNameFont()"><span>フォント：<small>デフォルト</small></span></label>
            @{[ renderFontCustomForm() ]}
          </fieldset>
          $set::test
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
## フォントカスタム欄
sub renderFontCustomForm {
  my $html;
  my $i = 1;
  foreach (@set::googlefonts) {
    $html .= '<label class="check-button"><input type="radio" name="nameFont" value="'.$_->[0].'"'.($::pc{nameFont} eq $_->[0] ? ' checked':'').' oninput="changeNameFont()"><span style="font-family:'."'$_->[0]'".';font-weight:'.$_->[1].';">フォント：<small>'.$_->[0].'</small></span></label>';
    $i++;
  }
  return $html.'<script>const fontList = '.JSON::PP->new->encode(\@set::googlefonts).';</script>';
}

### 削除フォーム --------------------------------------------------
sub renderDeleteForm {
  return if ($mode ne 'edit');

  my $html = <<~"HTML";
    <form name="del" method="post" action="./" class="deleteform">
      <fieldset style="font-size: 80%;">
        <input type="hidden" name="mode" value="delete">
        <input type="hidden" name="type" value="$::pc{type}">
        <input type="hidden" name="id"   value="$::in{id}">
        <input type="hidden" name="pass" value="$::in{pass}">
        <input type="checkbox" name="check1" value="1" required>
        <input type="checkbox" name="check2" value="1" required>
        <input type="checkbox" name="check3" value="1" required>
        <input type="submit" value="シート削除"><br>
        ※チェックを全て入れてください
      </fieldset>
    </form>
  HTML
  # 管理者用画像削除フォーム
  if($LOGIN_ID eq $set::masterid){
    $html .= <<~"HTML";
      <form name="imgdel" method="post" action="./" class="deleteform">
        <fieldset style="font-size: 80%;">
          <input type="hidden" name="mode" value="img-delete">
          <input type="hidden" name="type" value="$::pc{type}">
          <input type="hidden" name="id"   value="$::in{id}">
          <input type="hidden" name="pass" value="$::in{pass}">
          <input type="checkbox" name="check1" value="1" required>
          <input type="checkbox" name="check2" value="1" required>
          <input type="checkbox" name="check3" value="1" required>
          <input type="submit" value="画像削除">
        </fieldset>
      </form>
      <p class="right">@{[ $::in{log}?$::in{log}:'最終' ]}更新時のIP:$::pc{IP}</p>
    HTML
  }
  return $html;
}

1;
