"use strict";

var output = output || {};

output.generateUdonariumXmlDetailOfArianrhod2PC = (json, opt_url, defaultPalette, resources)=>{
	const dataDetails = {'リソース':resources};
	
	dataDetails['リソース'].push(
    `        <data name="フェイト使用上限">${json.fateLimit || 0}</data>`,
		`        <data name="所持金">${json.moneyTotal}</data>`,
	);
	dataDetails['情報'] = [
    `        <data name="PL">${json.playerName || '?'}</data>`,
    `        <data name="年齢">${json.age || ''}</data>`,
    `        <data name="性別">${json.gender || ''}</data>`,
    `        <data name="種族">${json.race || ''}</data>`,
    `        <data name="レベル">${json.level || ''}</data>`,
    `        <data name="メインクラス">${json.classMain || ''}</data>`,
    `        <data name="サポートクラス">${json.classSupport || ''}</data>`,
    `        <data name="称号クラス">${json.classTitle || ''}</data>`,
    `        <data type="note" name="説明">${(json.freeNote || '').replace(/&lt;br&gt;/g, '\n')}</data>`
	];
	if(opt_url) { dataDetails['情報'].push(`        <data name="URL">${opt_url}</data>`);}

	let addedParam = {};
	dataDetails['能力値'] = output.consts.AR2_STATUS.map((s)=>{
		addedParam[s.name] = 1;
		return `        <data name="${s.name}">${json['roll' + s.column]}</data>`
	});
	dataDetails['戦闘'] = [
    `        <data name="命中">{器用}+${json.battleAddAcc || 0}</data>`,
    `        <data name="命中ダイス">${json.battleDiceAcc || 0}</data>`,
    `        <data name="攻撃力">${json.battleTotalAtk || 0}</data>`,
    `        <data name="攻撃ダイス">${json.battleDiceAtk || 0}</data>`,
    `        <data name="回避">{敏捷}+${json.battleAddEva || 0}</data>`,
    `        <data name="回避ダイス">${json.battleDiceEva || 0}</data>`,
		`        <data name="物理防御力">${json.battleTotalDef || 0}</data>`,
		`        <data name="魔法防御力">${json.battleTotalMDef || 0}</data>`,
		`        <data name="行動値">${json.battleTotalIni || 0}</data>`,
		`        <data name="移動力">${json.battleTotalMove || 0}</data>`
	];
	addedParam['命中'] = addedParam['命中ダイス'] = addedParam['攻撃力'] = addedParam['攻撃ダイス'] = addedParam['回避'] = addedParam['回避ダイス'] = addedParam['物理防御力'] = addedParam['魔法防御力'] = addedParam['行動値'] = addedParam['移動力'] = 1;

	dataDetails['バフ・デバフ'] = defaultPalette.parameters.map((param)=>{
		if(addedParam[param.label]){ return `` }
		return `        <data type="numberResource" currentValue="${param.value}" name="${param.label}">${param.value < 10 ? 10 : param.value}</data>`; 
	});


	return dataDetails
};
