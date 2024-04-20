"use strict";

var output = output || {};
output.consts = output.consts || {};

output.consts.dicebot = 'VisionConnect';

output.consts.GOODS_COLUMNS = {
	name : '名称',
	type : '種別',
	note : '効果',
};

output.consts.ITEMS_COLUMNS = {
	name : '名称',
	type : '種別',
	lv   : 'レベル',
	note : '効果',
};

output.consts.BATTLE_COLUMNS = {
	name : '名称',
	acc : '命中',
	spl : '詠唱',
	eva : '回避',
	atk : '攻撃',
	det : '意志',
	def : '物防',
	mdf : '魔防',
	ini : '行動',
	str : '耐久',
};

output.consts.VC_PARAMS = [
  { name: 'バイタリティ', value: 'vitality' },
  { name: 'テクニック'  , value: 'technic' },
  { name: 'クレバー'    , value: 'clever' },
  { name: 'カリスマ'    , value: 'carisma' },
  { name: '命中値',       value: 'battleTotalAcc' },
  { name: '詠唱値',       value: 'battleTotalSpl' },
  { name: '回避値',       value: 'battleTotalEva' },
  { name: '攻撃値',       value: 'battleTotalAtk' },
  { name: '意志値',       value: 'battleTotalDet' },
  { name: '物防値',       value: 'battleTotalDef' },
  { name: '魔防値',       value: 'battleTotalMdf' },
  { name: '行動値',       value: 'battleTotalIni' },
  { name: '耐久値',       value: 'battleTotalStr' },
];