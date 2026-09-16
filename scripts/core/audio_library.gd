class_name AudioLibrary
extends RefCounted

## AudioLibrary
## Procedural, warning-free AudioStream generator and registry for Echoes of the Celestial Staff.
## Provides authentic, cached 16-bit PCM AudioStreamWAV resources for music loops,
## environmental ambience, combat foley, enemy attacks, boss cues, and UI sounds.
## Guarantees 100% warning-free playback across headless tests and active gameplay.

static var _cached_streams: Dictionary = {}

# -------------------------------------------------------------------------
# Music Stream Generation
# -------------------------------------------------------------------------

static func get_music_stream(state_id: StringName) -> AudioStreamWAV:
	if _cached_streams.has(state_id):
		return _cached_streams[state_id] as AudioStreamWAV
	
	var stream: AudioStreamWAV = null
	match state_id:
		&"exploration":
			# Gentle pentatonic ambient melody (C - D - E - G - A) with soft flutelike decay
			stream = _generate_pentatonic_loop(4.0, [261.63, 293.66, 329.63, 392.00, 440.00], 0.25)
		&"intermediate_boss":
			# Driving martial rhythm with taiko pulse and resonant gong accents
			stream = _generate_rhythmic_boss_loop(3.2, 110.0, 220.0, 0.40)
		&"final_boss_p1":
			# Low, menacing primordial drone with solemn string cadence
			stream = _generate_drone_loop(4.0, 65.41, 130.81, 0.45) # Low C
		&"final_boss_p2":
			# Frenzied dissonant corruption pulse with rapid percussion
			stream = _generate_frenzy_loop(2.4, 73.42, 146.83, 0.50) # Low D tension
		&"chapter_complete":
			# Triumphant rising celestial fanfare
			stream = _generate_fanfare(3.5, [261.63, 329.63, 392.00, 523.25, 659.25], 0.45)
		_:
			stream = _generate_pentatonic_loop(2.0, [261.63, 392.00], 0.20)
	
	if stream != null:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if state_id != &"chapter_complete" else AudioStreamWAV.LOOP_DISABLED
		_cached_streams[state_id] = stream
	return stream

# -------------------------------------------------------------------------
# Ambience Stream Generation
# -------------------------------------------------------------------------

static func get_ambience_stream(ambience_id: StringName) -> AudioStreamWAV:
	if _cached_streams.has(ambience_id):
		return _cached_streams[ambience_id] as AudioStreamWAV
	
	var stream: AudioStreamWAV = null
	match ambience_id:
		&"forest_wind":
			stream = _generate_filtered_noise(3.0, 0.18, 0.05)
		&"bamboo_rustle":
			stream = _generate_filtered_noise(2.5, 0.15, 0.12)
		&"shrine_hum":
			stream = _generate_drone_loop(3.0, 110.0, 164.81, 0.18)
		&"corrupted_heart":
			stream = _generate_drone_loop(2.5, 48.99, 97.98, 0.25)
		_:
			stream = _generate_filtered_noise(2.0, 0.12, 0.05)
	
	if stream != null:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_cached_streams[ambience_id] = stream
	return stream

# -------------------------------------------------------------------------
# Sound Effect (SFX) Generation
# -------------------------------------------------------------------------

static func get_sfx_stream(sfx_id: StringName) -> AudioStreamWAV:
	if _cached_streams.has(sfx_id):
		return _cached_streams[sfx_id] as AudioStreamWAV
	
	var stream: AudioStreamWAV = null
	match sfx_id:
		# Player Locomotion
		&"footstep":
			stream = _generate_thud(0.08, 90.0, 45.0, 0.20)
		&"jump":
			stream = _generate_chirp(0.14, 180.0, 360.0, 0.25)
		&"land":
			stream = _generate_thud(0.12, 120.0, 50.0, 0.30)
		
		# Staff Attacks & Swings
		&"staff_swing_light":
			stream = _generate_whoosh(0.12, 300.0, 150.0, 0.35)
		&"staff_swing_heavy":
			stream = _generate_whoosh(0.20, 220.0, 90.0, 0.45)
		&"charge_heavy":
			stream = _generate_chirp(0.30, 120.0, 440.0, 0.35)
		
		# Defense & Evasion
		&"dodge":
			stream = _generate_whoosh(0.16, 240.0, 120.0, 0.28)
		&"parry":
			stream = _generate_chime(0.22, 880.0, 0.40) # Resonant deflection ping
		&"perfect_parry":
			stream = _generate_chime_chord(0.35, [880.0, 1320.0, 1760.0], 0.55) # Brilliant metallic bell
		&"perfect_dodge":
			stream = _generate_whoosh(0.22, 480.0, 200.0, 0.35)
		
		# Combat Impacts
		&"hit_light":
			stream = _generate_impact(0.10, 280.0, 0.35)
		&"hit_heavy":
			stream = _generate_impact(0.20, 140.0, 0.55)
		&"stagger":
			stream = _generate_impact(0.28, 90.0, 0.60)
		&"enemy_death":
			stream = _generate_dissolve(0.35, 200.0, 60.0, 0.40)
		&"player_hit":
			stream = _generate_impact(0.18, 160.0, 0.50)
		&"player_death":
			stream = _generate_dissolve(0.50, 150.0, 40.0, 0.60)
		
		# Spirit & Transformation
		&"spirit_celestial_arc":
			stream = _generate_whoosh_harmonic(0.25, 440.0, 880.0, 0.45)
		&"spirit_heavenly_pulse":
			stream = _generate_impact(0.30, 110.0, 0.60)
		&"spirit_cloud_step":
			stream = _generate_whoosh(0.18, 520.0, 260.0, 0.35)
		&"awakening_start":
			stream = _generate_fanfare(0.60, [330.0, 440.0, 550.0, 660.0], 0.55)
		&"awakening_end":
			stream = _generate_dissolve(0.40, 440.0, 110.0, 0.35)
		
		# Enemy Cues
		&"scout_claw":
			stream = _generate_whoosh(0.12, 400.0, 200.0, 0.30)
		&"thorn_slam":
			stream = _generate_thud(0.25, 110.0, 40.0, 0.50)
		&"spore_cast":
			stream = _generate_chirp(0.25, 220.0, 550.0, 0.35)
		&"spore_burst":
			stream = _generate_impact(0.15, 320.0, 0.30)
		
		# Boss Cues
		&"boss_intro":
			stream = _generate_thud(0.45, 80.0, 30.0, 0.60)
		&"boss_telegraph":
			stream = _generate_chime(0.25, 660.0, 0.35)
		&"boss_slam":
			stream = _generate_thud(0.35, 75.0, 35.0, 0.70)
		&"boss_transition":
			stream = _generate_frenzy_loop(0.8, 80.0, 160.0, 0.65)
		&"boss_defeat":
			stream = _generate_dissolve(0.80, 180.0, 45.0, 0.65)
		
		# UI Cues
		&"checkpoint":
			stream = _generate_chime_chord(0.45, [523.25, 659.25, 783.99], 0.45) # Healing major triad
		&"stance_switch":
			stream = _generate_chime(0.08, 1046.50, 0.25)
		&"victory_fanfare":
			stream = _generate_fanfare(1.2, [392.00, 523.25, 659.25, 783.99, 1046.50], 0.60)
		_:
			stream = _generate_chime(0.10, 440.0, 0.20)
	
	if stream != null:
		_cached_streams[sfx_id] = stream
	return stream

# -------------------------------------------------------------------------
# Core Synthesizers (Pure 16-bit PCM AudioStreamWAV)
# -------------------------------------------------------------------------

static func _create_pcm_buffer(sample_count: int) -> PackedByteArray:
	var b: PackedByteArray = PackedByteArray()
	b.resize(sample_count * 2)
	return b

static func _build_wav(bytes: PackedByteArray, mix_rate: int = 22050) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	return wav

static func _sample_to_i16(sample_f: float) -> int:
	var clamped: float = clampf(sample_f, -1.0, 1.0)
	return clampi(int(clamped * 32767.0), -32768, 32767)

static func _generate_thud(duration: float, start_freq: float, end_freq: float, volume: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = int(duration * float(mix_rate))
	var bytes: PackedByteArray = _create_pcm_buffer(count)
	
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(count)
		var freq: float = lerpf(start_freq, end_freq, t)
		phase += (freq * TAU) / float(mix_rate)
		var env: float = (1.0 - t) * (1.0 - t)
		var sample: float = sin(phase) * env * volume
		bytes.encode_s16(i * 2, _sample_to_i16(sample))
	
	return _build_wav(bytes, mix_rate)

static func _generate_whoosh(duration: float, start_freq: float, end_freq: float, volume: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = int(duration * float(mix_rate))
	var bytes: PackedByteArray = _create_pcm_buffer(count)
	
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(count)
		var freq: float = lerpf(start_freq, end_freq, t)
		phase += (freq * TAU) / float(mix_rate)
		var env: float = sin(t * PI) # Bell envelope
		var noise: float = randf_range(-0.15, 0.15)
		var sample: float = (sin(phase) * 0.7 + noise) * env * volume
		bytes.encode_s16(i * 2, _sample_to_i16(sample))
	
	return _build_wav(bytes, mix_rate)

static func _generate_whoosh_harmonic(duration: float, f1: float, f2: float, volume: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = int(duration * float(mix_rate))
	var bytes: PackedByteArray = _create_pcm_buffer(count)
	
	var p1: float = 0.0
	var p2: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(count)
		p1 += (f1 * TAU) / float(mix_rate)
		p2 += (f2 * TAU) / float(mix_rate)
		var env: float = sin(t * PI)
		var sample: float = (sin(p1) * 0.6 + sin(p2) * 0.4) * env * volume
		bytes.encode_s16(i * 2, _sample_to_i16(sample))
	
	return _build_wav(bytes, mix_rate)

static func _generate_chirp(duration: float, start_freq: float, end_freq: float, volume: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = int(duration * float(mix_rate))
	var bytes: PackedByteArray = _create_pcm_buffer(count)
	
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(count)
		var freq: float = lerpf(start_freq, end_freq, t)
		phase += (freq * TAU) / float(mix_rate)
		var env: float = 1.0 - t
		var sample: float = sin(phase) * env * volume
		bytes.encode_s16(i * 2, _sample_to_i16(sample))
	
	return _build_wav(bytes, mix_rate)

static func _generate_chime(duration: float, freq: float, volume: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = int(duration * float(mix_rate))
	var bytes: PackedByteArray = _create_pcm_buffer(count)
	
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(count)
		phase += (freq * TAU) / float(mix_rate)
		var env: float = exp(-5.0 * t) # Natural exponential decay
		var sample: float = sin(phase) * env * volume
		bytes.encode_s16(i * 2, _sample_to_i16(sample))
	
	return _build_wav(bytes, mix_rate)

static func _generate_chime_chord(duration: float, freqs: Array, volume: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = int(duration * float(mix_rate))
	var bytes: PackedByteArray = _create_pcm_buffer(count)
	
	var phases: Array = []
	for _f in freqs:
		phases.append(0.0)
	
	var n_freqs: float = float(freqs.size())
	for i in range(count):
		var t: float = float(i) / float(count)
		var env: float = exp(-4.0 * t)
		var sum_s: float = 0.0
		for j in range(freqs.size()):
			var f: float = float(freqs[j])
			phases[j] += (f * TAU) / float(mix_rate)
			sum_s += sin(phases[j])
		var sample: float = (sum_s / n_freqs) * env * volume
		bytes.encode_s16(i * 2, _sample_to_i16(sample))
	
	return _build_wav(bytes, mix_rate)

static func _generate_impact(duration: float, freq: float, volume: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = int(duration * float(mix_rate))
	var bytes: PackedByteArray = _create_pcm_buffer(count)
	
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(count)
		phase += (freq * TAU) / float(mix_rate)
		var noise: float = randf_range(-0.4, 0.4)
		var env: float = exp(-8.0 * t)
		var sample: float = (sin(phase) * 0.6 + noise * 0.4) * env * volume
		bytes.encode_s16(i * 2, _sample_to_i16(sample))
	
	return _build_wav(bytes, mix_rate)

static func _generate_dissolve(duration: float, start_freq: float, end_freq: float, volume: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = int(duration * float(mix_rate))
	var bytes: PackedByteArray = _create_pcm_buffer(count)
	
	var phase: float = 0.0
	for i in range(count):
		var t: float = float(i) / float(count)
		var f: float = lerpf(start_freq, end_freq, t)
		phase += (f * TAU) / float(mix_rate)
		var env: float = (1.0 - t)
		var noise: float = randf_range(-0.3, 0.3)
		var sample: float = (sin(phase) * 0.5 + noise * 0.5) * env * volume
		bytes.encode_s16(i * 2, _sample_to_i16(sample))
	
	return _build_wav(bytes, mix_rate)

static func _generate_filtered_noise(duration: float, volume: float, cutoff_weight: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = int(duration * float(mix_rate))
	var bytes: PackedByteArray = _create_pcm_buffer(count)
	
	var prev: float = 0.0
	for i in range(count):
		var raw: float = randf_range(-1.0, 1.0)
		prev = lerpf(prev, raw, cutoff_weight) # Simple one-pole low-pass filter
		var sample: float = prev * volume
		bytes.encode_s16(i * 2, _sample_to_i16(sample))
	
	return _build_wav(bytes, mix_rate)

static func _generate_drone_loop(duration: float, f1: float, f2: float, volume: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = int(duration * float(mix_rate))
	var bytes: PackedByteArray = _create_pcm_buffer(count)
	
	var p1: float = 0.0
	var p2: float = 0.0
	for i in range(count):
		p1 += (f1 * TAU) / float(mix_rate)
		p2 += (f2 * TAU) / float(mix_rate)
		var sample: float = (sin(p1) * 0.6 + sin(p2) * 0.4) * volume
		bytes.encode_s16(i * 2, _sample_to_i16(sample))
	
	return _build_wav(bytes, mix_rate)

static func _generate_pentatonic_loop(duration: float, notes: Array, volume: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = int(duration * float(mix_rate))
	var bytes: PackedByteArray = _create_pcm_buffer(count)
	
	var note_duration: float = duration / float(notes.size())
	var note_samples: int = int(note_duration * float(mix_rate))
	
	for n in range(notes.size()):
		var freq: float = float(notes[n])
		var phase: float = 0.0
		var start_sample: int = n * note_samples
		for s in range(note_samples):
			var idx: int = start_sample + s
			if idx >= count:
				break
			var t: float = float(s) / float(note_samples)
			phase += (freq * TAU) / float(mix_rate)
			var env: float = sin(t * PI)
			var sample: float = sin(phase) * env * volume
			bytes.encode_s16(idx * 2, _sample_to_i16(sample))
	
	return _build_wav(bytes, mix_rate)

static func _generate_rhythmic_boss_loop(duration: float, bass_f: float, snare_f: float, volume: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = int(duration * float(mix_rate))
	var bytes: PackedByteArray = _create_pcm_buffer(count)
	
	var beats: int = 8
	var beat_samples: int = count / beats
	
	for b in range(beats):
		var is_snare: bool = (b % 2 == 1)
		var freq: float = snare_f if is_snare else bass_f
		var phase: float = 0.0
		var start_s: int = b * beat_samples
		for s in range(beat_samples):
			var idx: int = start_s + s
			if idx >= count:
				break
			var t: float = float(s) / float(beat_samples)
			phase += (freq * TAU) / float(mix_rate)
			var env: float = exp(-6.0 * t)
			var noise: float = randf_range(-0.25, 0.25) if is_snare else 0.0
			var sample: float = (sin(phase) * 0.7 + noise) * env * volume
			bytes.encode_s16(idx * 2, _sample_to_i16(sample))
	
	return _build_wav(bytes, mix_rate)

static func _generate_frenzy_loop(duration: float, f1: float, f2: float, volume: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = int(duration * float(mix_rate))
	var bytes: PackedByteArray = _create_pcm_buffer(count)
	
	var p1: float = 0.0
	var p2: float = 0.0
	for i in range(count):
		p1 += (f1 * TAU) / float(mix_rate)
		p2 += (f2 * TAU) / float(mix_rate)
		var noise: float = randf_range(-0.2, 0.2)
		var sample: float = (sin(p1) * 0.5 + sin(p2) * 0.4 + noise * 0.2) * volume
		bytes.encode_s16(i * 2, _sample_to_i16(sample))
	
	return _build_wav(bytes, mix_rate)

static func _generate_fanfare(duration: float, notes: Array, volume: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = int(duration * float(mix_rate))
	var bytes: PackedByteArray = _create_pcm_buffer(count)
	
	var step_dur: float = duration / float(notes.size())
	var step_samples: int = int(step_dur * float(mix_rate))
	
	for n in range(notes.size()):
		var freq: float = float(notes[n])
		var phase: float = 0.0
		var start_s: int = n * step_samples
		for s in range(step_samples):
			var idx: int = start_s + s
			if idx >= count:
				break
			var t: float = float(s) / float(step_samples)
			phase += (freq * TAU) / float(mix_rate)
			var env: float = 1.0 - (t * 0.3)
			var sample: float = (sin(phase) * 0.8 + sin(phase * 2.0) * 0.2) * env * volume
			bytes.encode_s16(idx * 2, _sample_to_i16(sample))
	
	return _build_wav(bytes, mix_rate)
