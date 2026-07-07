// 画像 ----------------------------------------
// 全体表示
async function popImage(id = 1) {
  let imageBox = document.getElementById("image-box") || null;
  if(!imageBox){
    imageBox = document.createElement('div');
    imageBox.id = 'image-box';
    imageBox.addEventListener('click', () => { closeImage() });
    let imageSrc = document.createElement('img');
    imageSrc.id = "image-box-image";
    imageBox.append(imageSrc);
    document.body.append(imageBox);
    await new Promise((r) => setTimeout(r, 1));
  }
  if(typeof images !== 'undefined'){
    document.getElementById('image-box-image').src = images[id];
  }
  imageBox.style.bottom = 0;
  imageBox.style.opacity = 1;
}
function closeImage() {
  let imageBox = document.getElementById("image-box");
  imageBox.style.opacity = 0;
  setTimeout(function(){
    imageBox.style.bottom = '-100vh';
  },200);
}
// Prev/Nextボタン・スポイラー表示ボタン
window.addEventListener('DOMContentLoaded', ()=>{
  if(imageLayouts && Object.keys(imageLayouts).length > 1){
    let prev = document.createElement('span');
    prev.classList.add('prev-button');
    prev.addEventListener('click', () => { changeImage(-1) });
    let next = document.createElement('span');
    next.classList.add('next-button');
    next.addEventListener('click', () => { changeImage(1) });
    document.getElementById('image').append(prev, next);
  }
  if(imageLayouts && Object.keys(imageLayouts).length > 0){
    Object.keys(imageLayouts).forEach(id => {
      if(imageLayouts[id].spoiler){
        if(hasDeclaredAdultAge == 1 && (
          (imageLayouts[id].spoiler == 'R-18'  && alwaysShowSpoilers['R-18']  == 1) ||
          (imageLayouts[id].spoiler == 'R-18G' && alwaysShowSpoilers['R-18G'] == 1)
        )) {
          delete imageLayouts[id].spoiler;
        }
      }
    });
    const selectedLayout = imageLayouts[selectedImage] || {};
    const currentImage = document.querySelector('.image.current');
    if(selectedLayout.spoiler){
      currentImage?.append(createRemoveSpoilerButton(selectedImage, selectedLayout.spoiler));
    }
    else if(currentImage){
      delete currentImage.dataset.spoiler;
    }
  }
  // パートナー画像
  document.querySelectorAll(`.partner .image`).forEach(obj => {
    const spoiler = obj.dataset.spoiler || '';
    if(hasDeclaredAdultAge == 1 && (
      (spoiler == 'R-18'  && alwaysShowSpoilers['R-18']  == 1) ||
      (spoiler == 'R-18G' && alwaysShowSpoilers['R-18G'] == 1)
    )) {
      delete obj.dataset.spoiler;
    }
    else if(spoiler){
      obj.append(createRemoveSpoilerButton('', spoiler));
    }
  });
});
// スポイラー警告および表示ボタン生成
function createRemoveSpoilerButton(id, type = imageLayouts[id].spoiler) {
  let notes = document.createElement('div');
  notes.classList.add('spoiler-notes');
  if(type == 'R-18'   ){ notes.innerHTML = "<p>画像はR-18（成人向け／性的表現を含む）として設定されています。</p>" }
  if(type == 'R-18G'  ){ notes.innerHTML = "<p>画像はR-18G（成人向け／グロテスク表現を含む）として設定されています。</p>" }
  if(type == 'spoiler'){ notes.innerHTML = "<p>画像はネタバレのおそれのあるものとして設定されています。</p>" }

  if(hasDeclaredAdultAge == 1 || type == 'spoiler'){
    let button = document.createElement('span');
    button.textContent = "表示";
    button.classList.add('remove-spoiler-button');
    button.addEventListener('click', (e) => { 
      delete notes.parentNode.dataset.spoiler;
      if(id){ delete imageLayouts[id].spoiler; }
      notes.remove();
    });
    notes.append(button);
  }
  else {
    notes.innerHTML += `<small>18歳未満のユーザーには表示できません。</small>`;
    if(id) {
      notes.innerHTML += `<small>あなたが18歳以上である場合は、<a href="./?mode=option">閲覧設定</a>で設定してください。</small>`;
    }
  }
  return notes;
}
// 画像変更
function changeImage(direction = 0){
  const selected = getImageId(direction);

  if(images.hasOwnProperty(selected)){
    selectedImage = selected;
    
    const imageArea = document.querySelector('#image');
    let next = document.createElement('div');
    next.classList.add('image','next');
    next.style.backgroundImage    = `url(${images[selected]})`;
    next.style.backgroundSize     = imageLayouts[selected].fit;
    next.style.backgroundPosition = `${imageLayouts[selected].X} ${imageLayouts[selected].Y}`;
    next.innerHTML = `
      <div onclick="popImage('${selected}')">
        <p class="words" style="${imageLayouts[selected].wordsPosition}">${imageLayouts[selected].words}</p>
      </div>
      <p class="image-copyright">${imageLayouts[selected].copyright}</p>`;
    if(imageLayouts[selected].spoiler){
      next.dataset.spoiler = imageLayouts[selected].spoiler;
      next.append(createRemoveSpoilerButton(selectedImage));
    }
    next.addEventListener('transitionend', () => {
      next.classList.replace('next','current');
    });
    const img = new Image();
    img.src = images[selected];
    img.addEventListener('load', () => {
      document.querySelectorAll('#image .image').forEach(el => {
        el.addEventListener('transitionend', () => {
          el.remove();
        });
        el.style.opacity = 0;
      });
      imageArea.prepend(next);
    });

  }
}
function getImageId(direction = 0) {
  const ids =
    Object.keys(images)
    .filter(key => /^[0-9]+$/.test(key))
    .map(Number)
    .sort((a, b) => a - b);
  const index = ids.indexOf(Number(selectedImage));

  if (index === -1) return selectedImage;

  return ids[(index + direction + ids.length) % ids.length];
}
// 開閉系 ----------------------------------------
function closeTextareaForCopy() {
  document.getElementById('copyText-box').remove();
  document.getElementById('copyText-box-textarea').remove();
}
function popTextareaForCopy(text) {
  const div = document.createElement('div');
  div.id = 'copyText-box';
  div.onclick = closeTextareaForCopy;

  const textarea = document.createElement('textarea');
  textarea.id = 'copyText-box-textarea';
  textarea.value = text;

  document.getElementsByTagName('main')[0].appendChild(div);
  document.getElementsByTagName('main')[0].appendChild(textarea);

  textarea.focus();
  textarea.setSelectionRange(0, textarea.value.length);
}
function editOn() {
  document.querySelectorAll('.float-box:not(#login-form)').forEach(obj => { obj.classList.remove('show') });
  document.getElementById("login-form").classList.toggle('show');
}
function loglistOn() {
  document.querySelectorAll('.float-box:not(#loglist)').forEach(obj => { obj.classList.remove('show') });
  document.getElementById("loglist").classList.toggle('show');
}
function downloadListOn() {
  document.querySelectorAll('.float-box:not(#downloadlist)').forEach(obj => { obj.classList.remove('show') });
  document.getElementById("downloadlist").classList.toggle('show');
}
let cpOpenFirst = 0;
function chatPaletteOn() {
  document.querySelectorAll('.float-box:not(.chat-palette)').forEach(obj => { obj.classList.remove('show') });
  document.querySelector(".chat-palette").classList.toggle('show');
  if(!cpOpenFirst){ chatPaletteSelect(paletteTool); }
  cpOpenFirst++;
}
function chatPaletteSelect(tool) {
  const url = './?mode=palette&id='+sheetId+'&tool='+tool;
  fetch(url)
  .then(response => { return response.text(); })
  .then(text => { document.getElementById('chatPaletteBox').value = text; });
  document.querySelectorAll('.chat-palette-menu a').forEach(elm => {
    elm.classList.remove('check');
  });
  document.getElementById('cp-switch-'+(tool||'ytc')).classList.add('check');
}
// セッション履歴開閉 ----------------------------------------
let historyView = true;
window.addEventListener('DOMContentLoaded', ()=>{
  if(document.querySelector("#history tbody:nth-of-type(9)")){
    historyView = false,
    switchHistoryClose();
  document.querySelector('#history .open-button').dataset.open = '';
  }
});
function switchHistoryView(){
  historyView = !historyView;
  historyView ? switchHistoryOpen() : switchHistoryClose();
  document.querySelector('#history .open-button').dataset.open = historyView ? 'true' : '';
}
function switchHistoryOpen(){
  const table = document.querySelector('#history > table');
  // 表示
  table.querySelectorAll('tbody').forEach(row => {
    row.style.display = "";
  });
  // 省略業を削除
  document.getElementById('collapsed-history-row').remove();
}
function switchHistoryClose(){
  const table = document.querySelector('#history > table');
  rows = table.querySelectorAll('tbody:not(:nth-of-type(-n+1)):not(:nth-last-of-type(-n+5))');
  // 最下部以外を非表示
  rows.forEach(row => {
    row.style.display = "none";
  });
  // 省略行を生成
  const theadRow = table.querySelector("thead tr");
  colLength = theadRow.children.length
  const newTbody = document.createElement("tbody");
  newTbody.id = "collapsed-history-row";
  const newCell = document.createElement("td");
  newCell.colSpan = colLength;
  newCell.innerText = "︙\n省略されたセッション履歴\n︙";
  newTbody.appendChild(newCell);
  if (rows.length < 1) {
    table.appendChild(newTbody);
  } else {
    table.insertBefore(newTbody, rows[0]);
  }
}

// 収支履歴開閉 ----------------------------------------
let cashbookView = false;
function switchCashbookView(num = ""){
  cashbookView = !cashbookView;
  document.getElementById('cashbook'+num).dataset.open = cashbookView ? 'true' : '';
  document.querySelector(`#cashbook${num} .open-button`).dataset.open = cashbookView ? 'true' : '';
}

// スクロール位置 ----------------------------------------
window.addEventListener('DOMContentLoaded', ()=>{
  document.querySelector('.header-back-name').addEventListener('click', ()=>{
    window.scroll({
      top: 0,
      behavior: "smooth",
    });
  })
});

// ルビ ----------------------------------------
window.addEventListener('load', ()=>{
  if (rubyCopyMode == 0){
    document.querySelectorAll('ruby:has(rp:nth-of-type(3):last-child)').forEach(ruby => {
      ruby.querySelector('ruby rp:nth-of-type(1)').textContent = '';
      ruby.querySelector('ruby rp:nth-of-type(2)').textContent = '(';
      ruby.querySelector('ruby rp:nth-of-type(3)').textContent = ')';
    });
  }
});

// シングルカラムモード ----------------------------------------
if(localStorage.getItem("singleColumnMode") == 1){
  const observer = new MutationObserver((mutations, observer) => {
    const targetElement = document.body;

    if (targetElement) {
      document.body.classList.remove('wide');
      observer.disconnect();
    }
  });

  observer.observe(document.documentElement, {
    childList: true,
    subtree: true
  });
}
