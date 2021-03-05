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
  
  footwork = 0;
  accuracyEnhance = 0;
  evasiveManeuver = 0;
  magicPowerEnhance = 0;
  alchemyEnhance = 0;
  shootersMartialArts = 0;
  tenacity = 0;
  capacity = 0;
  masteryMetalArmour = 0;
  masteryNonMetalArmour = 0;
  masteryShield = 0;
  masterySword = 0;
  masteryAxe = 0;
  masterySpear = 0;
  masteryMace = 0;
  masteryStaff = 0;
  masteryFlail = 0;
  masteryHammer = 0;
  masteryEntangle = 0;
  masteryGrapple = 0;
  masteryThrow = 0;
  masteryBow = 0;
  masteryCrossbow = 0;
  masteryBlowgun = 0;
  masteryGun = 0;
  masteryArtisan = 0;
  throwing = 0;
  songAddition = 0;
  
  const array = featsLv;
  let acquire = '';
  let featMax = level;
      featMax += checkSeekerBuildup('戦闘特技');
  for (let i = 0; i < array.length; i++) {
    let cL = document.getElementById("combat-feats-lv"+array[i]).classList;
    cL.remove("mark","error");
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
          if (f2 && lv['Fen'] >= 9) { (auto) ? box.value = "回避行動Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lv['Fen'] < 9) { (auto) ? box.value = "回避行動Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/^頑強/)){
        if(lv['Fig'] < 5 && lv['Gra'] < 5 && lv['Fen'] < 5){ cL.add("error"); }
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
        if(lv['Mys'] < 5){ cL.add("error"); }
        if(feat.match(/Ⅰ$/)){
          if (f2 && lv['Mys'] >= 7) { (auto) ? box.value = "スローイングⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lv['Mys'] < 7) { (auto) ? box.value = "スローイングⅠ" : cL.add("error") }
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
        if(!acquire.match('魔器習熟Ａ')){ cL.add("error"); }
      }
      else if (feat.match(/魔器の達人/)){
        if(!acquire.match('魔器習熟Ｓ')){ cL.add("error"); }
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
        if(lv['Gra'] < 9){ cL.add("error"); }
      }
      else if (feat.match(/斬り返し/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && (lv['Fig'] >= 7 || lv['Fen'] >= 7)) { (auto) ? box.value = "斬り返しⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || (lv['Fig'] < 7 && lv['Fen'] < 7)) { (auto) ? box.value = "斬り返しⅠ" : cL.add("error") }
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
          else if(f2 && (lv['Fig'] >= 9 || lv['Gra'] >= 9)){ (auto) ? box.value = "全力攻撃Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lv['Fig'] >= 15)               { (auto) ? box.value = "全力攻撃Ⅲ" : cL.add("mark") }
          else if(!f2 || (lv['Fig'] < 9 && lv['Gra'] < 9)) { (auto) ? box.value = "全力攻撃Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || (lv['Fig'] < 9 && lv['Gra'] < 9)) { (auto) ? box.value = "全力攻撃Ⅰ" : cL.add("error") }
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
          if (f2 && lv['Fen'] >= 7) { (auto) ? box.value = "挑発攻撃Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 ||  lv['Fen'] < 7) { (auto) ? box.value = "挑発攻撃Ⅰ" : cL.add("error") }
        }
      }
      else if (feat.match(/薙ぎ払い/)){
        if(feat.match(/Ⅰ$/)){
          if (f2 && lv['Fig'] >= 9) { (auto) ? box.value = "薙ぎ払いⅡ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if(!f2 || lv['Fig'] < 9) { (auto) ? box.value = "薙ぎ払いⅠ" : cL.add("error") }
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
          if     (f3 && lv['Fen'] >= 11) { (auto) ? box.value = "必殺攻撃Ⅲ" : cL.add("mark") }
          else if(f2 && level >=  7) { (auto) ? box.value = "必殺攻撃Ⅱ" : cL.add("mark") }
        }
        else if(feat.match(/Ⅱ$/)){
          if     (f3 && lv['Fen'] >= 11) { (auto) ? box.value = "必殺攻撃Ⅲ" : cL.add("mark") }
          else if(!f2 || level <  7) { (auto) ? box.value = "必殺攻撃Ⅰ" : cL.add("error") }
        }
        else if(feat.match(/Ⅲ$/)){
          if     (!f2 || level <  7) { (auto) ? box.value = "必殺攻撃Ⅰ" : cL.add("error") }
          else if(!f3 || lv['Fen'] < 11) { (auto) ? box.value = "必殺攻撃Ⅱ" : cL.add("error") }
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
      
      if     (feat === "足さばき"){ footwork = 1; }
      else if(feat === "回避行動Ⅰ"){ evasiveManeuver = 1; }
      else if(feat === "回避行動Ⅱ"){ evasiveManeuver = 2; }
      else if(feat === "命中強化Ⅰ"){ accuracyEnhance = 1; }
      else if(feat === "命中強化Ⅱ"){ accuracyEnhance = 2; }
      else if(feat === "魔力強化Ⅰ"){ magicPowerEnhance = 1; }
      else if(feat === "魔力強化Ⅱ"){ magicPowerEnhance = 2; }
      else if(feat === "賦術強化"){ alchemyEnhance = 1; }
      else if(feat === "頑強"){ tenacity += 15; }
      else if(feat === "超頑強"){ tenacity += 15; }
      else if(feat === "キャパシティ"){ capacity += 15; }
      else if(feat === "射手の体術"){ shootersMartialArts = 1; }
      else if(feat === "武器習熟Ａ／ソード"){ masterySword += 1; }
      else if(feat === "武器習熟Ａ／アックス"){ masteryAxe += 1; }
      else if(feat === "武器習熟Ａ／スピア"){ masterySpear += 1; }
      else if(feat === "武器習熟Ａ／メイス"){ masteryMace += 1; }
      else if(feat === "武器習熟Ａ／スタッフ"){ masteryStaff += 1; }
      else if(feat === "武器習熟Ａ／フレイル"){ masteryFlail += 1; }
      else if(feat === "武器習熟Ａ／ウォーハンマー"){ masteryHammer += 1; }
      else if(feat === "武器習熟Ａ／絡み"){ masteryEntangle += 1; }
      else if(feat === "武器習熟Ａ／格闘"){ masteryGrapple += 1; }
      else if(feat === "武器習熟Ａ／投擲"){ masteryThrow += 1; }
      else if(feat === "武器習熟Ａ／ボウ"){ masteryBow += 1; }
      else if(feat === "武器習熟Ａ／クロスボウ"){ masteryCrossbow += 1; }
      else if(feat === "武器習熟Ａ／ブロウガン"){ masteryBlowgun += 1; }
      else if(feat === "武器習熟Ａ／ガン"){ masteryGun += 1; }
      else if(feat === "武器習熟Ｓ／ソード"){ masterySword += 2; }
      else if(feat === "武器習熟Ｓ／アックス"){ masteryAxe += 2; }
      else if(feat === "武器習熟Ｓ／スピア"){ masterySpear += 2; }
      else if(feat === "武器習熟Ｓ／メイス"){ masteryMace += 2; }
      else if(feat === "武器習熟Ｓ／スタッフ"){ masteryStaff += 2; }
      else if(feat === "武器習熟Ｓ／フレイル"){ masteryFlail += 2; }
      else if(feat === "武器習熟Ｓ／ウォーハンマー"){ masteryHammer += 2; }
      else if(feat === "武器習熟Ｓ／絡み"){ masteryEntangle += 2; }
      else if(feat === "武器習熟Ｓ／格闘"){ masteryGrapple += 2; }
      else if(feat === "武器習熟Ｓ／投擲"){ masteryThrow += 2; }
      else if(feat === "武器習熟Ｓ／ボウ"){ masteryBow += 2; }
      else if(feat === "武器習熟Ｓ／クロスボウ"){ masteryCrossbow += 2; }
      else if(feat === "武器習熟Ｓ／ブロウガン"){ masteryBlowgun += 2; }
      else if(feat === "武器習熟Ｓ／ガン"){ masteryGun += 2; }
      else if(feat === "防具習熟Ａ／金属鎧"){ masteryMetalArmour += 1; }
      else if(feat === "防具習熟Ａ／非金属鎧"){ masteryNonMetalArmour += 1; }
      else if(feat === "防具習熟Ａ／盾"){ masteryShield += 1; }
      else if(feat === "防具習熟Ｓ／金属鎧"){ masteryMetalArmour += 2; }
      else if(feat === "防具習熟Ｓ／非金属鎧"){ masteryNonMetalArmour += 2; }
      else if(feat === "防具習熟Ｓ／盾"){ masteryShield += 2; }
      else if(feat === "魔器習熟Ａ"){ masteryArtisan += 1; }
      else if(feat === "魔器習熟Ｓ"){ masteryArtisan += 1; }
      else if(feat === "魔器の達人"){ masteryArtisan += 1; }
      else if(feat === "スローイングⅠ"){ throwing = 1; }
      else if(feat === "スローイングⅡ"){ throwing = 2; }
      
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
    let clv = (key === 'Wiz') ? Math.min(lv['Sor'],lv['Con']) : lv[key];
    if (classes[key]['craftData']){
      clv += checkSeekerBuildup(classes[key]['craftName']);
      const eName = classes[key]['craft'];
      document.getElementById("craft-"+eName).style.display = clv ? "block" : "none";
      const cMax = 20;
      for (let i = 1; i <= cMax; i++) {
        let cL = document.getElementById("craft-"+eName+i).classList;
        if ( (i <= clv)
          || (i <= clv+songAddition && key === 'Bar')
        ){
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
      clv += checkSeekerBuildup(classes[key]['magicName']);
      const eName = classes[key]['magic'];
      if(classes[key]['trancend']){
        document.getElementById("magic-"+eName).style.display = clv > 15 ? "block" : "none";
      }
      else {
        document.getElementById("magic-"+eName).style.display = clv ? "block" : "none";
      }
      const cMin = classes[key]['trancend'] ? 16 : 1;
      const cMax = 20;
      for (let i = cMin; i <= cMax; i++) {
        let cL = document.getElementById("magic-"+eName+i).classList;
        if(i <= clv){ cL.remove("fail","hidden"); }
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

// 名誉欄 ----------------------------------------
function calcHonor(){
  let pointTotal = 0;
  let mysticArtsPt = 0;
  const historyNum = form.historyNum.value;
  for (let i = 0; i <= historyNum; i++){
    const obj = form['history'+i+'Honor'];
    let point = safeEval(obj.value);
    if(isNaN(point)){
      obj.classList.add('error');
    }
    else {
      pointTotal += point;
      obj.classList.remove('error');
    }
  }
  let pointLost = 0;
  const dishonorItemsNum = form.dishonorItemsNum.value;
  for (let i = 1; i <= dishonorItemsNum; i++){
    let point = safeEval(form['dishonorItem'+i+'Pt'].value) || 0;
    pointLost += point;
  }
  pointTotal -= pointLost;
  const pointMax = pointTotal;
  let rank = '';
  for (let i = 0; i < adventurerRank.length; i++){
    if(adventurerRank[i]['num'] > pointTotal){ break; }
    rank = adventurerRank[i]['name'];
  }
  
  const honorItemsNum = form.honorItemsNum.value;
  for (let i = 1; i <= honorItemsNum; i++){
    let point = safeEval(form['honorItem'+i+'Pt'].value) || 0;
    pointTotal -= point;
  }
  const mysticArtsNum = form.mysticArtsNum.value;
  for (let i = 1; i <= mysticArtsNum; i++){
    let point = safeEval(form['mysticArts'+i+'Pt'].value) || 0;
    mysticArtsPt += point;
  }
  pointTotal -= mysticArtsPt;
  document.getElementById("honor-value"   ).innerHTML = pointTotal+' / '+pointMax;
  document.getElementById("honor-value-MA").innerHTML = pointTotal;
  document.getElementById("honor-rank").innerHTML = rank;
  document.getElementById("mystic-arts-honor-value").innerHTML = mysticArtsPt;
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
    <td><input type="number" name="dishonorItem${num}Pt" oninput="calcHonor()"></td>
  `;
  const target = document.querySelector("#dishonor-items-table tbody");
  target.appendChild(tbody, target);
  form.dishonorItemsNum.value = num;
}