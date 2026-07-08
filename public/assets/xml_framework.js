// Baraza-style XML Framework client
function initXmlFramework() {
  initGrids();
  initSubGrids();
  bindFormSubmit();
  bindActionButtons();
  bindDrilldown();
  bindJasper();
}

function initGrids() {
  document.querySelectorAll('.xml-grid#jqlist, .xml-grid:not(.sub-grid)').forEach((gridEl) => {
    if (gridEl.id !== 'jqlist' && gridEl.classList.contains('sub-grid')) return;
    setupGrid(gridEl);
  });

  const main = document.getElementById('jqlist');
  if (main) setupGrid(main);
}

function initSubGrids() {
  document.querySelectorAll('.sub-grid').forEach((gridEl) => setupGrid(gridEl));
}

function setupGrid(gridEl) {
  if (!gridEl || typeof agGrid === 'undefined' || gridEl.dataset.gridInit) return;
  gridEl.dataset.gridInit = '1';

  const viewKey = gridEl.dataset.view;
  const keyField = gridEl.dataset.keyfield || 'KF';

  const gridOptions = {
    defaultColDef: { flex: 1, minWidth: 100, resizable: true },
    rowModelType: 'infinite',
    cacheBlockSize: 30,
    maxBlocksInCache: 5,
    onRowClicked: (event) => {
      if (event.colDef?.editable) return;
      const key = event.data?.KF;
      if (key) openRecord(viewKey, key);
    },
    onCellValueChanged: (event) => {
      if (!event.colDef?.editable) return;
      inlineUpdate(viewKey, event.data.KF, event.colDef.field, event.newValue);
    },
    datasource: {
      getRows: async (params) => {
        const page = Math.floor(params.startRow / 30) + 1;
        const sort = params.sortModel?.[0];
        const url = new URL('/jsondata', window.location.origin);
        url.searchParams.set('view', viewKey);
        url.searchParams.set('page', page);
        url.searchParams.set('rows', 30);
        if (sort) {
          url.searchParams.set('sidx', sort.colId);
          url.searchParams.set('sord', sort.sort);
        }

        const response = await fetch(url);
        const data = await response.json();
        const rows = data.rows || [];

        if (data.columnDefs?.length) {
          const cols = [
            { field: 'row_number_counter', headerName: '#', width: 60, sortable: false, filter: false },
            ...data.columnDefs.map((c) => ({
              ...c,
              cellRenderer: c.editable ? undefined : htmlCellRenderer
            }))
          ];
          gridOptions.api.setGridOption('columnDefs', cols);
        } else if (rows[0]) {
          const dynamicCols = Object.keys(rows[0])
            .filter((k) => !['KF', 'CL', 'row_number_counter'].includes(k))
            .map((k) => ({ field: k, headerName: k.replace(/_/g, ' '), cellRenderer: htmlCellRenderer }));
          gridOptions.api.setGridOption('columnDefs', [
            { field: 'row_number_counter', headerName: '#', width: 60 },
            ...dynamicCols
          ]);
        }

        params.successCallback(rows, data.records || rows.length);
      }
    }
  };

  agGrid.createGrid(gridEl, gridOptions);
}

function htmlCellRenderer(params) {
  const span = document.createElement('span');
  span.innerHTML = params.value ?? '';
  return span;
}

function inlineUpdate(viewKey, id, field, value) {
  const body = new FormData();
  body.append('view', viewKey);
  body.append('id', id);
  body.append('field', field);
  body.append('value', value);
  body.append('oper', 'edit');

  fetch('/ajaxupdate', {
    method: 'POST',
    headers: { 'X-CSRF-Token': csrfToken() },
    body
  })
    .then((r) => r.json())
    .then((result) => {
      if (!result.success) alert(result.msg || 'Update failed');
    });
}

function bindFormSubmit() {
  document.querySelectorAll('.xml-data-form').forEach((form) => {
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const viewKey = form.dataset.view;
      const oper = form.dataset.oper || 'add';
      const dataKey = form.dataset.key;
      const body = new FormData(form);
      body.append('view', viewKey);
      body.append('oper', oper);
      if (dataKey) body.append('data', dataKey);

      const response = await fetch('/datapost', {
        method: 'POST',
        headers: { 'X-CSRF-Token': csrfToken() },
        body
      });
      const result = await response.json();
      alert(result.msg || (result.success ? 'Saved' : 'Error'));
      if (result.success) {
        if (result.jump && result.jumpview) {
          window.location.href = `/xml_app/${result.jumpview.split(':')[0]}?data=${result.jumplink || ''}`;
        } else {
          window.location.reload();
        }
      }
    });
  });
}

function bindActionButtons() {
  document.querySelectorAll('.action-fn-btn').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const fnct = btn.dataset.fnct;
      const view = btn.dataset.view;
      const data = prompt('Enter record ID for action:');
      if (!data) return;

      const body = new FormData();
      body.append('view', view);
      body.append('oper', 'action');
      body.append('fnct', fnct);
      body.append('data', data);

      const response = await fetch('/datapost', {
        method: 'POST',
        headers: { 'X-CSRF-Token': csrfToken() },
        body
      });
      const result = await response.json();
      alert(result.msg || (result.success ? 'Done' : 'Error'));
      if (result.success) window.location.reload();
    });
  });
}

function bindDrilldown() {
  document.querySelectorAll('.drilldown-link').forEach((link) => {
    link.addEventListener('click', async (e) => {
      e.preventDefault();
      const filter = link.dataset.filter;
      const value = link.dataset.value;
      const viewKey = document.querySelector('.filter-view')?.dataset?.viewKey || '';

      const body = new FormData();
      body.append('view', viewKey);
      body.append('filter', filter);
      body.append('value', value);

      const response = await fetch('/filters', {
        method: 'POST',
        headers: { 'X-CSRF-Token': csrfToken() },
        body
      });
      const result = await response.json();
      if (result.success) window.location.reload();
      else alert(result.msg || 'Filter failed');
    });
  });
}

function bindJasper() {
  document.querySelectorAll('.jasper-generate-btn').forEach((btn) => {
    btn.addEventListener('click', () => generateJasperReport(btn.dataset.report, btn.dataset.view, {}));
  });

  document.querySelectorAll('.jasper-params-form').forEach((form) => {
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const data = Object.fromEntries(new FormData(form));
      await generateJasperReport(form.dataset.report, form.dataset.view, data);
    });
  });
}

async function generateJasperReport(report, view, params) {
  const body = new FormData();
  body.append('report', report);
  body.append('view', view);
  Object.entries(params).forEach(([k, v]) => body.append(k, v));

  const response = await fetch('/reports', {
    method: 'POST',
    headers: { 'X-CSRF-Token': csrfToken() },
    body
  });
  const result = await response.json();
  const output = document.getElementById('jasper-output');

  if (result.success) {
    if (result.jumplink) {
      output.innerHTML = `<a href="${result.jumplink}" target="_blank" class="btn btn-success">Download PDF</a>`;
    } else {
      output.innerHTML = `<div class="alert alert-info">${result.msg}</div>`;
    }
  } else {
    alert(result.msg || 'Report failed');
  }
}

function showFormPanel() {
  document.getElementById('xml-form-panel')?.classList.remove('d-none');
  const form = document.getElementById('xml-data-form');
  if (form) {
    form.dataset.oper = 'add';
    form.dataset.key = '';
    form.reset();
  }
}

function hideFormPanel() {
  document.getElementById('xml-form-panel')?.classList.add('d-none');
}

function openRecord(viewKey, key) {
  const base = viewKey.split(':')[0];
  window.location.href = `/xml_app/${base}?view=${viewKey}&data=${key}`;
}

function deleteRecord() {
  const form = document.getElementById('xml-data-form');
  if (!form || !confirm('Delete this record?')) return;

  const body = new FormData();
  body.append('view', form.dataset.view);
  body.append('oper', 'delete');
  body.append('data', form.dataset.key);

  fetch('/datapost', {
    method: 'POST',
    headers: { 'X-CSRF-Token': csrfToken() },
    body
  })
    .then((r) => r.json())
    .then((result) => {
      alert(result.msg || (result.success ? 'Deleted' : 'Error'));
      if (result.success) window.location.href = `/xml_app/${form.dataset.view.split(':')[0]}`;
    });
}

function jumpToView(viewKey) {
  if (!viewKey) return;
  const key = viewKey.split(':')[0];
  const view = viewKey.includes(':') ? `?view=${viewKey}` : '';
  window.location.href = `/xml_app/${key}${view}`;
}

function updateField(filterName, value) {
  const body = new FormData();
  body.append('filter', filterName);
  body.append('value', value);
  fetch('/filters', { method: 'POST', headers: { 'X-CSRF-Token': csrfToken() }, body })
    .then(() => window.location.reload());
}

function generateReport(reportFile) {
  generateJasperReport(reportFile, '', {});
}

function openBrowser(action, value) {
  alert(`Browser ${action}: ${value}`);
}

function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content || '';
}
