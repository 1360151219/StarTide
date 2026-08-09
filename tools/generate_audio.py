#!/usr/bin/env python3

import math
import random
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "audio"
SAMPLE_RATE = 44100


def _write_wav(name, samples, stereo=False, target_peak=0.82):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    channels = 2 if stereo else 1
    peak = max(0.001, max(abs(value) for frame in samples for value in (frame if stereo else (frame,))))
    gain = target_peak / peak
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


def _tone(duration, voices, noise=0.0, sweep=0.0, pulse=0.0, seed=417):
    rng = random.Random(seed)
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


def _music(profile):
    duration = 32.0
    count = int(duration * SAMPLE_RATE)
    samples = []
    profiles = {
        "lobby": {"pitch": 1.0, "step": 0.5, "pluck": 0.085, "wood": 0.035, "air": 0.004, "pan": 0.18},
        "windbell": {"pitch": 1.0, "step": 0.4, "pluck": 0.095, "wood": 0.045, "air": 0.007, "pan": 0.24},
        "oasis": {"pitch": 0.8909, "step": 0.5, "pluck": 0.09, "wood": 0.06, "air": 0.005, "pan": 0.2},
        "volcano": {"pitch": 0.7492, "step": 0.5, "pluck": 0.065, "wood": 0.085, "air": 0.003, "pan": 0.14},
    }
    settings = profiles[profile]
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
            frequency *= settings["pitch"]
            loop_frequency = round(frequency * duration) / duration
            drift = 1.0 + 0.0025 * math.sin(TAU * (0.0625 + voice_index * 0.03125) * time)
            pad += math.sin(TAU * loop_frequency * drift * time + voice_index * 0.8) * 0.08
            pad += math.sin(TAU * loop_frequency * 2.0 * time) * 0.018
        step = settings["step"]
        note_index = int(time / step) % len(notes)
        note_time = time % step
        pluck_env = math.exp(-note_time * 7.5) * min(1.0, note_time / 0.008) * min(1.0, (step - note_time) / 0.04)
        pluck_frequency = notes[note_index] * settings["pitch"] * (0.5 if bar == 3 else 1.0)
        pluck = (
            math.sin(TAU * pluck_frequency * time)
            + 0.32 * math.sin(TAU * pluck_frequency * 2.0 * time)
            + 0.12 * math.sin(TAU * pluck_frequency * 3.0 * time)
        ) * settings["pluck"] * pluck_env
        beat_time = time % 2.0
        wood = (
            math.sin(TAU * (82.0 * settings["pitch"] - 28.0 * beat_time) * beat_time)
            + 0.18 * math.sin(TAU * 246.0 * settings["pitch"] * beat_time)
        ) * math.exp(-beat_time * 11.0) * settings["wood"]
        shimmer = math.sin(TAU * 880.0 * settings["pitch"] * time + 2.2 * math.sin(TAU * 0.09375 * time)) * settings["air"]
        breath = (math.sin(TAU * 137.0 * time) + 0.5 * math.sin(TAU * 211.0 * time)) * settings["air"] * (0.5 + 0.5 * math.sin(TAU * 0.03125 * time))
        transition = min(1.0, local / 0.08, (8.0 - local) / 0.08)
        loop_fade = min(1.0, time / 0.06, (duration - time) / 0.06)
        center = (pad * transition + pluck + wood + shimmer + breath) * 0.8 * loop_fade
        pan = settings["pan"] * math.sin(TAU * 0.03125 * time)
        samples.append((center * (1.0 - pan), center * (1.0 + pan)))
    return samples


TAU = math.tau


def main():
    for profile, file_name in {
        "lobby": "bgm_lobby.wav",
        "windbell": "bgm_windbell.wav",
        "oasis": "bgm_oasis.wav",
        "volcano": "bgm_volcano.wav",
    }.items():
        _write_wav(file_name, _music(profile), stereo=True, target_peak=0.72)
    sounds = {
        "ui_select.wav": _tone(0.13, [(660, 0.5, "sine"), (990, 0.25, "sine")], sweep=0.12, seed=101),
        "ui_confirm.wav": _tone(0.28, [(392, 0.38, "sine"), (587, 0.32, "sine"), (784, 0.18, "sine")], sweep=0.08, seed=102),
        "ui_navigate.wav": _tone(0.11, [(720, 0.38, "sine"), (1080, 0.16, "triangle")], sweep=0.16, seed=103),
        "ui_open.wav": _tone(0.2, [(440, 0.3, "sine"), (660, 0.24, "sine"), (880, 0.14, "triangle")], sweep=0.16, seed=104),
        "ui_back.wav": _tone(0.18, [(620, 0.32, "sine"), (310, 0.18, "triangle")], sweep=-0.3, seed=105),
        "ui_locked.wav": _tone(0.24, [(190, 0.38, "triangle"), (760, 0.12, "square")], noise=0.05, sweep=-0.12, seed=106),
        "ui_equip.wav": _tone(0.27, [(480, 0.25, "triangle"), (960, 0.22, "sine"), (1440, 0.08, "sine")], pulse=10.0, seed=107),
        "ui_upgrade_skill.wav": _tone(0.48, [(523, 0.24, "sine"), (659, 0.21, "sine"), (1047, 0.15, "triangle")], sweep=0.18, pulse=6.0, seed=108),
        "upgrade.wav": _tone(0.65, [(523, 0.28, "sine"), (659, 0.25, "sine"), (784, 0.22, "sine"), (1047, 0.12, "sine")], pulse=7.0, seed=109),
        "pickup.wav": _tone(0.18, [(740, 0.35, "triangle"), (1110, 0.2, "sine")], sweep=0.35, seed=201),
        "pickup_xp.wav": _tone(0.16, [(820, 0.32, "triangle"), (1640, 0.12, "sine")], sweep=0.42, seed=202),
        "pickup_heal.wav": _tone(0.36, [(392, 0.2, "sine"), (523, 0.26, "sine"), (784, 0.16, "triangle")], sweep=0.12, seed=203),
        "pickup_magnet.wav": _tone(0.42, [(180, 0.28, "sine"), (540, 0.18, "triangle"), (1080, 0.08, "sine")], sweep=0.65, pulse=8.0, seed=204),
        "pickup_haste.wav": _tone(0.31, [(460, 0.22, "triangle"), (920, 0.18, "sine")], noise=0.08, sweep=0.82, seed=205),
        "pickup_bomb.wav": _tone(0.44, [(105, 0.42, "sine"), (315, 0.2, "triangle")], noise=0.24, sweep=-0.46, seed=206),
        "hero_hurt.wav": _tone(0.24, [(135, 0.55, "triangle"), (82, 0.32, "sine")], noise=0.18, sweep=-0.28, seed=301),
        "enemy_defeat.wav": _tone(0.34, [(220, 0.32, "triangle"), (110, 0.4, "sine")], noise=0.25, sweep=-0.55, seed=302),
        "impact.wav": _tone(0.14, [(310, 0.3, "triangle"), (155, 0.23, "sine")], noise=0.2, sweep=-0.35, seed=303),
        "enemy_warning.wav": _tone(0.38, [(760, 0.31, "triangle"), (1140, 0.18, "sine")], noise=0.035, sweep=0.24, pulse=8.0, seed=304),
        "grub_roll_charge.wav": _tone(0.44, [(145, 0.34, "triangle"), (290, 0.18, "sine")], noise=0.1, sweep=0.62, pulse=9.0, seed=305),
        "grub_roll_move.wav": _tone(0.31, [(120, 0.31, "triangle"), (360, 0.14, "square")], noise=0.15, pulse=14.0, seed=306),
        "grub_roll_miss.wav": _tone(0.34, [(420, 0.2, "triangle"), (210, 0.28, "sine")], sweep=-0.58, pulse=5.0, seed=307),
        "bat_bolt_charge.wav": _tone(0.54, [(520, 0.22, "sine"), (1040, 0.18, "triangle"), (1560, 0.07, "sine")], noise=0.045, sweep=0.56, pulse=7.0, seed=308),
        "bat_bolt_launch.wav": _tone(0.22, [(640, 0.24, "triangle"), (1280, 0.15, "sine")], noise=0.09, sweep=0.9, seed=309),
        "bat_bolt_impact.wav": _tone(0.28, [(240, 0.3, "triangle"), (720, 0.16, "sine")], noise=0.15, sweep=-0.38, seed=310),
        "stage_transition.wav": _tone(0.55, [(392, 0.19, "sine"), (587, 0.2, "sine"), (880, 0.14, "triangle")], sweep=0.22, pulse=5.0, seed=311),
        "elite_appear.wav": _tone(0.66, [(110, 0.34, "sine"), (330, 0.2, "triangle"), (990, 0.08, "sine")], noise=0.12, sweep=0.35, pulse=6.0, seed=312),
        "elite_defeat.wav": _tone(0.72, [(220, 0.22, "triangle"), (440, 0.2, "sine"), (880, 0.13, "sine")], noise=0.1, sweep=0.44, pulse=5.0, seed=315),
        "result_victory.wav": _tone(0.92, [(392, 0.2, "sine"), (523, 0.23, "sine"), (659, 0.2, "triangle"), (1047, 0.12, "sine")], sweep=0.16, pulse=4.0, seed=313),
        "result_failure.wav": _tone(0.68, [(294, 0.24, "sine"), (220, 0.22, "triangle"), (147, 0.18, "sine")], sweep=-0.24, seed=314),
        "skill_star_lance.wav": _tone(0.23, [(720, 0.34, "sine"), (1080, 0.22, "triangle")], noise=0.04, sweep=0.42, seed=401),
        "skill_sun_orbit.wav": _tone(0.38, [(246, 0.3, "sine"), (493, 0.28, "sine"), (740, 0.14, "sine")], pulse=9.0, seed=402),
        "skill_frost_tide.wav": _tone(0.52, [(560, 0.22, "sine"), (840, 0.18, "sine"), (1120, 0.1, "triangle")], noise=0.08, sweep=-0.38, seed=403),
        "frost_hit.wav": _tone(0.23, [(820, 0.2, "triangle"), (1640, 0.1, "sine")], noise=0.09, sweep=-0.28, seed=404),
        "skill_ember_volley.wav": _tone(0.22, [(310, 0.3, "triangle"), (620, 0.2, "square")], noise=0.14, sweep=0.5, seed=405),
        "skill_meteor_rain.wav": _tone(0.62, [(92, 0.48, "sine"), (184, 0.28, "triangle")], noise=0.22, sweep=-0.42, seed=406),
        "meteor_impact.wav": _tone(0.5, [(82, 0.44, "sine"), (246, 0.2, "triangle"), (738, 0.07, "sine")], noise=0.25, sweep=-0.38, seed=407),
        "skill_phoenix_heart.wav": _tone(0.74, [(330, 0.24, "sine"), (495, 0.21, "sine"), (660, 0.18, "triangle")], noise=0.06, sweep=0.3, pulse=5.0, seed=408),
        "phoenix_impact.wav": _tone(0.48, [(440, 0.2, "sine"), (660, 0.24, "triangle"), (990, 0.13, "sine")], noise=0.05, sweep=0.24, seed=409),
    }
    for name, samples in sounds.items():
        _write_wav(name, samples)


if __name__ == "__main__":
    main()
