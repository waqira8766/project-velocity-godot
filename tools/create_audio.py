"""Generate original, loopable Velocity audio. Use Python 3 from the project root."""
from math import exp, pi, sin
from pathlib import Path
from random import Random
from struct import pack
from wave import open as open_wave

RATE = 22050
DESTINATION = Path(__file__).resolve().parents[1] / 'assets/audio'
RANDOM = Random(845)
DESTINATION.mkdir(parents=True, exist_ok=True)


def write(name, duration, sample):
    frame_count = round(RATE * duration)
    with open_wave(str(DESTINATION / f'{name}.wav'), 'wb') as stream:
        stream.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        stream.writeframes(b''.join(
            pack('<h', round(max(-1, min(1, sample(i / RATE, duration))) * 32766))
            for i in range(frame_count)
        ))


def tone(freq, time):
    return sin(2 * pi * freq * time)


def edge(time, duration):
    return min(time * 180, 1, (duration - time) * 75)


def impulse(name, duration, base, sweep, noise, decay):
    def sample(time, length):
        pitch = base + sweep * time
        body = tone(pitch, time) + .21 * tone(pitch * 2.07, time)
        grit = RANDOM.uniform(-1, 1) * noise
        return edge(time, length) * exp(-time * decay) * (.55 * body + grit)
    write(name, duration, sample)


impulse('step', .14, 84, -168, .25, 24)
impulse('land', .25, 68, -110, .26, 14)
impulse('jump', .24, 118, 320, .15, 9)
impulse('hit', .29, 115, -200, .42, 15)
impulse('damage', .30, 83, -118, .26, 11)
impulse('boost', .54, 54, 208, .43, 4.5)
impulse('lightning', .46, 96, -135, .57, 8)
impulse('slide', .37, 44, 23, .43, 10)
impulse('rewind', .83, 256, -146, .10, 2.8)
impulse('phase', .35, 262, -418, .14, 6)
impulse('shockwave', .61, 59, -61, .27, 8)
impulse('portal', .77, 96, 147, .20, 3.8)


def tone_cue(time, length):
    notes = (261.626, 329.628, 391.995, 523.251, 783.991)
    return sum(.28 * edge(time - .075 * index, length - .075 * index)
               * exp(-(time - .075 * index) * 5)
               * tone(freq, time - .075 * index)
               for index, freq in enumerate(notes) if time >= .075 * index)


write('goal', .92, tone_cue)


def score(time, length):
    bar = int(time / 2)
    root = (110.0, 130.813, 146.832, 98.0)[bar % 4]
    local = time % 2
    pulse = exp(-(local % .5) * 5.0) * min(local % .5 * 55, 1)
    chord = tone(root, local) * .52 + tone(root * 1.5, local) * .22
    chord += tone(root * 2.0, local) * .13 * tone(.5, time)
    bed = .09 * tone(55, time) + .05 * tone(110, time)
    return (chord * pulse * .23 + bed) * min(time * 8, 1, (length - time) * 8)


write('score', 16.0, score)


def atmosphere(time, length):
    harmonic = sum(tone((i * i + 11) / length, time + i * .155) for i in range(13)) / 13
    rumble = tone(42, time) * .14 + tone(61.5, time) * .10
    return harmonic * .20 + rumble * (.093 + .057 * tone(.5, time))


def wind(time, length):
    layers = sum(tone((i * i + 81) / length, time + i * .096) for i in range(28)) / 28
    return layers * (.21 + .02 * tone(.5,time)) + tone(79, time) * .024


write('atmosphere', 8.0, atmosphere)
write('wind', 8.0, wind)
