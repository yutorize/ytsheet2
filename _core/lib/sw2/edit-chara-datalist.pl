use strict;
use utf8;
use open ":utf8";

sub printCharaDataList {
  print <<"HTML";
  <datalist id="list-gender">
    <option value="男">
    <option value="女">
    <option value="その他">
    <option value="なし">
    <option value="不明">
    <option value="不詳">
  </datalist>
  <datalist id="list-weapon-name">
    <option value="〈〉">
    <option value="〈〉[刃]">
    <option value="〈〉[打]">
    <option value="〈〉[刃][打]">
    <option value="[魔]〈〉">
    <option value="[魔]〈〉[刃]">
    <option value="[魔]〈〉[打]">
    <option value="[魔]〈〉[刃][打]">
  </datalist>
  <datalist id="list-item-name">
    <option value="〈〉">
    <option value="[魔]〈〉">
  </datalist>
  <datalist id="list-usage">
    <option value="1H">
    <option value="1H#">
    <option value="1H投">
    <option value="1H拳">
    <option value="1H両">
    <option value="1H騎">
    <option value="2H">
    <option value="2H#">
    <option value="振2H">
    <option value="突2H">
  </datalist>
  <datalist id="list-honor-item">
    <option value="〈〉">
    <option value="【】">
    <option value="《》">
  </datalist>
  <datalist id="list-grow">
    <option value="器用">
    <option value="敏捷">
    <option value="筋力">
    <option value="生命">
    <option value="知力">
    <option value="精神">
  </datalist>
  <datalist id="list-language">
    <option value="交易共通語">
    <option value="地方語（）">
    <option value="神紀文明語">
    <option value="魔法文明語">
    <option value="魔動機文明語">
    <option value="エルフ語">
    <option value="ドワーフ語">
    <option value="グラスランナー語">
    <option value="シャドウ語">
    <option value="ソレイユ語">
    <option value="ミアキス語">
    <option value="リカント語">
    <option value="ドラゴン語">
    <option value="妖精語">
    <option value="海獣語">
    <option value="ヴァルグ語">
    <option value="汎用蛮族語">
    <option value="妖魔語">
    <option value="巨人語">
    <option value="ドレイク語">
    <option value="バジリスク語">
    <option value="ノスフェラトゥ語">
    <option value="マーマン語">
    <option value="ケンタウロス語">
    <option value="ライカンスロープ語">
    <option value="リザードマン語">
    <option value="ハルピュイア語">
    <option value="バルカン語">
    <option value="翼人語">
    <option value="魔神語">
  </datalist>
HTML
}

1;
