#!/usr/bin/env python3

import array
import math
import random
import sys
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "audio"
SAMPLE_RATE = 44100
TAU = math.tau


def _write_wav(name, samples, stereo=False, target_peak=0.6):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    if stereo:
        left, right = samples
        if len(left) != len(right):
            raise ValueError(f"stereo channel length mismatch: {name}")
        left_mean = sum(left) / max(1, len(left))
        right_mean = sum(right) / max(1, len(right))
        peak = max(
            0.001,
            max(abs(value - left_mean) for value in left),
            max(abs(value - right_mean) for value in right),
        )
        gain = target_peak / peak
        pcm = array.array("h")
        for left_value, right_value in zip(left, right):
            pcm.append(_pcm16((left_value - left_mean) * gain))
            pcm.append(_pcm16((right_value - right_mean) * gain))
        channels = 2
        frame_count = len(left)
    else:
        mean = sum(samples) / max(1, len(samples))
        peak = max(0.001, max(abs(value - mean) for value in samples))
        gain = target_peak / peak
        pcm = array.array("h", (_pcm16((value - mean) * gain) for value in samples))
        channels = 1
        frame_count = len(samples)
    if sys.byteorder == "big":
        pcm.byteswap()
    with wave.open(str(OUTPUT / name), "wb") as target:
        target.setnchannels(channels)
        target.setsampwidth(2)
        target.setframerate(SAMPLE_RATE)
        target.setnframes(frame_count)
        target.writeframes(pcm.tobytes())


def _pcm16(value):
    return int(max(-1.0, min(1.0, value)) * 32767)


def _envelope(time, duration, attack=0.004, release=0.04):
    return min(1.0, time / max(attack, 0.0001)) * min(1.0, (duration - time) / max(release, 0.0001))


def _canvas_friction(duration, seed, roughness=0.55, movement=7.0, attack=0.008, release=0.05):
    rng = random.Random(seed)
    count = int(duration * SAMPLE_RATE)
    fast = 0.0
    slow = 0.0
    samples = []
    fast_rate = 0.16 + roughness * 0.12
    slow_rate = 0.012 + roughness * 0.008
    for index in range(count):
        time = index / SAMPLE_RATE
        white = rng.random() * 2.0 - 1.0
        fast += (white - fast) * fast_rate
        slow += (white - slow) * slow_rate
        band = fast - slow
        grain = white - fast
        gesture = 0.64 + 0.36 * math.sin(TAU * movement * time + 0.35) ** 2
        value = (band * 0.82 + grain * 0.16 * roughness) * gesture
        samples.append(value * _envelope(time, duration, attack, release))
    return samples


def _wood_tap(duration, frequency, seed, hardness=0.55, decay=13.0):
    rng = random.Random(seed)
    phases = [rng.random() * TAU for _ in range(4)]
    ratios = [1.0, 2.18, 3.73, 5.11]
    strengths = [1.0, 0.42 * hardness, 0.23 * hardness, 0.1 * hardness]
    count = int(duration * SAMPLE_RATE)
    click_state = 0.0
    samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        body = 0.0
        for partial, ratio in enumerate(ratios):
            partial_decay = decay * (1.0 + partial * 0.42)
            body += strengths[partial] * math.sin(TAU * frequency * ratio * time + phases[partial]) * math.exp(-partial_decay * time)
        white = rng.random() * 2.0 - 1.0
        click_state += (white - click_state) * 0.32
        click = (white - click_state) * hardness * math.exp(-time * 78.0)
        attack = min(1.0, time / 0.0018)
        release = min(1.0, (duration - time) / 0.012)
        samples.append((body * 0.54 + click * 0.42) * attack * release)
    return samples


def _enamel_chime(duration, frequency, seed, decay=8.0, brightness=0.7):
    rng = random.Random(seed)
    ratios = [1.0, 2.71, 4.08, 5.43, 7.16]
    strengths = [1.0, 0.52, 0.31, 0.19, 0.1]
    phases = [rng.uniform(-0.18, 0.18) for _ in ratios]
    count = int(duration * SAMPLE_RATE)
    samples = []
    for index in range(count):
        time = index / SAMPLE_RATE
        value = 0.0
        for partial, ratio in enumerate(ratios):
            partial_decay = decay * (1.0 + partial * (0.32 + brightness * 0.12))
            value += strengths[partial] * (0.72 + brightness * 0.28) * math.sin(TAU * frequency * ratio * time + phases[partial]) * math.exp(-partial_decay * time)
        strike = (rng.random() * 2.0 - 1.0) * brightness * math.exp(-time * 105.0)
        attack = min(1.0, time / 0.0024)
        release = min(1.0, (duration - time) / 0.018)
        samples.append((value * 0.36 + strike * 0.14) * attack * release)
    return samples


def _pluck(duration, frequency, seed, damping=0.995, brightness=0.6):
    rng = random.Random(seed)
    delay = max(8, int(SAMPLE_RATE / max(40.0, frequency)))
    raw = [rng.random() * 2.0 - 1.0 for _ in range(delay)]
    buffer = []
    for index, value in enumerate(raw):
        smooth = (raw[index - 1] + value + raw[(index + 1) % delay]) / 3.0
        buffer.append(value * brightness + smooth * (1.0 - brightness))
    count = int(duration * SAMPLE_RATE)
    samples = []
    cursor = 0
    for index in range(count):
        value = buffer[cursor]
        following = buffer[(cursor + 1) % delay]
        buffer[cursor] = (value + following) * 0.5 * damping
        cursor = (cursor + 1) % delay
        time = index / SAMPLE_RATE
        attack = min(1.0, time / 0.002)
        release = min(1.0, (duration - time) / 0.018)
        samples.append(value * attack * release)
    return samples


def _wind(duration, seed, brightness=0.5, gust=0.7, loop=False):
    rng = random.Random(seed)
    count = int(duration * SAMPLE_RATE)
    crossfade = min(int(0.8 * SAMPLE_RATE), max(1, count // 4)) if loop else 0
    raw_count = count + crossfade
    low = 0.0
    middle = 0.0
    for _ in range(2048):
        white = rng.random() * 2.0 - 1.0
        low += (white - low) * 0.0024
        middle += (white - middle) * (0.028 + brightness * 0.015)
    raw = []
    phase = rng.random() * TAU
    for index in range(raw_count):
        time = index / SAMPLE_RATE
        white = rng.random() * 2.0 - 1.0
        low += (white - low) * 0.0024
        middle += (white - middle) * (0.028 + brightness * 0.015)
        band = middle - low
        air = white - middle
        gust_shape = 0.58 + 0.25 * math.sin(TAU * 0.37 * time + phase) + 0.17 * math.sin(TAU * 0.83 * time + phase * 0.43)
        value = band * (0.74 + gust * 0.16) + air * brightness * 0.1
        raw.append(value * max(0.18, gust_shape))
    if loop:
        samples = raw[:count]
        for index in range(crossfade):
            amount = index / max(1, crossfade - 1)
            samples[index] = raw[count + index] * (1.0 - amount) + samples[index] * amount
        return samples
    samples = []
    for index, value in enumerate(raw):
        time = index / SAMPLE_RATE
        samples.append(value * _envelope(time, duration, 0.018, 0.08))
    return samples


def _reverse(samples):
    return list(reversed(samples))


def _mix_at(target, source, start=0.0, gain=1.0, wrap=False):
    start_index = int(round(start * SAMPLE_RATE))
    target_size = len(target)
    for source_index, value in enumerate(source):
        target_index = start_index + source_index
        if wrap:
            target_index %= target_size
        elif target_index < 0 or target_index >= target_size:
            continue
        target[target_index] += value * gain


def _mix_stereo(left, right, source, start=0.0, gain=1.0, pan=0.0, wrap=False):
    pan = max(-1.0, min(1.0, pan))
    left_gain = math.cos((pan + 1.0) * math.pi * 0.25) * gain
    right_gain = math.sin((pan + 1.0) * math.pi * 0.25) * gain
    _mix_at(left, source, start, left_gain, wrap)
    _mix_at(right, source, start, right_gain, wrap)


def _compose(duration, layers, drive=1.0):
    samples = [0.0] * int(duration * SAMPLE_RATE)
    for source, start, gain in layers:
        _mix_at(samples, source, start, gain)
    if drive > 1.0:
        normalizer = math.tanh(drive)
        samples = [math.tanh(value * drive) / normalizer for value in samples]
    fade_count = min(int(0.01 * SAMPLE_RATE), len(samples) // 4)
    for index in range(fade_count):
        start_amount = index / max(1, int(0.0015 * SAMPLE_RATE))
        end_amount = index / max(1, fade_count - 1)
        samples[index] *= min(1.0, start_amount)
        samples[-1 - index] *= end_amount
    return samples


def _compress_music_bus(samples, threshold=0.025, ratio=4.0):
    for index, value in enumerate(samples):
        magnitude = abs(value)
        if magnitude <= threshold:
            continue
        samples[index] = math.copysign(threshold + (magnitude - threshold) / ratio, value)


def _scale_frequency(root, mode, degree, octave=0):
    scale_size = len(mode)
    scale_octave, scale_index = divmod(degree, scale_size)
    semitones = mode[scale_index] + 12 * (scale_octave + octave)
    return root * 2.0 ** (semitones / 12.0)


def _music(profile):
    duration = 32.0
    count = int(duration * SAMPLE_RATE)
    left = [0.0] * count
    right = [0.0] * count
    motif = [0, 1, 2, 4, 2, 1, 3, 0]
    profiles = {
        "lobby": {
            "seed": 501,
            "root": 293.66,
            "mode": [0, 2, 4, 6, 7, 9, 11],
            "step": 0.5,
            "swing": 0.0,
            "rhythm": [1, 0, 1, 1, 1, 0, 1, 0],
            "progression": [0, 4, 3, 1],
            "melody_gain": 0.12,
            "note_length": 0.82,
            "damping": 0.994,
            "brightness": 0.48,
            "wind_gain": 0.045,
            "wind_brightness": 0.36,
            "wood_step": 2.0,
            "wood_frequency": 176.0,
            "wood_gain": 0.036,
            "chime_every": 8,
            "chime_gain": 0.035,
        },
        "windbell": {
            "seed": 601,
            "root": 261.63,
            "mode": [0, 2, 4, 5, 7, 9, 11],
            "step": 0.4,
            "swing": 0.0,
            "rhythm": [1, 1, 1, 0, 1, 1, 0, 1],
            "progression": [0, 3, 4, 1],
            "melody_gain": 0.13,
            "note_length": 0.62,
            "damping": 0.9935,
            "brightness": 0.66,
            "wind_gain": 0.064,
            "wind_brightness": 0.58,
            "wood_step": 1.6,
            "wood_frequency": 205.0,
            "wood_gain": 0.043,
            "chime_every": 5,
            "chime_gain": 0.045,
        },
        "oasis": {
            "seed": 701,
            "root": 220.0,
            "mode": [0, 2, 3, 5, 7, 9, 10],
            "step": 0.5,
            "swing": 0.22,
            "rhythm": [1, 0, 1, 1, 0, 1, 1, 0],
            "progression": [0, 3, 1, 4],
            "melody_gain": 0.115,
            "note_length": 0.76,
            "damping": 0.9945,
            "brightness": 0.42,
            "wind_gain": 0.038,
            "wind_brightness": 0.42,
            "wood_step": 1.0,
            "wood_frequency": 148.0,
            "wood_gain": 0.055,
            "chime_every": 12,
            "chime_gain": 0.026,
        },
        "volcano": {
            "seed": 801,
            "root": 196.0,
            "mode": [0, 2, 3, 5, 7, 8, 10],
            "step": 0.8,
            "swing": 0.0,
            "rhythm": [1, 0, 0, 1, 1, 0, 1, 0],
            "progression": [0, 5, 3, 1],
            "melody_gain": 0.098,
            "note_length": 1.12,
            "damping": 0.996,
            "brightness": 0.31,
            "wind_gain": 0.052,
            "wind_brightness": 0.3,
            "wood_step": 1.6,
            "wood_frequency": 92.0,
            "wood_gain": 0.072,
            "chime_every": 10,
            "chime_gain": 0.022,
        },
    }
    settings = profiles[profile]
    seed = settings["seed"]

    wind_left = _wind(duration, seed + 1, settings["wind_brightness"], 0.76, True)
    wind_right = _wind(duration, seed + 2, settings["wind_brightness"] * 0.92, 0.7, True)
    for index in range(count):
        left[index] += wind_left[index] * settings["wind_gain"]
        right[index] += wind_right[index] * settings["wind_gain"]

    for bar_index, base_degree in enumerate(settings["progression"]):
        bar_time = bar_index * 8.0
        for chord_index, chord_degree in enumerate([0, 2, 4]):
            frequency = _scale_frequency(settings["root"] * 0.5, settings["mode"], base_degree + chord_degree)
            chord = _pluck(5.4, frequency, seed + 20 + bar_index * 7 + chord_index, 0.997, 0.28 + chord_index * 0.08)
            _mix_stereo(left, right, chord, bar_time, 0.055 - chord_index * 0.008, (chord_index - 1) * 0.38, True)
        canvas = _canvas_friction(0.62, seed + 70 + bar_index, 0.34, 2.4, 0.06, 0.12)
        _mix_stereo(left, right, canvas, bar_time - 0.16, 0.026, -0.55 if bar_index % 2 == 0 else 0.55, True)

    step_count = int(duration / settings["step"])
    for step_index in range(step_count):
        if not settings["rhythm"][step_index % len(settings["rhythm"])]:
            continue
        note_time = step_index * settings["step"]
        if step_index % 2 == 1:
            note_time += settings["step"] * settings["swing"]
        phrase = step_index // len(motif)
        degree = motif[step_index % len(motif)] + settings["progression"][phrase % 4]
        frequency = _scale_frequency(settings["root"], settings["mode"], degree)
        pluck = _pluck(settings["note_length"], frequency, seed + 100 + step_index, settings["damping"], settings["brightness"])
        pan = math.sin(step_index * 1.71) * (0.34 if profile != "windbell" else 0.48)
        _mix_stereo(left, right, pluck, note_time, settings["melody_gain"], pan, True)
        if step_index % settings["chime_every"] == 0:
            chime = _enamel_chime(0.78, frequency * 2.0, seed + 300 + step_index, 9.5, 0.56)
            _mix_stereo(left, right, chime, note_time + 0.04, settings["chime_gain"], -pan, True)

    wood_count = int(duration / settings["wood_step"])
    for beat_index in range(wood_count):
        beat_time = beat_index * settings["wood_step"]
        accent = 1.0 if beat_index % 4 == 0 else 0.58 if beat_index % 2 == 0 else 0.38
        tap = _wood_tap(0.19, settings["wood_frequency"] * (1.0 + 0.08 * (beat_index % 3)), seed + 500 + beat_index, 0.32 + accent * 0.18, 15.0)
        _mix_stereo(left, right, tap, beat_time, settings["wood_gain"] * accent, 0.16 if beat_index % 2 == 0 else -0.16, True)

    _compress_music_bus(left)
    _compress_music_bus(right)
    return left, right


def _build_sounds():
    sounds = {}

    sounds["ui_select.wav"] = (_compose(0.13, [
        (_wood_tap(0.1, 520, 101, 0.42, 19.0), 0.0, 0.62),
        (_enamel_chime(0.12, 1040, 102, 18.0, 0.52), 0.008, 0.34),
    ]), 0.42)
    sounds["ui_confirm.wav"] = (_compose(0.28, [
        (_wood_tap(0.16, 236, 103, 0.48, 14.0), 0.0, 0.62),
        (_pluck(0.25, 523.25, 104, 0.992, 0.48), 0.018, 0.42),
        (_enamel_chime(0.2, 783.99, 105, 12.0, 0.58), 0.055, 0.32),
    ]), 0.55)
    sounds["ui_navigate.wav"] = (_compose(0.11, [
        (_wood_tap(0.085, 610, 106, 0.62, 24.0), 0.0, 0.66),
        (_canvas_friction(0.09, 107, 0.35, 12.0, 0.002, 0.02), 0.006, 0.24),
    ]), 0.38)
    sounds["ui_open.wav"] = (_compose(0.2, [
        (_canvas_friction(0.18, 108, 0.38, 3.0, 0.008, 0.05), 0.0, 0.42),
        (_enamel_chime(0.17, 659.25, 109, 13.0, 0.45), 0.025, 0.45),
    ]), 0.48)
    sounds["ui_back.wav"] = (_compose(0.18, [
        (_reverse(_canvas_friction(0.17, 110, 0.42, 3.6, 0.008, 0.055)), 0.0, 0.43),
        (_wood_tap(0.11, 185, 111, 0.38, 17.0), 0.055, 0.54),
    ]), 0.45)
    sounds["ui_locked.wav"] = (_compose(0.24, [
        (_wood_tap(0.14, 158, 112, 0.7, 13.0), 0.0, 0.8),
        (_wood_tap(0.13, 142, 113, 0.58, 15.0), 0.085, 0.66),
        (_canvas_friction(0.18, 114, 0.7, 8.0, 0.003, 0.05), 0.025, 0.24),
    ], 1.08), 0.61)
    sounds["ui_equip.wav"] = (_compose(0.27, [
        (_wood_tap(0.2, 226, 115, 0.52, 12.0), 0.0, 0.72),
        (_canvas_friction(0.14, 116, 0.36, 5.0, 0.004, 0.04), 0.01, 0.28),
        (_enamel_chime(0.2, 880, 117, 11.0, 0.64), 0.052, 0.38),
    ]), 0.56)
    sounds["ui_upgrade_skill.wav"] = (_compose(0.48, [
        (_pluck(0.36, 523.25, 118, 0.994, 0.46), 0.0, 0.38),
        (_pluck(0.34, 659.25, 119, 0.994, 0.5), 0.075, 0.36),
        (_pluck(0.3, 783.99, 120, 0.993, 0.54), 0.15, 0.34),
        (_enamel_chime(0.27, 1046.5, 121, 9.0, 0.58), 0.19, 0.28),
    ]), 0.6)
    sounds["upgrade.wav"] = (_compose(0.65, [
        (_wind(0.62, 122, 0.3, 0.54), 0.0, 0.16),
        (_pluck(0.45, 392.0, 123, 0.995, 0.38), 0.0, 0.31),
        (_pluck(0.43, 523.25, 124, 0.995, 0.44), 0.1, 0.32),
        (_pluck(0.4, 659.25, 125, 0.994, 0.5), 0.2, 0.33),
        (_pluck(0.34, 783.99, 126, 0.994, 0.55), 0.3, 0.31),
        (_enamel_chime(0.34, 1046.5, 127, 7.5, 0.66), 0.275, 0.25),
    ]), 0.68)

    sounds["pickup.wav"] = (_compose(0.18, [
        (_wood_tap(0.1, 420, 201, 0.38, 20.0), 0.0, 0.48),
        (_enamel_chime(0.15, 940, 202, 14.0, 0.54), 0.018, 0.44),
    ]), 0.4)
    sounds["pickup_xp.wav"] = (_compose(0.16, [
        (_enamel_chime(0.13, 1240, 203, 18.0, 0.62), 0.0, 0.46),
        (_enamel_chime(0.1, 1860, 204, 22.0, 0.48), 0.045, 0.25),
    ]), 0.34)
    sounds["pickup_heal.wav"] = (_compose(0.36, [
        (_wind(0.34, 205, 0.28, 0.48), 0.0, 0.14),
        (_pluck(0.32, 392.0, 206, 0.995, 0.34), 0.0, 0.42),
        (_pluck(0.26, 523.25, 207, 0.994, 0.42), 0.07, 0.4),
        (_enamel_chime(0.2, 783.99, 208, 11.0, 0.4), 0.12, 0.2),
    ]), 0.53)
    sounds["pickup_magnet.wav"] = (_compose(0.42, [
        (_reverse(_wind(0.4, 209, 0.55, 0.78)), 0.0, 0.42),
        (_enamel_chime(0.34, 260, 210, 9.0, 0.44), 0.02, 0.36),
        (_enamel_chime(0.24, 536, 211, 12.0, 0.42), 0.12, 0.26),
    ]), 0.57)
    sounds["pickup_haste.wav"] = (_compose(0.31, [
        (_wind(0.29, 212, 0.68, 0.82), 0.0, 0.46),
        (_pluck(0.2, 740, 213, 0.991, 0.76), 0.075, 0.42),
        (_canvas_friction(0.18, 214, 0.42, 12.0, 0.004, 0.045), 0.02, 0.24),
    ]), 0.5)
    sounds["pickup_bomb.wav"] = (_compose(0.44, [
        (_wood_tap(0.4, 76, 215, 0.74, 7.5), 0.0, 0.82),
        (_canvas_friction(0.41, 216, 0.9, 15.0, 0.001, 0.12), 0.0, 0.64),
        (_wood_tap(0.18, 238, 217, 0.62, 17.0), 0.09, 0.34),
    ], 1.24), 0.72)

    sounds["hero_hurt.wav"] = (_compose(0.24, [
        (_wood_tap(0.22, 92, 301, 0.78, 9.0), 0.0, 0.86),
        (_canvas_friction(0.2, 302, 0.94, 17.0, 0.001, 0.065), 0.0, 0.72),
    ], 1.3), 0.78)
    sounds["enemy_defeat.wav"] = (_compose(0.34, [
        (_canvas_friction(0.31, 303, 0.75, 8.0, 0.003, 0.11), 0.0, 0.54),
        (_wood_tap(0.16, 178, 304, 0.5, 15.0), 0.0, 0.48),
        (_wood_tap(0.14, 244, 305, 0.45, 18.0), 0.075, 0.35),
        (_wood_tap(0.12, 318, 306, 0.4, 21.0), 0.145, 0.25),
    ]), 0.57)
    sounds["impact.wav"] = (_compose(0.14, [
        (_wood_tap(0.12, 212, 307, 0.55, 21.0), 0.0, 0.62),
        (_canvas_friction(0.105, 308, 0.68, 13.0, 0.001, 0.025), 0.0, 0.38),
    ]), 0.41)
    sounds["enemy_warning.wav"] = (_compose(0.38, [
        (_canvas_friction(0.35, 309, 0.34, 4.0, 0.008, 0.08), 0.0, 0.18),
        (_enamel_chime(0.29, 680, 310, 8.0, 0.66), 0.0, 0.5),
        (_enamel_chime(0.23, 742, 311, 9.0, 0.68), 0.12, 0.46),
    ]), 0.68)
    sounds["grub_roll_charge.wav"] = (_compose(0.44, [
        (_canvas_friction(0.42, 312, 0.72, 9.0, 0.004, 0.09), 0.0, 0.48),
        (_wood_tap(0.14, 132, 313, 0.48, 14.0), 0.0, 0.48),
        (_wood_tap(0.14, 148, 314, 0.5, 14.0), 0.11, 0.5),
        (_wood_tap(0.14, 166, 315, 0.54, 14.0), 0.22, 0.52),
    ]), 0.58)
    sounds["grub_roll_move.wav"] = (_compose(0.31, [
        (_canvas_friction(0.29, 316, 0.82, 16.0, 0.002, 0.055), 0.0, 0.5),
        *[(_wood_tap(0.075, 118 + index * 9, 317 + index, 0.46, 24.0), index * 0.052, 0.34) for index in range(5)],
    ]), 0.52)
    sounds["grub_roll_miss.wav"] = (_compose(0.34, [
        (_wood_tap(0.22, 108, 322, 0.66, 10.0), 0.0, 0.68),
        (_reverse(_canvas_friction(0.31, 323, 0.78, 6.0, 0.003, 0.1)), 0.0, 0.5),
    ]), 0.55)
    sounds["bat_bolt_charge.wav"] = (_compose(0.54, [
        (_wind(0.51, 324, 0.5, 0.62), 0.0, 0.24),
        (_enamel_chime(0.43, 520, 325, 6.5, 0.72), 0.0, 0.42),
        (_enamel_chime(0.35, 713, 326, 7.0, 0.66), 0.13, 0.38),
    ]), 0.58)
    sounds["bat_bolt_launch.wav"] = (_compose(0.22, [
        (_reverse(_wind(0.2, 327, 0.74, 0.8)), 0.0, 0.5),
        (_pluck(0.17, 740, 328, 0.99, 0.82), 0.035, 0.5),
    ]), 0.61)
    sounds["bat_bolt_impact.wav"] = (_compose(0.28, [
        (_wood_tap(0.23, 188, 329, 0.58, 13.0), 0.0, 0.68),
        (_canvas_friction(0.25, 330, 0.68, 11.0, 0.001, 0.07), 0.0, 0.46),
        (_enamel_chime(0.18, 570, 331, 14.0, 0.46), 0.035, 0.24),
    ]), 0.66)
    sounds["stage_transition.wav"] = (_compose(0.55, [
        (_wood_tap(0.22, 196, 332, 0.4, 12.0), 0.0, 0.46),
        (_pluck(0.42, 392, 333, 0.995, 0.4), 0.0, 0.33),
        (_pluck(0.36, 523.25, 334, 0.994, 0.46), 0.09, 0.34),
        (_pluck(0.3, 659.25, 335, 0.993, 0.52), 0.18, 0.34),
        (_enamel_chime(0.26, 880, 336, 9.0, 0.55), 0.24, 0.24),
    ]), 0.68)
    sounds["elite_appear.wav"] = (_compose(0.66, [
        (_wind(0.63, 337, 0.36, 0.72), 0.0, 0.24),
        (_wood_tap(0.56, 78, 338, 0.7, 6.5), 0.0, 0.76),
        (_enamel_chime(0.48, 330, 339, 5.5, 0.7), 0.04, 0.36),
        (_enamel_chime(0.38, 541, 340, 6.8, 0.72), 0.18, 0.35),
    ], 1.12), 0.74)
    sounds["elite_defeat.wav"] = (_compose(0.72, [
        (_canvas_friction(0.68, 341, 0.72, 7.0, 0.002, 0.16), 0.0, 0.34),
        (_wood_tap(0.5, 104, 342, 0.64, 8.0), 0.0, 0.7),
        (_pluck(0.5, 330, 343, 0.996, 0.36), 0.08, 0.3),
        (_pluck(0.43, 440, 344, 0.995, 0.42), 0.18, 0.31),
        (_pluck(0.35, 659.25, 345, 0.994, 0.48), 0.3, 0.3),
        (_enamel_chime(0.3, 880, 346, 7.5, 0.58), 0.36, 0.25),
    ], 1.1), 0.76)
    sounds["result_victory.wav"] = (_compose(0.92, [
        (_wind(0.88, 347, 0.28, 0.46), 0.0, 0.12),
        (_wood_tap(0.3, 176, 348, 0.38, 11.0), 0.0, 0.38),
        (_pluck(0.66, 392, 349, 0.996, 0.34), 0.0, 0.27),
        (_pluck(0.6, 523.25, 350, 0.996, 0.4), 0.12, 0.29),
        (_pluck(0.52, 659.25, 351, 0.995, 0.46), 0.24, 0.3),
        (_pluck(0.42, 783.99, 352, 0.995, 0.5), 0.36, 0.28),
        (_enamel_chime(0.44, 1046.5, 353, 6.5, 0.62), 0.34, 0.24),
        (_enamel_chime(0.34, 1318.5, 354, 7.0, 0.58), 0.48, 0.18),
    ]), 0.76)
    sounds["result_failure.wav"] = (_compose(0.68, [
        (_canvas_friction(0.64, 355, 0.5, 3.2, 0.01, 0.15), 0.0, 0.27),
        (_wood_tap(0.42, 122, 356, 0.5, 8.0), 0.0, 0.58),
        (_pluck(0.48, 293.66, 357, 0.995, 0.3), 0.02, 0.28),
        (_pluck(0.38, 220, 358, 0.995, 0.26), 0.14, 0.3),
        (_pluck(0.29, 146.83, 359, 0.994, 0.22), 0.28, 0.32),
    ]), 0.62)

    sounds["skill_star_lance.wav"] = (_compose(0.23, [
        (_reverse(_wind(0.2, 401, 0.72, 0.84)), 0.0, 0.42),
        (_pluck(0.18, 910, 402, 0.99, 0.88), 0.02, 0.56),
        (_enamel_chime(0.12, 1460, 403, 16.0, 0.62), 0.085, 0.26),
    ]), 0.58)
    sounds["skill_sun_orbit.wav"] = (_compose(0.38, [
        (_pluck(0.31, 246.94, 404, 0.995, 0.34), 0.0, 0.28),
        (_enamel_chime(0.22, 370, 405, 10.0, 0.58), 0.0, 0.36),
        (_enamel_chime(0.21, 555, 406, 10.5, 0.6), 0.085, 0.34),
        (_enamel_chime(0.18, 740, 407, 11.0, 0.62), 0.17, 0.32),
    ]), 0.48)
    sounds["skill_frost_tide.wav"] = (_compose(0.52, [
        (_wind(0.49, 408, 0.68, 0.88), 0.0, 0.48),
        (_canvas_friction(0.46, 409, 0.42, 4.0, 0.012, 0.12), 0.0, 0.27),
        (_enamel_chime(0.27, 1040, 410, 11.0, 0.48), 0.19, 0.3),
        (_enamel_chime(0.2, 1510, 411, 15.0, 0.42), 0.27, 0.2),
    ]), 0.6)
    sounds["frost_hit.wav"] = (_compose(0.23, [
        (_canvas_friction(0.2, 412, 0.72, 16.0, 0.001, 0.06), 0.0, 0.42),
        (_enamel_chime(0.15, 1480, 413, 18.0, 0.64), 0.018, 0.4),
    ]), 0.43)
    sounds["skill_ember_volley.wav"] = (_compose(0.22, [
        (_pluck(0.18, 330, 414, 0.989, 0.9), 0.0, 0.56),
        (_canvas_friction(0.19, 415, 0.86, 18.0, 0.001, 0.055), 0.0, 0.48),
        (_wind(0.18, 416, 0.7, 0.82), 0.02, 0.3),
    ], 1.08), 0.58)
    sounds["skill_meteor_rain.wav"] = (_compose(0.62, [
        (_wind(0.59, 417, 0.38, 0.76), 0.0, 0.26),
        (_wood_tap(0.28, 132, 418, 0.56, 10.0), 0.0, 0.58),
        (_wood_tap(0.27, 104, 419, 0.6, 9.0), 0.15, 0.64),
        (_wood_tap(0.25, 82, 420, 0.66, 8.0), 0.3, 0.7),
        (_canvas_friction(0.34, 421, 0.62, 8.0, 0.004, 0.1), 0.16, 0.34),
    ], 1.12), 0.68)
    sounds["meteor_impact.wav"] = (_compose(0.5, [
        (_wood_tap(0.46, 66, 422, 0.82, 6.0), 0.0, 0.9),
        (_canvas_friction(0.47, 423, 0.96, 17.0, 0.001, 0.15), 0.0, 0.78),
        (_wood_tap(0.2, 186, 424, 0.58, 14.0), 0.075, 0.34),
        (_wood_tap(0.16, 274, 425, 0.52, 18.0), 0.15, 0.24),
    ], 1.36), 0.78)
    sounds["skill_phoenix_heart.wav"] = (_compose(0.74, [
        (_wind(0.7, 426, 0.42, 0.7), 0.0, 0.2),
        (_wood_tap(0.25, 164, 427, 0.34, 11.0), 0.0, 0.34),
        (_pluck(0.52, 330, 428, 0.996, 0.38), 0.0, 0.3),
        (_pluck(0.46, 440, 429, 0.995, 0.44), 0.12, 0.31),
        (_pluck(0.38, 659.25, 430, 0.995, 0.5), 0.25, 0.31),
        (_enamel_chime(0.3, 990, 431, 8.0, 0.54), 0.32, 0.24),
    ]), 0.7)
    sounds["phoenix_impact.wav"] = (_compose(0.48, [
        (_wood_tap(0.36, 176, 432, 0.5, 10.0), 0.0, 0.52),
        (_canvas_friction(0.43, 433, 0.58, 8.0, 0.003, 0.13), 0.0, 0.36),
        (_enamel_chime(0.34, 660, 434, 8.0, 0.6), 0.025, 0.38),
        (_enamel_chime(0.25, 940, 435, 9.0, 0.58), 0.13, 0.3),
    ]), 0.72)

    return sounds


def main():
    music_targets = {
        "lobby": ("bgm_lobby.wav", 0.48),
        "windbell": ("bgm_windbell.wav", 0.52),
        "oasis": ("bgm_oasis.wav", 0.5),
        "volcano": ("bgm_volcano.wav", 0.54),
    }
    for profile, (file_name, target_peak) in music_targets.items():
        _write_wav(file_name, _music(profile), stereo=True, target_peak=target_peak)
    for name, (samples, target_peak) in _build_sounds().items():
        _write_wav(name, samples, target_peak=target_peak)


if __name__ == "__main__":
    main()
