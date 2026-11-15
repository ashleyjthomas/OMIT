/**
 * OMIT3 — Google Sheets receiver
 *
 * One row per TRIAL (4 rows per child), which is the grain the brms model wants
 * (chose_hi ~ condition * age + (1 | ID)). Participant-level and practice-block
 * fields repeat on each of a child's rows. Mirrors the LANG-CARE / LICK-4 setup.
 *
 * The task also writes everything into the CHS response record; this Sheet is a
 * second sink, for watching recruitment, version balance and comprehension-check
 * pass rates while data come in. CHS remains the source of truth.
 *
 * Setup:
 *   1. Make a new Google Sheet (this is your data file).
 *   2. Extensions -> Apps Script -> paste this whole file -> Save.
 *   3. Deploy -> New deployment:
 *        Type:           Web app
 *        Description:    OMIT3 data receiver
 *        Execute as:     Me (your account)
 *        Who has access: Anyone
 *   4. Copy the Web app URL (.../exec) and paste it into
 *        chs/src/chs_protocol_template.js as SHEETS_WEBHOOK, then
 *        run `python3 build/build.py` and re-paste dist/chs_protocol.js into CHS.
 *   5. Visit that URL in a browser — you should see "OMIT3 receiver is live."
 *
 * The front end posts { headers: [...], rows: [ {...}, ... ] } as text/plain
 * (text/plain avoids a CORS preflight). The header row is written once from
 * `headers`; each POST appends rows in the sheet's own column order, so
 * reordering columns later does not break anything.
 *
 * NOTE: the caregiver's payment email is deliberately NOT sent here. It stays in
 * the CHS record and is dropped when the data are de-identified for publication.
 */

const SHEET_NAME = 'Data';   // tab to write into; created if missing

function doPost(e) {
  const lock = LockService.getScriptLock();
  try {
    lock.waitLock(20000);   // two children finishing at once would otherwise interleave

    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName(SHEET_NAME);
    if (!sheet) sheet = ss.insertSheet(SHEET_NAME);

    const data = JSON.parse(e.postData.contents);
    const rows = data.rows || (data.row ? [data.row] : []);
    const incomingHeaders = data.headers || (rows.length ? Object.keys(rows[0]) : []);

    if (sheet.getLastRow() === 0) {
      sheet.appendRow(incomingHeaders);
      sheet.setFrozenRows(1);
    }

    const sheetHeaders = sheet
      .getRange(1, 1, 1, Math.max(sheet.getLastColumn(), 1))
      .getValues()[0];

    const values = rows.map(function (row) {
      return sheetHeaders.map(function (h) {
        const v = row[h];
        return v === undefined || v === null ? '' : v;
      });
    });

    if (values.length) {
      sheet
        .getRange(sheet.getLastRow() + 1, 1, values.length, sheetHeaders.length)
        .setValues(values);
    }

    return ContentService
      .createTextOutput(JSON.stringify({ ok: true, appended: values.length }))
      .setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ ok: false, error: String(err) }))
      .setMimeType(ContentService.MimeType.JSON);
  } finally {
    try { lock.releaseLock(); } catch (ignore) {}
  }
}

function doGet() {
  return ContentService.createTextOutput('OMIT3 receiver is live.');
}
