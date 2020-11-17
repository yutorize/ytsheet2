// 開閉系
function popImage() {
  document.getElementById("image-box").style.bottom = 0;
  document.getElementById("image-box").style.opacity = 1;
}
function closeImage() {
  document.getElementById("image-box").style.opacity = 0;
  setTimeout(function(){
    document.getElementById("image-box").style.bottom = '-100vh';
  },200);
}
function editOn() {
  document.getElementById("login-form").classList.toggle('show');
}
function backuplistOn() {
  document.getElementById("backuplist").classList.toggle('show');
}
function donwloadListOn() {
  document.getElementById("downloadlist").classList.toggle('show');
}
let cpOpenFirst = 0;
function chatPaletteOn() {
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