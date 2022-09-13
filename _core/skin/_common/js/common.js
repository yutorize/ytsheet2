// ナイトモード
const htmlClass = document.getElementsByTagName('html')[0].classList;
let nightMode = localStorage.getItem("nightMode");
if(nightMode == 1) { htmlClass.add('night'); }
function nightModeChange() {
  if(nightMode != 1) { htmlClass.add('night');nightMode = 1; }
  else { htmlClass.remove('night'); nightMode = 0; }
  localStorage.setItem("nightMode", nightMode);
}
// 検索フォーム
function formSwitch(){
  const viewMode = document.getElementById("form-search-area").style.display == 'none' ? 0 : 1;
  document.getElementById("form-search-area").style.display = viewMode ? 'none' : '';
}