class BreathingEngine {
  constructor() {
    // Base patterns in seconds: [inhale, holdIn, exhale, holdOut]
    this.patterns = {
      relax:    [4, 7, 8, 0],   // 4-7-8 breathing
      focus:    [4, 4, 4, 4],   // Box breathing
      balance:  [5, 0, 5, 0],   // Coherent breathing
      restore:  [4, 0, 6, 0],   // Extended exhale
      energize: [6, 0, 4, 0],   // Stimulating breath
      unwind:   [4, 4, 6, 0],   // Deep slow
    };

    // Phase names for UI
    this.phaseNames = ['Inhale', 'Hold', 'Exhale', 'Hold'];
  }

  // Calculate the scaled pattern based on target BPM
  getScaledPattern(modeId, targetBPM) {
    const basePattern = this.patterns[modeId];
    if (!basePattern) return [0,0,0,0];
    
    const baseCycleTime = basePattern.reduce((a, b) => a + b, 0);
    const targetCycleTime = 60 / targetBPM;
    const scale = targetCycleTime / baseCycleTime;
    
    return basePattern.map(phase => phase * scale);
  }
}

export const breathingEngine = new BreathingEngine();
