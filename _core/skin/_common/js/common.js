// ナイトモード
const bodyClass = document.body.classList;
let nightMode = localStorage.getItem("nightMode");
if(nightMode == 1) { bodyClass.add('night'); }
function nightModeChange() {
  if(nightMode != 1) { bodyClass.add('night');nightMode = 1; }
  else { bodyClass.remove('night'); nightMode = 0; }
  localStorage.setItem("nightMode", nightMode);
}
// 検索フォーム
function formSwitch(){
  const viewMode = document.getElementById("form-search-area").style.display == 'none' ? 0 : 1;
  document.getElementById("form-search-area").style.display = viewMode ? 'none' : '';
}