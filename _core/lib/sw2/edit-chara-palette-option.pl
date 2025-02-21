use strict;
use utf8;
use open ":utf8";

package palette;

sub chatPaletteFormOptional {
    my %pc = %{shift;};

    require($::core_dir . '/lib/edit.pl');

    $::pc{chatPaletteInsertNum} = ($pc{chatPaletteInsertNum} ||= 2);
    $::pc{paletteAttackNum} = ($pc{paletteAttackNum} ||= 3);
    $::pc{paletteMagicNum} = ($pc{paletteMagicNum} ||= 3);
    my $html = <<"HTML";
<div class="box" id="palette-optional">
    <h2>プリセットの追加オプション</h2>
    <div id="palette-common-classes">
        <h3>一般技能の判定の出力設定</h3>
        <p>その行の技能のレベルと、選択したボーナスの組み合わせが追加されます</p>
        <table class="edit-table side-margin">
            <tbody class="highlight-hovered-row">
HTML
    foreach ('TMPL',1 .. $pc{commonClassNum}){
        $html .= '<template id="palette-common-class-template">' if $_ eq 'TMPL';
        $html .= '<tr id="palette-common-class-row'.$_.'"><td class="name">'.($pc{"commonClass$_"} =~ s/[(（].+?[）)]$//r).'</td>';
        $html .= '<td class="left">';
        $html .= ::checkbox("paletteCommonClass${_}Dex", '器用度B', 'setChatPalette');
        $html .= ::checkbox("paletteCommonClass${_}Agi", '敏捷度B', 'setChatPalette');
        $html .= ::checkbox("paletteCommonClass${_}Str", '筋力B'  , 'setChatPalette');
        $html .= ::checkbox("paletteCommonClass${_}Vit", '生命力B', 'setChatPalette');
        $html .= ::checkbox("paletteCommonClass${_}Int", '知力B'  , 'setChatPalette');
        $html .= ::checkbox("paletteCommonClass${_}Mnd", '精神力B', 'setChatPalette');
        $html .= '</template>' if $_ eq 'TMPL';
    }
    $html .= <<"HTML";
          </table>
        </div>
        <details id="palette-insert" @{[ $pc{chatPaletteInsert1} ? 'open' : '' ]}>
          <summary class="header2">追加挿入</summary>
          <ul>
HTML
    foreach ('TMPL',1 .. $pc{chatPaletteInsertNum}){
        $html .= '<template id="palette-insert-template">' if $_ eq 'TMPL';
        $html .= "<li>"
            . ::selectBox("chatPaletteInsert${_}Position", 'setChatPalette', 'def=|<先頭>','general|<非戦闘系の直後>','common|<一般技能の直後>','feats|<宣言特技の直後>','magic|<魔法系の直後>','attack|<武器攻撃系の直後>','defense|<抵抗回避の直後>')
            . "に挿入"
            . "<textarea name=\"chatPaletteInsert${_}\" onchange=\"setChatPalette()\">$pc{'chatPaletteInsert'.$_}</textarea>";
        $html .= '</template>' if $_ eq 'TMPL';
    }
    $html .= <<"HTML";
          </ul>
          <div class="add-del-button"><a onclick="addChatPaletteInsert()">▼</a><a onclick="delChatPaletteInsert()">▲</a></div>
          @{[ ::input "chatPaletteInsertNum","hidden" ]}
        </details>
        <details id="palette-attack" @{[ $pc{"paletteAttack1Name"} ? 'open' : '' ]}>
          <summary class="header2">武器攻撃の追加オプション</summary>
          <p>宣言特技などの名称と修正を入力すると、それにもとづいた命中判定および威力算出の行が追加されます。</p>
          <table class="edit-table side-margin">
            <thead>
              <tr>
                <th>
                <th class="name  ">名称（宣言特技名など）
                <th class="acc   ">命中修正
                <th class="crit  ">C値修正
                <th class="dmg   "><span class="small">ダメージ<br>修正</span>
                <th class="roll  ">出目修正
                <th class="target">対象の武器
            <tbody class="highlight-hovered-row">
HTML
    foreach ('TMPL',1 .. $pc{paletteAttackNum}){
        $html .= '<template id="palette-attack-template">' if $_ eq 'TMPL';
        $html .= '<tr id="palette-attack-row'.$_.'">';
        $html .= '<td class="handle">';
        $html .= '<td>'.::input("paletteAttack${_}Name",'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteAttack${_}Acc" ,'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteAttack${_}Crit",'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteAttack${_}Dmg" ,'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteAttack${_}Roll",'','','onchange="setChatPalette()"');
        $html .= '<td class="palette-attack-checklist left">';
        my %added;
        foreach my $num (1 .. $pc{weaponNum}) {
            my $name = $pc{"weapon${num}Name"}.$pc{"weapon${num}Usage"} || '―';
            next if $added{$name};
            $html .= ::checkbox("paletteAttack${_}CheckWeapon${num}",$name,'setChatPalette');
            $added{$name} = 1;
        }
        $html .= '</template>' if $_ eq 'TMPL';
    }
    $html .= <<"HTML";
          </table>
          <div class="add-del-button"><a onclick="addPaletteAttack()">▼</a><a onclick="delPaletteAttack()">▲</a></div>
          @{[ ::input "paletteAttackNum","hidden" ]}
        </details>
        <details id="palette-magic" @{[ $pc{"paletteMagic1Name"} ? 'open' : '' ]}>
          <summary class="header2">魔法の追加オプション</summary>
          <p>宣言特技などの名称と修正を入力すると、それにもとづいた、行使判定および威力算出の行が追加されます。</p>
          <table class="edit-table side-margin">
            <thead>
              <tr>
                <th>
                <th class="name ">名称（宣言特技名など）
                <th class="power">魔力修正
                <th class="cast ">行使修正
                <th class="rate ">威力修正
                <th class="crit ">C値修正
                <th class="dmg  "><span class="small">ダメージ<br>修正</span>
                <th class="roll ">出目修正
                <th class="target">対象の魔法
            <tbody class="highlight-hovered-row">
HTML
    foreach ('TMPL',1 .. $pc{paletteMagicNum}){
        $html .= '<template id="palette-magic-template">' if $_ eq 'TMPL';
        $html .= '<tr id="palette-magic-row'.$_.'">';
        $html .= '<td class="handle">';
        $html .= '<td>'.::input("paletteMagic${_}Name" ,'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteMagic${_}Power",'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteMagic${_}Cast" ,'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteMagic${_}Rate" ,'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteMagic${_}Crit" ,'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteMagic${_}Dmg"  ,'','','onchange="setChatPalette()"');
        $html .= '<td>'.::input("paletteMagic${_}Roll" ,'','','onchange="setChatPalette()"');
        $html .= '<td class="palette-magic-checklist left">';
        foreach my $name (@data::class_caster){
            next if (!$data::class{$name}{magic}{jName});
            my $id    = $data::class{$name}{id};
            $html .= ::checkbox("paletteMagic${_}Check$id",$data::class{$name}{magic}{jName},'setChatPalette');
        }
        $html .= '</template>' if $_ eq 'TMPL';
    }
    $html .= <<"HTML";
          </table>
          <div class="add-del-button"><a onclick="addPaletteMagic()">▼</a><a onclick="delPaletteMagic()">▲</a></div>
          @{[ ::input "paletteMagicNum","hidden" ]}
        </details>
      </div>
HTML
}

1;
