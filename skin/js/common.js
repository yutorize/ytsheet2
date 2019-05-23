// ナイトモード
let nightMode = localStorage.getItem("nightMode");
if(nightMode == 1) { document.getElementById("nightmode").href = './skin/css/night.css?1.05.003'; }
function nightModeChange() {
  if(nightMode != 1) { document.getElementById("nightmode").href = './skin/css/night.css?1.05.003'; nightMode = 1; }
  else { document.getElementById("nightmode").href = ''; nightMode = 0; }
  localStorage.setItem("nightMode", nightMode);
}

function formSwitch(){
  const viewMode = document.getElementById("form-search-area").style.display == 'none' ? 0 : 1;
  document.getElementById("form-search-area").style.display = viewMode ? 'none' : '';
}