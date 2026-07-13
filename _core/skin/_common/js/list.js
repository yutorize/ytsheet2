// 検索フォーム開閉 ----------------------------------------
function toggleHide(id){
  document.getElementById(id).classList.toggle('hide');
}
// 空クエリを削除 ----------------------------------------
document.forms.search.addEventListener('submit', cleanQuery);

function cleanQuery(e) {
  e.preventDefault();
  this.removeEventListener('submit', cleanQuery);
  var query = serialize(this);
  location.href = this.action + '?' + (function(){
    var arr = [];
    [].forEach.call(query.split('&'), function(item) {
      if (item.split('=')[1]) {
        arr.push(item);
      }
    });
    return arr.join('&');
  })();
}

function serialize(form) {
  var s = [];
  if (typeof form !== 'object' && form.nodeName.toUpperCase() !== 'FORM') {
    return s;
  }

  var length = form.elements.length;
  for (var i = 0; i < length; i++) {
    var field = form.elements[i];
    if (field.name && !field.disabled && field.type != 'file' && field.type != 'reset' && field.type != 'submit' && field.type != 'button') {
      if (field.type == 'select-multiple') {
        var l = form.elements[i].options.length;
        for (var j = 0; j < l; j++) {
          if (field.options[j].selected) {
            s[s.length] = encodeURIComponent(field.name) + '=' + encodeURIComponent(field.options[j].value);
          }
        }
      } else if ((field.type != 'checkbox' && field.type != 'radio') || field.checked) {
        s[s.length] = encodeURIComponent(field.name) + '=' + encodeURIComponent(field.value);
      }
    }
  }
  return s.join('&').replace(/%20/g, '+');
}


// ラジオボタン解除 ----------------------------------------
document.querySelectorAll('#form-search input[type="radio"]').forEach(radioButton => {
  let label = radioButton.closest(`label`);

  if(label){
    label.addEventListener("mouseup", ()=>{
      if(radioButton.checked){
        clearRadioButton(radioButton)
      }
    });
  }
  else {
    radioButton.addEventListener("mouseup", ()=>{
      if(radioButton.checked){
        clearRadioButton(radioButton)
      }
    });
  }
});
function clearRadioButton(radioButton) {
  setTimeout(()=>{
    radioButton.checked = false;
    radioButton.dispatchEvent(new Event('input'));
  },100)
}
