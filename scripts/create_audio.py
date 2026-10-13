import math
import pathlib
import struct
import wave

output = pathlib.Path(__file__).resolve().parents[1] / 'Crailglitun/Resources/tick.wav'
with wave.open(str(output), 'w') as sound:
    sound.setparams((1, 2, 22050, 0, 'NONE', 'not compressed'))
    sound.writeframes(b''.join(struct.pack('<h', int(2600 * math.sin(2 * math.pi * 850 * i / 22050) * math.exp(-i / 150))) for i in range(1400)))
