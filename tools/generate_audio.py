#!/usr/bin/env python3

import math
import random
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "audio"
SAMPLE_RATE = 22050


def _write_wav(name, samples, stereo=False):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    channels = 2 if stereo else 1
    peak = max(0.001, max(abs(value) for frame in samples for value in (frame if stereo else (frame,))))
    gain = 0.92 / peak
    with wave.open(str(OUTPUT / name), "wb") as target:
        target.setnchannels(channels)
        target.setsampwidth(2)
        target.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for frame in samples:
            values = frame if stereo else (frame,)
            for value in values:
                frames.extend(struct.pack("<h", int(max(-1.0, min(1.0, value * gain)) * 32767)))
        target.writeframes(frames)


def _envelope(time, duration, attack=0.01, release=0.15):
    return min(1.0, time / max(attack, 0.001)) * min(1.0, (duration - time) / max(release, 0.001))


def _tone(duration, voices, noise=0.0, sweep=0.0, pulse=0.0):
    rng = random.Random(417)
    samples = []
    count = int(duration * SAMPLE_RATE)
    for index in range(count):
        time = index / SAMPLE_RATE
        envelope = _envelope(time, duration)
        value = 0.0
        for frequency, volume, wave_kind in voices:
            current = frequency * (1.0 + sweep * time / duration)
            phase = TAU * current * time
            if wave_kind == "triangle":
                value += volume * (2.0 / math.pi) * math.asin(math.sin(phase))
            elif wave_kind == "square":
                value += volume * (1.0 if math.sin(phase) >= 0.0 else -1.0)
            else:
                value += volume * math.sin(phase)
        if pulse > 0.0:
            value *= 0.7 + 0.3 * math.sin(TAU * pulse * time) ** 2
        value += noise * (rng.random() * 2.0 - 1.0) * (1.0 - time / duration)
        samples.append(value * envelope)
    return samples


def _music():
    rng = random.Random(90210)
    duration = 32.0
    count = int(duration * SAMPLE_RATE)
    samples = []
    chords = [
        (110.00, 164.81, 220.00),
        (98.00, 146.83, 196.00),
        (130.81, 164.81, 220.00),
        (87.31, 130.81, 174.61),
    ]
    notes = [440.00, 493.88, 523.25, 659.25, 587.33, 523.25, 493.88, 392.00]
    for index in range(count):
        time = index / SAMPLE_RATE
        bar = int(time / 8.0) % len(chords)
        local = time % 8.0
        pad = 0.0
        for voice_index, frequency in enumerate(chords[bar]):
            drift = 1.0 + 0.0025 * math.sin(TAU * (0.07 + voice_index * 0.013) * time)
            pad += math.sin(TAU * frequency * drift * time + voice_index * 0.8) * 0.08
            pad += math.sin(TAU * frequency * 2.0 * time) * 0.018
        note_index = int(time / 0.5) % len(notes)
        note_time = time % 0.5
        pluck_env = math.exp(-note_time * 7.0)
        pluck_frequency = notes[note_index] * (0.5 if bar == 3 else 1.0)
        pluck = (math.sin(TAU * pluck_frequency * time) + 0.35 * math.sin(TAU * pluck_frequency * 2.0 * time)) * 0.09 * pluck_env
        beat_time = time % 2.0
        heartbeat = math.sin(TAU * (54.0 - 22.0 * beat_time) * beat_time) * math.exp(-beat_time * 9.0) * 0.055
        shimmer = math.sin(TAU * 880.0 * time + 2.2 * math.sin(TAU * 0.09 * time)) * 0.008
        breath = (rng.random() * 2.0 - 1.0) * 0.006 * (0.5 + 0.5 * math.sin(TAU * 0.04 * time))
        transition = min(1.0, local / 0.35, (8.0 - local) / 0.35)
        center = (pad * transition + pluck + heartbeat + shimmer + breath) * 0.8
        pan = 0.22 * math.sin(TAU * 0.03125 * time)
        samples.append((center * (1.0 - pan), center * (1.0 + pan)))
    return samples


TAU = math.tau


def main():
    _write_wav("bgm_starbound.wav", _music(), stereo=True)
    sounds = {
        "ui_select.wav": _tone(0.13, [(660, 0.5, "sine"), (990, 0.25, "sine")], sweep=0.12),
        "ui_confirm.wav": _tone(0.28, [(392, 0.38, "sine"), (587, 0.32, "sine"), (784, 0.18, "sine")], sweep=0.08),
        "upgrade.wav": _tone(0.65, [(523, 0.28, "sine"), (659, 0.25, "sine"), (784, 0.22, "sine"), (1047, 0.12, "sine")], pulse=7.0),
        "pickup.wav": _tone(0.18, [(740, 0.35, "triangle"), (1110, 0.2, "sine")], sweep=0.35),
        "hero_hurt.wav": _tone(0.24, [(135, 0.55, "triangle"), (82, 0.32, "sine")], noise=0.18, sweep=-0.28),
        "enemy_defeat.wav": _tone(0.34, [(220, 0.32, "triangle"), (110, 0.4, "sine")], noise=0.25, sweep=-0.55),
        "impact.wav": _tone(0.14, [(310, 0.3, "triangle"), (155, 0.23, "sine")], noise=0.2, sweep=-0.35),
        "skill_star_lance.wav": _tone(0.23, [(720, 0.34, "sine"), (1080, 0.22, "triangle")], noise=0.04, sweep=0.42),
        "skill_sun_orbit.wav": _tone(0.38, [(246, 0.3, "sine"), (493, 0.28, "sine"), (740, 0.14, "sine")], pulse=9.0),
        "skill_frost_tide.wav": _tone(0.52, [(560, 0.22, "sine"), (840, 0.18, "sine"), (1120, 0.1, "triangle")], noise=0.08, sweep=-0.38),
        "skill_ember_volley.wav": _tone(0.22, [(310, 0.3, "triangle"), (620, 0.2, "square")], noise=0.14, sweep=0.5),
        "skill_meteor_rain.wav": _tone(0.62, [(92, 0.48, "sine"), (184, 0.28, "triangle")], noise=0.22, sweep=-0.42),
        "skill_phoenix_heart.wav": _tone(0.74, [(330, 0.24, "sine"), (495, 0.21, "sine"), (660, 0.18, "triangle")], noise=0.06, sweep=0.3, pulse=5.0),
    }
    for name, samples in sounds.items():
        _write_wav(name, samples)


if __name__ == "__main__":
    main()
