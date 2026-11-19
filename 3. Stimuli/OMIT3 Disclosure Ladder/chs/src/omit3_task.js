/* OMIT3 — four-trial disclosure study, jsPsych 7 task module.
 * Built for Children Helping Science (lookit-jspsych). The same file runs standalone
 * (index.html) for testing. OMIT3_DESIGN (contents, trials, versions, narration) and
 * OMIT3_ICON_SIZES are injected above this block by build/build.py.
 */
(function (global) {
  'use strict';

  const D = global.OMIT3_DESIGN;
  const ICON = global.OMIT3_ICON_SIZES; // {name: [w,h]}

  // ---------------------------------------------------------------- geometry (inches on a 10 x 5.625 slide)
  const SW = 10, SH = 5.625;
  const px = (x) => (100 * x / SW).toFixed(3) + '%';
  const py = (y) => (100 * y / SH).toFixed(3) + '%';
  const G = {
    protoIntro: [3.98, 1.99, 1.94, 2.37],
    protoEst: [3.84, 2.14, 2.16, 2.64],
    desk: [3.98, 3.70, 1.97, 1.97],
    chalkboard: [0.18, 0.15, 3.66, 2.15],
    lunchroom: [0.18, 0.25, 7.93, 4.24],
    playground: [0.29, 0.15, 6.77, 4.24],
    cloudSlot: { cx: 6.07, cy: 2.27, w: 1.00, h: 0.78 },
    houseL: [0.80, 0.45, 2.64, 2.64],
    houseR: [6.55, 0.54, 2.64, 2.64],
    protoEnc: [2.92, 2.57, 1.57, 1.92],
    mateEnc: [5.52, 2.60, 1.57, 1.92],
    balloonSlot: { cx: 4.65, cy: 2.51, w: 1.00, h: 0.80 },
    noSymbol: 0.58,
    narrator: [8.30, 3.40, 1.52, 2.14],   // bottom-right corner, clear of every scene element
    shelf: [0.22, 0.14, 0.40, 0.40],        // first small star (top-left); the rest follow at 0.46 in spacing
    bigStar: [3.75, 1.35, 2.50, 2.50],
    figL: [2.59, 2.28, 1.54, 1.88],
    figR: [5.87, 2.28, 1.54, 1.88],
    figLmem: [2.59, 2.95, 1.54, 1.88],
    figRmem: [5.87, 2.95, 1.54, 1.88],
    qmark: [4.30, 0.10, 1.40, 1.40],
    memSlot: { cx: 5.00, cy: 2.15, w: 1.60, h: 1.10 },
    text: [1.50, 0.95, 7.00, 0.50],
    icecream: [4.12, 3.03, 1.76, 1.76],
    candy: [4.29, 2.57, 1.42, 1.42],
    prop: [4.12, 3.03, 1.76, 1.76],
    prTrio: { mid: [4.23, 1.85, 1.54, 1.88], left: [1.85, 2.28, 1.54, 1.88], right: [6.61, 2.28, 1.54, 1.88] },
    // recap page after the comprehension checks: one row per classmate — the protagonist, the classmate,
    // then what they were told (green tick) and what they were not told (red cross)
    recap: { rowTop: [0.95, 3.15], protX: 0.34, mateX: 1.78, figW: 1.32, figH: 1.61, figDy: 0.05,
             cardX: [3.25, 6.18], cardW: 2.80, cardH: 1.70 },
    // DV pages (better friends / ice cream / candy): above the question, a cropped still of each
    // classmate's encounter — the moment the protagonist told them the thing — side by side with a
    // black line between. `crop` is the slice of the encounter scene each panel shows (x, y, w, h in
    // stage inches); the panel has the same shape, so the still is the scene zoomed, not squashed.
    // The characters move down and in a little to make room; everything stays clear of the Why? box.
    dvp: {
      crop: [2.70, 2.00, 5.40, 2.55],
      textTop: 0.58, top: 0.96, w: 3.516, h: 1.66, x: [1.384, 5.050],
      line: [4.950, 0.90, 0.10, 1.78],
      figL: [2.778, 2.74, 1.163, 1.42], figR: [6.058, 2.74, 1.163, 1.42],
      icecream: [4.325, 2.78, 1.35, 1.35], candy: [4.420, 2.86, 1.16, 1.16], prop: [4.325, 2.78, 1.35, 1.35],
    },
  };

  let BASE = '';
  const asset = (p) => BASE + 'assets/' + p;
  const audioUrl = (key) => BASE + 'audio/' + key + '.mp3';

  // Every element carries a key (asset + slot). On a new page, elements whose key was not on the
  // previous page animate in (characters slide, bubbles/icons pop, backgrounds fade); unchanged ones stay put.
  function img(src, r, extra) {
    extra = extra || {};
    const cls = extra.cls ? ' class="' + extra.cls + '"' : '';
    const dat = extra.choice ? ' data-choice="' + extra.choice + '"' : '';
    const kind = extra.kind || (src.indexOf('/characters/') >= 0 ? 'char' : src.indexOf('/icons/') >= 0 || src.indexOf('nosymbol') >= 0 ? 'pop' : 'fade');
    const key = src.replace(/^.*assets\//, '') + '@' + r[0].toFixed(2) + ',' + r[1].toFixed(2);
    return '<img src="' + src + '"' + cls + dat + ' data-k="' + key + '" data-kind="' + kind + '" draggable="false" style="position:absolute;left:' + px(r[0]) + ';top:' + py(r[1]) +
      ';width:' + px(r[2]) + ';height:' + py(r[3]) + ';">';
  }
  function layer(name, cls) {
    const dx = name === 'balloon' ? px(0.12) : '0';
    return '<img src="' + asset('layers/' + name + '.png') + '"' + (cls ? ' class="' + cls + '"' : '') + ' data-k="layer:' + name + '" data-kind="pop" draggable="false" style="position:absolute;left:' + dx + ';top:0;width:100%;height:100%;">';
  }
  function fitRect(iconName, slot) {
    const s = ICON[iconName]; const ar = s[0] / s[1];
    let w = slot.w, h = w / ar;
    if (h > slot.h) { h = slot.h; w = h * ar; }
    return [slot.cx - w / 2, slot.cy - h / 2, w, h];
  }
  const charImg = (name, r, extra) => img(asset('characters/' + name.toLowerCase() + '.png'), r, extra);
  // One card on the recap page: the content, plus a green tick (was told) or red cross (was not).
  // c is { icon, face }. The emotion icons are whole figures that shrink to an illegible speck at this
  // size — the tear disappears — so those are framed on the head (.o3-face); animal icons fit whole.
  function recapCard(c, r, told) {
    return '<div class="o3-card" data-k="card:' + c.icon + (told ? ':y' : ':n') + '@' + r[0].toFixed(2) + ',' + r[1].toFixed(2) + '" data-kind="pop" style="left:' + px(r[0]) +
      ';top:' + py(r[1]) + ';width:' + px(r[2]) + ';height:' + py(r[3]) + ';">' +
      '<span class="o3-cardic"><img class="' + (c.face ? 'o3-face' : '') + '" src="' + asset('icons/' + c.icon + '.png') + '" draggable="false"></span>' +
      '<span class="o3-mark ' + (told ? 'o3-mk-y">&#10003;' : 'o3-mk-n">&#10007;') + '</span></div>';
  }
  const iconFile = (content, prot) => D.contents[content].kind === 'emotion' ? prot.toLowerCase() + '_' + content : D.contents[content].icon;

  const DANCE_SEQ = [1, 2, 3, 4, 1, 6, 7, 8, 5, 3, 7, 2];   // order of the 8 dance frames in the loop
  const STAR_PATH = 'M50 5 L61 36 L95 36 L68 56 L78 90 L50 70 L22 90 L32 56 L5 36 L39 36 Z';
  function starSvg(cls) {
    return '<svg class="o3-star ' + (cls || '') + '" viewBox="0 0 100 100"><path d="' + STAR_PATH + '" stroke-linejoin="round"/></svg>';
  }
  function shelfHtml(filled, total) {
    let h = '<div class="o3-shelf">';
    for (let i = 0; i < total; i++) {
      const r = [G.shelf[0] + i * 0.46, G.shelf[1], G.shelf[2], G.shelf[3]];
      h += '<div class="o3-slot' + (i < filled ? ' filled' : '') + '" data-slot="' + (i + 1) + '" style="position:absolute;left:' + px(r[0]) + ';top:' + py(r[1]) + ';width:' + px(r[2]) + ';height:' + py(r[3]) + ';">' + starSvg() + '</div>';
    }
    return h + '</div>';
  }
  function confettiHtml(n) {
    const cols = ['#f5b400', '#2f6fd6', '#e8553e', '#39b54a', '#9b59b6', '#ff8ac2'];
    let h = '<div class="o3-confetti">';
    for (let i = 0; i < n; i++) {
      const x = Math.random() * 100, d = (Math.random() * 1.5).toFixed(2), dur = (2.2 + Math.random() * 1.8).toFixed(2), rot = Math.floor(Math.random() * 360);
      h += '<i style="left:' + x.toFixed(1) + '%;background:' + cols[i % cols.length] + ';animation-delay:' + d + 's;animation-duration:' + dur + 's;transform:rotate(' + rot + 'deg)"></i>';
    }
    return h + '</div>';
  }

  // ---------------------------------------------------------------- scenes
  const SC = {
    intro: (P) => charImg(P, G.protoIntro),
    establish: (P, content, scene) => {
      const c = D.contents[content]; let h = '';
      if (scene === 'lunch room') h += img(asset('bg/lunchroom.png'), G.lunchroom);
      else if (scene === 'playground') h += img(asset('bg/playground.png'), G.playground);
      else h += img(asset('bg/chalkboard.png'), G.chalkboard);
      h += layer('cloud');
      h += charImg(P, G.protoEst);
      if (c.kind !== 'emotion') h += img(asset('bg/desk.png'), G.desk);
      h += img(asset('icons/' + iconFile(content, P) + '.png'), fitRect(iconFile(content, P), G.cloudSlot));
      return h;
    },
    // still: the scene as a finished picture — the speech bubble already showing, nothing tagged for
    // shaking, the houses dropped (at still scale they are fragments of wall and window), and an
    // emotion shown as a close-up of the face, since the whole-figure icon loses its tear when small.
    // Used for the DV-page stills, where the scene is a reminder, not a page being played.
    encounter: (P, C, content, told, still) => {
      const late = still ? '' : 'o3-late';
      let h = still ? '' : img(asset('bg/houses.png'), G.houseL) + img(asset('bg/houses.png'), G.houseR);
      // the speech bubble and its content are "late": hidden until the narration has finished, then popped in
      // the classmate is tagged 'mate' so the greeting line can shake it (shakeOn targets
      // [data-choice]; clicks attach only to .zone, so this never makes the figure clickable)
      h += charImg(P, G.protoEnc) + charImg(C, G.mateEnc, still ? {} : { choice: 'mate' }) + layer('balloon', late);
      const ic = iconFile(content, P); const r = fitRect(ic, G.balloonSlot);
      if (still && D.contents[content].kind === 'emotion') {
        h += '<span class="o3-bubface" style="left:' + px(r[0]) + ';top:' + py(r[1]) + ';width:' + px(r[2]) + ';height:' + py(r[3]) +
          ';"><img src="' + asset('icons/' + ic + '.png') + '" draggable="false"></span>';
      } else h += img(asset('icons/' + ic + '.png'), r, { cls: late });
      if (!told) {
        const n = G.noSymbol; h += img(asset('layers/nosymbol.png'), [r[0] + r[2] / 2 - n / 2 - 0.22, r[1] + r[3] / 2 - n / 2, n, n], { cls: late });
      }
      return h;
    },
    // One DV-page still: the encounter scene, cropped to G.dvp.crop, inside a box of the same shape.
    // Scene elements are positioned in % of the stage, so an inner box sized SW x SH relative to the
    // crop and shifted by the crop's origin reproduces that slice of the page exactly, at panel scale.
    // The inner elements lose their data-k: the still is one picture that fades in, not a scene
    // replaying its own entrance animations inside the frame.
    shot: (P, mate, content, r) => {
      const c = G.dvp.crop;
      const inner = SC.encounter(P, mate, content, true, true).replace(/ data-k="[^"]*"/g, '');
      return '<div class="o3-panel" data-k="shot:' + mate + ':' + content + '" data-kind="fade" style="left:' + px(r[0]) +
        ';top:' + py(r[1]) + ';width:' + px(r[2]) + ';height:' + py(r[3]) + ';">' +
        '<div class="o3-shot" style="left:' + (-100 * c[0] / c[2]).toFixed(3) + '%;top:' + (-100 * c[1] / c[3]).toFixed(3) +
        '%;width:' + (100 * SW / c[2]).toFixed(3) + '%;height:' + (100 * SH / c[3]).toFixed(3) + '%;">' + inner + '</div></div>';
    },
    // yes/no check: the classmate being asked about, the content, and two big buttons
    yesno: (P, content, who, text) => {
      const ic = iconFile(content, P);
      return '<div class="qtext" style="position:absolute;left:' + px(G.text[0]) + ';top:' + py(0.55) + ';width:' + px(G.text[2]) + ';">' + text + '</div>' +
        charImg(who, [4.23, 1.35, 1.54, 1.88]) + img(asset('icons/' + ic + '.png'), fitRect(ic, { cx: 6.35, cy: 2.0, w: 1.2, h: 1.0 })) +
        '<div class="zone o3-yn o3-yes" data-choice="yes" style="left:' + px(2.4) + ';top:' + py(3.7) + ';">&#10003; Yes</div>' +
        '<div class="zone o3-yn o3-no" data-choice="no" style="left:' + px(5.6) + ';top:' + py(3.7) + ';">&#10007; No</div>';
    },
    // shots: [{ mate, content }, ...] in c1/c2 order — stills of what each classmate was told, shown
    // above the question so the child is not choosing from memory. Practice passes none and keeps the
    // original layout (there is no earlier scene to show, and its question text runs to three lines).
    dv: (left, right, prop, text, shots) => {
      const Q = shots ? G.dvp : G;
      let h = '';
      if (text) h += '<div class="qtext" style="position:absolute;left:' + px(G.text[0]) + ';top:' + py(shots ? G.dvp.textTop : G.text[1]) + ';width:' + px(G.text[2]) + ';">' + text + '</div>';
      if (shots) {
        const L = G.dvp.line;
        h += '<div class="o3-dvline" data-k="dvline" data-kind="fade" style="left:' + px(L[0]) + ';top:' + py(L[1]) + ';width:' + px(L[2]) + ';height:' + py(L[3]) + ';"></div>';
        shots.forEach((s, i) => { h += SC.shot(s.prot, s.mate, s.content, [G.dvp.x[i], G.dvp.top, G.dvp.w, G.dvp.h]); });
      }
      if (prop === 'icecream') h += img(asset('bg/icecream.png'), Q.icecream);
      else if (prop === 'candy') h += img(asset('bg/candy.png'), Q.candy);
      else if (prop) h += img(asset('bg/' + prop + '.png'), Q.prop);
      h += charImg(left, Q.figL, { cls: 'zone', choice: 'left' }) + charImg(right, Q.figR, { cls: 'zone', choice: 'right' });
      return h;
    },
    // rows: [{ mate, told: {icon, face}, not: {icon, face} }, ...] — one per classmate, in c1/c2 order
    recap: (P, rows) => {
      const R = G.recap;
      return rows.map((row, i) => {
        const top = R.rowTop[i];
        // data-choice tags the row so the narration can shake it while that classmate's line plays
        // (shakeOn targets [data-choice]; clicks attach only to .zone, so these stay unclickable)
        const side = 'row' + (i + 1);
        return charImg(P, [R.protX, top + R.figDy, R.figW, R.figH], { choice: side }) +
          charImg(row.mate, [R.mateX, top + R.figDy, R.figW, R.figH], { choice: side }) +
          recapCard(row.told, [R.cardX[0], top, R.cardW, R.cardH], true) +
          recapCard(row.not, [R.cardX[1], top, R.cardW, R.cardH], false);
      }).join('');
    },
    practiceTrio: (P, left, right) => charImg(P, G.prTrio.mid) + (left ? charImg(left, G.prTrio.left, { choice: 'left' }) : '') + (right ? charImg(right, G.prTrio.right, { choice: 'right' }) : ''),
    frame: (name) => img(asset('frames/' + name + '.png'), [0, 0, SW, SH]),
    reward: (n, total) => {
      const r = G.bigStar; let h = '<div class="o3-bigstar" style="position:absolute;left:' + px(r[0]) + ';top:' + py(r[1]) + ';width:' + px(r[2]) + ';height:' + py(r[3]) + ';">' + starSvg('big') + '</div>';
      if (n >= total) h += confettiHtml(60) + '<div class="o3-banner">You did it!</div>';
      return h;
    },
  };


  // ---------------------------------------------------------------- narrator (lip-flap driven by audio level)
  const Narrator = (() => {
    const FR = ['rest', 'small', 'open', 'oh', 'grin', 'blink'];
    const src = {}; FR.forEach((f) => { src[f] = asset('narrator/' + f + '.png'); });
    let ctx = null, analyser = null, buf = null, connected = new WeakSet();
    function ensureCtx() {
      if (ctx) return true;
      try { const AC = window.AudioContext || window.webkitAudioContext; ctx = new AC(); analyser = ctx.createAnalyser(); analyser.fftSize = 512; analyser.connect(ctx.destination); buf = new Uint8Array(analyser.fftSize); return true; }
      catch (e) { ctx = null; return false; }
    }
    function attach(el) {
      const api = { el, raf: null, blinkT: null, mode: 'idle', fallbackT: null, gotSignal: false, grinUntil: 0 };
      if (!el) { return { talk() {}, silent() {}, react() {}, stop() {} }; }
      const show = (f) => { if (el.dataset.f !== f) { el.dataset.f = f; el.src = src[f]; } };
      const blink = () => { if (api.mode === 'stopped') return; const cur = el.dataset.f || 'rest'; if (cur === 'rest') { show('blink'); setTimeout(() => { if (el.dataset.f === 'blink') show('rest'); }, 140); } api.blinkT = setTimeout(blink, 2200 + Math.random() * 2800); };
      api.blinkT = setTimeout(blink, 1500 + Math.random() * 2000);
      let level = 0, last = 0;
      const pick = (v) => (v < 0.02 ? 'rest' : v < 0.06 ? 'small' : v < 0.12 ? 'open' : 'oh');
      const loop = (t) => {
        if (api.mode !== 'talk') return;
        if (t - last > 70) {
          last = t;
          let v = 0;
          if (analyser && api.el) { analyser.getByteTimeDomainData(buf); let s = 0; for (let i = 0; i < buf.length; i += 4) { const d = (buf[i] - 128) / 128; s += d * d; } v = Math.sqrt(s / (buf.length / 4)); if (v > 0.01) api.gotSignal = true; }
          if (!api.gotSignal && t - api.talkStart > 700) v = [0.01, 0.04, 0.09, 0.15][Math.floor(Math.random() * 4)];   // no analyser signal (CORS/autoplay) -> random flap
          level = level * 0.4 + v * 0.6;
          if (t < api.grinUntil) show('grin'); else if (el.dataset.f !== 'blink') show(pick(level));
        }
        api.raf = requestAnimationFrame(loop);
      };
      api.talk = (audio) => {
        api.mode = 'talk'; api.talkStart = performance.now(); api.gotSignal = false;
        if (ensureCtx()) { try { if (ctx.state === 'suspended') ctx.resume(); if (!connected.has(audio)) { ctx.createMediaElementSource(audio).connect(analyser); connected.add(audio); } } catch (e) { /* fall back to random flap */ } }
        if (api.raf) cancelAnimationFrame(api.raf); api.raf = requestAnimationFrame(loop);
      };
      api.silent = () => { api.mode = 'idle'; if (api.raf) cancelAnimationFrame(api.raf); api.raf = null; show('rest'); };
      api.react = () => { api.grinUntil = performance.now() + 1200; show('grin'); setTimeout(() => { if (api.mode !== 'talk' && el.dataset.f === 'grin') show('rest'); }, 1200); };
      api.stop = () => { api.mode = 'stopped'; if (api.raf) cancelAnimationFrame(api.raf); if (api.blinkT) clearTimeout(api.blinkT); };
      return api;
    }
    return { attach, frames: FR };
  })();

  // ---------------------------------------------------------------- plugin
  const CSS = `
  .omit3-stage{position:relative;background:#fff;width:min(100vw,calc(100vh*16/9));aspect-ratio:16/9;margin:0 auto;overflow:hidden;container-type:inline-size;user-select:none;}
  .omit3-wrap{position:fixed;inset:0;background:#fff;display:flex;align-items:center;justify-content:center;}
  .omit3-stage .qtext{font-family:Arial,Helvetica,sans-serif;font-size:2.5cqw;color:#333;line-height:1.15;text-align:center;}
  .omit3-stage .zone{opacity:1;transition:transform .12s;}
  .omit3-stage.ready .zone{cursor:pointer;}
  .omit3-stage.ready .zone:hover{transform:scale(1.06);}
  .omit3-stage .zone.chosen{outline:0.6cqw solid #f5b400;outline-offset:0.4cqw;border-radius:1cqw;}
  .omit3-stage .zone.dim{opacity:.35;}
  .o3-yn{position:absolute;width:20cqw;height:9cqw;border-radius:2cqw;font:700 4cqw Arial,sans-serif;color:#fff;display:flex;align-items:center;justify-content:center;box-shadow:0 .4cqw 0 rgba(0,0,0,.18);}
  .o3-yes{background:#39b54a;} .o3-no{background:#e8553e;}
  @keyframes o3-shake{0%,100%{transform:rotate(0)}20%{transform:rotate(-7deg) translateY(-2cqw)}40%{transform:rotate(6deg)}60%{transform:rotate(-5deg) translateY(-1cqw)}80%{transform:rotate(4deg)}}
  .omit3-stage .shake{animation:o3-shake .7s ease-in-out infinite !important;transform-origin:50% 90%;}
  .omit3-narrator{position:absolute;pointer-events:none;}
  .o3-card{position:absolute;pointer-events:none;background:#fff;border:0.4cqw solid #9cb7d8;border-radius:1.4cqw;box-shadow:0 .3cqw .7cqw rgba(70,95,130,.16);display:flex;align-items:center;gap:0.8cqw;padding:0.8cqw;box-sizing:border-box;}
  .o3-cardic{flex:1 1 auto;height:100%;position:relative;overflow:hidden;display:flex;align-items:center;justify-content:center;}
  .o3-cardic img{max-width:100%;max-height:100%;}
  /* emotion icons are whole figures: blow the image up and slide it so the head alone fills the cell */
  .o3-cardic img.o3-face{position:absolute;height:258%;width:auto;max-width:none;max-height:none;top:-8%;left:50%;transform:translateX(-50%);}
  .o3-mark{flex:0 0 auto;width:4cqw;height:4cqw;border-radius:50%;color:#fff;font:700 2.6cqw/1 Arial,sans-serif;display:flex;align-items:center;justify-content:center;}
  .o3-mk-y{background:#39b54a;} .o3-mk-n{background:#e8553e;}
  /* DV-page stills: a window onto the earlier encounter scene, the two split by a black line */
  .o3-panel{position:absolute;overflow:hidden;background:#f3f6fa;border-radius:1.2cqw;pointer-events:none;}
  .o3-shot{position:absolute;}
  .o3-shot .o3-bubface{position:absolute;overflow:hidden;}
  .o3-shot .o3-bubface img{position:absolute;height:300%;width:auto;max-width:none;left:50%;top:-10%;transform:translateX(-50%);}
  .o3-dvline{position:absolute;background:#111;border-radius:0.2cqw;}
  .o3-star path{fill:#e6e6e6;stroke:#bdbdbd;stroke-width:4;transition:fill .3s,stroke .3s;}
  .o3-slot.filled .o3-star path{fill:#f5b400;stroke:#d08f00;}
  .o3-slot.just .o3-star{animation:o3-pop .5s ease-out;}
  .o3-star.big path{fill:#f5b400;stroke:#d08f00;stroke-width:3;filter:drop-shadow(0 0 1.2cqw rgba(245,180,0,.7));}
  .o3-bigstar{animation:o3-starin .9s cubic-bezier(.2,.8,.3,1.2) backwards;}
  .o3-bigstar.fly{transition:all .8s cubic-bezier(.4,0,.2,1);}
  @keyframes o3-starin{0%{transform:scale(0) rotate(-180deg);opacity:0}100%{transform:none;opacity:1}}
  .o3-banner{position:absolute;left:0;right:0;top:72%;text-align:center;font:700 7cqw Arial,sans-serif;color:#2f6fd6;animation:o3-pop .6s ease-out .6s backwards;}
  .o3-confetti{position:absolute;inset:0;overflow:hidden;pointer-events:none;}
  .o3-confetti i{position:absolute;top:-4%;width:1.1cqw;height:1.6cqw;border-radius:.2cqw;opacity:.9;animation:o3-fall linear infinite;}
  @keyframes o3-fall{to{transform:translateY(110cqh) rotate(720deg)}}
  @keyframes o3-bounce{0%,100%{transform:translateY(0) scaleX(1)}50%{transform:translateY(-3cqw) scaleX(1.03)}}
  @keyframes o3-slideL{from{transform:translateX(-70cqw);opacity:0}to{transform:none;opacity:1}}
  @keyframes o3-slideR{from{transform:translateX(70cqw);opacity:0}to{transform:none;opacity:1}}
  @keyframes o3-pop{0%{transform:scale(.2);opacity:0}70%{transform:scale(1.12);opacity:1}100%{transform:none}}
  @keyframes o3-fade{from{opacity:0}to{opacity:1}}
  .omit3-stage .o3-enter-L{animation:o3-slideL .7s cubic-bezier(.2,.8,.3,1) backwards;}
  .omit3-stage .o3-enter-R{animation:o3-slideR .7s cubic-bezier(.2,.8,.3,1) backwards;}
  .omit3-stage .o3-enter-pop{animation:o3-pop .45s ease-out backwards;}
  .omit3-stage .o3-enter-fade{animation:o3-fade .5s ease-out backwards;}
  .omit3-stage video ~ .omit3-next{right:2cqw;opacity:.7;}
  .omit3-next{position:absolute;right:18cqw;bottom:2cqw;font:600 2.4cqw Arial,sans-serif;padding:.9cqw 2.4cqw;border-radius:1.2cqw;border:0;background:#2f6fd6;color:#fff;cursor:pointer;display:none;}
  .omit3-why{position:absolute;left:50%;bottom:2cqw;transform:translateX(-50%);width:52cqw;display:none;background:rgba(255,255,255,.96);border:1px solid #ccc;border-radius:1.2cqw;padding:1cqw 1.2cqw;box-shadow:0 .3cqw 1.2cqw rgba(0,0,0,.12);}
  .omit3-why label{display:block;font:1.7cqw Arial,sans-serif;color:#444;margin-bottom:.5cqw;}
  .omit3-why textarea{width:100%;box-sizing:border-box;height:6.5cqw;font:1.9cqw Arial,sans-serif;padding:.6cqw;border:1px solid #bbb;border-radius:.6cqw;resize:none;}
  .omit3-replay{position:absolute;left:2cqw;bottom:2cqw;font:2cqw Arial,sans-serif;padding:.6cqw 1.4cqw;border-radius:1cqw;border:1px solid #bbb;background:#fff;color:#555;cursor:pointer;display:none;}
  `;
  let cssInjected = false;
  let prevKeys = new Set();   // element keys shown on the previous page

  class Omit3ScenePlugin {
    static info = {
      name: 'omit3-scene',
      parameters: {
        scene: { type: 'STRING', default: '' },
        audio: { type: 'COMPLEX', default: null },       // narration key, or [{key, shake:'left'|'right'}] played in order
        choices: { type: 'BOOL', default: false },        // left/right zones in the scene
        correct: { type: 'STRING', default: null },       // 'left' | 'right' for training items
        wrong_audio: { type: 'COMPLEX', default: null },   // key or segment list, played after a wrong answer
        right_audio: { type: 'STRING', default: null },
        praise_always: { type: 'BOOL', default: false },   // false: right_audio only after a corrected retry
        why: { type: 'BOOL', default: false },
        why_audio: { type: 'STRING', default: 'why' },
        auto_advance_ms: { type: 'INT', default: 500 },
        show_next: { type: 'BOOL', default: false },      // parent must press Next (no choices)
        next_label: { type: 'STRING', default: null },
        min_ms: { type: 'INT', default: 0 },
        narrator: { type: 'BOOL', default: true },
        stars: { type: 'INT', default: -1 },       // filled stars to show on the shelf (-1 hides it)
        total_stars: { type: 'INT', default: 5 },
        reward: { type: 'INT', default: 0 },       // >0: this page awards star #reward
        video: { type: 'STRING', default: null },   // url: play a video full-stage, advance when it ends
        dance: { type: 'COMPLEX', default: null },  // { frames: [urls], fps, ms }: narrator dances centre-stage, then advance
      },
    };
    constructor(jsPsych) { this.jsPsych = jsPsych; }
    trial(display, trial) {
      const jsPsych = this.jsPsych;
      if (!cssInjected) { const s = document.createElement('style'); s.textContent = CSS; document.head.appendChild(s); cssInjected = true; }
      const narrHtml = (trial.narrator && !trial.video && !trial.dance) ? '<img class="omit3-narrator" src="' + asset('narrator/rest.png') + '" style="left:' + px(G.narrator[0]) + ';top:' + py(G.narrator[1]) + ';width:' + px(G.narrator[2]) + ';height:' + py(G.narrator[3]) + ';">' : '';
      const shelf = trial.stars >= 0 ? shelfHtml(trial.stars, trial.total_stars) : '';
      display.innerHTML = '<div class="omit3-wrap"><div class="omit3-stage">' + trial.scene + shelf + narrHtml +
        '<div class="omit3-why"><label>Why do you think that? Type your answer, or tell your grown-up and they can type what you say. Then press Next.</label><textarea class="omit3-whytext" autocomplete="off"></textarea></div>' +
        '<button class="omit3-replay">&#9654; hear again</button><button class="omit3-next">Next &#8250;</button>' +
        '</div></div>';
      const narr = Narrator.attach(display.querySelector('.omit3-narrator'));
      const stage = display.querySelector('.omit3-stage');
      const nextBtn = display.querySelector('.omit3-next');
      const replayBtn = display.querySelector('.omit3-replay');
      // entrance animations for elements that were not on the previous page
      let enterMs = 0; const nowKeys = new Set();
      const els = Array.from(stage.querySelectorAll('[data-k]'));
      const newEls = els.filter((el) => { nowKeys.add(el.dataset.k); return !prevKeys.has(el.dataset.k) && !el.classList.contains('o3-late'); });
      const allNew = newEls.length === els.length;   // whole page changed: stagger characters a little
      let order = 0;
      newEls.forEach((el) => {
        const kind = el.dataset.kind; let cls, dur;
        if (kind === 'char') { const leftFrac = parseFloat(el.style.left) / 100; cls = leftFrac < 0.42 ? 'o3-enter-L' : 'o3-enter-R'; dur = 700; }
        else if (kind === 'pop') { cls = 'o3-enter-pop'; dur = 450; }
        else { cls = 'o3-enter-fade'; dur = 500; }
        let delay = 0;
        if (kind === 'char') { delay = allNew ? 120 + 100 * (order++) : 80; }
        else if (kind === 'pop') { delay = allNew ? 500 : 200; }     // bubbles/icons after the characters have arrived
        el.style.animationDelay = delay + 'ms'; el.classList.add(cls);
        enterMs = Math.max(enterMs, delay + dur);
      });
      prevKeys = nowKeys;
      const t0 = performance.now();
      const data = { choice: null, rt: null, attempts: 0, audio_ok: null, audio_key: Array.isArray(trial.audio) ? trial.audio.map((a) => a.key).join('+') : trial.audio };
      let readyAt = null, finished = false, audio = null, timer = null;

      const finish = () => {
        if (finished) return; finished = true;
        if (audio) { audio.pause(); audio = null; }
        if (timer) clearTimeout(timer);
        const ta = display.querySelector('.omit3-whytext'); if (trial.why && ta) data.why_text = ta.value.trim();
        narr.stop();
        display.innerHTML = '';
        jsPsych.finishTrial(data);
      };
      // the entrance animation (o3-enter-*) would otherwise override the shake animation on a character that has just slid in
      const shakeOn = (side) => { stage.querySelectorAll('[data-choice="' + side + '"]').forEach((z) => { z.classList.remove('o3-enter-L', 'o3-enter-R', 'o3-enter-pop', 'o3-enter-fade'); z.style.animationDelay = ''; z.classList.add('shake'); }); };
      const shakeOff = () => { stage.querySelectorAll('.shake').forEach((z) => z.classList.remove('shake')); };
      const play = (key, onEnd) => {
        if (audio) { audio.pause(); }
        if (!key) { onEnd && onEnd(); return; }
        if (Array.isArray(key)) {   // sequence of segments, each optionally shaking one side while it plays
          const seq = key.slice();
          const step = (ok) => { shakeOff(); const it = seq.shift(); if (!it) { onEnd && onEnd(ok !== false); return; } if (it.shake) shakeOn(it.shake); play(it.key, step); };
          step(true); return;
        }
        audio = new Audio(); audio.crossOrigin = 'anonymous'; audio.src = audioUrl(key);
        let done = false;
        const end = (ok) => { if (done) return; done = true; narr.silent(); if (data.audio_ok === null) data.audio_ok = ok; onEnd && onEnd(ok); };
        narr.talk(audio);
        audio.addEventListener('ended', () => end(true));
        audio.addEventListener('error', () => end(false));
        const p = audio.play();
        if (p && p.catch) p.catch(() => end(false));
      };
      const late = Array.from(stage.querySelectorAll('.o3-late'));
      late.forEach((el) => { el.style.visibility = 'hidden'; el.style.animation = 'none'; });
      const afterNarration = (ok) => {
        replayBtn.style.display = 'block';
        let hold = 0;
        if (late.length) {   // reveal the bubble now that the sentence has been said
          late.forEach((el, i) => { el.style.visibility = ''; el.style.animation = ''; el.classList.remove('o3-enter-pop'); void el.offsetWidth; el.style.animationDelay = (i * 120) + 'ms'; el.classList.add('o3-enter-pop'); });
          hold = 1300;
        }
        if (trial.choices) {
          stage.classList.add('ready'); readyAt = performance.now();
        } else if (trial.show_next || !ok) {
          nextBtn.style.display = 'block';
        } else {
          const wait = Math.max(trial.auto_advance_ms + hold, trial.min_ms - (performance.now() - t0));
          timer = setTimeout(finish, wait);
        }
      };
      replayBtn.addEventListener('click', () => { if (trial.audio) play(trial.audio, () => {}); });
      nextBtn.addEventListener('click', finish);
      if (trial.next_label) nextBtn.innerHTML = trial.next_label;

      if (trial.choices) {
        stage.querySelectorAll('.zone').forEach((z) => {
          z.addEventListener('click', () => {
            if (!stage.classList.contains('ready') || finished) return;
            const side = z.dataset.choice;
            data.attempts += 1;
            if (trial.correct && side !== trial.correct) {
              data.wrong_first = data.wrong_first || side;
              if (data.attempts >= 3) { data.choice = side; data.rt = Math.round(performance.now() - readyAt); finish(); return; }
              stage.classList.remove('ready');
              play(trial.wrong_audio, () => { stage.classList.add('ready'); });
              return;
            }
            data.choice = side; data.rt = Math.round(performance.now() - readyAt);
            stage.classList.remove('ready');
            stage.querySelectorAll('.zone').forEach((o) => o.classList.add(o === z ? 'chosen' : 'dim'));
            narr.react();
            const after = () => { if (trial.why) { const wb = display.querySelector('.omit3-why'); wb.style.display = 'block'; play(trial.why_audio, () => { nextBtn.style.display = 'block'; display.querySelector('.omit3-whytext').focus(); }); } else { timer = setTimeout(finish, 600); } };
            if (trial.correct && trial.right_audio && (trial.praise_always || data.attempts > 1)) play(trial.right_audio, after); else after();
          });
        });
      }
      if (trial.dance) {
        const dz = trial.dance; const r = [3.4, 0.9, 3.2, 4.5];
        const im = document.createElement('img'); im.draggable = false; im.src = dz.frames[0];
        im.style.cssText = 'position:absolute;left:' + px(r[0]) + ';top:' + py(r[1]) + ';width:' + px(r[2]) + ';height:' + py(r[3]) + ';object-fit:contain;animation:o3-bounce .5s ease-in-out infinite;transform-origin:50% 100%;';
        stage.insertBefore(im, stage.firstChild);
        let k = 0; const iv = setInterval(() => { k = (k + 1) % dz.frames.length; im.src = dz.frames[k]; }, 1000 / (dz.fps || 5));
        timer = setTimeout(() => { clearInterval(iv); finish(); }, dz.ms || 10000);
        setTimeout(() => play(trial.audio, () => {}), 250);
        return;
      }
      if (trial.video) {
        const v = document.createElement('video'); v.setAttribute('playsinline', ''); v.preload = 'auto';
        // mp4 (H.264) first, then a .webm twin of the same name as a fallback for browsers without H.264
        v.innerHTML = '<source src="' + trial.video + '" type="video/mp4"><source src="' + trial.video.replace(/\.mp4$/, '.webm') + '" type="video/webm">';
        v.style.cssText = 'position:absolute;inset:0;width:100%;height:100%;background:#000;object-fit:contain;';
        stage.insertBefore(v, stage.firstChild);
        v.addEventListener('ended', () => { timer = setTimeout(finish, 400); });
        v.querySelectorAll('source')[1].addEventListener('error', () => { nextBtn.style.display = 'block'; });
        const p = v.play(); if (p && p.catch) p.catch(() => { nextBtn.style.display = 'block'; });
        nextBtn.textContent = 'Skip \u203a'; setTimeout(() => { if (!finished) nextBtn.style.display = 'block'; }, 5000);
        data.video = trial.video;
        return;   // no narration on video pages
      }
      if (trial.reward > 0) {
        const big = stage.querySelector('.o3-bigstar'), slot = stage.querySelector('.o3-slot[data-slot="' + trial.reward + '"]');
        if (big && slot) setTimeout(() => {
          big.classList.add('fly'); big.style.left = slot.style.left; big.style.top = slot.style.top; big.style.width = slot.style.width; big.style.height = slot.style.height;
          setTimeout(() => { slot.classList.add('filled', 'just'); big.style.opacity = '0'; narr.react(); }, 800);
        }, 1400);
      }
      // small delay so images paint before narration starts
      setTimeout(() => play(trial.audio, afterNarration), 250 + enterMs);
    }
  }

  // ---------------------------------------------------------------- timeline
  function buildTimeline(jsPsych, opts) {
    opts = opts || {};
    BASE = opts.baseUrl || '';
    const vkey = opts.version || jsPsych.randomization.sampleWithoutReplacement(Object.keys(D.versions), 1)[0];
    const V = D.versions[vkey];
    // Why? prompts: 'all' = after every DV (and the two practice sharing items), 'friend' = only after the
    // better-friends question (default), 'none' = never.
    const whyMode = opts.why === true ? 'all' : opts.why === false ? 'none' : (opts.why || 'friend');
    const why = whyMode === 'all', whyF = whyMode !== 'none';
    const TOTAL = 5; let stars = 0;
    const video = opts.video || {};   // { mid: url, end: url } — a cartoon break after story 2 and/or after the last star
    // narrator: false removes the corner character everywhere, and with it the dance break (which is
    // that same character). The lip-flap depends on a Web Audio analyser reading the narration; when
    // the browser refuses it (CORS, autoplay policy) the mouth flaps at random, so this is the off switch.
    const useNarr = opts.narrator !== false;
    const useRemind = opts.remind !== false;   // recap page after each trial's comprehension checks
    // stills of the two encounters on each DV page; follows `remind` unless set on its own
    const useShots = opts.shots === undefined ? useRemind : opts.shots !== false;
    let dance = useNarr ? (opts.dance || null) : null;   // true | { frames: [urls], fps, ms } — dance break after story 2 (before the video, if both)
    if (dance === true) dance = { frames: DANCE_SEQ.map((k) => asset('narrator/dance_' + String(k).padStart(2, '0') + '.png')), fps: 4, ms: 12000 };
    const T = [];
    const common = { version: vkey };

    const scene = (p) => Object.assign({ type: Omit3ScenePlugin, stars: stars, total_stars: TOTAL, narrator: useNarr }, p, { data: Object.assign({}, common, p.data || {}) });
    const reward = (label) => { stars += 1; T.push(scene({ scene: SC.reward(stars, TOTAL), audio: 'rw_' + stars, stars: stars - 1, reward: stars, show_next: stars === TOTAL, data: { item: 'reward', reward: stars, after: label } })); };

    // framing
    T.push(scene({ scene: SC.frame('welcome'), audio: 'fr_welcome', show_next: true, data: { item: 'welcome' } }));

    // practice
    const PR = D.practice;
    const bestLeft = V.practice_best_side === 'left';
    const pL = bestLeft ? PR.best : PR.friend, pR = bestLeft ? PR.friend : PR.best;
    const bestSide = bestLeft ? 'left' : 'right';
    const prData = (item) => ({ block: 'practice', item: item, left: pL, right: pR, best_side: bestLeft ? 'left' : 'right' });
    // Sam alone, then each friend slides in on its own page while it is introduced (left one first)
    T.push(scene({ scene: SC.practiceTrio(PR.prot, null, null), audio: 'pr_intro', data: prData('intro') }));
    T.push(scene({ scene: SC.practiceTrio(PR.prot, pL, null), audio: [{ key: bestLeft ? 'pr_friend1_best' : 'pr_friend1_friend', shake: 'left' }], data: prData('friend1') }));
    T.push(scene({ scene: SC.practiceTrio(PR.prot, pL, pR), audio: [{ key: bestLeft ? 'pr_friend2_friend' : 'pr_friend2_best', shake: 'right' }], data: prData('friend2') }));
    // question + the two options named in left-to-right order, each character shaking while it is named
    const labels = [{ key: bestLeft ? 'pr_best_first' : 'pr_friend_first', shake: 'left' }, { key: bestLeft ? 'pr_friend_second' : 'pr_best_second', shake: 'right' }];
    const roleL = bestLeft ? 'best friend' : 'friend', roleR = bestLeft ? 'friend' : 'best friend';
    const optText = pL + ', ' + PR.prot + '\u2019s ' + roleL + ', or ' + pR + ', ' + PR.prot + '\u2019s ' + roleR + '?';
    // response training: the roles were just stated, so this has a knowable correct answer and
    // carries the wrong-answer correction loop. Named options are deliberately NOT appended here —
    // they would restate which character is the best friend and give the answer away.
    T.push(scene({ scene: SC.dv(pL, pR, null, 'Who is ' + PR.prot + '’s best friend?'), audio: 'pr_bestfriend', choices: true,
      correct: bestSide, wrong_audio: 'pr_bestfriend_wrong', right_audio: 'pr_bestfriend_right', praise_always: true, data: Object.assign(prData('bestfriend'), { correct_side: bestSide }) }));
    // better-friends wording check: with the roles just given, children should pick the best friend
    T.push(scene({ scene: SC.dv(pL, pR, null, 'Who do you think ' + PR.prot + ' is better friends with: ' + optText), audio: [{ key: 'pr_friend_q' }].concat(labels), choices: true, why: why, data: prData('friend_q') }));
    // the two practice sharing items are the test items themselves \u2014 same props, same wording, and
    // in the same order this version uses for the real ones, so the warm-up rehearses the real task
    const PRQ = {
      icecream: 'Who do you think ' + PR.prot + ' would want to share the ice cream with, even though they\u2019d have to lick the same ice cream cone: ',
      candy: 'Who do you think ' + PR.prot + ' would want to share candy with, by sharing a few of the candies: ',
    };
    const prItems = V.dv_item_first === 'candy' ? ['candy', 'icecream'] : ['icecream', 'candy'];
    prItems.forEach((it) => T.push(scene({ scene: SC.dv(pL, pR, it, PRQ[it] + optText), audio: [{ key: 'pr_' + it }].concat(labels),
      choices: true, why: why, data: Object.assign(prData(it), { dv_item_first: V.dv_item_first }) })));
    reward('practice');
    T.push(scene({ scene: SC.frame('start'), audio: 'fr_start', data: { item: 'start' } }));

    // four trials
    V.order.forEach((t, idx) => {
      const d = D.trials[t]; const P = d.prot;
      let hi = d.hi, lo = d.lo;
      if (t === 'PF') { hi = V.pf_fav === 'owl' ? 'owl_fav' : 'rabbit_fav'; lo = V.pf_fav === 'owl' ? 'rabbit' : 'owl'; }
      const hiTo = V.hi_to[t];                       // 1 or 2
      const hiName = hiTo === 1 ? d.c1 : d.c2;
      // sh_* ride on every trial row: the sheet reads them off the better-friend trial, and the
      // establishing page's own `scene` field is not on that trial (it would otherwise come out undefined)
      const base = { block: 'trial', position: idx + 1, trial: t, protagonist: P, left: d.c1, right: d.c2,
        hi_content: hi, lo_content: lo, hi_told_to: hiTo, hi_classmate: hiName, recording: hiTo === 1 ? 'A' : 'B',
        sh_emotion_first: t === 'SH' ? V.sh_emotion_first : '', sh_sad_scene: t === 'SH' ? V.sh_sad_scene : '' };
      const tr = (p, item, extra) => scene(Object.assign(p, { data: Object.assign({ item: item }, base, extra || {}) }));

      T.push(tr({ scene: SC.intro(P), audio: t + '_intro' }, 'intro'));
      // establishing
      let estOrder = [hi, lo];
      let sceneOf = {};
      if (t === 'SH') {
        estOrder = V.sh_emotion_first === 'sad' ? ['sad', 'happy'] : ['happy', 'sad'];
        sceneOf = { sad: V.sh_sad_scene, happy: V.sh_sad_scene === 'lunch room' ? 'playground' : 'lunch room' };
      }
      estOrder.forEach((c) => {
        const key = t === 'SH' ? t + '_est_' + c + '_' + (sceneOf[c] === 'lunch room' ? 'lunch' : 'recess') : t + '_est_' + c;
        T.push(tr({ scene: SC.establish(P, c, sceneOf[c] || 'school'), audio: key }, 'establish_' + (c === hi ? 'hi' : 'lo'),
          { content: c, scene: sceneOf[c] || 'school' }));
      });
      // encounters: classmate 1 then classmate 2; on each, the meeting + what was NOT told first, then what was told
      [[1, d.c1], [2, d.c2]].forEach(([ci, C]) => {
        const told = hiTo === ci ? hi : lo, not = hiTo === ci ? lo : hi;
        T.push(tr({ scene: SC.encounter(P, C, not, false), audio: [{ key: t + '_meet' + ci, shake: 'mate' }, { key: t + '_enc' + ci + '_nottold_' + not }] }, 'enc' + ci + '_nottold', { classmate: C, content: not }));
        T.push(tr({ scene: SC.encounter(P, C, told, true), audio: t + '_enc' + ci + '_told_' + told }, 'enc' + ci + '_told', { classmate: C, content: told }));
      });
      // comprehension checks: "Just to double check: did P tell C <content>?" — higher-rung content for classmate 1 then 2,
      // then the lower-rung content for classmate 1 then 2 (one yes and one no per content)
      [[hi, 'hi'], [lo, 'lo']].forEach(([c, lab]) => {
        [[1, d.c1], [2, d.c2]].forEach(([ci, C]) => {
          const toldThis = (hiTo === ci) === (c === hi);
          const ans = toldThis ? 'yes' : 'no';
          const qtext = 'Did ' + P + ' tell ' + C + ' ' + D.contents[c].told + '?';
          // praise_always: "That's right!" after every correct answer, not only after a corrected
          // retry — otherwise a child who gets them all right first time never hears it
          T.push(tr({ scene: SC.yesno(P, c, C, qtext), audio: t + '_yn' + ci + '_' + c, choices: true, correct: ans,
            wrong_audio: t + '_ynfix' + ci + '_' + c + '_' + ans, right_audio: 'mem_right', praise_always: true }, 'check_' + lab + ci, { classmate: C, content: c, correct_side: ans }));
        });
      });
      // recap: "So, to remind you. P did tell C1 X, but didn't tell C1 Y. And P did tell C2 Y, but
      // didn't tell C2 X." — both classmates on one page, with the protagonist and all four cards,
      // so the DVs that follow do not rest on memory alone.
      if (useRemind) {
        const cardOf = (c) => ({ icon: iconFile(c, P), face: D.contents[c].kind === 'emotion' });
        const rows = [[1, d.c1], [2, d.c2]].map(([ci, C]) => ({
          mate: C, told: cardOf(hiTo === ci ? hi : lo), not: cardOf(hiTo === ci ? lo : hi),
        }));
        const rk = t + '_recap_' + hi + '_' + (hiTo === 1 ? 'A' : 'B');
        T.push(tr({ scene: SC.recap(P, rows), min_ms: 1200,
          audio: [{ key: rk + '_1', shake: 'row1' }, { key: rk + '_2', shake: 'row2' }] }, 'recap'));
      }
      // DVs. Each carries a still of what each classmate was told (see SC.shot), so the choice does
      // not rest on memory; `shots: false` drops them and restores the plain two-character page.
      const shots = useShots ? [[1, d.c1], [2, d.c2]].map(([ci, C]) => ({ prot: P, mate: C, content: hiTo === ci ? hi : lo })) : null;
      T.push(tr({ scene: SC.dv(d.c1, d.c2, null, 'Who do you think ' + P + ' is better friends with?', shots), audio: t + '_dv_friend', choices: true, why: whyF }, 'friend'));
      const items = V.dv_item_first === 'candy' ? ['candy', 'icecream'] : ['icecream', 'candy'];   // constant within child, counterbalanced across versions
      items.forEach((it) => T.push(tr({ scene: SC.dv(d.c1, d.c2, it, null, shots), audio: t + '_dv_' + it, choices: true, why: why }, it, { dv_item_first: V.dv_item_first })));
      reward(t);
      if (idx === 1 && dance) T.push(scene({ scene: '', dance: dance, audio: 'dance_mid', stars: stars, data: { item: 'dance' } }));
      if (idx === 1 && video.mid) T.push(scene({ scene: '', audio: 'vd_mid', data: { item: 'video_intro' } }), scene({ scene: '', video: video.mid, stars: stars, data: { item: 'video' } }));
    });

    if (video.end) T.push(scene({ scene: '', audio: 'vd_end', data: { item: 'video_intro' } }), scene({ scene: '', video: video.end, stars: stars, data: { item: 'video' } }));
    T.push(scene({ scene: SC.frame('alldone'), audio: 'fr_done', show_next: true, next_label: 'Finish &#8250;', data: { item: 'done' } }));

    // derived fields on every choice trial
    T.forEach((tr) => {
      if (!tr.choices) return;
      tr.on_finish = (data) => {
        if (data.choice) {
          data.choice_name = data.choice === 'left' ? data.left : data.choice === 'right' ? data.right : data.choice;
          if (data.hi_classmate) data.chose_hi = data.choice_name === data.hi_classmate ? 1 : 0;
          if (data.best_side) data.chose_best = data.choice === data.best_side ? 1 : 0;
          if (data.correct_side) { data.correct = (data.wrong_first ? 0 : (data.choice === data.correct_side ? 1 : 0)); data.final_correct = data.choice === data.correct_side ? 1 : 0; }
        }
      };
    });
    return { timeline: T, version: vkey };
  }

  // asset lists for preloading
  function assetLists(opts) {
    const useNarr = !(opts && opts.narrator === false);
    const imgs = [];
    const add = (p) => imgs.push(asset(p));
    ['casey', 'percy', 'kendall', 'jamie', 'sam', 'blake', 'morgan', 'avery', 'orin', 'riley', 'cameron', 'elliot', 'parker', 'quinn', 'rowan'].forEach((c) => add('characters/' + c + '.png'));
    Object.keys(ICON).forEach((i) => add('icons/' + i + '.png'));
    // juicebox.png and cookies.png are still in assets/, unused since the practice items became the test items
    ['lunchroom', 'playground', 'chalkboard', 'desk', 'houses', 'question', 'icecream', 'candy'].forEach((b) => add('bg/' + b + '.png'));
    ['welcome', 'about', 'start', 'alldone'].forEach((f) => add('frames/' + f + '.png'));
    ['cloud', 'balloon', 'nosymbol'].forEach((l) => add('layers/' + l + '.png'));
    if (useNarr) {
      Narrator.frames.forEach((f) => add('narrator/' + f + '.png'));
      for (let k = 1; k <= 8; k++) add('narrator/dance_' + String(k).padStart(2, '0') + '.png');
    }
    const audio = Object.keys(D.narration).map(audioUrl);
    return { images: imgs, audio: audio };
  }

  global.OMIT3 = { buildTimeline, assetLists, Omit3ScenePlugin, scenes: SC, setBase: (b) => { BASE = b; } };
})(typeof window !== 'undefined' ? window : globalThis);
