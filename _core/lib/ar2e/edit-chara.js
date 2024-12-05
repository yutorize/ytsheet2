"use strict";
const gameSystem = 'ar2e';

window.onload = function() {
  setName();
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
  return true;
}

// レギュレーション ----------------------------------------
function changeRegu(){
  document.getElementById("history0-exp").textContent = form.history0Exp.value;
  document.getElementById("history0-money").textContent = form.history0Money.value;
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
  document.getElementById('exp-used-level').textContent = expUse['level'];
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
    if(races[race]?.['stt'][s]){
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
  document.querySelector(`#lifepath-origin th`    ).textContent = eLifepath ? '特異' : '出自';
  document.querySelector(`#lifepath-experience th`).textContent = eLifepath ? '転移' : '境遇';
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
    if     (classes[name]?.base){
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
  document.getElementById('class-main-value'   ).textContent = classMain;
  document.getElementById('class-support-value').textContent = classSupport;
  document.getElementById('class-title-value'  ).textContent = classTitle;
  document.getElementById('hp-grow').textContent = hpGrow;
  document.getElementById('mp-grow').textContent = mpGrow;

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
    if(classes[name]?.base || classes[name]?.limited){
      opt.style.display = (classes[name].base === classMainLv1 || classes[name].limited === classMainLv1 ? '' : 'none');
    }
  });
  // スキルの種別選択肢のクラス部分を書き換え
  for(let num = 1; num <= form['skillsNum'].value; num++){
    const select = form[`skill${num}Type`];
    const selected = select.value;
    for(let i = select.options.length - 1; i > 0; i--) {
      if(!select.options[i].value.match(/^(race|add|general|style|faith|geis)$/)){ select.options[i].remove(); }
    }
    if(classes[classMain]?.type === 'fate'){
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
    if(selected && !selected.match(/^(race|add|general|style|faith|geis|power|another)$/)){ array.push(selected); }
    Array.from(new Set(array)).forEach(name => {
      const option = document.createElement('option');
      option.value = name;
      option.text = name;
      select.appendChild(option);
    });
    select.value = selected;
  }
  //ライフパスの見出し
  document.querySelector(`#lifepath-motive th`).textContent = (classes[classMain]?.type === 'fate') ? '運命' : '目的';
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
    document.getElementById(`lvup1-${s.toLowerCase()}`).textContent = '+'+sttMake;
    document.getElementById(`stt-${s.toLowerCase()}-base`).textContent = sttBase[s];
    document.getElementById(`stt-${s.toLowerCase()}-grow`).textContent = sttGrow[s];
    document.getElementById(`stt-${s.toLowerCase()}-bonus`).textContent = sttBonus;
    document.getElementById(`stt-${s.toLowerCase()}-total`).textContent = sttTotal[s];
    document.getElementById(`roll-${s.toLowerCase()}`).textContent = sttRoll[s];
    // HP／MP／フェイト使用上限／携帯可能重量
    if(s === 'Str'){
      let hpAuto = autoCalcSkill['バイタリティ'] ? level : 0;
      document.getElementById(`hp-base`).textContent = sttBase[s];
      document.getElementById(`hp-auto`).textContent = hpAuto;
      document.getElementById(`hp-total`).textContent = sttBase[s] + Number(form[`hpMain`].value) + Number(form[`hpSupport`].value) + Number(form[`hpAdd`].value) + hpAuto + hpGrow;
    }
    else if(s === 'Mnd'){
      let mpAuto = autoCalcSkill['インテンション'] ? level : 0;
      document.getElementById(`mp-base`).textContent = sttBase[s];
      document.getElementById(`mp-auto`).textContent = mpAuto;
      document.getElementById(`mp-total`).textContent = sttBase[s] + Number(form[`mpMain`].value) + Number(form[`mpSupport`].value) + Number(form[`mpAdd`].value) + mpAuto + mpGrow;
    }
    else if(s === 'Luk'){
      document.getElementById(`fate-limit-base`).textContent = sttTotal[s];
      document.getElementById(`fate-limit-total`).textContent = sttTotal[s] + Number(form[`fateLimitAdd`].value);
    }
  });
  if(makeBonusTotal > 5){ sttNames.forEach(s => { form[`stt${s}Make`].classList.add('error') }); }
  document.getElementById(`make-bonus-total`).textContent = makeBonusTotal;
  // フェイト／スキルレベル合計最大値
  const fateBase = (classMainLv1 === classSupportLv1) ? 6 : 5;
  let fateGrow = 0;
  let skillsLvLimit = 1+1+4;
  for(let lv = 2; lv <= level; lv++){
    if(form[`lvUp${lv}Class`].value === 'fate'){ skillsLvLimit += 2; fateGrow += parseInt(lv/10)+1; }
    else if(form[`lvUp${lv}Class`].value      ){ skillsLvLimit += 2 }
    else { skillsLvLimit += 3; }
  }
  document.getElementById('fate-base').textContent = fateBase;
  document.getElementById('fate-grow').textContent = fateGrow;
  document.getElementById('fate-total').textContent = fateBase + Number(form.fateAdd.value) + fateGrow;
  document.getElementById('skills-lv-limit').textContent = skillsLvLimit;
  document.getElementById('gskills-lv-limit').textContent = level + 1;
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
  document.getElementById(`weight-base-weapon`).textContent = weightBaseWeapon;
  document.getElementById(`weight-base-armour`).textContent = weightBaseArmour;
  document.getElementById(`weight-base-items`).textContent  = weightBaseItems;
  document.getElementById(`weight-limit-weapon`).textContent = weightWeapon;
  document.getElementById(`weight-limit-armour`).textContent = weightArmour;
  document.getElementById(`weight-limit-items`).textContent  = weightItems;
  document.getElementById(`armament-weight-limit-weapon`).textContent = weightWeapon;
  document.getElementById(`armament-weight-limit-armour`).textContent = weightArmour;
  document.getElementById(`items-weight-limit`).textContent  = weightItems;

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
            else if(lSkill.match(/^フェイス/)){ //天恵
              copyLvUpToSkill(lSkill, classMain);
              type = 'faith';
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
    if(classes[type]?.type === 'fate'){ type = 'power'; }
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
    bg.toggle('faith',   type === 'faith'  );
    bg.toggle('add',     type === 'add'    );
    bg.toggle('geis',    type === 'geis'   );
    bg.toggle('power',   type === 'power'  );
    bg.toggle('another', type === 'another');
    
    let markFlag = 0; //自動計算マーク
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
    else if(name.match(/(^|[\/／])レガシーサイン/)){ autoCalcSkill['レガシーサイン'] = 1; }
    form[`skill${num}Name`].parentNode.classList.toggle('calc', markFlag);
  }
  document.getElementById('skills-lv-total').textContent = total;
  document.getElementById('gskills-lv-total').textContent = general - (autoCalcSkill['レガシーサイン'] || 0);
  expUse['skills'] = (general - 2) *5;

  calcSkillLvLimit();
  calcStt();
  calcExp();
}

// 最大スキルレベル計算 ----------------------------------------
function calcSkillLvLimit(){
  let num = skillsLvLimitAddType;
  document.getElementById('skills-lv-limit-add').textContent = (!num) ? '' : (num > 0) ? '+'+num : num;
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
  document.getElementById('armament-total-weight-weapon').textContent = weightW;
  document.getElementById('armament-total-weight-armour').textContent = weightA;
  document.getElementById('armament-total-acc-right').textContent = acc - accL;
  document.getElementById('armament-total-acc-left' ).textContent = acc - accR;
  document.getElementById('armament-total-atk-right').textContent = atk - atkL;
  document.getElementById('armament-total-atk-left' ).textContent = atk - atkR;
  document.getElementById('armament-total-eva'   ).textContent = eva ;
  document.getElementById('armament-total-def'   ).textContent = def ;
  document.getElementById('armament-total-mdef'  ).textContent = mdef;
  document.getElementById('armament-total-ini'   ).textContent = ini ;
  document.getElementById('armament-total-move'  ).textContent = move;

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
  document.getElementById('battle-total-acc' ).textContent = acc ;
  document.getElementById('battle-total-acc-right').textContent = acc - accL;
  document.getElementById('battle-total-acc-left' ).textContent = acc - accR;
  document.getElementById('battle-total-atk' ).textContent = atk ;
  document.getElementById('battle-total-atk-right').textContent = atk - atkL;
  document.getElementById('battle-total-atk-left' ).textContent = atk - atkR;
  document.getElementById('battle-total-eva' ).textContent = eva ;
  document.getElementById('battle-total-def' ).textContent = def ;
  document.getElementById('battle-total-mdef').textContent = mdef;
  document.getElementById('battle-total-ini' ).textContent = ini ;
  document.getElementById('battle-total-move').textContent = move;
  document.getElementById('battle-dice-acc').textContent = accDice;
  document.getElementById('battle-dice-atk').textContent = atkDice;
  document.getElementById('battle-dice-eva').textContent = evaDice;
}

// 特殊な判定計算 ----------------------------------------
function calcRolls(){
  document.getElementById('roll-trapdetect-total'  ).textContent = sttRoll['Sen'] + Number(form.rollTrapDetectSkill.value   )+ Number(form.rollTrapDetectOther.value  );
  document.getElementById('roll-traprelease-total' ).textContent = sttRoll['Dex'] + Number(form.rollTrapReleaseSkill.value  )+ Number(form.rollTrapReleaseOther.value );
  document.getElementById('roll-dengerdetect-total').textContent = sttRoll['Sen'] + Number(form.rollDangerDetectSkill.value )+ Number(form.rollDangerDetectOther.value);
  document.getElementById('roll-enemylore-total'   ).textContent = sttRoll['Int'] + Number(form.rollEnemyLoreSkill.value    )+ Number(form.rollEnemyLoreOther.value   );
  document.getElementById('roll-appraisal-total'   ).textContent = sttRoll['Int'] + Number(form.rollAppraisalSkill.value    )+ Number(form.rollAppraisalOther.value   );
  document.getElementById('roll-magic-total'       ).textContent = sttRoll['Int'] + Number(form.rollMagicSkill.value        )+ Number(form.rollMagicOther.value       );
  document.getElementById('roll-song-total'        ).textContent = sttRoll['Mnd'] + Number(form.rollSongSkill.value         )+ Number(form.rollSongOther.value        );
  document.getElementById('roll-alchemy-total'     ).textContent = sttRoll['Dex'] + Number(form.rollAlchemySkill.value      )+ Number(form.rollAlchemyOther.value     );

  document.getElementById('roll-trapdetect-total-dice'  ).textContent = Number(form.rollSenDice.value)+ Number(form.rollTrapDetectDiceAdd.value  );
  document.getElementById('roll-traprelease-total-dice' ).textContent = Number(form.rollDexDice.value)+ Number(form.rollTrapReleaseDiceAdd.value );
  document.getElementById('roll-dengerdetect-total-dice').textContent = Number(form.rollSenDice.value)+ Number(form.rollDangerDetectDiceAdd.value);
  document.getElementById('roll-enemylore-total-dice'   ).textContent = Number(form.rollIntDice.value)+ Number(form.rollEnemyLoreDiceAdd.value   );
  document.getElementById('roll-appraisal-total-dice'   ).textContent = Number(form.rollIntDice.value)+ Number(form.rollAppraisalDiceAdd.value   );
  document.getElementById('roll-magic-total-dice'       ).textContent = Number(form.rollIntDice.value)+ Number(form.rollMagicDiceAdd.value       );
  document.getElementById('roll-song-total-dice'        ).textContent = Number(form.rollMndDice.value)+ Number(form.rollSongDiceAdd.value        );
  document.getElementById('roll-alchemy-total-dice'     ).textContent = Number(form.rollDexDice.value)+ Number(form.rollAlchemyDiceAdd.value     );
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
  document.getElementById('items-weight-total').textContent = weight;
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
  document.getElementById("history-money-total").textContent = cash;
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
  document.getElementById('cashbook-total-value').textContent = cash;
  //document.getElementById('cashbook-deposit-value').textContent = deposit;
  //document.getElementById('cashbook-debt-value').textContent = debt;
  if(form.moneyAuto.checked){
    form.money.value = commify(cash);
    form.money.readOnly = true;
  }
  else {
    form.money.readOnly = false;
  }
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
  document.getElementById("exp-total").textContent = total;
  document.getElementById("exp-used-level" ).textContent = expUse['level' ] || 0;
  document.getElementById("exp-used-skill" ).textContent = expUse['skills' ] || 0;
  document.getElementById("exp-used-geises").textContent = expUse['geises'] || 0;
  document.getElementById("exp-used-connections").textContent = expUse['connections'] || 0;
  document.getElementById("exp-rest").textContent = rest;
  document.getElementById("history-exp-total").textContent = total;
  document.getElementById("history-payment-total").textContent = payment;
}

// スキル欄 ----------------------------------------
// 追加
function addSkill(){
  document.querySelector("#skills-table tfoot").before(createRow('skill','skillsNum'));
  checkClass();
}
// 削除
function delSkill(){
  if(delRow('skillsNum', '#skills-table tbody:last-of-type')){
    calcSkills();
  }
}
// ソート
(() => {
  let sortable = Sortable.create(document.getElementById('skills-table'), {
    group: "skills",
    dataIdAttr: 'id',
    animation: 150,
    handle: '.handle',
    filter: 'thead,tfoot,template',
    onSort: function(evt){ skillsSortAfter(); },
    onStart: function(evt){
      document.querySelectorAll('.trash-box').forEach((obj) => { obj.style.display = 'none' });
      document.getElementById('skills-trash').style.display = 'block';
    },
    onEnd: function(evt){
      if(!skillTrashNum) { document.getElementById('skills-trash').style.display = 'none' }
    },
  });

  let trashtable = Sortable.create(document.getElementById('skills-trash-table'), {
    group: "skills",
    dataIdAttr: 'id',
    animation: 150,
    filter: 'thead,tfoot,template',
  });

  let skillTrashNum = 0;
  function skillsSortAfter(){
    let num = 1;
    for(let id of sortable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      replaceSortedNames(row,num,/^(skill)(?:Trash)?[0-9]+(.+)$/);
      num++;
    }
    form.skillsNum.value = num-1;
    let del = 0;
    for(let id of trashtable.toArray()) {
      const row = document.querySelector(`tbody#${id}`);
      if(!row) continue;
      del++;
      replaceSortedNames(row,'Trash'+del,/^(skill)(?:Trash)?[0-9]+(.+)$/);
    }
    skillTrashNum = del;
    if(!del){ document.getElementById('skills-trash').style.display = 'none' }
    calcSkills();
  }
})();

// コネクション欄 ----------------------------------------
// 追加
function addConnection(){
  document.querySelector("#connections-table tbody").append(createRow('connection','connectionsNum'));
}
// 削除
function delConnection(){
  if(delRow('connectionsNum', '#connections-table tbody tr:last-of-type')){
    calcConnections();
  }
}
// ソート
setSortable('connection','#connections-table tbody','tr');

// 誓約欄 ----------------------------------------
// 追加
function addGeis(){
  document.querySelector("#geises-table tbody").append(createRow('geis','geisesNum'));
}
// 削除
function delGeis(){
  if(delRow('geisesNum', '#geises-table tbody tr:last-of-type')){
    calcGeises();
  }
}
// ソート
setSortable('geis','#geises-table tbody','tr');

// 履歴欄 ----------------------------------------
// 追加
function addHistory(){
  document.querySelector("#history-table tfoot").before(createRow('history','historyNum'));
}
// 削除
function delHistory(){
  if(delRow('historyNum', '#history-table tbody:last-of-type')){
    calcExp(); calcCash();
  }
}
// ソート
setSortable('history','#history-table','tbody');

