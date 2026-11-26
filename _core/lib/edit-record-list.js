"use strict";

class RecordListEditor {
  constructor(root, { setupRecord, onChange } = {}) {
    this.label = root.dataset.recordLabel;
    this.placeholder = root.dataset.recordPlaceholder;
    this.forms = root.querySelector('[data-record-forms]');
    this.list = root.querySelector('[data-record-order]');
    this.orderPanel = root.querySelector('[data-record-order-panel]');
    this.rowTemplate = root.querySelector('[data-record-order-row]');
    this.formTemplate = root.querySelector('[data-record-template]');
    this.orderField = root.querySelector('[data-record-form-order]');
    this.lastNumberField = root.querySelector('[data-record-last-number]');
    const controls = root.querySelector(':scope > .record-list-buttons');
    const addButton = controls.querySelector('[data-record-add]');
    this.deleteLastButton = controls.querySelector('[data-record-delete-last]');
    this.setupRecord = setupRecord;
    this.onChange = onChange;

    Array.from(this.forms.children).forEach(record => this.register(record));
    this.sync();
    Sortable.create(this.list, {
      handle: '.handle',
      animation: 150,
      onUpdate: () => this.changeOrder(),
    });
    addButton.addEventListener('click', () => this.add());
    this.deleteLastButton.addEventListener('click', () => {
      const removed = this.remove(this.forms.lastElementChild, this.list.lastElementChild);
      if(removed && this.deleteLastButton.disabled){ addButton.focus({ preventScroll: true }); }
    });
  }

  register(record) {
    this.setupRecord?.(record);
    const row = this.rowTemplate.content.firstElementChild.cloneNode(true);
    const nameInput = record.querySelector(`[name="${record.dataset.recordName}"]`);
    const nameButton = row.querySelector('.record-order-name');
    row.dataset.recordNumber = record.dataset.recordNumber;
    const updateLabel = () => {
      nameButton.textContent = nameInput.value.trim() || `${this.label} ${row.dataset.recordNumber}`;
    };
    updateLabel();
    nameInput.addEventListener('input', updateLabel);
    nameButton.addEventListener('click', () => {
      record.focus({ preventScroll: true });
      const headerHeight = document.getElementById('header-menu')?.clientHeight ?? 0;
      const top = record.getBoundingClientRect().top + window.scrollY - headerHeight - 30;
      const behavior = window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth';
      window.scrollTo({ top, behavior });
    });
    row.querySelector('[data-record-delete]').addEventListener('click', () => {
      const adjacentRow = row.nextElementSibling ?? row.previousElementSibling;
      if(!this.remove(record, row)){ return; }
      const focusTarget = this.orderPanel.hidden
        ? this.forms.firstElementChild
        : adjacentRow.querySelector('[data-record-delete]');
      focusTarget.focus({ preventScroll: true });
    });
    this.list.append(row);
    return nameInput;
  }

  add() {
    const number = Number(this.lastNumberField.value) + 1;
    if(!Number.isSafeInteger(number)){ return; }
    const template = document.createElement('template');
    template.innerHTML = this.formTemplate.innerHTML.replaceAll(this.placeholder, number);
    const record = template.content.firstElementChild;
    this.lastNumberField.value = number;
    this.forms.append(record);
    const nameInput = this.register(record);
    this.changeOrder();
    nameInput.focus();
  }

  remove(record, row) {
    if(this.forms.children.length <= 1 || !delRowNode(`#${CSS.escape(record.id)}`)){ return false; }
    row.remove();
    this.changeOrder();
    return true;
  }

  changeOrder() {
    this.sync();
    this.orderField.dispatchEvent(new Event('change', { bubbles: true }));
  }

  sync() {
    const rows = Array.from(this.list.children);
    const records = new Map(Array.from(this.forms.children, record => [record.dataset.recordNumber, record]));
    rows.forEach((row, index) => {
      const record = records.get(row.dataset.recordNumber);
      if(record !== this.forms.children[index]){ this.forms.insertBefore(record, this.forms.children[index]); }
    });
    this.orderField.value = rows.map(row => row.dataset.recordNumber).join(',');
    this.orderPanel.hidden = rows.length <= 1;
    this.deleteLastButton.disabled = rows.length <= 1;
    this.onChange?.(rows.length);
  }
}
