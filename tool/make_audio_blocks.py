"""Synthesises the Blocks Jodo sound effects.

Reuses the helpers from make_audio.py (everything above its SFX section)
without re-running it, so the existing sounds are left untouched.
Everything is generated from scratch — original and royalty-free.
Output: assets/audio/sfx/*.ogg
"""
import os

HERE = os.path.dirname(__file__)
with open(os.path.join(HERE, "make_audio.py"), encoding="utf-8") as f:
    src = f.read()
exec(src.split("# ---------------------------------------------------------------- SFX")[0])

# Block pick-up — soft rising "bloop" as the piece lifts off the tray.
t = t_(0.09)
f = 420 + 520 * (t / t[-1]) ** 0.7
x = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_ad(len(t), 0.002, 0.04)
sfx("block_pick", x, -8)

# Block place — chunky, satisfying "clack" (wood + low thump).
t = t_(0.16)
f = 190 * np.exp(-t * 30) + 95
body = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_ad(len(t), 0.001, 0.045)
click = bp(noise(0.16), 1200, 5200) * env_ad(len(t), 0.0005, 0.008)
tok = np.sin(2 * np.pi * 1450 * t) * env_ad(len(t), 0.0005, 0.018)
sfx("block_place", body + 0.55 * click + 0.35 * tok, -3)

# Invalid drop — soft low "bwop" as the piece slides back.
t = t_(0.18)
f = 260 * np.exp(-t * 6) + 120
x = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_ad(len(t), 0.004, 0.07)
sfx("block_invalid", lp(x, 1500), -9)

# Line clear — bright crystalline sweep + sparkle (one line).
buf = np.zeros(int(0.8 * SR))
dur = 0.35
t = t_(dur)
sw = bp(noise(dur), 2500, 9000) * np.sin(np.pi * np.linspace(0, 1, len(t))) ** 2
place(buf, 0.35 * sw, 0)
for i, m in enumerate([84, 88, 91, 96]):
    place(buf, 0.55 * bell(midi(m), 0.45), 0.03 + i * 0.045)
sfx("line_clear", buf, -3)

# Multi-line clear — bigger: whoosh, punchy bass hit and a wider arpeggio.
buf = np.zeros(int(1.2 * SR))
dur = 0.5
t = t_(dur)
sw = bp(noise(dur), 1500, 10000) * np.sin(np.pi * np.linspace(0, 1, len(t))) ** 1.5
place(buf, 0.4 * sw, 0)
tt = t_(0.3)
fb = 140 * np.exp(-tt * 12) + 55
place(buf, 0.9 * np.sin(2 * np.pi * np.cumsum(fb) / SR) * env_ad(len(tt), 0.001, 0.12), 0)
for i, m in enumerate([79, 84, 88, 91, 96, 100]):
    place(buf, 0.5 * bell(midi(m), 0.5), 0.02 + i * 0.05)
for i in range(10):
    place(buf, 0.15 * bell(midi(98 + rng.integers(0, 10)), 0.2), 0.3 + i * 0.045)
sfx("line_clear_multi", buf, -2)

# Combo — punchy rising "power-up" sting layered on top of a clear.
buf = np.zeros(int(0.7 * SR))
dur = 0.28
t = t_(dur)
f = 300 * 2 ** (2.2 * t / dur)
x = np.sign(np.sin(2 * np.pi * np.cumsum(f) / SR)) * 0.25 + np.sin(2 * np.pi * np.cumsum(f) / SR)
place(buf, lp(x * env_ad(len(t), 0.01, 0.2), 4000) * 0.6, 0)
for m in [84, 88, 91]:
    place(buf, 0.45 * bell(midi(m + 12), 0.4), 0.26)
sfx("combo", buf, -3)

# New pieces — airy pop-in "whoop-whoop-whoop" (one per tray slot).
buf = np.zeros(int(0.45 * SR))
for i, m in enumerate([74, 79, 83]):
    tt = t_(0.08)
    fr = midi(m) * (1 + 0.6 * (tt / tt[-1]))
    place(buf, np.sin(2 * np.pi * np.cumsum(fr) / SR) * env_ad(len(tt), 0.002, 0.03) * 0.7, i * 0.07)
sfx("refill", buf, -9)

# No moves — "uh-oh": two falling tones + soft thud.
buf = np.zeros(int(0.7 * SR))
for i, (m, d) in enumerate([(69, 0.16), (62, 0.32)]):
    tt = t_(d)
    fv = midi(m) * (1 - 0.04 * tt / d)
    s = np.sin(2 * np.pi * np.cumsum(fv) / SR) + 0.3 * np.sin(4 * np.pi * np.cumsum(fv) / SR)
    s *= np.clip(tt / 0.01, 0, 1) * np.exp(-tt / (d * 0.6))
    place(buf, lp(s, 2000), i * 0.17)
sfx("no_moves", buf, -4)

print("done")
