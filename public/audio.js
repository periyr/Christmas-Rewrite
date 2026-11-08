// Sound for Christmas Rewrite: every effect and the music are made in code
// with the Web Audio API, so there are no sound files to load or license.
//
//   GameAudio.play("page")   one effect (names come from src/Sounds.elm)
//   GameAudio.toggleMute()   on/off, remembered in localStorage
//
// Browsers only allow sound after the player has clicked or pressed a key,
// so the audio starts on the first click or key press. The music is "Silent
// Night" (Franz Gruber, 1818, public domain) on a quiet music box, looping.
(() => {
  const MUTE_KEY = "one-more-christmas-muted";
  const SFX_VOLUME = 0.55;
  const MUSIC_VOLUME = 0.03; // well under the effects, so they stay clear

  let ctx = null, master, sfxBus, musicBus, room;
  let muted = false;
  try { muted = localStorage.getItem(MUTE_KEY) === "1"; } catch (_) {}

  // ---------- setup ----------

  function start() {
    if (ctx) { if (ctx.state === "suspended") ctx.resume(); return; }
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    ctx = new AC();
    master = ctx.createGain();
    master.gain.value = muted ? 0 : 1;
    master.connect(ctx.destination);

    // A small, warm room: a short generated reverb and a gentle low-pass.
    const warm = ctx.createBiquadFilter();
    warm.type = "lowpass"; warm.frequency.value = 7000;
    warm.connect(master);
    room = ctx.createConvolver();
    room.buffer = impulse(1.6, 3);
    const wet = ctx.createGain(); wet.gain.value = 0.22;
    room.connect(wet).connect(warm);

    sfxBus = ctx.createGain(); sfxBus.gain.value = SFX_VOLUME;
    sfxBus.connect(warm); sfxBus.connect(room);
    musicBus = ctx.createGain(); musicBus.gain.value = MUSIC_VOLUME;
    musicBus.connect(warm); musicBus.connect(room);

    startMusic();
  }

  function impulse(seconds, decay) {
    const length = Math.floor(ctx.sampleRate * seconds);
    const buffer = ctx.createBuffer(2, length, ctx.sampleRate);
    for (let c = 0; c < 2; c++) {
      const data = buffer.getChannelData(c);
      for (let i = 0; i < length; i++) data[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / length, decay);
    }
    return buffer;
  }

  let noiseBuffer = null;
  function noise() {
    if (!noiseBuffer) {
      noiseBuffer = ctx.createBuffer(1, ctx.sampleRate, ctx.sampleRate);
      const d = noiseBuffer.getChannelData(0);
      for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
    }
    const src = ctx.createBufferSource();
    src.buffer = noiseBuffer;
    return src;
  }

  // ---------- building blocks ----------

  const note = (name) => {
    const m = /^([A-G])(#|b)?(\d)$/.exec(name);
    const semis = { C: -9, D: -7, E: -5, F: -4, G: -2, A: 0, B: 2 }[m[1]] + (m[2] === "#" ? 1 : m[2] === "b" ? -1 : 0);
    return 440 * Math.pow(2, (semis + (Number(m[3]) - 4) * 12) / 12);
  };

  // A soft pitched tone with a quick attack and a smooth fade.
  function tone(freq, { at = 0, dur = 0.3, type = "sine", gain = 0.3, attack = 0.005, glide = null, bus = sfxBus } = {}) {
    const t = ctx.currentTime + at;
    const osc = ctx.createOscillator(), g = ctx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, t);
    if (glide) osc.frequency.exponentialRampToValueAtTime(glide, t + dur);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(gain, t + attack);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    osc.connect(g).connect(bus);
    osc.start(t); osc.stop(t + dur + 0.05);
  }

  // A music-box / small bell note: a sine with a faint, faster-fading overtone.
  function bell(freq, { at = 0, dur = 1.2, gain = 0.22, bus = sfxBus } = {}) {
    tone(freq, { at, dur, gain, bus });
    tone(freq * 4, { at, dur: dur * 0.3, gain: gain * 0.18, bus });
    tone(freq * 2.01, { at, dur: dur * 0.5, gain: gain * 0.12, bus });
  }

  // Filtered noise: paper, cardboard, footsteps, whooshes.
  function hiss({ at = 0, dur = 0.2, gain = 0.2, type = "bandpass", freq = 2000, to = null, q = 1, attack = 0.01, bus = sfxBus } = {}) {
    const t = ctx.currentTime + at;
    const src = noise(), f = ctx.createBiquadFilter(), g = ctx.createGain();
    f.type = type; f.Q.value = q;
    f.frequency.setValueAtTime(freq, t);
    if (to) f.frequency.exponentialRampToValueAtTime(to, t + dur);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(gain, t + attack);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    src.connect(f).connect(g).connect(bus);
    src.start(t, Math.random() * 0.5); src.stop(t + dur + 0.05);
  }

  const pentatonic = ["C6", "D6", "E6", "G6", "A6", "C7", "D7", "E7"].map(note);
  const pick = (list) => list[Math.floor(Math.random() * list.length)];
  const wobble = (x, amount = 0.04) => x * (1 + (Math.random() * 2 - 1) * amount);

  // ---------- the effects ----------

  const sounds = {
    // reading and moving on
    "page": () => { hiss({ dur: 0.28, gain: 0.12, freq: 1400, to: 3200, q: 0.8, attack: 0.06 }); },
    "paper-open": () => { hiss({ dur: 0.16, gain: 0.1, type: "highpass", freq: 2500, attack: 0.02 }); hiss({ at: 0.08, dur: 0.18, gain: 0.08, freq: 3000, to: 1800, q: 0.7 }); },
    "paper-close": () => { hiss({ dur: 0.14, gain: 0.08, freq: 2200, to: 1200, q: 0.8, attack: 0.03 }); },
    "panel-open": () => { tone(wobble(330), { dur: 0.09, gain: 0.08, type: "triangle" }); hiss({ at: 0.02, dur: 0.18, gain: 0.06, freq: 1800, q: 0.7 }); },
    "panel-close": () => { tone(wobble(262), { dur: 0.08, gain: 0.06, type: "triangle" }); },

    // pieces
    "book-pick": () => { tone(wobble(150), { dur: 0.12, gain: 0.18, glide: 110 }); hiss({ dur: 0.08, gain: 0.07, type: "lowpass", freq: 900 }); },
    "book-place": () => { tone(wobble(120), { dur: 0.16, gain: 0.22, glide: 80 }); hiss({ dur: 0.1, gain: 0.08, type: "lowpass", freq: 700 }); },
    "card-pick": () => { hiss({ dur: 0.07, gain: 0.1, type: "highpass", freq: 3000 }); },
    "card-place": () => { hiss({ dur: 0.06, gain: 0.08, type: "highpass", freq: 2600 }); tone(wobble(1700), { at: 0.03, dur: 0.05, gain: 0.06, type: "triangle" }); },
    "cutout-pick": () => { hiss({ dur: 0.09, gain: 0.12, freq: 900, q: 1.2 }); },
    "cutout-place": () => { hiss({ dur: 0.1, gain: 0.12, freq: 600, q: 1.2 }); tone(wobble(200), { dur: 0.08, gain: 0.08, type: "triangle" }); },
    "glass-pick": () => { bell(wobble(note("E7"), 0.02), { dur: 0.35, gain: 0.07 }); },
    "glass-place": () => { bell(wobble(note("C7"), 0.02), { dur: 0.4, gain: 0.08 }); bell(wobble(note("G7"), 0.02), { at: 0.06, dur: 0.35, gain: 0.05 }); },

    // the photograph falls: a soft burst and a little cascade of glass
    "shatter": () => {
      hiss({ dur: 0.35, gain: 0.16, type: "highpass", freq: 3500, attack: 0.004 });
      for (let i = 0; i < 14; i++) bell(wobble(pick(pentatonic), 0.03), { at: 0.02 + Math.pow(i / 14, 1.6) * 0.8, dur: 0.4, gain: 0.05 + Math.random() * 0.03 });
    },

    // answers, gently
    "nope": () => { tone(220, { dur: 0.12, gain: 0.12, type: "triangle" }); tone(196, { at: 0.11, dur: 0.16, gain: 0.1, type: "triangle" }); },
    "hmm": () => { tone(247, { dur: 0.35, gain: 0.1, type: "triangle", glide: 233 }); },
    "mistake": () => { bell(note("E5"), { gain: 0.14 }); bell(note("C5"), { at: 0.22, dur: 1.4, gain: 0.14 }); },
    "fail": () => { ["A4", "F4", "D4"].forEach((n, i) => bell(note(n), { at: i * 0.32, dur: 1.8, gain: 0.13 })); },
    "success": () => { ["C5", "E5", "G5", "C6"].forEach((n, i) => bell(note(n), { at: i * 0.13, dur: 1.4, gain: 0.15 })); },

    // through time
    "diary-open": () => { tone(110, { dur: 0.2, gain: 0.12, glide: 80 }); hiss({ at: 0.05, dur: 0.4, gain: 0.08, freq: 1200, to: 2800, q: 0.6, attack: 0.1 }); bell(note("G6"), { at: 0.25, dur: 1.2, gain: 0.06 }); },
    "travel": () => {
      hiss({ dur: 2.4, gain: 0.07, freq: 400, to: 4000, q: 0.5, attack: 1.2 });
      for (let i = 0; i < 16; i++) bell(pentatonic[i % 8] / (i < 8 ? 2 : 1), { at: 0.15 + i * 0.13, dur: 0.9, gain: 0.06 });
    },
    "tear": () => {
      hiss({ dur: 1.7, gain: 0.07, freq: 3500, to: 500, q: 0.5, attack: 0.5 });
      for (let i = 0; i < 10; i++) bell(pentatonic[7 - (i % 8)] / (i < 8 ? 1 : 2), { at: 0.1 + i * 0.14, dur: 0.9, gain: 0.05 });
    },
    // the clock ticks three times and stops, with one low soft bell
    "clock-stop": () => {
      [0, 0.5, 1].forEach((at, i) => tone(i % 2 ? 1400 : 1700, { at, dur: 0.04, gain: 0.1, type: "triangle" }));
      bell(note("C3"), { at: 1.5, dur: 3, gain: 0.12 });
    },
    "ending-saved": () => {
      // the opening of "Jingle Bells" (public domain) on little bells
      const tune = [["E5", 0], ["E5", 0.25], ["E5", 0.5], ["E5", 1], ["E5", 1.25], ["E5", 1.5], ["E5", 2], ["G5", 2.25], ["C5", 2.5], ["D5", 2.75], ["E5", 3]];
      tune.forEach(([n, at]) => bell(note(n), { at: at * 0.9, dur: n === "E5" && at === 3 ? 2 : 0.9, gain: 0.12 }));
    },
    "ending-closed": () => { ["A3", "C4", "E4", "A4"].forEach((n, i) => bell(note(n), { at: i * 0.18, dur: 3.5, gain: 0.08 })); },

    // walking: a muffled step on the boards
    "step": () => { hiss({ dur: 0.06, gain: 0.05, type: "lowpass", freq: wobble(320, 0.15) }); },

    // the title screen
    "twinkle": () => { bell(wobble(pick(pentatonic), 0.01), { dur: 0.8, gain: 0.035 }); },
    "click": () => { tone(wobble(660, 0.02), { dur: 0.08, gain: 0.08, type: "triangle" }); bell(note("G6"), { at: 0.04, dur: 0.5, gain: 0.04 }); },
  };

  // ---------- the 1973 shadow play ----------
  //
  // Each performance slide plays a 3.6 s puppet animation (styles.css,
  // "theatre-*" keyframes). Each scene's sounds are timed to its keyframes and
  // go through their own gain, so leaving the slide early fades them out.

  const SCENE = 3.6;
  const cue = (percent) => SCENE * percent / 100;
  let sceneBus = null;

  function stopScene() {
    if (!sceneBus) return;
    const old = sceneBus;
    old.gain.setTargetAtTime(0, ctx.currentTime, 0.08);
    setTimeout(() => old.disconnect(), 600);
    sceneBus = null;
  }

  function startScene(build) {
    stopScene();
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) return; // the puppets hold still then
    sceneBus = ctx.createGain();
    sceneBus.connect(sfxBus);
    build(sceneBus);
  }

  // Small pieces the scenes share. Puppets are card on sticks behind a sheet,
  // so their steps are soft card taps and everything else is small and light.
  const pat = (bus, at, pitch = 1) => { hiss({ bus, at, dur: 0.07, gain: 0.09, freq: 700 * pitch, q: 1.4 }); tone(wobble(180 * pitch), { bus, at, dur: 0.06, gain: 0.05, type: "triangle" }); };
  const hop = (bus, at) => { tone(wobble(330), { bus, at, dur: 0.16, gain: 0.07, glide: 520 }); };
  const land = (bus, at) => { hiss({ bus, at, dur: 0.08, gain: 0.1, freq: 500, q: 1.2 }); };
  const jingle = (bus, at) => { bell(wobble(note("A6"), 0.02), { bus, at, dur: 0.3, gain: 0.035 }); bell(wobble(note("E7"), 0.02), { bus, at: at + 0.04, dur: 0.25, gain: 0.025 }); };
  const flutter = (bus, at) => { for (let i = 0; i < 4; i++) hiss({ bus, at: at + i * 0.07, dur: 0.06, gain: 0.07, freq: 1100, q: 0.9 }); };
  const pageFlip = (bus, at) => { hiss({ bus, at, dur: 0.3, gain: 0.1, freq: 1300, to: 3000, q: 0.8, attack: 0.06 }); };
  const glow = (bus, at) => { ["C6", "E6", "G6"].forEach((n, i) => bell(note(n), { bus, at: at + i * 0.09, dur: 1.4, gain: 0.05 })); };
  const keyTurn = (bus, at) => { tone(1900, { bus, at, dur: 0.03, gain: 0.08, type: "triangle" }); tone(1400, { bus, at: at + 0.09, dur: 0.04, gain: 0.08, type: "triangle" }); };
  const creak = (bus, at) => { tone(140, { bus, at, dur: 0.55, gain: 0.06, type: "sawtooth", glide: 210 }); hiss({ bus, at, dur: 0.5, gain: 0.04, freq: 900, q: 3 }); };
  const crackle = (bus, from, to) => { for (let t = from; t < to; t += 0.12 + Math.random() * 0.2) hiss({ bus, at: t, dur: 0.025, gain: 0.05 + Math.random() * 0.04, type: "highpass", freq: 2500 }); };

  // The puppets' voices, small and soft. The cast is whoever the player staged.
  const voices = {
    // two little yips, up then down
    fox: (bus, at) => {
      [0, 0.17].forEach((d, i) => {
        tone(wobble(i ? 820 : 760, 0.02), { bus, at: at + d, dur: 0.11, gain: 0.07, type: "triangle", glide: i ? 1150 : 1080, attack: 0.01 });
        tone(wobble(1600, 0.02), { bus, at: at + d + 0.02, dur: 0.06, gain: 0.02, glide: 1250 });
      });
    },
    // "hoo, hoo-hoo": low and round, each hoot dipping slightly
    owl: (bus, at) => {
      [[0, 0.42], [0.55, 0.2], [0.8, 0.38]].forEach(([d, len]) => {
        tone(wobble(392, 0.01), { bus, at: at + d, dur: len, gain: 0.09, glide: 349, attack: 0.06 });
        tone(wobble(196, 0.01), { bus, at: at + d, dur: len, gain: 0.03, type: "triangle", glide: 175, attack: 0.06 });
      });
    },
    // a tiny giggle: quick bouncing notes that tumble down
    child: (bus, at) => {
      [988, 880, 932, 784, 830, 698].forEach((f, i) => {
        tone(wobble(f, 0.015), { bus, at: at + i * 0.085, dur: 0.07, gain: 0.05, type: "triangle", glide: f * 0.92, attack: 0.008 });
        tone(wobble(f * 2, 0.015), { bus, at: at + i * 0.085, dur: 0.05, gain: 0.015 });
      });
    },
  };

  const scenes = {
    // Original script
    "bridge": (b, voice) => {
      voice(b, cue(4)); voice(b, cue(93));                    // crosses the bridge, bobbing, lantern swinging
      [10, 30, 50, 70].forEach((p) => pat(b, cue(p)));
      [10, 34, 58].forEach((p) => jingle(b, cue(p)));
      bell(note("G6"), { bus: b, at: cue(92), dur: 1, gain: 0.04 });
    },
    "door": (b, voice) => {
      voice(b, cue(82));                      // three hops, reaches up, turns the key, the door swings open
      [0, 23, 45].forEach((p, i) => hop(b, cue(p) + (i ? 0 : 0.05)));
      [23, 45, 61].forEach((p) => land(b, cue(p)));
      keyTurn(b, cue(72));
      creak(b, cue(76));
      glow(b, cue(86));
    },
    "reading-home": (b, voice) => {
      voice(b, cue(8)); voice(b, cue(84));              // lifts the book, opens it, the room warms
      hiss({ bus: b, at: cue(30), dur: 0.4, gain: 0.05, freq: 900, q: 0.8, attack: 0.15 });
      pageFlip(b, cue(52)); pageFlip(b, cue(68));
      glow(b, cue(56));
    },
    // The neighbours' retelling
    "gate": (b, voice) => {
      voice(b, cue(70));                      // walks to the gate, leans down, finds and lifts the key
      [5, 17, 29, 41].forEach((p) => pat(b, cue(p)));
      hiss({ bus: b, at: cue(48), dur: 0.35, gain: 0.06, freq: 1500, q: 0.8, attack: 0.1 });
      jingle(b, cue(64)); jingle(b, cue(80));
      bell(note("E6"), { bus: b, at: cue(90), dur: 1, gain: 0.04 });
    },
    "fireplace": (b, voice) => {
      voice(b, cue(47)); voice(b, cue(86));                 // flutters up to perch by the fire, opens the book
      crackle(b, 0, SCENE);
      flutter(b, cue(2)); flutter(b, cue(25));
      land(b, cue(45));
      pageFlip(b, cue(55)); pageFlip(b, cue(72));
    },
    "lantern-home": (b, voice) => {
      voice(b, cue(4)); voice(b, cue(70));              // crosses home with the lantern; the house lights up
      [10, 30, 50, 70].forEach((p) => pat(b, cue(p)));
      [10, 34].forEach((p) => jingle(b, cue(p)));
      glow(b, cue(54));
    },
  };

  // ---------- music: Silent Night on a music box ----------

  // [note, beats] in 3/4. "-" is a rest.
  const melody = [
    ["G4", 1.5], ["A4", 0.5], ["G4", 1], ["E4", 3],
    ["G4", 1.5], ["A4", 0.5], ["G4", 1], ["E4", 3],
    ["D5", 2], ["D5", 1], ["B4", 3],
    ["C5", 2], ["C5", 1], ["G4", 3],
    ["A4", 2], ["A4", 1], ["C5", 1.5], ["B4", 0.5], ["A4", 1],
    ["G4", 1.5], ["A4", 0.5], ["G4", 1], ["E4", 3],
    ["A4", 2], ["A4", 1], ["C5", 1.5], ["B4", 0.5], ["A4", 1],
    ["G4", 1.5], ["A4", 0.5], ["G4", 1], ["E4", 3],
    ["D5", 2], ["D5", 1], ["F5", 1.5], ["D5", 0.5], ["B4", 1],
    ["C5", 3], ["E5", 3],
    ["C5", 1], ["G4", 1], ["E4", 1], ["G4", 1.5], ["F4", 0.5], ["D4", 1],
    ["C4", 6],
    ["-", 6],
  ];
  // One chord per bar (3 beats).
  const chords = "C C C C G G C C F F C C F F C C G G C C C G C C C C".split(" ");
  const chordNotes = { C: ["C3", "G3", "E4"], F: ["F2", "C3", "A3"], G: ["G2", "D3", "B3"] };
  const BEAT = 0.75; // seconds: slow and calm

  let musicTimer = null;
  function startMusic() {
    if (musicTimer) return;
    let next = ctx.currentTime + 0.5;
    const loopLength = melody.reduce((s, [, b]) => s + b, 0) * BEAT;
    const scheduleLoop = (t0) => {
      let t = t0;
      for (const [n, beats] of melody) {
        if (n !== "-") {
          const at = t - ctx.currentTime;
          bell(note(n), { at, dur: Math.max(1.2, beats * BEAT * 1.4), gain: 0.5, bus: musicBus });
        }
        t += beats * BEAT;
      }
      chords.forEach((c, bar) => chordNotes[c].forEach((n) =>
        tone(note(n), { at: t0 + bar * 3 * BEAT - ctx.currentTime, dur: 3 * BEAT + 0.6, gain: 0.08, type: "triangle", attack: 0.4, bus: musicBus })));
    };
    // Schedule one loop ahead, a little before the current one ends.
    scheduleLoop(next);
    musicTimer = setInterval(() => {
      if (ctx.currentTime > next + loopLength - 2) { next += loopLength; scheduleLoop(next); }
    }, 500);
  }

  // ---------- public ----------

  function play(name) {
    if (!ctx || ctx.state !== "running") return;
    if (name === "scene-stop") { stopScene(); return; }
    if (muted) return;
    if (name.startsWith("scene-")) {
      // "scene-<setting>-<fox|owl|child>"
      const rest = name.slice("scene-".length), cut = rest.lastIndexOf("-");
      const scene = scenes[rest.slice(0, cut)], voice = voices[rest.slice(cut + 1)] || (() => {});
      if (scene) startScene((bus) => scene(bus, voice));
      return;
    }
    const sound = sounds[name];
    if (sound) sound();
  }

  function toggleMute() {
    muted = !muted;
    try { localStorage.setItem(MUTE_KEY, muted ? "1" : "0"); } catch (_) {}
    if (ctx) master.gain.setTargetAtTime(muted ? 0 : 1, ctx.currentTime, 0.05);
    updateButton();
    return muted;
  }

  // ---------- the on/off button, and starting on the first input ----------

  let button = null;
  function updateButton() {
    if (!button) return;
    button.classList.toggle("is-muted", muted);
    button.setAttribute("aria-pressed", String(!muted));
    button.setAttribute("aria-label", muted ? "Sound off. Turn sound on" : "Sound on. Turn sound off");
    button.title = muted ? "Sound off" : "Sound on";
  }

  function addButton() {
    button = document.createElement("button");
    button.type = "button";
    button.className = "sound-toggle";
    button.innerHTML = '<svg viewBox="0 0 24 24" aria-hidden="true"><path class="sound-toggle__speaker" d="M4 9h4l5-4v14l-5-4H4Z"/><path class="sound-toggle__waves" d="M16 9c1.3 1.6 1.3 4.4 0 6M18.5 6.5c2.7 3 2.7 8 0 11"/><path class="sound-toggle__cross" d="M16 9l5 6M21 9l-5 6"/></svg>';
    button.addEventListener("click", (e) => { e.stopPropagation(); start(); toggleMute(); button.blur(); });
    document.body.appendChild(button);
    updateButton();
  }

  const firstInput = () => { start(); };
  window.addEventListener("pointerdown", firstInput);
  window.addEventListener("keydown", firstInput);

  // Title screen: bulbs twinkle as the pointer passes; menu lines click.
  document.addEventListener("mouseover", (e) => {
    if (e.target.classList && e.target.classList.contains("title-bulb")) play("twinkle");
  });
  document.addEventListener("click", (e) => {
    if (e.target.closest && e.target.closest(".title-menu__item:not(:disabled)")) play("click");
  });

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", addButton);
  else addButton();

  window.GameAudio = { play, toggleMute, start };
})();
