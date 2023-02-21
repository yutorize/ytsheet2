"use strict";
modeZero = 1;

// 求道者 ----------------------------------------
function checkSeekerBuildup(name){
  let add = 0;
  for (let i = 1; i <= 5; i++){
    if (i === 1 && lvSeeker <  3) break;
    if (i === 2 && lvSeeker <  7) break;
    if (i === 3 && lvSeeker < 11) break;
    if (i === 4 && lvSeeker < 15) break;
    if (i === 5 && lvSeeker < 19) break;
    if(form['seekerBuildup'+i].value === name){ add++ }
  }
  return add;
}
function checkSeekerAbility(name){
  for (let i = 1; i <= 5; i++){
    if (i === 1 && lvSeeker <  4) break;
    if (i === 2 && lvSeeker <  8) break;
    if (i === 3 && lvSeeker < 12) break;
    if (i === 4 && lvSeeker < 16) break;
    if (i === 5 && lvSeeker < 20) break;
    if(form['seekerAbility'+i].value === name){ return 1 }
  }
  return 0;
}
function checkSeeker(){
  if(lvSeeker){
    document.getElementById('seeker-buildup1').classList.toggle('hidden', !form.failView.checked && lvSeeker <  3);
    document.getElementById('seeker-buildup2').classList.toggle('hidden', !form.failView.checked && lvSeeker <  7);
    document.getElementById('seeker-buildup3').classList.toggle('hidden', !form.failView.checked && lvSeeker < 11);
    document.getElementById('seeker-buildup4').classList.toggle('hidden', !form.failView.checked && lvSeeker < 15);
    document.getElementById('seeker-buildup5').classList.toggle('hidden', !form.failView.checked && lvSeeker < 19);
    document.querySelector('#seeker-buildup1 + dd').classList.toggle('hidden', !form.failView.checked && lvSeeker <  3);
    document.querySelector('#seeker-buildup2 + dd').classList.toggle('hidden', !form.failView.checked && lvSeeker <  7);
    document.querySelector('#seeker-buildup3 + dd').classList.toggle('hidden', !form.failView.checked && lvSeeker < 11);
    document.querySelector('#seeker-buildup4 + dd').classList.toggle('hidden', !form.failView.checked && lvSeeker < 15);
    document.querySelector('#seeker-buildup5 + dd').classList.toggle('hidden', !form.failView.checked && lvSeeker < 19);
    document.querySelector('#seeker-buildup1 + dd').classList.toggle('fail', lvSeeker <  3);
    document.querySelector('#seeker-buildup2 + dd').classList.toggle('fail', lvSeeker <  7);
    document.querySelector('#seeker-buildup3 + dd').classList.toggle('fail', lvSeeker < 11);
    document.querySelector('#seeker-buildup4 + dd').classList.toggle('fail', lvSeeker < 15);
    document.querySelector('#seeker-buildup5 + dd').classList.toggle('fail', lvSeeker < 19);
    
    document.querySelector('#seeker-ability1').classList.toggle('hidden', !form.failView.checked && lvSeeker <  4);
    document.querySelector('#seeker-ability2').classList.toggle('hidden', !form.failView.checked && lvSeeker <  8);
    document.querySelector('#seeker-ability3').classList.toggle('hidden', !form.failView.checked && lvSeeker < 12);
    document.querySelector('#seeker-ability4').classList.toggle('hidden', !form.failView.checked && lvSeeker < 16);
    document.querySelector('#seeker-ability5').classList.toggle('hidden', !form.failView.checked && lvSeeker < 20);
    document.querySelector('#seeker-ability1').classList.toggle('fail', lvSeeker <  4);
    document.querySelector('#seeker-ability2').classList.toggle('fail', lvSeeker <  8);
    document.querySelector('#seeker-ability3').classList.toggle('fail', lvSeeker < 12);
    document.querySelector('#seeker-ability4').classList.toggle('fail', lvSeeker < 16);
    document.querySelector('#seeker-ability5').classList.toggle('fail', lvSeeker < 20);
  }
  else {
    document.querySelectorAll('dt[id^="seeker-buildup"], dt[id^="seeker-buildup"]+dd').forEach(obj => {
      obj.classList.add('hidden');
    });
    document.getElementById('seeker-abilities').classList.add('hidden');
  }
}

// 戦闘特技チェック ----------------------------------------
function checkFeats(){
  checkSeeker();

  Object.keys(feats).forEach(key => { feats[key] = 0; });
  
  const array = featsLv;
  let acquire = '';
  let featMax = level;
      featMax += checkSeekerBuildup('戦闘特技');
  for (let i = 0; i < array.length; i++) {
    let cL = document.getElementById("combat-feats-lv"+array[i]).classList;
    cL.remove("mark","error");
    if(array[i].match(/bat/) && lv['Bat'] <= 0){
      cL.add('hidden');
      continue;
    }
    const featLv = Number( array[i].replace(/[^0-9]/g, '') );
    if(featLv > 15){
      document.getElementById("combat-feats-lv"+array[i]).dataset.lv = (featLv > level) ? '+' : array[i];
    }
    if(featMax >= featLv){
      const f2 = (array[i+1] && featMax >= Number( array[i+1].replace(/[^0-9]/g, '') )) ? 1 : 0; //次枠の開放状況
      const f3 = (array[i+2] && featMax >= Number( array[i+2].replace(/[^0-9]/g, '') )) ? 1 : 0; //次々枠の開放状況
      const box = form["combatFeatsLv"+array[i]];
      const auto = form.featsAutoOn.checked;
      let feat = box.options[box.selectedIndex].value;
      acquire += feat + ',';
      
      if (feat.match(/足さばき/)){
        if(level < 9){ cL.add("error"); }
      }
      else if (feat.match(/ガーディアン/)){
        if(level < 9 || !acquire.match('かばう')){ cL.add("error"); }
      }
      else if (feat.match(/回避行動/)){
        if(level < 3){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && (lv['Fen'] >= 9 || lv['Bat'] >= 9)) { (auto) ? box.value = "回避行動Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || (lv['Fen'] < 9 && lv['Bat'] < 9)) { (auto) ? box.value = "回避行動Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/^頑強/)){
        if(lv['Fig'] < 5 && lv['Gra'] < 5 && lv['Fen'] < 5 && lv['Bat'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/超頑強/)){
        if((lv['Fig'] < 7 && lv['Gra'] < 7)|| !acquire.match('頑強')){ cL.add("error"); }
      }
      else if (feat.match(/キャパシティ/)){
        if(level < 11){ cL.add("error"); }
      }
      else if (feat.match(/自己占瞳/)){
        if(lv['Mys'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/射手の体術/)){
        if(lv['Sho'] < 7){ cL.add("error"); }
      }
      else if (feat.match(/スローイング/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 5) { (auto) ? box.value = "スローイングⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 5) { (auto) ? box.value = "スローイングⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/占瞳操作/)){
        if(lv['Mys'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/双撃/)){
        if(!acquire.match('両手利き')){ cL.add("error"); }
      }
      else if (feat.match(/代償軽減/)){
        if(lv['Mys'] < 3){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && lv['Mys'] >= 7) { (auto) ? box.value = "代償軽減Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lv['Mys'] < 7) { (auto) ? box.value = "代償軽減Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/鷹の目/)){
        if(!acquire.match(/精密射撃|魔法誘導/)){ cL.add("error"); }
      }
      else if (feat.match(/鉄壁/)){
        if(!acquire.match('かばう')){ cL.add("error"); }
      }
      else if (feat.match(/跳び蹴り/)){
        if(lv['Gra'] < 9){ cL.add("error"); }
      }
      else if (feat.match(/投げ強化/)){
        if(lv['Gra'] < 3){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && lv['Gra'] >= 9) { (auto) ? box.value = "投げ強化Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lv['Gra'] < 9) { (auto) ? box.value = "投げ強化Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/二刀流/)){
        if(level < 5 || !acquire.match('両手利き')){ cL.add("error"); }
      }
      else if (feat.match(/二刀無双/)){
        if(level < 11 || !acquire.match('二刀流')){ cL.add("error"); }
      }
      else if (feat.match(/ハーモニー/)){
        if(lv['Bar'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/武器習熟Ｓ／(.*)/)){
        if(level < 5 || !(acquire.match('武器習熟Ａ／' + RegExp.$1))){ cL.add("error"); }
      }
      else if (feat.match(/武器の達人/)){
        if(level < 11 || !(acquire.match('武器習熟Ｓ／'))){ cL.add("error"); }
      }
      else if (feat.match(/賦術強化/)){
        if(lv['Alc'] < 7){ cL.add("error"); }
      }
      else if (feat.match(/賦術の極意/)){
        if(lv['Alc'] < 7){ cL.add("error"); }
      }
      else if (feat.match(/踏みつけ/)){
        if(lv['Gra'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/ブロッキング/)){
        if(level < 3){ cL.add("error"); }
      }
      else if (feat.match(/防具習熟Ｓ／(.*)/)){
        if(level < 5 || !acquire.match('防具習熟Ａ／' + RegExp.$1)){ cL.add("error"); }
      }
      else if (feat.match(/防具の達人/)){
        if(level < 11 || !acquire.match('防具習熟Ｓ／')){ cL.add("error"); }
      }
      else if (feat.match(/魔器習熟Ｓ/)){
        if(lv['Art'] < 5 || !acquire.match('魔器習熟Ａ')){ cL.add("error"); }
      }
      else if (feat.match(/魔器の達人/)){
        if(lv['Art'] < 11 || !acquire.match('魔器習熟Ｓ')){ cL.add("error"); }
      }
      else if (feat.match(/魔導書習熟Ｓ/)){
        if(!acquire.match('魔導書習熟Ａ')){ cL.add("error"); }
      }
      else if (feat.match(/魔導書の達人/)){
        if(lv['Gri'] < 11 || !acquire.match('魔導書習熟Ｓ')){ cL.add("error"); }
      }
      else if (feat.match(/魔晶石の達人/)){
        if(level < 9){ cL.add("error"); }
      }
      else if (feat.match(/マリオネット/)){
        if(level < 5){ cL.add("error"); }
      }
      else if (feat.match(/魔力強化/)){
        if(levelCasters[1] < 6){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 11 && levelCasters[1] >= 10) { (auto) ? box.value = "魔力強化Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 11 || levelCasters[1] < 10) { (auto) ? box.value = "魔力強化Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/マルチガード/)){
        if(level < 7 || !acquire.match('かばう')){ cL.add("error"); }
      }
      else if (feat.match(/命中強化/)){
        if(level < 7){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 13) { (auto) ? box.value = "命中強化Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 13) { (auto) ? box.value = "命中強化Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/連続賦術/)){
        if(lv['Alc'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/練体の極意/)){
        if(lv['Enh'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/ＭＰ軽減/)){
        if(level < 5){ cL.add("error"); }
      }
      else if (feat.match(/インファイト/)){
        if(lv['Gra'] < 5){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && lv['Gra'] >= 9) { (auto) ? box.value = "インファイトⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lv['Gra'] < 9) { (auto) ? box.value = "インファイトⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/カード軽減/)){
        if(lv['Alc'] < 5){ cL.add("error"); }
      }
      else if (feat.match(/影矢/)){
        if(lv['Sho'] < 9){ cL.add("error"); }
      }
      else if (feat.match(/かばう/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && level >= 9) { (auto) ? box.value = "かばうⅢ" : cL.add("mark") }
          else if(f2 && level >= 5) { (auto) ? box.value = "かばうⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && level >= 9) { (auto) ? box.value = "かばうⅢ" : cL.add("mark") }
          else if(!f2 || level < 5) { (auto) ? box.value = "かばうⅠ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || level < 5) { (auto) ? box.value = "かばうⅠ" : cL.add("error") }
          else if(!f3 || level < 9) { (auto) ? box.value = "かばうⅡ" : cL.add("error") }
        }
      }
      else if (feat.match(/牙折り/)){
        if(lv['Gra'] < 9 && lv['Bat'] < 9){ cL.add("error"); }
      }
      else if (feat.match(/斬り返し/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && (lv['Fig'] >= 7 || lv['Fen'] >= 7 || lv['Bat'] >= 7)) { (auto) ? box.value = "斬り返しⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || (lv['Fig'] < 7 && lv['Fen'] < 7 && lv['Bat'] < 7)) { (auto) ? box.value = "斬り返しⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/牽制攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && level >= 11) { (auto) ? box.value = "牽制攻撃Ⅲ" : cL.add("mark") }
          else if(f2 && level >=  7) { (auto) ? box.value = "牽制攻撃Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && level >= 11) { (auto) ? box.value = "牽制攻撃Ⅲ" : cL.add("mark") }
          else if(!f2 || level <  7) { (auto) ? box.value = "牽制攻撃Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || level <  7) { (auto) ? box.value = "牽制攻撃Ⅰ" : cL.add("error") }
          else if(!f3 || level < 11) { (auto) ? box.value = "牽制攻撃Ⅱ" : cL.add("error") }
        }
      }
      else if (feat.match(/全力攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && lv['Fig'] >= 15)               { (auto) ? box.value = "全力攻撃Ⅲ" : cL.add("mark") }
          else if(f2 && (lv['Fig'] >= 9 || lv['Gra'] >= 9 || lv['Bat'] >= 9)){ (auto) ? box.value = "全力攻撃Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lv['Fig'] >= 15)               { (auto) ? box.value = "全力攻撃Ⅲ" : cL.add("mark") }
          else if(!f2 || (lv['Fig'] < 9 && lv['Gra'] < 9 && lv['Bat'] < 9)) { (auto) ? box.value = "全力攻撃Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || (lv['Fig'] < 9 && lv['Gra'] < 9 && lv['Bat'] < 9)) { (auto) ? box.value = "全力攻撃Ⅰ" : cL.add("error") }
          else if(!f3 || lv['Fig'] < 15)               { (auto) ? box.value = "全力攻撃Ⅱ" : cL.add("error") }
        }
      }
      else if (feat.match(/双占瞳/)){
        if(lv['Mys'] < 7){ cL.add("error"); }
      }
      else if (feat.match(/ダブルキャスト/)){
        if(levelCasters[0] < 9){ cL.add("error"); }
      }
      else if (feat.match(/挑発攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && (lv['Fen'] >= 7 || lv['Bat'] >= 7)) { (auto) ? box.value = "挑発攻撃Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || (lv['Fen'] <  7 &&  lv['Bat'] < 7)) { (auto) ? box.value = "挑発攻撃Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/薙ぎ払い/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && (lv['Fig'] >= 9 || lv['Bat'] >= 9)) { (auto) ? box.value = "薙ぎ払いⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || (lv['Fig'] < 9 && lv['Bat'] < 9)) { (auto) ? box.value = "薙ぎ払いⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/バイオレントキャスト/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && level >= 13) { (auto) ? box.value = "バイオレントキャストⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || level < 13) { (auto) ? box.value = "バイオレントキャストⅠ" : cL.add("error") }
        }
      }
      else if (feat.match(/必殺攻撃/)){
        if(feat.match(/Ⅰ$/)){
          if     (f3 && (lv['Fen'] >= 11 || lv['Bat'] >= 11)) { (auto) ? box.value = "必殺攻撃Ⅲ" : cL.add("mark") }
          else if(f2 && level >=  7) { (auto) ? box.value = "必殺攻撃Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && (lv['Fen'] >= 11 || lv['Bat'] >= 11)) { (auto) ? box.value = "必殺攻撃Ⅲ" : cL.add("mark") }
          else if(!f2 || level <  7) { (auto) ? box.value = "必殺攻撃Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || level <  7) { (auto) ? box.value = "必殺攻撃Ⅰ" : cL.add("error") }
          else if(!f3 || (lv['Fen'] < 11 && lv['Bat'] < 11)) { (auto) ? box.value = "必殺攻撃Ⅱ" : cL.add("error") }
        }
      }
      else if (feat.match(/マルチアクション/)){
        if(level < 5){ cL.add("error"); }
      }
      else if (feat.match(/魔法拡大すべて/)){
        if(!acquire.match('魔法拡大／')){ cL.add("error"); }
      }
      else if (feat.match(/魔法制御/)){
        if(!acquire.match('魔法誘導') || !acquire.match('魔法収束')){ cL.add("error"); }
      }
      feat = box.options[box.selectedIndex].value;
      
      const weaponsRegex = new RegExp('武器習熟(Ａ|Ｓ)／(' + weapons.join('|') + ')');
      if     (feat === "足さばき"){ feats['足さばき'] = 1; }
      else if(feat === "回避行動Ⅰ"){ feats['回避行動'] = 1; }
      else if(feat === "回避行動Ⅱ"){ feats['回避行動'] = 2; }
      else if(feat === "心眼"){ feats['心眼'] = 4; }
      else if(feat === "命中強化Ⅰ"){ feats['命中強化'] = 1; }
      else if(feat === "命中強化Ⅱ"){ feats['命中強化'] = 2; }
      else if(feat === "魔力強化Ⅰ"){ feats['魔力強化'] = 1; }
      else if(feat === "魔力強化Ⅱ"){ feats['魔力強化'] = 2; }
      else if(feat === "賦術強化"){ feats['賦術強化'] = 1; }
      else if(feat === "頑強")  { feats['頑強'] += 15; }
      else if(feat === "超頑強"){ feats['頑強'] += 15; }
      else if(feat === "キャパシティ"){ feats['キャパシティ'] += 15; }
      else if(feat === "射手の体術"){ feats['射手の体術'] = 1; }
      else if(feat.match(weaponsRegex)){
        feats['武器習熟／'+RegExp.$2] ||= 0;
        if     (RegExp.$1 === 'Ａ'){ feats['武器習熟／'+RegExp.$2] += 1; }
        else if(RegExp.$1 === 'Ｓ'){ feats['武器習熟／'+RegExp.$2] += 2; }
      }
      else if(feat.match(/防具習熟(Ａ|Ｓ)／(金属鎧|非金属鎧|盾)/)){
        feats['防具習熟／'+RegExp.$2] ||= 0;
        if     (RegExp.$1 === 'Ａ'){ feats['防具習熟／'+RegExp.$2] += 1; }
        else if(RegExp.$1 === 'Ｓ'){ feats['防具習熟／'+RegExp.$2] += 2; }
      }
      else if(feat === "魔器習熟Ａ"){ feats['魔器習熟'] += 1; }
      else if(feat === "魔器習熟Ｓ"){ feats['魔器習熟'] += 1; }
      else if(feat === "魔器の達人"){ feats['魔器習熟'] += 1; }
      else if(feat === "スローイングⅠ"){ feats['スローイング'] = 1; }
      else if(feat === "スローイングⅡ"){ feats['スローイング'] = 2; }
      
      cL.remove("fail","hidden");
    }
    else {
      cL.add("fail");
      if(form.failView.checked && featLv <= 17){
        cL.remove("hidden")
      }
      else if(form.failView.checked && (lvSeeker)) {
        cL.remove("hidden")
      }
      else {
        cL.add("hidden")
      }
    }
  }
  
  calcSubStt();
  calcMobility();
  calcMagic();
  calcAttack();
  calcDefense();
  checkCraft();
}

// 技芸 ----------------------------------------
function checkCraft() {
  Object.keys(classes).forEach(function(key) {
    let cLv = lv[key];
    if (classes[key]['craftData']){
      const eName = classes[key]['craft'];
      document.getElementById("craft-"+eName).style.display = cLv ? "block" : "none";
      const cMax = 20;
      cLv += checkSeekerBuildup(classes[key]['craftName']);
      cLv += (key === 'Art' && lv.Art >= 17) ? 2 : (key === 'Art' && lv.Art >= 16) ? 1 : 0;
      for (let i = 1; i <= cMax; i++) {
        let cL = document.getElementById("craft-"+eName+i).classList;
        if (i <= cLv){
          cL.remove("fail","hidden");
        }
        else {
          cL.add("fail");
          if(form.failView.checked && i <= 17){
            cL.remove("hidden")
          }
          else if(form.failView.checked && (lvSeeker)) {
            cL.remove("hidden")
          }
          else {
            cL.add("hidden")
          }
        }
      }
    }
    else if (classes[key]['magicData']){
      cLv += checkSeekerBuildup(classes[key]['magicName']);
      const eName = classes[key]['magic'];
      if(classes[key]['trancend']){
        document.getElementById("magic-"+eName).style.display = cLv > 15 ? "block" : "none";
      }
      else {
        document.getElementById("magic-"+eName).style.display = cLv ? "block" : "none";
      }
      const cMin = classes[key]['trancend'] ? 16 : 1;
      const cMax = 20;
      for (let i = cMin; i <= cMax; i++) {
        let cL = document.getElementById("magic-"+eName+i).classList;
        if(i <= cLv){ cL.remove("fail","hidden"); }
        else {
          cL.add("fail");
          if(form.failView.checked && i <= 17){
            cL.remove("hidden")
          }
          else if(form.failView.checked && (lvSeeker)) {
            cL.remove("hidden")
          }
          else {
            cL.add("hidden")
          }
        }
      }
    }
  });
  calcFairy();
}

// 妖精魔法 ----------------------------------------
function calcFairy(){
  const flv = lv['Fai'];  
  const a1 = Number(form.fairyContractEarth.value);
  const a2 = Number(form.fairyContractWater.value);
  const a3 = Number(form.fairyContractFire.value );
  const a4 = Number(form.fairyContractWind.value );
  const a5 = Number(form.fairyContractLight.value);
  const a6 = Number(form.fairyContractDark.value );  
  document.getElementById('fairy-sim-url').href = "http://yutorize.2-d.jp/ft_sim/?ft="
    + flv.toString(18)
    + a1.toString(18)
    + a2.toString(18)
    + a3.toString(18)
    + a4.toString(18)
    + a5.toString(18)
    + a6.toString(18);
}

// 秘伝欄 ----------------------------------------
// 追加
function addMysticArts(){
  let num = Number(form.mysticArtsNum.value) + 1;
  let tbody = document.createElement('li');
  tbody.setAttribute('id',idNumSet('mystic-arts'));
  tbody.innerHTML = `
    <span class="handle"></span>
    <input type="text" name="mysticArts${num}">
    <span class="honor-pt">
      <select name="mysticArts${num}PtType" oninput="calcHonor()" data-type="human">
      <option value="">人族名誉点
      <option value="barbaros">蛮族名誉点
      <option value="dragon">盟竜点
      </select>
      <span class="honor-select-view"></span>
      <input type="number" name="mysticArts${num}Pt" oninput="calcHonor()">
    </span>
  `;
  const target = document.querySelector("#mystic-arts-list");
  target.appendChild(tbody, target);
  form.mysticArtsNum.value = num;
}

// 名誉欄 ----------------------------------------
function calcHonor(){
  let pointTotal = {
    'human'   : safeEval(form['history0Honor'].value)  || 0,
    'barbaros': safeEval(form['history0HonorB'].value) || 0,
    'dragon'  : safeEval(form['history0HonorD'].value) || 0
  };
  const historyNum = form.historyNum.value;
  for (let i = 1; i <= historyNum; i++){
    const obj = form['history'+i+'Honor'];
    let point = safeEval(obj.value);
    if(isNaN(point)){
      obj.classList.add('error');
    }
    else {
      let type  = form['history'+i+'HonorType'].value || 'human';
      form['history'+i+'HonorType'].dataset.type = type;
      pointTotal[type] += point;
      obj.classList.remove('error');
    }
  }
  let pointLost = { 'human':0, 'barbaros':0, 'dragon':0 };
  const dishonorItemsNum = form.dishonorItemsNum.value;
  for (let i = 1; i <= dishonorItemsNum; i++){
    let point = safeEval(form['dishonorItem'+i+'Pt'].value) || 0;
    let type  = form['dishonorItem'+i+'PtType'].value || 'human';
    form['dishonorItem'+i+'PtType'].dataset.type = type;
    pointLost[type] += point;
  }
  pointTotal['human']    -= pointLost['human'];
  pointTotal['barbaros'] -= pointLost['barbaros'];
  pointTotal['dragon']   -= pointLost['dragon'];
  const pointMax = { ... pointTotal };
  
  const honorItemsNum = form.honorItemsNum.value;
  for (let i = 1; i <= honorItemsNum; i++){
    let point = safeEval(form['honorItem'+i+'Pt'].value) || 0;
    let type  = form['honorItem'+i+'PtType'].value || 'human';
    form['honorItem'+i+'PtType'].dataset.type = type;
    pointTotal[type] -= point;
  }
  let mysticArtsPt = { 'human':0, 'barbaros':0, 'dragon':0 };
  const mysticArtsNum = form.mysticArtsNum.value;
  for (let i = 1; i <= mysticArtsNum; i++){
    let point = safeEval(form['mysticArts'+i+'Pt'].value) || 0;
    let type  = form['mysticArts'+i+'PtType'].value || 'human';
    form['mysticArts'+i+'PtType'].dataset.type = type;
    if(type === 'hu+ba'){
      mysticArtsPt['human']    += point;
      mysticArtsPt['barbaros'] += point;
    }
    else {
      mysticArtsPt[type] += point;
    }
  }
  pointTotal['human']    -= mysticArtsPt['human'];
  pointTotal['barbaros'] -= mysticArtsPt['barbaros'];
  pointTotal['dragon']   -= mysticArtsPt['dragon'];
  document.getElementById("honor-value"   ).innerHTML = pointTotal['human']+' / '+pointMax['human'];
  document.getElementById("honor-value-MA").innerHTML = pointTotal['human'];
  document.getElementById("honor-barbaros-value").innerHTML = pointTotal['barbaros']+' / '+pointMax['barbaros'];
  document.getElementById("honor-dragon-value").innerHTML = pointTotal['dragon']+' / '+pointMax['dragon'];
  document.getElementById("mystic-arts-honor-value").innerHTML = mysticArtsPt['human']+'／'+mysticArtsPt['barbaros']+'／'+mysticArtsPt['dragon'];
}
// 追加
function addHonorItems(){
  let num = Number(form.honorItemsNum.value) + 1;
  let tbody = document.createElement('tr');
  tbody.setAttribute('id',idNumSet('honor-item'));
  tbody.innerHTML = `
    <td class="handle"></td>
    <td><input type="text" name="honorItem${num}"></td>
    <td>
      <span class="honor-pt">
        <select name="honorItem'.$num.'PtType" oninput="calcHonor()" data-type="human">
          <option value="">人族名誉点
          <option value="barbaros">蛮族名誉点
          <option value="dragon">盟竜点
        </select>
        <span class="honor-select-view"></span>
        <input type="number" name="honorItem${num}Pt" oninput="calcHonor()">
      </span>
    </td>
  `;
  const target = document.querySelector("#honor-items-table");
  target.appendChild(tbody, target);
  form.honorItemsNum.value = num;
}
// 不名誉欄 ----------------------------------------
function calcDishonor(){
}
function addDishonorItems(){
  let num = Number(form.dishonorItemsNum.value) + 1;
  let tbody = document.createElement('tr');
  tbody.setAttribute('id',idNumSet('dishonor-item'));
  tbody.innerHTML = `
    <td class="handle"></td>
    <td><input type="text" name="dishonorItem${num}"></td>
    <td>
      <span class="honor-pt">
        <select name="dishonorItem${num}PtType" oninput="calcHonor()" data-type="human">
          <option value="" selected>人族名誉点
          <option value="barbaros">蛮族名誉点
          <option value="dragon">盟竜点
        </select>
        <span class="honor-select-view"></span>
        <input type="number" name="dishonorItem${num}Pt" oninput="calcHonor()">
      </span>
    </td>
  `;
  const target = document.querySelector("#dishonor-items-table tbody");
  target.appendChild(tbody, target);
  form.dishonorItemsNum.value = num;
}
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
    <td><input name="history${num}Exp"    type="text" oninput="calcExp()"></td>
    <td><input name="history${num}Money"  type="text" oninput="calcCash()"></td>
    <td>
      <span class="honor-pt">
        <select name="history${num}HonorType" oninput="calcHonor()" data-type="human">
          <option value="">人族名誉点
          <option value="barbaros">蛮族名誉点
          <option value="dragon">盟竜点
        </select>
        <span class="honor-select-view"></span>
        <input name="history${num}Honor"  type="text" oninput="calcHonor()">
      </span>
    </td>
    <td><input name="history${num}Grow"   type="text" oninput="calcStt()" list="list-grow"></td>
    <td><input name="history${num}Gm"     type="text"></td>
    <td><input name="history${num}Member" type="text"></td>
  </tr>
  <tr><td colspan="6" class="left"><input name="history${num}Note" type="text"></td></tr>`;
  const target = document.querySelector("#history-table tfoot");
  target.parentNode.insertBefore(tbody, target);
  
  form.historyNum.value = num;
}