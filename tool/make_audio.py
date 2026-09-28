"""Synthesises every sound + the background music loop for Mil ke Khelo.

All audio is generated from scratch here (no samples), so there are no
licensing questions. Output: 44.1 kHz OGG Vorbis in ../out/.
"""
import os
import subprocess

import numpy as np
from scipy.signal import butter, lfilter

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(os.path.join(OUT, "sfx"), exist_ok=True)
os.makedirs(os.path.join(OUT, "music"), exist_ok=True)
rng = np.random.default_rng(7)


# ---------------------------------------------------------------- helpers
def t_(dur):
    return np.arange(int(dur * SR)) / SR


def env_ad(n, attack=0.004, decay=0.15):
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    d = np.exp(-np.maximum(t - attack, 0) / decay)
    return a * d


def lp(x, fc, order=2):
    b, a = butter(order, fc / (SR / 2), "low")
    return lfilter(b, a, x)


def hp(x, fc, order=2):
    b, a = butter(order, fc / (SR / 2), "high")
    return lfilter(b, a, x)


def bp(x, lo, hi, order=2):
    b, a = butter(order, [lo / (SR / 2), hi / (SR / 2)], "band")
    return lfilter(b, a, x)


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def place(buf, sig, at):
    i = int(at * SR)
    end = min(len(buf), i + len(sig))
    if i < len(buf):
        buf[i:end] += sig[: end - i]


def marimba(f, dur=0.35, bright=1.0):
    t = t_(dur)
    n = len(t)
    s = np.sin(2 * np.pi * f * t) * env_ad(n, 0.002, dur * 0.45)
    s += 0.35 * bright * np.sin(2 * np.pi * f * 4 * t) * env_ad(n, 0.001, dur * 0.08)
    s += 0.12 * bright * np.sin(2 * np.pi * f * 10 * t) * env_ad(n, 0.0005, 0.012)
    return s


def bell(f, dur=0.8):
    t = t_(dur)
    n = len(t)
    s = np.zeros(n)
    for ratio, amp, dec in [(1, 1, 0.5), (2.0, 0.5, 0.3), (3.01, 0.25, 0.18), (5.4, 0.12, 0.08)]:
        s += amp * np.sin(2 * np.pi * f * ratio * t) * env_ad(n, 0.002, dur * dec)
    return s


def pluck(f, dur=0.3):
    """Soft bass pluck: triangle-ish, low-passed."""
    t = t_(dur)
    ph = (f * t) % 1.0
    tri = 4 * np.abs(ph - 0.5) - 1
    s = (0.7 * tri + 0.5 * np.sin(2 * np.pi * f * t)) * env_ad(len(t), 0.004, dur * 0.5)
    return lp(s, 900)


def noise(dur):
    return rng.standard_normal(int(dur * SR))


def normalize(x, peak_db=-3.0):
    p = np.max(np.abs(x)) + 1e-9
    return x / p * (10 ** (peak_db / 20))


def fade(x, fin=0.002, fout=0.01):
    n = len(x)
    a = int(fin * SR)
    b = int(fout * SR)
    if a:
        x[:a] *= np.linspace(0, 1, a)
    if b:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def write(path, x, stereo=False, q=4):
    x = np.clip(x, -1, 1)
    raw = path + ".raw"
    (x * 32767).astype("<i2").tofile(raw)
    ch = "2" if stereo else "1"
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", ch,
         "-i", raw, "-c:a", "libvorbis", "-q:a", str(q), path],
        check=True,
    )
    os.remove(raw)


def sfx(name, x, peak=-3.0):
    x = fade(normalize(x, peak))
    write(os.path.join(OUT, "sfx", name + ".ogg"), x)


# ---------------------------------------------------------------- SFX
# UI tap — soft bubbly "pop" (pitch drops fast), like chat-app taps.
t = t_(0.07)
f = 700 * np.exp(-t * 18) + 380
x = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_ad(len(t), 0.001, 0.025)
sfx("tap", x, -6)

# Toggle — tiny crisp tick.
t = t_(0.04)
x = np.sin(2 * np.pi * 2200 * t) * env_ad(len(t), 0.0005, 0.006)
x += 0.4 * hp(noise(0.04), 3000) * env_ad(len(t), 0.0005, 0.003)
sfx("toggle", x, -8)

# Card flip / swipe — airy whoosh + paper snap.
dur = 0.22
t = t_(dur)
n = noise(dur)
sweep = np.linspace(0, 1, len(t))
w = bp(n, 600, 5000) * np.sin(np.pi * sweep) ** 2
snap = hp(noise(dur), 2500) * env_ad(len(t), 0.0005, 0.01)
snap = np.roll(snap, int(0.15 * SR))
sfx("card_flip", 0.8 * w + 0.5 * snap, -5)

# Shuffle — quick riffle of little card clicks.
buf = np.zeros(int(0.45 * SR))
for i in range(12):
    c = hp(noise(0.02), 1800) * env_ad(int(0.02 * SR), 0.0005, 0.004)
    place(buf, c * (0.6 + 0.4 * rng.random()), 0.02 + i * 0.03 + rng.random() * 0.008)
sfx("shuffle", buf, -5)

# Dice rattle — random plastic clacks in a cup.
buf = np.zeros(int(0.6 * SR))
for i in range(16):
    fclk = 1800 + rng.random() * 1600
    tt = t_(0.025)
    c = np.sin(2 * np.pi * fclk * tt) * env_ad(len(tt), 0.0005, 0.005)
    c += 0.6 * bp(noise(0.025), 1500, 6000) * env_ad(len(tt), 0.0005, 0.004)
    place(buf, c * (0.4 + 0.6 * rng.random()), 0.01 + i * 0.035 + rng.random() * 0.01)
sfx("dice_roll", buf, -6)

# Dice land — satisfying wooden thunk.
t = t_(0.18)
f = 260 * np.exp(-t * 25) + 140
x = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_ad(len(t), 0.001, 0.05)
x += 0.5 * bp(noise(0.18), 800, 3000) * env_ad(len(t), 0.0005, 0.01)
sfx("dice_land", x, -3)

# Goti step — short, light marimba hop.
sfx("step", marimba(midi(79), 0.12), -9)

# Ladder — fast ascending marimba run (C major pentatonic).
buf = np.zeros(int(0.9 * SR))
for i, m in enumerate([72, 74, 76, 79, 81, 84]):
    place(buf, marimba(midi(m), 0.3), i * 0.07)
place(buf, 0.5 * bell(midi(96), 0.5), 0.42)
sfx("ladder", buf, -3)

# Snake — cartoon slide-whistle down with wobble.
dur = 0.7
t = t_(dur)
f = 900 * (1 - t / dur) ** 1.5 + 180
f = f * (1 + 0.03 * np.sin(2 * np.pi * 9 * t))
x = np.sin(2 * np.pi * np.cumsum(f) / SR)
x = 0.8 * x + 0.2 * np.sign(x) * np.abs(x) ** 3  # a little reed
x *= env_ad(len(t), 0.01, 0.5)
sfx("snake", lp(x, 3000), -4)

# Turn change — soft two-note chime.
buf = np.zeros(int(0.6 * SR))
place(buf, bell(midi(79), 0.4), 0)
place(buf, bell(midi(84), 0.5), 0.09)
sfx("turn", buf, -9)

# Countdown tick + GO.
t = t_(0.14)
sfx("countdown", np.sin(2 * np.pi * 880 * t) * env_ad(len(t), 0.002, 0.05) + 0.3 * np.sin(2 * np.pi * 1760 * t) * env_ad(len(t), 0.001, 0.02), -6)
buf = np.zeros(int(0.5 * SR))
for m in [72, 76, 79, 84]:
    place(buf, 0.6 * bell(midi(m + 12), 0.45), 0)
sfx("go", buf, -4)

# Timer tick (last seconds) — dry woodblock tick.
t = t_(0.05)
x = np.sin(2 * np.pi * 1300 * t) * env_ad(len(t), 0.0005, 0.008)
sfx("timer_tick", x, -10)

# Correct — bright sparkly ding.
buf = np.zeros(int(0.6 * SR))
place(buf, bell(midi(88), 0.5), 0)
place(buf, 0.5 * bell(midi(95), 0.4), 0.04)
sfx("correct", buf, -5)

# Wrong — friendly low "bonk-bonk" (not harsh).
buf = np.zeros(int(0.45 * SR))
for i, m in enumerate([55, 50]):
    tt = t_(0.18)
    s = np.sin(2 * np.pi * midi(m) * tt) + 0.3 * np.sin(2 * np.pi * midi(m) * 2 * tt)
    place(buf, lp(s * env_ad(len(tt), 0.003, 0.08), 1500), i * 0.13)
sfx("wrong", buf, -4)

# Round win — quick sparkle arpeggio.
buf = np.zeros(int(1.0 * SR))
for i, m in enumerate([76, 79, 84, 88, 91]):
    place(buf, bell(midi(m), 0.5) * 0.8, i * 0.06)
sfx("round_win", buf, -3)

# Hint — magic shimmer.
buf = np.zeros(int(0.9 * SR))
for i in range(14):
    m = 84 + rng.integers(0, 12)
    place(buf, 0.35 * bell(midi(m), 0.3), i * 0.04)
sfx("hint", lp(buf, 9000), -7)

# Win — celebratory fanfare (≈2 s).
buf = np.zeros(int(2.4 * SR))
seq = [(72, 0.00), (76, 0.10), (79, 0.20), (84, 0.32)]
for m, at in seq:
    place(buf, marimba(midi(m), 0.4), at)
    place(buf, 0.5 * bell(midi(m + 12), 0.4), at)
for m in [72, 76, 79, 84, 88]:  # final chord
    place(buf, 0.7 * bell(midi(m), 1.6), 0.5)
    place(buf, 0.6 * marimba(midi(m - 12), 1.0), 0.5)
for i in range(18):  # sparkles
    place(buf, 0.18 * bell(midi(96 + rng.integers(0, 8)), 0.25), 0.55 + i * 0.07)
sfx("win", buf, -2)

# Lose / time up — gentle descending "wah-wah".
buf = np.zeros(int(1.4 * SR))
for i, m in enumerate([67, 66, 65]):
    tt = t_(0.32 if i < 2 else 0.7)
    fv = midi(m) * (1 + 0.012 * np.sin(2 * np.pi * 6 * tt))
    s = np.sin(2 * np.pi * np.cumsum(fv) / SR)
    s = s + 0.35 * np.sin(2 * np.pi * 2 * np.cumsum(fv) / SR)
    s *= np.clip(np.minimum(tt / 0.03, 1), 0, 1) * np.exp(-tt / (0.25 if i < 2 else 0.5))
    place(buf, lp(s, 1800), i * 0.3)
sfx("lose", buf, -4)


# ---------------------------------------------------------------- MUSIC
# Cheerful, unobtrusive casual loop: 112 BPM, C major, 16 bars
# (I–V–vi–IV | I–V–IV–V) × 2 with a light melody on the second half.
BPM = 112
beat = 60 / BPM
bars = 16
loop_len = bars * 4 * beat
L = np.zeros(int((loop_len + 2.0) * SR))
R = np.zeros_like(L)

chords = {
    "C": [60, 64, 67], "G": [55, 59, 62], "Am": [57, 60, 64], "F": [53, 57, 60],
}
prog = ["C", "G", "Am", "F", "C", "G", "F", "G"] * 2
roots = {"C": 36, "G": 43, "Am": 45, "F": 41}


def pan(sig, p, at):
    place(L, sig * (1 - p) ** 0.5, at)
    place(R, sig * p ** 0.5, at)


for bar, ch in enumerate(prog):
    t0 = bar * 4 * beat
    notes = chords[ch]
    # Arpeggiated marimba 8ths (up-down pattern), gently panned.
    pattern = [0, 1, 2, 1, 0, 2, 1, 2]
    for i, idx in enumerate(pattern):
        m = notes[idx] + 12
        vel = 0.28 if i % 2 == 0 else 0.2
        pan(vel * marimba(midi(m), 0.32, 0.7), 0.35 if i % 2 else 0.65, t0 + i * beat / 2)
    # Bass: root on 1, fifth on 2&, root on 3, octave on 4.
    r = roots[ch]
    for at, m, v in [(0, r, 0.55), (1.5, r + 7, 0.35), (2, r, 0.5), (3, r + 12, 0.35)]:
        pan(v * pluck(midi(m), 0.42), 0.5, t0 + at * beat)
    # Soft kick on 1 & 3, rim on 2 & 4, shaker 16ths.
    for b in range(4):
        at = t0 + b * beat
        if b % 2 == 0:
            tt = t_(0.18)
            kf = 110 * np.exp(-tt * 30) + 48
            k = np.sin(2 * np.pi * np.cumsum(kf) / SR) * env_ad(len(tt), 0.001, 0.08)
            pan(0.45 * k, 0.5, at)
        else:
            rim = bp(noise(0.06), 1500, 5000) * env_ad(int(0.06 * SR), 0.0005, 0.012)
            pan(0.12 * rim, 0.55, at)
        for s16 in range(4):
            sh = hp(noise(0.04), 6000) * env_ad(int(0.04 * SR), 0.004, 0.012)
            pan((0.05 if s16 % 2 else 0.03) * sh, 0.7 if s16 % 2 else 0.3, at + s16 * beat / 4)

# Melody (bars 9–16) — sparse, bell-like, stays in the background.
melody = [
    (8, 0, 76, 1), (8, 1, 79, 1), (8, 2, 81, 2),
    (9, 0, 79, 1), (9, 1, 76, 1), (9, 2, 74, 2),
    (10, 0, 72, 1), (10, 1, 76, 1), (10, 2, 79, 1.5), (10, 3.5, 81, 0.5),
    (11, 0, 77, 2), (11, 2, 76, 1), (11, 3, 74, 1),
    (12, 0, 76, 1), (12, 1, 79, 1), (12, 2, 84, 2),
    (13, 0, 83, 1), (13, 1, 79, 1), (13, 2, 74, 2),
    (14, 0, 77, 1), (14, 1, 76, 1), (14, 2, 72, 1), (14, 3, 74, 1),
    (15, 0, 79, 3),
]
for bar, b, m, length in melody:
    pan(0.22 * bell(midi(m), max(0.5, length * beat * 1.2)), 0.5, (bar * 4 + b) * beat)

# Seamless loop: fold the tail back into the start, then trim.
n = int(loop_len * SR)
L[: len(L) - n] += L[n:]
R[: len(R) - n] += R[n:]
L, R = L[:n], R[:n]
# Warm it up a touch and keep headroom.
L, R = lp(L, 7000), lp(R, 7000)
peak = max(np.abs(L).max(), np.abs(R).max())
L, R = L / peak * 0.7, R / peak * 0.7
st = np.empty(2 * n)
st[0::2], st[1::2] = L, R
write(os.path.join(OUT, "music", "bgm_loop.ogg"), st, stereo=True, q=3)

print("done")
