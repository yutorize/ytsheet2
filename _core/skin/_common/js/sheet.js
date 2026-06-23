// 開閉系 ----------------------------------------
async function popImage(id) {
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
    id ||= 1;
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
