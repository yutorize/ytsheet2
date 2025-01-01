// ナイトモード
const htmlClass = document.getElementsByTagName('html')[0].classList;
let nightMode = localStorage.getItem("nightMode");
if(nightMode == 1) { htmlClass.add('night'); }
function nightModeChange() {
  if(nightMode != 1) { htmlClass.add('night');nightMode = 1; }
  else { htmlClass.remove('night'); nightMode = 0; }
  localStorage.setItem("nightMode", nightMode);
}
// カラーカスタムON/OFF
let colorlessMode = localStorage.getItem("colorlessMode");
if(colorlessMode == 1) { htmlClass.add('colorless'); }
function changeColorlessMode(){
  if(colorlessMode != 1) { htmlClass.add('colorless');    colorlessMode = 1; }
  else                   { htmlClass.remove('colorless'); colorlessMode = 0; }
  localStorage.setItem("colorlessMode", colorlessMode);
}
window.addEventListener("DOMContentLoaded", () => {
  console.log('colorlessMode:'+colorlessMode);
  const obj = document.querySelector('[onchange*=changeColorlessMode]') || '';
  if(obj && colorlessMode == 1){
    obj.checked = true;
  }
})
// ルビコピーON/OFF
let rubyCopyMode = localStorage.getItem("rubyCopyMode") ?? 1;
function changeRubyCopyMode(){
  if(rubyCopyMode != 1) { rubyCopyMode = 1; }
  else                  { rubyCopyMode = 0; }
  localStorage.setItem("rubyCopyMode", rubyCopyMode);
}
window.addEventListener("DOMContentLoaded", () => {
  console.log('rubyCopyMode:'+rubyCopyMode)
  const obj = document.querySelector('[onchange*=changeRubyCopyMode]') || ''
  if(obj && rubyCopyMode == 1){
    obj.checked = true;
  }
})
// 検索フォーム
function formSwitch(){
  const viewMode = document.getElementById("form-search-area").style.display == 'none' ? 0 : 1;
  document.getElementById("form-search-area").style.display = viewMode ? 'none' : '';
}
