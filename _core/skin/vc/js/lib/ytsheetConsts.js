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
output.consts = {};

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