/* MIT License

Copyright 2020 @Shunshun94

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
var output = output || {};
var io = io || {};
io.github = io.github || {};
io.github.shunshun94 = io.github.shunshun94 || {};
io.github.shunshun94.trpg = io.github.shunshun94.trpg || {};
io.github.shunshun94.trpg.ytsheet = io.github.shunshun94.trpg.ytsheet || {};

io.github.shunshun94.trpg.ytsheet.generateCharacterTextFromYtSheet2VisionConnectPC = (json) => {
	const result = [];
  result.push(`キャラクター名：${json.characterName}

種族　　：${json.race}
クラス　：${json.class}
スタイル：${json.style1}／${json.style2}

ＨＰ　　：${json.hpMax}
スタミナ：${json.staminaMax}

■能力値■
バイタリティ：${json.vitality}
テクニック　：${json.technic}
クレバー　　：${json.clever}
カリスマ　　：${json.carisma}

■特技■
${json.speciality1Name || ''} / ${json.speciality1Note || ''}
${json.speciality2Name || ''} / ${json.speciality2Note || ''}
`);
	result.push('■グッズ■');
	result.push(io.github.shunshun94.trpg.ytsheet._convertList(output.GetGoods(json), output.consts.GOODS_COLUMNS, ' / '));
	result.push('');
	result.push('■アイテム■');
	result.push(io.github.shunshun94.trpg.ytsheet._convertList(output.getItems(json), output.consts.GOODS_COLUMNS, ' / '));
	result.push('');
	result.push('■戦闘値■');
	result.push(io.github.shunshun94.trpg.ytsheet._convertList(output.getBattles(json), output.consts.BATTLE_COLUMNS, ' | '));
	result.push('\n');
	result.push('■メモ■');
  result.push((json.freeNote || '').replace(/&lt;br&gt;/gm, '\n').replace(/&quot;/gm, '"'));
	result.push('\n');
	result.push('■履歴■');
  result.push((json.freeHistory || '').replace(/&lt;br&gt;/gm, '\n').replace(/&quot;/gm, '"'));

	return result.join('\n');
};

output.GetGoods = (json) => {
  let number = 1;
  const data = [];
  for(let cursor = 1; cursor <= json.goodsNum; cursor++) {
    if(json[`goods${cursor}Name`] || json[`goods${cursor}Type`] || json[`goods${cursor}Note`]){
      data.push({
        name: json[`goods${cursor}Name`] || '',
        type: json[`goods${cursor}Type`] || '',
        note: json[`goods${cursor}Note`] || '',
      });
      number++;
    }
  }
  return data;
};

output.getItems = (json) => {
  const data = [];
  for(let cursor = 1; cursor <= json.goodsNum; cursor++) {
    if(json[`item${cursor}Name`] || json[`item${cursor}Type`] || json[`item${cursor}Lv`] || json[`item${cursor}Note`]){
      data.push({
        name: json[`item${cursor}Name`] || '',
        type: json[`item${cursor}Type`] || '',
        lv  : json[`item${cursor}Lv`] || '',
        note: json[`item${cursor}Note`] || '',
      });
    }
  }
  return data;
};

output.getBattles = (json) => {
  const data = [];
  const list = {
    'Base':'基本戦闘値',
    'Race':'種族特性：'+(json.battleRaceName || ''),
    'Subtotal':'小計',
    'Weapon':'武器：'+(json.battleWeaponName || ''),
    'Head':'頭防具：'+(json.battleHeadName   || ''),
    'Body':'胴防具：'+(json.battleBodyName   || ''),
    'Acc1':'装飾品：'+(json.battleAcc1Name   || ''),
    'Acc2':'装飾品：'+(json.battleAcc2Name   || ''),
    'Other':'その他修正',
    'Total':'合計',
  }
  for(let cursor in list) {
    if(cursor === 'Subtotal' || cursor === 'Weapon' || cursor === 'Total'){
      data.push('-');
    }
    data.push({
      name: list[cursor],
      acc : json[`battle${cursor}Acc`] || '',
      spl : json[`battle${cursor}Spl`] || '',
      eva : json[`battle${cursor}Eva`] || '',
      atk : json[`battle${cursor}Atk`] || '',
      det : json[`battle${cursor}Det`] || '',
      def : json[`battle${cursor}Def`] || '',
      mdf : json[`battle${cursor}Mdf`] || '',
      ini : json[`battle${cursor}Ini`] || '',
      str : json[`battle${cursor}Str`] || '',
    });
  }
  return data;
};
