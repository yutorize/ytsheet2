"use strict";
const gameSystem = 'ar2e';

window.onload = function() {
  nameSet();
  level = Number(form.level.value);
  race = form.race.value;
  classMainLv1    = form.classMainLv1.value;
  classSupportLv1 = form.classSupportLv1.value;
  [...Array(Number(form.level.value-1))].map((_, i) => checkGrow(i+2));
  checkLv();
  checkRace();
  checkClass();
  calcSkills();
  calcLvUpSkills();
  calcBattle();
  calcWeight();
  calcCash();
  changeHandedness();
  imagePosition();
  changeColor();
  
  palettePresetChange();
};

// 送信前チェック ----------------------------------------
function formCheck(){
  if(form.characterName.value === '' && form.aka.value === ''){
    alert('キャラクター名か二つ名のいずれかを入力してください。');
    form.characterName.focus();
    return false;
  }
  if(form.protect.value === 'password' && form.pass.value === ''){
    alert('パスワードが入力されていません。');
    form.pass.focus();
    return false;
  }
}

// レギュレーション ----------------------------------------
function changeRegu(){
  document.getElementById("history0-exp").innerHTML = form.history0Exp.value;
  document.getElementById("history0-money").innerHTML = form.history0Money.value;
}


// レベル変更 ----------------------------------------
let level = 1;
function changeLv() {
  const newLevel = Number(form.level.value);
  if(newLevel <= 0){
    alert('キャラクターレベルを0以下にはできません');
    form.level.value = level;
    return;
  }
  if(newLevel - level > 0){
    for(let i = level+1; i <= newLevel; i++){ addLvUp(i); }
  }
  else if(newLevel - level < 0) {
    for(let i = level; i > newLevel; i--){ delLvUp(i); }
  }
  level = newLevel;
  checkLv();
  checkClass();
  calcStt();
}
// 追加
function addLvUp(num){
  const classesOption = (num >= 20) ? lvupClasses20 : (num >= 15) ? lvupClasses15 : (num >= 10) ? lvupClasses10 : lvupClasses1;
  let line = document.createElement('tr');
  line.setAttribute('id',idNumSet('lvup'));
  line.innerHTML = `
    <th>${num}</th>
    <td><input type="checkbox" name="lvUp${num}SttStr" onchange="checkGrow(${num})" value="1"></td>
    <td><input type="checkbox" name="lvUp${num}SttDex" onchange="checkGrow(${num})" value="1"></td>
    <td><input type="checkbox" name="lvUp${num}SttAgi" onchange="checkGrow(${num})" value="1"></td>
    <td><input type="checkbox" name="lvUp${num}SttInt" onchange="checkGrow(${num})" value="1"></td>
    <td><input type="checkbox" name="lvUp${num}SttSen" onchange="checkGrow(${num})" value="1"></td>
    <td><input type="checkbox" name="lvUp${num}SttMnd" onchange="checkGrow(${num})" value="1"></td>
    <td><input type="checkbox" name="lvUp${num}SttLuk" onchange="checkGrow(${num})" value="1"></td>
    <td class="select-or-input">
      <select name="lvUp${num}Class" onchange="changeClass();calcLvUpSkills();">${classesOption}</select>
      <input type="text" name="lvUp${num}ClassFree" onchange="changeClass()">
    </td>
    <td class="skill"><input type="text" name="lvUp${num}Skill1" oninput="calcLvUpSkills()"></td>
    <td class="skill"><input type="text" name="lvUp${num}Skill2" oninput="calcLvUpSkills()"></td>
    <td class="skill"><input type="text" name="lvUp${num}Skill3" oninput="calcLvUpSkills()"></td>
  `;
  document.querySelector("#levelup-lines").prepend(line);
  
}
// 削除
function delLvUp(num){
  if(
    form[`lvUp${num}SttStr`].checked || 
    form[`lvUp${num}SttDex`].checked || 
    form[`lvUp${num}SttAgi`].checked || 
    form[`lvUp${num}SttInt`].checked || 
    form[`lvUp${num}SttSen`].checked || 
    form[`lvUp${num}SttMnd`].checked || 
    form[`lvUp${num}SttLuk`].checked || 
    form[`lvUp${num}Class`].value
  ){
    if (!confirm(delConfirmText)) return false;
  }
  document.getElementById("lvup"+num).remove();
}

// レベルチェック ----------------------------------------
function checkLv() {
  expUse['level'] = 0;
  for(let lv = 2; lv <= level; lv++){
    expUse['level'] += (lv - 1) * 10;
  }
  document.getElementById('exp-used-level').innerHTML = expUse['level'];
  calcExp();
}

// 種族変更 ----------------------------------------
let race;
function changeRace(){
  race = form.race.value;
  
  checkRace();
  calcStt();
}
// 種族チェック ----------------------------------------
function checkRace(){
  document.getElementById('race').classList.toggle('free', form.race.value === 'free');
  sttNames.forEach(s => {
    if(races[race] && races[race]['stt'][s]){
      form[`stt${s}Race`].value = races[race]['stt'][s];
      form[`stt${s}Race`].readOnly = true;
    }
    else if(race){
      form[`stt${s}Race`].readOnly = false;
    }
    else {
      form[`stt${s}Race`].value = '';
      form[`stt${s}Race`].readOnly = true;
    }
  });
  //アーシアン専用ライフパス
  document.getElementById('lifepath-earthian').style.display = race === 'アーシアン' ? '' : 'none';
  const eLifepath = (race === 'アーシアン' && form.lifepathEarthian.checked) ? 1 : 0;
  document.querySelector(`#lifepath-origin th`    ).innerHTML = eLifepath ? '特異' : '出自';
  document.querySelector(`#lifepath-experience th`).innerHTML = eLifepath ? '転移' : '境遇';
}

// クラス変更 ----------------------------------------
let classMain;
let classMainLv1;
let classSupport;
let classSupportLv1;
let classTitle;
function changeClass(type){
  classMainLv1 = form.classMainLv1.value;
  classSupportLv1 = form.classSupportLv1.value;

  checkClass();
  calcStt();
}
// クラスチェック ----------------------------------------
let hpGrow = 0;
let mpGrow = 0;
function checkClass(){
  classMain = classMainLv1;
  classSupport = classSupportLv1;
  classTitle = '';
  hpGrow = 0;
  mpGrow = 0;
  if(classSupport === 'free'){
    classSupport = form.classSupportLv1Free.value || ' ';
  }
  document.getElementById('lvup1-class').innerHTML = classMain+'<hr>'+classSupport;
  let experienced = [classMain,classSupport];
  for(let lv = 2; lv <= level; lv++){
    const name = form[`lvUp${lv}Class`].value;
    if     (classes[name] && classes[name]['base']){
      classMain = name;
      experienced.push(classMain);
    }
    else if(classes[name]){
      classSupport = name;
      experienced.push(classSupport);
    }
    else if(name === 'free'){
      classSupport = form[`lvUp${lv}ClassFree`].value || ' ';
      experienced.push(classSupport);
    }
    else if(name === 'title'){
      classTitle = form[`lvUp${lv}ClassFree`].value || ' ';
      experienced.push(classTitle);
    }

    if(classes[classMain]){
      hpGrow += classes[classMain]['stt']['HpGrow'];
      mpGrow += classes[classMain]['stt']['MpGrow'];
    }

    form[`lvUp${lv}Class`].parentNode.classList.toggle('free', name.match(/^(free|title)$/));
  }
  document.getElementById('class-main-value'   ).innerHTML = classMain;
  document.getElementById('class-support-value').innerHTML = classSupport;
  document.getElementById('class-title-value'  ).innerHTML = classTitle;
  document.getElementById('hp-grow').innerHTML = hpGrow;
  document.getElementById('mp-grow').innerHTML = mpGrow;

  document.getElementById('class-support-lv1').classList.toggle('free', form.classSupportLv1.value === 'free');

  // クラス修正
  sttNames.forEach(s => {
    if(classes[classMain]){
      if(classes[classMain]['type'] === 'fate'){
        form[`stt${s}Main`].readOnly = false;
      }
      else {
        form[`stt${s}Main`].value    = classes[classMain]['stt'][s] || '';
        form[`stt${s}Main`].readOnly = true;
      }
    }
    else if(classMain) {
      form[`stt${s}Main`].readOnly = false;
    }
    else {
      form[`stt${s}Main`].value    = '';
      form[`stt${s}Main`].readOnly = true;
    }
    if(classes[classSupport]){
      form[`stt${s}Support`].value    = classes[classSupport]['stt'][s] || '';
      form[`stt${s}Support`].readOnly = true;
    }
    else if(classSupport) {
      form[`stt${s}Support`].readOnly = false;
    }
    else {
      form[`stt${s}Support`].value    = '';
      form[`stt${s}Support`].readOnly = true;
    }
  });
  // 初期クラス修正
  if(classes[classMain]){
    const baseClass = classes[classMain]['base'] || classMain;
    form[`hpMain`].value = classes[baseClass]['stt']['Hp'] || '';
    form[`mpMain`].value = classes[baseClass]['stt']['Mp'] || '';
    form[`hpMain`].readOnly = true;
    form[`mpMain`].readOnly = true;
  }
  else if(classMain) {
    form[`hpMain`].readOnly = false;
    form[`mpMain`].readOnly = false;
  }
  else {
    form[`hpMain`].value = '';
    form[`mpMain`].value = '';
    form[`hpMain`].readOnly = true;
    form[`mpMain`].readOnly = true;
  }
  if(classes[classSupportLv1]){
    form[`hpSupport`].value    = classes[classSupportLv1]['stt']['Hp'] || '';
    form[`mpSupport`].value    = classes[classSupportLv1]['stt']['Mp'] || '';
    form[`hpSupport`].readOnly = true;
    form[`mpSupport`].readOnly = true;
  }
  else if(classSupportLv1) {
    form[`hpSupport`].readOnly = false;
    form[`mpSupport`].readOnly = false;
  }
  else {
    form[`hpSupport`].value = '';
    form[`mpSupport`].value = '';
    form[`hpSupport`].readOnly = true;
    form[`mpSupport`].readOnly = true;
  }

  // サポートクラス欄から条件に合わない選択肢を削除
  // レベルアップ履歴のクラスチェンジ欄から条件に合わない選択肢を削除
  document.querySelectorAll(`#levelup select[name$="Class"] option, select[name="classSupportLv1"] option`).forEach(opt => {
    const name = opt.value;
    if(classes[name] && (classes[name]['base'] || classes[name]['limited'])){
      opt.style.display = (classes[name]['base'] === classMainLv1 || classes[name]['limited'] === classMainLv1 ? '' : 'none');
    }
  });
  // スキルの種別選択肢のクラス部分を書き換え
  for(let num = 1; num <= form['skillsNum'].value; num++){
    const select = form[`skill${num}Type`];
    const selected = select.value;
    for(let i = select.options.length - 1; i > 0; i--) {
      if(!select.options[i].value.match(/^(race|add|general|style|geis)$/)){ select.options[i].remove(); }
    }
    if(classes[classMain] && classes[classMain]['type'] === 'fate'){
      Array.from(new Set([
        {'value':'power'  ,'text' : 'パワー（共通）'},
        {'value':'another','text' : '異才'},
      ])).forEach(op => {
        const option = document.createElement('option');
        option.value = op.value;
        option.text = op.text;
        select.appendChild(option);
      });
    }
    let array = experienced.concat();
    if(selected && !selected.match(/^(race|add|general|style|geis|power|another)$/)){ array.push(selected); }
    Array.from(new Set(array)).forEach(name => {
      const option = document.createElement('option');
      option.value = name;
      option.text = name;
      select.appendChild(option);
    });
    select.value = selected;
  }
  //ライフパスの見出し
  document.querySelector(`#lifepath-motive th`).innerHTML = (classes[classMain] && classes[classMain]['type'] === 'fate') ? '運命' : '目的';
}
// 成長チェック ----------------------------------------
function checkGrow(num) {
  let total = 0;
  sttNames.forEach(s => {
    total += form[`lvUp${num}Stt${s}`].checked ? 1 : 0;
    form[`lvUp${num}Stt${s}`].disabled = false;
  });
  if(total >= 3){
    sttNames.forEach(s => {
      if(!form[`lvUp${num}Stt${s}`].checked){ form[`lvUp${num}Stt${s}`].disabled = true; }
    });
  }
  calcStt();
}

// ステータス計算 ----------------------------------------
const sttNames = ['Str','Dex','Agi','Int','Sen','Mnd','Luk'];
let sttBase  = {};
let sttTotal = {};
let sttRoll  = {};
function calcStt() {
  // 能力値
  let sttGrow = {'Str':0,'Dex':0,'Agi':0,'Int':0,'Sen':0,'Mnd':0,'Luk':0};
  sttBase     = {'Str':0,'Dex':0,'Agi':0,'Int':0,'Sen':0,'Mnd':0,'Luk':0};
  sttTotal    = {'Str':0,'Dex':0,'Agi':0,'Int':0,'Sen':0,'Mnd':0,'Luk':0};
  sttRoll     = {'Str':0,'Dex':0,'Agi':0,'Int':0,'Sen':0,'Mnd':0,'Luk':0};
  let makeBonusTotal = 0;
  sttNames.forEach(s => {
    for(let lv = 2; lv <= level; lv++){
      if(form[`lvUp${lv}Stt${s}`].checked ){ sttGrow[s]++; }
    }
    const sttRace = Number(form[`stt${s}Race`].value);
    const sttMake = Number(form[`stt${s}Make`].value);
    sttBase[s] = sttRace + sttMake + Number(form[`stt${s}BaseAdd`].value) + sttGrow[s];
    const sttBonus = parseInt(sttBase[s] / 3);
    sttTotal[s] = sttBonus + Number(form[`stt${s}Main`].value) + Number(form[`stt${s}Support`].value) + Number(form[`stt${s}Add`].value);
    sttRoll[s]  = sttTotal[s] + Number(form[`roll${s}Add`].value);
    
    makeBonusTotal += sttMake;
    form[`stt${s}Make`].classList.toggle('error', sttRace + sttMake > 13);
    document.getElementById(`lvup1-${s.toLowerCase()}`).innerHTML = '+'+sttMake;
    document.getElementById(`stt-${s.toLowerCase()}-base`).innerHTML = sttBase[s];
    document.getElementById(`stt-${s.toLowerCase()}-grow`).innerHTML = sttGrow[s];
    document.getElementById(`stt-${s.toLowerCase()}-bonus`).innerHTML = sttBonus;
    document.getElementById(`stt-${s.toLowerCase()}-total`).innerHTML = sttTotal[s];
    document.getElementById(`roll-${s.toLowerCase()}`).innerHTML = sttRoll[s];
    // HP／MP／フェイト使用上限／携帯可能重量
    if(s === 'Str'){
      let hpAuto = autoCalcSkill['バイタリティ'] ? level : 0;
      document.getElementById(`hp-base`).innerHTML = sttBase[s];
      document.getElementById(`hp-auto`).innerHTML = hpAuto;
      document.getElementById(`hp-total`).innerHTML = sttBase[s] + Number(form[`hpMain`].value) + Number(form[`hpSupport`].value) + Number(form[`hpAdd`].value) + hpAuto + hpGrow;
    }
    else if(s === 'Mnd'){
      let mpAuto = autoCalcSkill['インテンション'] ? level : 0;
      document.getElementById(`mp-base`).innerHTML = sttBase[s];
      document.getElementById(`mp-auto`).innerHTML = mpAuto;
      document.getElementById(`mp-total`).innerHTML = sttBase[s] + Number(form[`mpMain`].value) + Number(form[`mpSupport`].value) + Number(form[`mpAdd`].value) + mpAuto + mpGrow;
    }
    else if(s === 'Luk'){
      document.getElementById(`fate-limit-base`).innerHTML = sttTotal[s];
      document.getElementById(`fate-limit-total`).innerHTML = sttTotal[s] + Number(form[`fateLimitAdd`].value);
    }
  });
  if(makeBonusTotal > 5){ sttNames.forEach(s => { form[`stt${s}Make`].classList.add('error') }); }
  document.getElementById(`make-bonus-total`).innerHTML = makeBonusTotal;
  // フェイト／スキルレベル合計最大値
  const fateBase = (classMainLv1 === classSupportLv1) ? 6 : 5;
  let fateGrow = 0;
  let skillsLvLimit = 1+1+4;
  for(let lv = 2; lv <= level; lv++){
    if(form[`lvUp${lv}Class`].value === 'fate'){ skillsLvLimit += 2; fateGrow += parseInt(lv/10)+1; }
    else if(form[`lvUp${lv}Class`].value      ){ skillsLvLimit += 2 }
    else { skillsLvLimit += 3; }
  }
  document.getElementById('fate-base').innerHTML = fateBase;
  document.getElementById('fate-grow').innerHTML = fateGrow;
  document.getElementById('fate-total').innerHTML = fateBase + Number(form.fateAdd.value) + fateGrow;
  document.getElementById('skills-lv-limit').innerHTML = skillsLvLimit;
  document.getElementById('gskills-lv-limit').innerHTML = level + 1;
  //重量
  const weightBaseWeapon = sttBase[ autoCalcSkill['アストラルボディ'] || 'Str' ];
  const weightBaseArmour = autoCalcSkill['ファランクススタイル'] && autoCalcSkill['アストラルボディ'] ? Math.max(sttBase[ autoCalcSkill['ファランクススタイル'] ], sttBase['Mnd'])
                         : sttBase[ autoCalcSkill['ファランクススタイル'] || autoCalcSkill['アストラルボディ'] || 'Str' ];
  const weightBaseItems  = autoCalcSkill['エンラージリミット'] && autoCalcSkill['アストラルボディ'] ? Math.max(sttBase['Str']*2, sttBase['Mnd'])
                         : autoCalcSkill['エンラージリミット'] ? sttBase['Str'] * 2
                         : autoCalcSkill['アストラルボディ']   ? sttBase['Mnd']
                         : sttBase['Str'];
  const weightWeapon = weightBaseWeapon + Number(form.weightLimitAddWeapon.value);
  const weightArmour = weightBaseArmour + Number(form.weightLimitAddArmour.value);
  const weightItems  = weightBaseItems  + Number(form.weightLimitAddItems.value);
  document.getElementById(`weight-base-weapon`).innerHTML = weightBaseWeapon;
  document.getElementById(`weight-base-armour`).innerHTML = weightBaseArmour;
  document.getElementById(`weight-base-items`).innerHTML  = weightBaseItems;
  document.getElementById(`weight-limit-weapon`).innerHTML = weightWeapon;
  document.getElementById(`weight-limit-armour`).innerHTML = weightArmour;
  document.getElementById(`weight-limit-items`).innerHTML  = weightItems;
  document.getElementById(`armament-weight-limit-weapon`).innerHTML = weightWeapon;
  document.getElementById(`armament-weight-limit-armour`).innerHTML = weightArmour;
  document.getElementById(`items-weight-limit`).innerHTML  = weightItems;

  calcBattle();
  calcRolls();
}
// 武器の合計切り替え ----------------------------------------
function changeHandedness(){
  const hand = String(form.handedness.value || 1);
  document.getElementById('battle-total-acc-right').classList.toggle('hide', hand.match(/2|3/) || (hand == 1 && form.armamentHandRType.value.match(/^[-―ー盾]?$/) ) );
  document.getElementById('battle-total-acc-left' ).classList.toggle('hide', hand.match(/2|3/) || (hand == 1 && form.armamentHandLType.value.match(/^[-―ー盾]?$/) ) );
  document.getElementById('battle-total-atk-right').classList.toggle('hide', hand.match(/2/) || (hand == 1 && form.armamentHandRType.value.match(/^[-―ー盾]?$/) ) );
  document.getElementById('battle-total-atk-left' ).classList.toggle('hide', hand.match(/2/) || (hand == 1 && form.armamentHandLType.value.match(/^[-―ー盾]?$/) ) );
  document.getElementById('battle-total-acc' ).classList.toggle('hide', hand.match(/1/));
  document.getElementById('battle-total-atk' ).classList.toggle('hide', hand.match(/1|3/));
}

// レベルアップ欄スキル計算 ----------------------------------------
function calcLvUpSkills(type){
  let skillLv = {};
  for(let lv = 1; lv <= level; lv++){
    const _class = lv > 1 ? form[`lvUp${lv}Class`].value : ''; //フェイトor転職／スキル×3
    let fail = {};
    if(_class){ fail[3] = 1; }
    const numMax = lv === 1 ? 6 : 3;
    for(let i = 1; i <= numMax; i++){
      const obj = form[`lvUp${lv}Skill${i}`];
      let skill = obj.value;
      let learning = [];
      //ラーニング系
      while(skill.match(/^(.+?)[/／](.+)$/)){
        learning.push(RegExp.$1);
        skillLv[RegExp.$1] = skillLv[RegExp.$1] ? skillLv[RegExp.$1]+1 : 1;
        skill = RegExp.$2;
      }
      //パワーは隣の欄を封鎖
      obj.classList.remove('error');
      if(skillType[skill] === 'power' || skillType[skill] === 'another'){
        if(i === 3){ obj.classList.add('error'); } //3つ目はエラー
        else if(fail[i+1]){ obj.classList.add('error'); } //隣が封鎖済みもエラー
        else { fail[i+1] = 1; } //封鎖
      }
      obj.classList.toggle('fail', fail[i] === 1);
      //
      if(skill && !fail[i]){
        if(!skillLv[skill]){ // Lv0⇒1
          skillLv[skill] = 1;
          if(skillType[skill] && skillType[skill] === 'geis'){ skillLv[skill]++; }//誓約は2から
        }
        else { // Lv +1
          skillLv[skill]++;
        }
        obj.parentNode.dataset.lv = skillLv[skill];

        // スキル欄へ転記
        if(type === 'copy'){
          let type = '';
          //Lv1習得の場合は自動で種別を入れる
          if(lv === 1){
            type = (i === 1) ? 'race'
                 : (i >= 2 && i <= 4) ? classMainLv1
                 : classSupportLv1;
          }
          //ラーニング系
          learning.forEach( lSkill => {
            if(lSkill.match(/^異才/)){ //異才
              copyLvUpToSkill(lSkill, classMain);
              type = 'another';
            }
            else { //異才以外
              copyLvUpToSkill(lSkill, type);
              type = 'add';
            }
          });
          copyLvUpToSkill(skill, type);
        }
      }
      else { obj.parentNode.dataset.lv = ''; }
    }
  }
  if(type === 'copy'){ calcSkills(); } else { calcSkillLvLimit(); }

  // 転記処理
  function copyLvUpToSkill(skill, type){
    if(skillNum[skill]){ // もうある場合はLv入れるだけ
      form[`skill${ skillNum[skill] }Lv`].value = skillLv[skill];
    }
    else { //ない場合
      for(let num = 1; num <= form['skillsNum'].value+1; num++){
        if(!form[`skill${num}Name`]){ addSkill(); } //空欄なかったら作る
        const skn = form[`skill${num}Name`];
        const skt = form[`skill${num}Type`];
        if(!skn.value){ //空欄なので入れる
          skn.value = skill;
          if(type){ skt.value = type; }
          else { skt.value = '' }
          form[`skill${num}Lv`].value = skillLv[skill];
          skillNum[skill] = num;
          break;
        }
      }
    }
  }
}

// スキル計算 ----------------------------------------
let skillType = {};
let skillNum = {};
let skillsLvLimitAddType = 0;
let autoCalcSkill = {};
function calcSkills(){
  skillNum = {};
  skillsLvLimitAddType = 0;
  autoCalcSkill = {};
  let total   = 0;
  let general = 0;
  for(let num = 1; num <= form['skillsNum'].value; num++){
    const name = form[`skill${num}Name`].value;
    const lv   = Number(form[`skill${num}Lv`].value);
    let type = form[`skill${num}Type`].value;
    if(classes[type] && classes[type]['type'] === 'fate'){ type = 'power'; }
    if(lv){
      if     (type === 'general'){ general += lv; }
      else if(type === 'add'    ){ total += lv; skillsLvLimitAddType += 1 }
      else if(type === 'geis'   ){ total += lv; skillsLvLimitAddType += 1 }
      else if(type === 'power'  ){ total += lv; skillsLvLimitAddType -= lv }
      else if(type === 'another'){ total += lv; skillsLvLimitAddType += lv }
      else                       { total += lv; }
    }
    if(name){ skillType[name] = type; skillNum[name] = num; }
    const bg = form['skill'+num+'Name'].parentNode.parentNode.parentNode.classList;
    bg.toggle('race',    type === 'race'   );
    bg.toggle('general', type === 'general');
    bg.toggle('style',   type === 'style'  );
    bg.toggle('add',     type === 'add'    );
    bg.toggle('geis',    type === 'geis'   );
    bg.toggle('power',   type === 'power'  );
    bg.toggle('another', type === 'another');
    
    let markFlag = 0;
    if     (name.match(/(^|[\/／])インテンション/)    ){ autoCalcSkill['インテンション']     = lv; markFlag = 1; }
    else if(name.match(/(^|[\/／])バイタリティ/)      ){ autoCalcSkill['バイタリティ']       = lv; markFlag = 1; }
    else if(name.match(/(^|[\/／])エンラージリミット/)){ autoCalcSkill['エンラージリミット'] = lv; markFlag = 1; }
    else if(name.match(/(^|[\/／])アストラルボディ/)  ){ autoCalcSkill['アストラルボディ']   = lv ? 'Mnd' : ''; markFlag = 1; }
    else if(name.match(/(^|[\/／])ファランクススタイル[:：]器用/)){ autoCalcSkill['ファランクススタイル'] = lv ? 'Dex' : ''; markFlag = 1; }
    else if(name.match(/(^|[\/／])ファランクススタイル[:：]敏捷/)){ autoCalcSkill['ファランクススタイル'] = lv ? 'Agi' : ''; markFlag = 1; }
    else if(name.match(/(^|[\/／])ファランクススタイル[:：]知力/)){ autoCalcSkill['ファランクススタイル'] = lv ? 'Int' : ''; markFlag = 1; }
    else if(name.match(/(^|[\/／])ファランクススタイル[:：]感知/)){ autoCalcSkill['ファランクススタイル'] = lv ? 'Sen' : ''; markFlag = 1; }
    else if(name.match(/(^|[\/／])ファランクススタイル[:：]精神/)){ autoCalcSkill['ファランクススタイル'] = lv ? 'Mnd' : ''; markFlag = 1; }
    else if(name.match(/(^|[\/／])ファランクススタイル[:：]幸運/)){ autoCalcSkill['ファランクススタイル'] = lv ? 'Luk' : ''; markFlag = 1; }
    form[`skill${num}Name`].parentNode.classList.toggle('calc', markFlag);
  }
  document.getElementById('skills-lv-total').innerHTML = total;
  document.getElementById('gskills-lv-total').innerHTML = general;
  expUse['skills'] = (general - 2) *5;

  calcSkillLvLimit();
  calcStt();
  calcExp();
}

// 最大スキルレベル計算 ----------------------------------------
function calcSkillLvLimit(){
  let num = skillsLvLimitAddType;
  document.getElementById('skills-lv-limit-add').innerHTML = (!num) ? '' : (num > 0) ? '+'+num : num;
}

// 武器・戦闘判定計算 ----------------------------------------
function calcBattle(){
  let weightW = 0;
  let weightA = 0;
  let acc  = 0;
  let atk  = 0;
  let eva  = 0;
  let def  = 0;
  let ini  = 0;
  let mdef = 0;
  let move = 0;
  ['HandR','HandL','Head','Body','Sub','Other'].forEach(id => {
    if(id.match(/Hand/)){ weightW += Number(form[`armament${id}Weight`].value) }
    else { weightA += Number(form[`armament${id}Weight`].value) }
    acc  += Number(form[`armament${id}Acc`].value);
    atk  += Number(form[`armament${id}Atk`].value);
    eva  += Number(form[`armament${id}Eva`].value);
    def  += Number(form[`armament${id}Def`].value);
    mdef += Number(form[`armament${id}MDef`].value);
    ini  += Number(form[`armament${id}Ini`].value);
    move += Number(form[`armament${id}Move`].value);
  });
  let accR = Number(form[`armamentHandRAcc`].value);
  let accL = Number(form[`armamentHandLAcc`].value);
  let atkR = Number(form[`armamentHandRAtk`].value);
  let atkL = Number(form[`armamentHandLAtk`].value);
  document.getElementById('armament-total-weight-weapon').innerHTML = weightW;
  document.getElementById('armament-total-weight-armour').innerHTML = weightA;
  document.getElementById('armament-total-acc-right').innerHTML = acc - accL;
  document.getElementById('armament-total-acc-left' ).innerHTML = acc - accR;
  document.getElementById('armament-total-atk-right').innerHTML = atk - atkL;
  document.getElementById('armament-total-atk-left' ).innerHTML = atk - atkR;
  document.getElementById('armament-total-eva'   ).innerHTML = eva ;
  document.getElementById('armament-total-def'   ).innerHTML = def ;
  document.getElementById('armament-total-mdef'  ).innerHTML = mdef;
  document.getElementById('armament-total-ini'   ).innerHTML = ini ;
  document.getElementById('armament-total-move'  ).innerHTML = move;

  acc  += sttRoll['Dex'];
  atk  += 0;
  eva  += sttRoll['Agi'];
  def  += 0;
  
  mdef += sttTotal['Mnd'];
  ini  += sttTotal['Agi'] + sttTotal['Sen'];
  move += sttTotal['Str'] + 5;
  
  let accDice = Number(form.rollDexDice.value);
  let atkDice = Number(form.rollStrDice.value);
  let evaDice = Number(form.rollAgiDice.value);

  ['Skill','Other'].forEach(id => {
    acc  += Number(form[`battle${id}Acc`].value);
    atk  += Number(form[`battle${id}Atk`].value);
    eva  += Number(form[`battle${id}Eva`].value);
    def  += Number(form[`battle${id}Def`].value);
    mdef += Number(form[`battle${id}MDef`].value);
    ini  += Number(form[`battle${id}Ini`].value);
    move += Number(form[`battle${id}Move`].value);
    
    accDice += Number(form[`battle${id}AccDice`].value);
    atkDice += Number(form[`battle${id}AtkDice`].value);
    evaDice += Number(form[`battle${id}EvaDice`].value);
  });
  if( def < 0){  def = 0; }
  if(mdef < 0){ mdef = 0; }
  ['HandR','HandL','Head','Body','Sub','Other'].forEach(id => {
    const obj = form[`armament${id}Move`];
    obj.classList.toggle('error', Number(obj.value) < 0 && move <= 0);
  });
  document.getElementById('battle-total-acc' ).innerHTML = acc ;
  document.getElementById('battle-total-acc-right').innerHTML = acc - accL;
  document.getElementById('battle-total-acc-left' ).innerHTML = acc - accR;
  document.getElementById('battle-total-atk' ).innerHTML = atk ;
  document.getElementById('battle-total-atk-right').innerHTML = atk - atkL;
  document.getElementById('battle-total-atk-left' ).innerHTML = atk - atkR;
  document.getElementById('battle-total-eva' ).innerHTML = eva ;
  document.getElementById('battle-total-def' ).innerHTML = def ;
  document.getElementById('battle-total-mdef').innerHTML = mdef;
  document.getElementById('battle-total-ini' ).innerHTML = ini ;
  document.getElementById('battle-total-move').innerHTML = move;
  document.getElementById('battle-dice-acc').innerHTML = accDice;
  document.getElementById('battle-dice-atk').innerHTML = atkDice;
  document.getElementById('battle-dice-eva').innerHTML = evaDice;
}

// 特殊な判定計算 ----------------------------------------
function calcRolls(){
  document.getElementById('roll-trapdetect-total'  ).innerHTML = sttRoll['Sen'] + Number(form.rollTrapDetectSkill.value   )+ Number(form.rollTrapDetectOther.value  );
  document.getElementById('roll-traprelease-total' ).innerHTML = sttRoll['Dex'] + Number(form.rollTrapReleaseSkill.value  )+ Number(form.rollTrapReleaseOther.value );
  document.getElementById('roll-dengerdetect-total').innerHTML = sttRoll['Sen'] + Number(form.rollDangerDetectSkill.value )+ Number(form.rollDangerDetectOther.value);
  document.getElementById('roll-enemylore-total'   ).innerHTML = sttRoll['Int'] + Number(form.rollEnemyLoreSkill.value    )+ Number(form.rollEnemyLoreOther.value   );
  document.getElementById('roll-appraisal-total'   ).innerHTML = sttRoll['Int'] + Number(form.rollAppraisalSkill.value    )+ Number(form.rollAppraisalOther.value   );
  document.getElementById('roll-magic-total'       ).innerHTML = sttRoll['Int'] + Number(form.rollMagicSkill.value        )+ Number(form.rollMagicOther.value       );
  document.getElementById('roll-song-total'        ).innerHTML = sttRoll['Mnd'] + Number(form.rollSongSkill.value         )+ Number(form.rollSongOther.value        );
  document.getElementById('roll-alchemy-total'     ).innerHTML = sttRoll['Dex'] + Number(form.rollAlchemySkill.value      )+ Number(form.rollAlchemyOther.value     );

  document.getElementById('roll-trapdetect-total-dice'  ).innerHTML = Number(form.rollSenDice.value)+ Number(form.rollTrapDetectDiceAdd.value  );
  document.getElementById('roll-traprelease-total-dice' ).innerHTML = Number(form.rollDexDice.value)+ Number(form.rollTrapReleaseDiceAdd.value );
  document.getElementById('roll-dengerdetect-total-dice').innerHTML = Number(form.rollSenDice.value)+ Number(form.rollDangerDetectDiceAdd.value);
  document.getElementById('roll-enemylore-total-dice'   ).innerHTML = Number(form.rollIntDice.value)+ Number(form.rollEnemyLoreDiceAdd.value   );
  document.getElementById('roll-appraisal-total-dice'   ).innerHTML = Number(form.rollIntDice.value)+ Number(form.rollAppraisalDiceAdd.value   );
  document.getElementById('roll-magic-total-dice'       ).innerHTML = Number(form.rollIntDice.value)+ Number(form.rollMagicDiceAdd.value       );
  document.getElementById('roll-song-total-dice'        ).innerHTML = Number(form.rollMndDice.value)+ Number(form.rollSongDiceAdd.value        );
  document.getElementById('roll-alchemy-total-dice'     ).innerHTML = Number(form.rollDexDice.value)+ Number(form.rollAlchemyDiceAdd.value     );
}

// 携行重量計算 ----------------------------------------
function calcWeight(){
  let weight = 0;
  let w = form.items.value;
  w.replace(
    /[@＠]\[\s*?([\+\-\*\/]?[0-9]+)+\s*?\]/g,
    function (num, idx, old) {
      weight += safeEval(num.slice(2,-1)) || 0;
    }
  );
  document.getElementById('items-weight-total').innerHTML = weight;
}

// 収支履歴計算 ----------------------------------------
function calcCash(){
  let cash = 0;
  //let deposit = 0;
  //let debt = 0;
  const historyNum = form.historyNum.value;
  for (let i = 0; i <= historyNum; i++){
    const obj = form['history'+i+'Money'];
    let hCash = safeEval(obj.value);
    if(isNaN(hCash)){
      obj.classList.add('error');
    }
    else {
      cash += hCash;
      obj.classList.remove('error');
    }
    if(isNaN(hCash)){
      obj
    }
  }
  document.getElementById("history-money-total").innerHTML = cash;
  let s = form.cashbook.value;
  s.replace(
    /::([\+\-\*\/]?[0-9]+)+/g,
    function (num, idx, old) {
      cash += safeEval(num.slice(2)) || 0;
    }
  );
  s.replace(
    /:>([\+\-\*\/]?[0-9]+)+/g,
    function (num, idx, old) {
      deposit += safeEval(num.slice(2)) || 0;
    }
  );
  s.replace(
    /:<([\+\-\*\/]?[0-9]+)+/g,
    function (num, idx, old) {
      debt += safeEval(num.slice(2)) || 0;
    }
  );
  cash = cash //- deposit + debt;
  document.getElementById('cashbook-total-value').innerHTML = cash;
  //document.getElementById('cashbook-deposit-value').innerHTML = deposit;
  //document.getElementById('cashbook-debt-value').innerHTML = debt;
}

// コネクション計算 ----------------------------------------
function calcConnections(){
  expUse['connections'] = 0;
  for(let i = 1; i <= Number(form.connectionsNum.value); i++){
    if(form[`connection${i}Name`].value) expUse['connections']++;
  }
  calcExp();
}

// 誓約計算 ----------------------------------------
function calcGeises(){
  expUse['geises'] = 0;
  for(let i = 1; i <= Number(form.geisesNum.value); i++){
    expUse['geises'] += Number(form[`geis${i}Cost`].value);
  }
  calcExp();
}

// 経験点計算 ----------------------------------------
function calcExp(){
  let total = Number(form['history0Exp'].value);
  let payment = 0;
  for (let i = 1; i <= Number(form.historyNum.value); i++){
    const obj = form['history'+i+'Exp'];
    let exp = safeEval(obj.value);
    let pay = Number(form['history'+i+'Payment'].value);
    if(isNaN(exp)){
      obj.classList.add('error');
    }
    else {
      total += exp;
      payment += pay;
      obj.classList.remove('error');
      form['history'+i+'Payment'].classList.toggle('error', pay > exp);
    }
  }
  total -= payment;
  let rest = total;
  for (let key in expUse){
    rest -= expUse[key];
  }
  document.getElementById("exp-total").innerHTML = total;
  document.getElementById("exp-used-level" ).innerHTML = expUse['level' ] || 0;
  document.getElementById("exp-used-skill" ).innerHTML = expUse['skills' ] || 0;
  document.getElementById("exp-used-geises").innerHTML = expUse['geises'] || 0;
  document.getElementById("exp-used-connections").innerHTML = expUse['connections'] || 0;
  document.getElementById("exp-rest").innerHTML = rest;
  document.getElementById("history-exp-total").innerHTML = total;
  document.getElementById("history-payment-total").innerHTML = payment;
}

// スキル欄 ----------------------------------------
// 追加
function addSkill(){
  let num = Number(form.skillsNum.value) + 1;
  let tbody = document.createElement('tbody');
  tbody.setAttribute('id',idNumSet('skill'));
  tbody.innerHTML = `<tr>
    <td rowspan="2" class="handle"></td>
    <td><input name="skill${num}Name"   type="text"   placeholder="名称" onchange="calcSkills()"></td>
    <td><input name="skill${num}Lv"     type="number" placeholder="Lv" oninput="calcSkills()"></td>
    <td><input name="skill${num}Timing" type="text"   placeholder="タイミング" list="list-timing"></td>
    <td><input name="skill${num}Roll"   type="text"   placeholder="判定"   list="list-roll"></td>
    <td><input name="skill${num}Target" type="text"   placeholder="対象"   list="list-target"></td>
    <td><input name="skill${num}Range"  type="text"   placeholder="射程"   list="list-range"></td>
    <td><input name="skill${num}Cost"   type="number" placeholder="ｺｽﾄ" min="0"></td>
    <td><input name="skill${num}Reqd"   type="text"   placeholder="使用条件"   list="list-reqd"></td>
  </tr>
  <tr><td colspan="8"><div>
    <b>取得元</b><select name="skill${num}Type" onchange="calcSkills();calcLvUpSkills();">
      <option value="">
      <option value="race">種族
      <option value="general">一般
      <option value="style">流派
      <option value="geis">誓約
      <option value="add">他スキル
      <option value="another">異才
      <option value="power">パワー（共通）
    </select>
    <b>分類</b><input name="skill${num}Category" type="text" list="list-category">
    <b>効果</b><input name="skill${num}Note" type="text">
  </div></td></tr>`;
  document.querySelector("#skills-table tbody:last-of-type").after(tbody);
  
  form.skillsNum.value = num;
  checkClass();
}
// 削除
function delSkill(){
  let num = Number(form.skillsNum.value);
  if(num > 2){
    if(form[`skill${num}Name`  ].value || 
       form[`skill${num}Lv`    ].value || 
       form[`skill${num}Timing`].value || 
       form[`skill${num}Roll`  ].value || 
       form[`skill${num}Target`].value || 
       form[`skill${num}Range` ].value || 
       form[`skill${num}Cost`  ].value || 
       form[`skill${num}Reqd`  ].value || 
       form[`skill${num}Note`  ].value
    ){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#skills-table tbody:last-of-type").remove();
    
    form.skillsNum.value = num - 1;
    calcSkills();
  }
}
// ソート
let skillsSortable = Sortable.create(document.getElementById('skills-table'), {
  group: "skills",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onSort: function(evt){ skillsSortAfter(); },
  onStart: function(evt){
    document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
    document.getElementById('skills-trash').style.display = 'block';
  },
  onEnd: function(evt){
    if(!skillTrashNum) { document.getElementById('skills-trash').style.display = 'none' }
  },
});
let skillsSortableTrash = Sortable.create(document.getElementById('skills-trash-table'), {
  group: "skills",
  dataIdAttr: 'id',
  animation: 100,
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost'
});
let skillTrashNum = 0;
function skillsSortAfter(){
  const order = skillsSortable.toArray();
  let num = 1;
  for(let id of order) {
    if(document.getElementById(id)){
      document.querySelector(`#${id} [name$="Type"]`    ).setAttribute('name',`skill${num}Type`);
      document.querySelector(`#${id} [name$="Category"]`).setAttribute('name',`skill${num}Category`);
      document.querySelector(`#${id} [name$="Name"]`    ).setAttribute('name',`skill${num}Name`);
      document.querySelector(`#${id} [name$="Lv"]`      ).setAttribute('name',`skill${num}Lv`);
      document.querySelector(`#${id} [name$="Timing"]`  ).setAttribute('name',`skill${num}Timing`);
      document.querySelector(`#${id} [name$="Roll"]`    ).setAttribute('name',`skill${num}Roll`);
      document.querySelector(`#${id} [name$="Target"]`  ).setAttribute('name',`skill${num}Target`);
      document.querySelector(`#${id} [name$="Range"]`   ).setAttribute('name',`skill${num}Range`);
      document.querySelector(`#${id} [name$="Cost"]`    ).setAttribute('name',`skill${num}Cost`);
      document.querySelector(`#${id} [name$="Reqd"]`    ).setAttribute('name',`skill${num}Reqd`);
      document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`skill${num}Note`);
      num++;
    }
  }
  form.skillsNum.value = num-1;
  let del = 0;
  const trashOrder = skillsSortableTrash.toArray();
  for(let id of trashOrder) {
    if(document.getElementById(id)){
      del++;
      document.querySelector(`#${id} [name$="Type"]`    ).setAttribute('name',`skillD${del}Type`);
      document.querySelector(`#${id} [name$="Category"]`).setAttribute('name',`skillD${del}Category`);
      document.querySelector(`#${id} [name$="Name"]`    ).setAttribute('name',`skillD${del}Name`);
      document.querySelector(`#${id} [name$="Lv"]`      ).setAttribute('name',`skillD${del}Lv`);
      document.querySelector(`#${id} [name$="Timing"]`  ).setAttribute('name',`skillD${del}Timing`);
      document.querySelector(`#${id} [name$="Roll"]`    ).setAttribute('name',`skillD${del}Roll`);
      document.querySelector(`#${id} [name$="Target"]`  ).setAttribute('name',`skillD${del}Target`);
      document.querySelector(`#${id} [name$="Range"]`   ).setAttribute('name',`skillD${del}Range`);
      document.querySelector(`#${id} [name$="Cost"]`    ).setAttribute('name',`skillD${del}Cost`);
      document.querySelector(`#${id} [name$="Reqd"]`    ).setAttribute('name',`skillD${del}Reqd`);
      document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`skillD${del}Note`);
    }
  }
  skillTrashNum = del;
  if(!del){ document.getElementById('skills-trash').style.display = 'none' }
  calcSkills();
}

// コネクション欄 ----------------------------------------
// 追加
function addConnection(){
  let num = Number(form.connectionsNum.value) + 1;
  let tr = document.createElement('tr');
  tr.setAttribute('id',idNumSet('connection'));
  tr.innerHTML = `
    <td class="handle"> </td>
    <td><input name="connection${num}Name"     type="text" onchange="calcConnections()"></td>
    <td><input name="connection${num}Relation" type="text"></td>
    <td><input name="connection${num}Note"     type="text"></td>
  `;
  document.querySelector("#connections-table tbody tr:last-of-type").after(tr);
  
  form.connectionsNum.value = num;
}
// 削除
function delConnection(){
  let num = Number(form.connectionsNum.value);
  if(num > 1){
    if(form[`connection${num}Name`].value || form[`connection${num}Relation`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#connections-table tbody tr:last-of-type").remove();

    form.connectionsNum.value = num - 1;
    
    calcConnections();
  }
}
// ソート
let connectionsSortable = Sortable.create(document.querySelector('#connections-table tbody'), {
  group: "connections",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = connectionsSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Name"]`    ).setAttribute('name',`connection${num}Name`);
        document.querySelector(`#${id} [name$="Relation"]`).setAttribute('name',`connection${num}Relation`);
        document.querySelector(`#${id} [name$="Note"]`    ).setAttribute('name',`connection${num}Note`);
        num++;
      }
    }
  }
});

// 誓約欄 ----------------------------------------
// 追加
function addGeis(){
  let num = Number(form.geisesNum.value) + 1;
  let tr = document.createElement('tr');
  tr.setAttribute('id',idNumSet('geis'));
  tr.innerHTML = `
    <td class="handle"> </td>
    <td><input name="geis${num}Name" type="text"></td>
    <td><input name="geis${num}Cost" type="number" oninput="calcGeises()"></td>
    <td><textarea name="geis${num}Note"></textarea></td>
  `;
  document.querySelector("#geises-table tbody tr:last-of-type").after(tr);
  
  form.geisesNum.value = num;
}
// 削除
function delGeis(){
  let num = Number(form.geisesNum.value);
  if(num > 1){
    if(form[`geis${num}Name`].value || form[`geis${num}Cost`].value || form[`geis${num}Note`].value){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#geises-table tbody tr:last-of-type").remove();

    form.geisesNum.value = num - 1;
  }
  calcGeises();
}
// ソート
let geisesSortable = Sortable.create(document.querySelector('#geises-table tbody'), {
  group: "geises",
  dataIdAttr: 'id',
  animation: 100,
  handle: '.handle',
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = geisesSortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Name"]`).setAttribute('name',`geis${num}Name`);
        document.querySelector(`#${id} [name$="Cost"]`).setAttribute('name',`geis${num}Cost`);
        document.querySelector(`#${id} [name$="Note"]`).setAttribute('name',`geis${num}Note`);
        num++;
      }
    }
  }
});

// 履歴欄 ----------------------------------------
// 追加
function addHistory(){
  let num = Number(form.historyNum.value) + 1;
  let tbody = document.createElement('tbody');
  tbody.setAttribute('id',idNumSet('history'));
  tbody.innerHTML = `<tr>
    <td rowspan="2" class="handle"></td>
    <td rowspan="2"><input name="history${num}Date"   type="text"></td>
    <td rowspan="2"><input name="history${num}Title"  type="text"></td>
    <td><input name="history${num}Exp"     type="text" oninput="calcExp()"></td>
    <td><input name="history${num}Payment" type="number" oninput="calExp()"></td>
    <td><input name="history${num}Money"   type="text" oninput="calcCash()"></td>
    <td><input name="history${num}Gm"      type="text"></td>
    <td><input name="history${num}Member"  type="text"></td>
  </tr>
  <tr><td colspan="5" class="left"><input name="history${num}Note" type="text"></td></tr>`;
  document.querySelector("#history-table tbody:last-of-type").after(tbody);
  
  form.historyNum.value = num;
}
// 削除
function delHistory(){
  let num = Number(form.historyNum.value);
  if(num > 1){
    if(form[`history${num}Date`  ].value || 
       form[`history${num}Title` ].value || 
       form[`history${num}Exp`   ].value || 
       form[`history${num}Money` ].value || 
       form[`history${num}Gm`    ].value || 
       form[`history${num}Member`].value || 
       form[`history${num}Note`  ].value
    ){
      if (!confirm(delConfirmText)) return false;
    }
    document.querySelector("#history-table tbody:last-of-type").remove();

    form.historyNum.value = num - 1;
    calcExp(); calcCash();
  }
}
// ソート
let historySortable = Sortable.create(document.getElementById('history-table'), {
  group: "history",
  dataIdAttr: 'id',
  animation: 150,
  handle: '.handle',
  scroll: true,
  filter: 'thead,tfoot',
  ghostClass: 'sortable-ghost',
  onUpdate: function (evt) {
    const order = historySortable.toArray();
    let num = 1;
    for(let id of order) {
      if(document.getElementById(id)){
        document.querySelector(`#${id} [name$="Date"]`  ).setAttribute('name',`history${num}Date`);
        document.querySelector(`#${id} [name$="Title"]` ).setAttribute('name',`history${num}Title`);
        document.querySelector(`#${id} [name$="Exp"]`   ).setAttribute('name',`history${num}Exp`);
        document.querySelector(`#${id} [name$="Money"]` ).setAttribute('name',`history${num}Money`);
        document.querySelector(`#${id} [name$="Gm"]`    ).setAttribute('name',`history${num}Gm`);
        document.querySelector(`#${id} [name$="Member"]`).setAttribute('name',`history${num}Member`);
        document.querySelector(`#${id} [name$="Note"]`  ).setAttribute('name',`history${num}Note`);
        num++;
      }
    }
  }
});

