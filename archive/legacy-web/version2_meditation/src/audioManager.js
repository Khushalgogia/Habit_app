class AudioManager {
  constructor() {
    this.ctx = null;
    this.masterGain = null;
    this.bgGain = null;
    this.cueGain = null;
    
    this.bgOsc = null;
    this.noiseNode = null;
    this.isPlayingBg = false;

    // Buffers for the 3 finalized mp3s
    this.buffers = {
      inhale: null,
      exhale: null,
      hold: null
    };
    
    this.isLoaded = false;
    this.currentPhaseNodes = [];
  }

  async init() {
    if (this.ctx && this.isLoaded) return;
    try {
      if (!this.ctx) {
        this.ctx = new (window.AudioContext || window.webkitAudioContext)();
        this.masterGain = this.ctx.createGain();
        this.bgGain = this.ctx.createGain();
        this.cueGain = this.ctx.createGain();

        this.bgGain.connect(this.masterGain);
        this.cueGain.connect(this.masterGain);
        this.masterGain.connect(this.ctx.destination);

        // Default volumes
        this.masterGain.gain.value = 0.8;
        this.bgGain.gain.value = 0.5;
        this.cueGain.gain.value = 0.8; // Cues Volume
      }

      if (!this.isLoaded) {
        await this.loadAllBuffers();
        this.isLoaded = true;
      }
    } catch (e) {
      console.error("Web Audio API not supported", e);
    }
  }

  async loadAllBuffers() {
    try {
      const [inhaleRes, exhaleRes, holdRes] = await Promise.all([
        fetch('/sounds/selected_sounds/inhale_sound.mp3'),
        fetch('/sounds/selected_sounds/exhale_sound.mp3'),
        fetch('/sounds/selected_sounds/hold_sound.mp3')
      ]);

      const [inhaleArray, exhaleArray, holdArray] = await Promise.all([
        inhaleRes.arrayBuffer(),
        exhaleRes.arrayBuffer(),
        holdRes.arrayBuffer()
      ]);

      // Decode arrays into Web Audio API buffers
      this.buffers.inhale = await this.ctx.decodeAudioData(inhaleArray);
      this.buffers.exhale = await this.ctx.decodeAudioData(exhaleArray);
      this.buffers.hold = await this.ctx.decodeAudioData(holdArray);
    } catch (e) {
      console.error("Failed to load audio buffers. Ensure files exist in /public/sounds/selected_sounds/", e);
    }
  }

  // --- Background Ambient Sounds (Unchanged) ---
  createNoiseBuffer() {
    if (!this.ctx) return null;
    const bufferSize = this.ctx.sampleRate * 2;
    const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const output = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      output[i] = Math.random() * 2 - 1;
    }
    return buffer;
  }

  playBackground(type) {
    if (!this.ctx) return;
    this.stopBackground();
    if (type === 'None') return;

    this.isPlayingBg = true;

    if (type === 'Ocean' || type === 'Rain') {
      const buffer = this.createNoiseBuffer();
      this.noiseNode = this.ctx.createBufferSource();
      this.noiseNode.buffer = buffer;
      this.noiseNode.loop = true;

      const filter = this.ctx.createBiquadFilter();
      filter.type = type === 'Ocean' ? 'lowpass' : 'bandpass';
      filter.frequency.value = type === 'Ocean' ? 400 : 1000;
      
      if (type === 'Ocean') {
         const lfo = this.ctx.createOscillator();
         lfo.frequency.value = 0.1;
         const lfoGain = this.ctx.createGain();
         lfoGain.gain.value = 300;
         lfo.connect(lfoGain);
         lfoGain.connect(filter.frequency);
         lfo.start();
      }

      this.noiseNode.connect(filter);
      filter.connect(this.bgGain);
      this.noiseNode.start();
    } else if (type === 'Forest') {
      this.bgOsc = this.ctx.createOscillator();
      this.bgOsc.type = 'sine';
      
      const lfo = this.ctx.createOscillator();
      lfo.type = 'sawtooth';
      lfo.frequency.value = 2;
      
      const lfoGain = this.ctx.createGain();
      lfoGain.gain.value = 500;
      
      lfo.connect(lfoGain);
      lfoGain.connect(this.bgOsc.frequency);
      
      this.bgOsc.connect(this.bgGain);
      this.bgOsc.start();
      lfo.start();
    }
  }

  stopBackground() {
    this.isPlayingBg = false;
    if (this.noiseNode) {
      try { this.noiseNode.stop(); } catch(e){}
      this.noiseNode.disconnect();
      this.noiseNode = null;
    }
    if (this.bgOsc) {
      try { this.bgOsc.stop(); } catch(e){}
      this.bgOsc.disconnect();
      this.bgOsc = null;
    }
  }

  // --- Finalized MP3 Buffer Playback Engine ---

  stopCurrentPhaseSound() {
    if (!this.ctx) return;
    const now = this.ctx.currentTime;
    
    this.currentPhaseNodes.forEach(item => {
      try {
        if (item.gainNode) {
          // Smooth 0.2s crossfade out to radically prevent clicks/pops
          item.gainNode.gain.cancelScheduledValues(now);
          item.gainNode.gain.setValueAtTime(item.gainNode.gain.value, now);
          item.gainNode.gain.linearRampToValueAtTime(0, now + 0.2);
        }
        if (item.source) {
          item.source.stop(now + 0.2);
          setTimeout(() => { try { item.source.disconnect(); } catch(e){} }, 300);
        }
      } catch (e) { console.warn("Error stopping node", e); }
    });
    this.currentPhaseNodes = [];
  }

  _playBuffer(bufferName, durationSeconds, shouldStretch, loop = false, pitchShift = 1.0) {
    if (!this.ctx || !this.isLoaded) return;
    const buffer = this.buffers[bufferName];
    if (!buffer) return;

    const source = this.ctx.createBufferSource();
    source.buffer = buffer;
    source.loop = loop;

    // Dynamic stretching: If the breath is 8s but audio is 6s, scale playbackRate to stretch the audio to fit perfectly.
    if (shouldStretch && durationSeconds > 0) {
      source.playbackRate.value = buffer.duration / durationSeconds;
    } else {
      source.playbackRate.value = pitchShift;
    }

    const gainNode = this.ctx.createGain();
    const now = this.ctx.currentTime;
    
    // Smooth 0.2s fade in to prevent pops
    gainNode.gain.setValueAtTime(0, now);
    gainNode.gain.linearRampToValueAtTime(1.0, now + 0.2);

    source.connect(gainNode);
    gainNode.connect(this.cueGain);

    source.start(now);

    // If it's not looping, ensure it stops completely cleanly at the duration boundary
    if (!loop && durationSeconds > 0) {
      source.stop(now + durationSeconds + 0.5); // Provide 0.5s padding to finish fade out
      // Fade out exactly at the end 
      gainNode.gain.setValueAtTime(1.0, now + Math.max(0, durationSeconds - 0.2));
      gainNode.gain.linearRampToValueAtTime(0, now + durationSeconds);
    }

    this.currentPhaseNodes.push({ source, gainNode });
  }

  playPhaseSound(phaseIndex, durationSeconds) {
    if (!this.isLoaded) return;
    this.stopCurrentPhaseSound();

    if (phaseIndex === 0) { 
      // Inhale Phase: Play Tibetan rubbed drone, stretch perfectly to duration
      this._playBuffer('inhale', durationSeconds, true, false);
    } 
    else if (phaseIndex === 1 || phaseIndex === 3) { 
      // Hold Phase: Play loud heartbeat on infinite loop. Do not stretch heartbeat.
      this._playBuffer('hold', durationSeconds, false, true);
    } 
    else if (phaseIndex === 2) { 
      // Exhale Phase: Play Monk "Om" Chant, stretch perfectly to duration
      this._playBuffer('exhale', durationSeconds, true, false);
    } 
  }

  playComplete() {
    this.stopCurrentPhaseSound();
    if (!this.isLoaded) return;
    
    // Play the inhaled Tibetan bowl, but pitch-shifted down (0.6x speed) 
    // to simulate a very deep, long final release gong.
    this._playBuffer('inhale', 8, false, false, 0.6);
  }
}

export const audioManager = new AudioManager();
