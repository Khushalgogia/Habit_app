import React, { useState, useEffect, useRef } from 'react';
import { 
  Wind, Focus, Scale, BatteryCharging, 
  Coffee, Moon, Play, Pause, X, 
  ChevronLeft, Clock, Music, Heart, Settings
} from 'lucide-react';
import { breathingEngine } from './breathingEngine';
import { audioManager } from './audioManager';

// --- ADAPTIVE COLOR PALETTES (Aurora Blobs) ---
const themeColors = {
  home: { blob1: 'bg-rose-200', blob2: 'bg-violet-200', blob3: 'bg-sky-200' },
  relax: { blob1: 'bg-purple-300', blob2: 'bg-fuchsia-300', blob3: 'bg-indigo-300' },
  focus: { blob1: 'bg-emerald-300', blob2: 'bg-cyan-300', blob3: 'bg-teal-300' },
  balance: { blob1: 'bg-amber-300', blob2: 'bg-orange-300', blob3: 'bg-yellow-200' },
  restore: { blob1: 'bg-sky-300', blob2: 'bg-blue-300', blob3: 'bg-indigo-200' },
  energize: { blob1: 'bg-rose-400', blob2: 'bg-orange-300', blob3: 'bg-pink-300' },
  unwind: { blob1: 'bg-indigo-300', blob2: 'bg-slate-400', blob3: 'bg-purple-300' }
};

const modes = [
  { id: 'relax', name: 'Relax', ratio: '4-7-8', desc: 'Calm your nervous system.', pattern: [4, 7, 8, 0], benefits: ['Activates parasympathetic system', 'Lowers heart rate naturally'], reason: 'Extending the exhale longer than the inhale signals to your vagus nerve that you are safe, forcefully turning off your fight-or-flight response.', icon: Wind, textPrimary: 'text-purple-700', bgPrimary: 'bg-purple-600' },
  { id: 'focus', name: 'Focus', ratio: 'Box Breath', desc: 'Sharpen your mental clarity.', pattern: [4, 4, 4, 4], benefits: ['Balances autonomic nervous system', 'Increases concentration'], reason: 'Equal duration in all four phases creates a perfectly neutral, balanced state that clears mental fog and heightens cognitive focus.', icon: Focus, textPrimary: 'text-emerald-700', bgPrimary: 'bg-emerald-600' },
  { id: 'balance', name: 'Balance', ratio: 'Coherent', desc: 'Center your wandering mind.', pattern: [5, 0, 5, 0], benefits: ['Synchronizes heart and brain', 'Stabilizes blood pressure'], reason: 'Breathing continuously at roughly 6 breaths per minute maximizes heart rate variability (HRV), putting your entire body into physiological coherence.', icon: Scale, textPrimary: 'text-amber-700', bgPrimary: 'bg-amber-500' },
  { id: 'restore', name: 'Restore', ratio: 'Deep Exhale', desc: 'Activate physical recovery.', pattern: [4, 0, 6, 0], benefits: ['Clears residual CO2', 'Relieves physical tension'], reason: 'A slightly longer, smooth exhale immediately reduces muscle tension and triggers the release of relaxation hormones throughout the body.', icon: BatteryCharging, textPrimary: 'text-sky-700', bgPrimary: 'bg-sky-500' },
  { id: 'energize', name: 'Energize', ratio: 'Stimulating', desc: 'Boost your daily energy.', pattern: [6, 0, 4, 0], benefits: ['Increases oxygen saturation', 'Elevates alertness'], reason: 'Inhaling for longer than you exhale gently stimulates the sympathetic nervous system, providing a natural, caffeine-free boost of alertness.', icon: Coffee, textPrimary: 'text-rose-700', bgPrimary: 'bg-rose-500' },
  { id: 'unwind', name: 'Unwind', ratio: 'Slow Down', desc: 'Prepare your body for sleep.', pattern: [4, 4, 6, 0], benefits: ['Disconnects racing thoughts', 'Induces physiological rest'], reason: 'Holding the breath gently before a long exhale drops core body temperature and dramatically slows brainwave activity, mimicking the onset of sleep.', icon: Moon, textPrimary: 'text-indigo-700', bgPrimary: 'bg-indigo-500' },
];

const durations = [2, 3, 5, 10, 15];
const soundsOptions = ['Rain', 'Ocean', 'Forest', 'None'];

const formatPattern = (p) => {
  const parts = [];
  if (p[0] > 0) parts.push(`${p[0]}s In`);
  if (p[1] > 0) parts.push(`${p[1]}s Hold`);
  if (p[2] > 0) parts.push(`${p[2]}s Out`);
  if (p[3] > 0) parts.push(`${p[3]}s Hold`);
  return parts.join(' • ');
};

export default function App() {
  const [view, setView] = useState('home'); // home, detail, session
  const [selectedMode, setSelectedMode] = useState(null);
  
  // Settings (normally from localStorage)
  const [duration, setDuration] = useState(5); 
  const [sound, setSound] = useState('Rain');
  const [bpm, setBpm] = useState(6); // 4, 6, 8

  // Session state
  const [isPlaying, setIsPlaying] = useState(false);
  
  const currentTheme = view === 'home' || !selectedMode ? themeColors.home : themeColors[selectedMode.id];

  const handleSelectMode = (mode) => {
    setSelectedMode(mode);
    setView('detail');
  };

  const [isStarting, setIsStarting] = useState(false);

  const handleStartSession = async () => {
    setIsStarting(true);
    // Init Audio context and buffer the remote MP3s on first user interaction
    await audioManager.init();
    setView('session');
    setIsPlaying(true);
    setIsStarting(false);
  };

  const handleEndSession = () => {
    setIsPlaying(false);
    audioManager.stopBackground();
    setView('detail');
  };

  return (
    <div className="min-h-screen bg-[#f8fafc] text-slate-900 font-sans selection:bg-slate-200 overflow-hidden relative">
      {/* Animated Color Orbs */}
      <div className="fixed inset-0 w-full h-full pointer-events-none z-0">
        <div className="absolute inset-0 bg-noise z-10 w-full h-full opacity-5 pointer-events-none" style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
          mixBlendMode: 'overlay'
        }}></div>
        <div className={`absolute top-[-10%] left-[-10%] w-96 h-96 rounded-full mix-blend-multiply filter blur-[80px] opacity-80 animate-blob transition-colors duration-1000 ${currentTheme.blob1}`}></div>
        <div className={`absolute top-[20%] right-[-10%] w-96 h-96 rounded-full mix-blend-multiply filter blur-[80px] opacity-80 animate-blob animation-delay-2000 transition-colors duration-1000 ${currentTheme.blob2}`}></div>
        <div className={`absolute bottom-[-20%] left-[20%] w-[40rem] h-[40rem] rounded-full mix-blend-multiply filter blur-[100px] opacity-80 animate-blob animation-delay-4000 transition-colors duration-1000 ${currentTheme.blob3}`}></div>
      </div>

      <div className="relative z-20 h-full min-h-screen">
        {view === 'home' && (
          <HomeView onSelect={handleSelectMode} />
        )}
        
        {view === 'detail' && selectedMode && (
          <DetailView 
            mode={selectedMode} 
            onBack={() => { setView('home'); setSelectedMode(null); }} 
            onStart={handleStartSession}
            duration={duration} setDuration={setDuration}
            sound={sound} setSound={setSound}
            bpm={bpm} setBpm={setBpm}
          />
        )}
        
        {view === 'session' && selectedMode && (
          <SessionView 
            mode={selectedMode} 
            onEnd={handleEndSession} 
            isPlaying={isPlaying}
            setIsPlaying={setIsPlaying}
            duration={duration}
            sound={sound}
            bpm={bpm}
          />
        )}
      </div>
    </div>
  );
}

// --- HOME VIEW ---
function HomeView({ onSelect }) {
  return (
    <div className="max-w-md mx-auto w-full px-6 py-12 animate-in fade-in duration-500 flex flex-col min-h-screen">
      <header className="flex justify-between items-center mb-8 shrink-0">
        <div>
          <h1 className="text-4xl font-extrabold tracking-tight text-slate-800">Aura</h1>
          <p className="text-slate-600 font-medium mt-1">Shape your state of mind.</p>
        </div>
        <div className="w-12 h-12 bg-white/50 backdrop-blur-xl border border-white/60 shadow-[0_8px_32px_0_rgba(31,38,135,0.05)] rounded-full flex items-center justify-center cursor-pointer hover:bg-white/60 transition-colors">
          <Heart className="w-6 h-6 text-slate-700" strokeWidth={2} />
        </div>
      </header>

      <div className="grid grid-cols-2 gap-4 pb-12 flex-1 auto-rows-min">
        {modes.map((mode, index) => {
          const isFeatured = index === 0;
          return (
            <button
              key={mode.id}
              onClick={() => onSelect(mode)}
              className={`text-left bg-white/50 backdrop-blur-xl border border-white/60 shadow-[0_8px_32px_0_rgba(31,38,135,0.05)] rounded-3xl p-5 hover:bg-white/60 hover:-translate-y-1 transition-all duration-300 group ${
                isFeatured ? 'col-span-2 flex flex-col p-6' : 'col-span-1 flex flex-col'
              }`}
            >
              <div className={`flex items-start ${isFeatured ? 'justify-between w-full mb-4' : 'flex-col mb-4'}`}>
                <div className={`w-14 h-14 rounded-2xl bg-white/50 border border-white/60 shadow-sm flex items-center justify-center shrink-0 ${mode.textPrimary} group-hover:scale-110 transition-transform duration-300 ${!isFeatured ? 'mb-3' : ''}`}>
                  <mode.icon className="w-7 h-7" strokeWidth={2} />
                </div>
                
                {/* Pattern Tag */}
                <div className={`${isFeatured ? 'mt-3' : ''}`}>
                  <span className={`text-[10px] font-bold px-2 py-1 rounded-md bg-white/60 border border-white mix-blend-multiply opacity-80 ${mode.textPrimary} whitespace-nowrap`}>
                    {formatPattern(mode.pattern)}
                  </span>
                </div>
              </div>

              <div>
                <h3 className={`font-bold text-slate-800 tracking-tight ${isFeatured ? 'text-2xl mb-1' : 'text-lg mb-1'}`}>
                  {mode.name}
                </h3>
                <p className={`text-slate-600 font-medium ${isFeatured ? 'text-sm mb-4' : 'text-xs mb-3'}`}>
                  {mode.desc}
                </p>
              </div>

              {/* Benefits List */}
              <ul className="space-y-1 mt-auto">
                {mode.benefits.slice(0, isFeatured ? 2 : 1).map((b, i) => (
                  <li key={i} className={`text-slate-500 ${isFeatured ? 'text-xs' : 'text-[11px]'} font-semibold flex items-center leading-tight`}>
                    <span className={`mr-1.5 opacity-70 ${mode.textPrimary}`}>✔</span> {b}
                  </li>
                ))}
              </ul>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// --- DETAIL VIEW ---
function DetailView({ mode, onBack, onStart, duration, setDuration, sound, setSound, bpm, setBpm }) {
  const [isStarting, setIsStarting] = useState(false);

  const handleStartWrapper = async () => {
    setIsStarting(true);
    await onStart();
  };
  return (
    <div className="max-w-md mx-auto w-full min-h-screen flex flex-col pt-6 animate-in slide-in-from-bottom-8 duration-500">
      <div className="px-6 py-4 flex justify-between items-center z-20">
        <button 
          onClick={onBack} 
          className="w-12 h-12 bg-white/50 backdrop-blur-xl border border-white/60 shadow-[0_8px_32px_0_rgba(31,38,135,0.05)] rounded-full flex items-center justify-center text-slate-700 hover:bg-white/70 transition-colors"
        >
          <ChevronLeft className="w-7 h-7" />
        </button>
      </div>

      <div className="flex-1 mt-2 px-4 pb-6 flex flex-col overflow-y-auto" style={{scrollbarWidth:'none', msOverflowStyle:'none'}}>
        <div className="bg-white/70 backdrop-blur-3xl border border-white/80 rounded-[2.5rem] p-6 flex-1 flex flex-col relative overflow-hidden backdrop-saturate-150">
          <div className="absolute top-0 left-0 right-0 h-32 bg-gradient-to-b from-white/40 to-transparent pointer-events-none"></div>

          {/* Header */}
          <div className="flex flex-col items-center text-center mb-6 z-10">
            <div className={`w-20 h-20 rounded-3xl bg-white/60 shadow-lg border border-white/80 flex items-center justify-center mb-4 transform -rotate-3 ${mode.textPrimary}`}>
              <mode.icon className="w-10 h-10 transform rotate-3" strokeWidth={2} />
            </div>
            <h2 className="text-3xl font-extrabold text-slate-800 tracking-tight mb-1">{mode.name}</h2>
            <p className="text-slate-500 text-sm font-medium">{mode.desc}</p>
          </div>

          {/* Anatomy of the Breath Dashboard */}
          <div className="bg-white/40 border border-white/60 shadow-sm rounded-2xl p-4 mb-6 z-10">
            <h4 className="text-xs font-bold text-slate-700 tracking-wider uppercase mb-3 text-center">Anatomy of the Breath</h4>
            
            <div className="flex items-center justify-between mb-4 px-1 gap-1">
              {mode.pattern[0] > 0 && (
                <div className="flex-1 flex flex-col items-center">
                  <div className="h-2 w-full bg-blue-400 rounded-full opacity-80 mb-1"></div>
                  <span className="text-[10px] font-bold text-slate-500">{mode.pattern[0]}s In</span>
                </div>
              )}
              {mode.pattern[1] > 0 && (
                <div className="flex-1 flex flex-col items-center">
                  <div className="h-2 w-full bg-slate-300 rounded-full opacity-80 mb-1"></div>
                  <span className="text-[10px] font-bold text-slate-400">{mode.pattern[1]}s Hold</span>
                </div>
              )}
              {mode.pattern[2] > 0 && (
                <div className="flex-1 flex flex-col items-center">
                  <div className="h-2 w-full bg-rose-400 rounded-full opacity-80 mb-1"></div>
                  <span className="text-[10px] font-bold text-slate-500">{mode.pattern[2]}s Out</span>
                </div>
              )}
              {mode.pattern[3] > 0 && (
                <div className="flex-[0.5] flex flex-col items-center">
                  <div className="h-2 w-full bg-slate-300 rounded-full opacity-80 mb-1"></div>
                  <span className="text-[10px] font-bold text-slate-400">{mode.pattern[3]}s Hold</span>
                </div>
              )}
            </div>

            <div className="bg-white/50 rounded-xl p-3 border border-white/40">
              <div className="flex items-start">
                <span className={`text-base mr-2 mt-0.5 ${mode.textPrimary}`}>💡</span>
                <div>
                  <h5 className="text-[11px] font-extrabold text-slate-700 mb-0.5">Why it works</h5>
                  <p className="text-[11px] text-slate-600 leading-snug font-medium">{mode.reason}</p>
                </div>
              </div>
            </div>
          </div>

          <div className="flex-1 flex flex-col justify-end space-y-6 z-10">
            
            {/* Speed (BPM) */}
            <div>
              <div className="flex justify-between items-end mb-3">
                <span className="text-slate-700 font-bold flex items-center">
                  <Settings className="w-4 h-4 mr-2 opacity-60" /> Speed
                </span>
                <span className={`text-xs font-bold ${mode.textPrimary}`}>{bpm} Breaths/Min</span>
              </div>
              <div className="grid grid-cols-3 gap-2">
                {[4, 6, 8].map(s => (
                  <button key={s} onClick={() => setBpm(s)}
                    className={`py-2 rounded-lg font-bold text-sm transition-all duration-300 ${
                      bpm === s ? `${mode.bgPrimary} text-white shadow-md` : 'bg-white/50 text-slate-600 hover:bg-white/80 border border-white/40'
                    }`}
                  >
                    {s === 4 ? 'Slow' : s === 6 ? 'Normal' : 'Fast'}
                  </button>
                ))}
              </div>
            </div>

            {/* Duration */}
            <div>
              <div className="flex justify-between items-end mb-3">
                <span className="text-slate-700 font-bold flex items-center">
                  <Clock className="w-4 h-4 mr-2 opacity-60" /> Time
                </span>
                <span className={`text-xs font-bold ${mode.textPrimary}`}>{duration} minutes</span>
              </div>
              <div className="flex gap-2 overflow-x-auto pb-1" style={{scrollbarWidth:'none', msOverflowStyle:'none'}}>
                {durations.map(d => (
                  <button key={d} onClick={() => setDuration(d)}
                    className={`flex-shrink-0 px-4 py-2 rounded-lg font-bold text-sm transition-all duration-300 ${
                      duration === d ? `${mode.bgPrimary} text-white shadow-md` : 'bg-white/50 text-slate-600 hover:bg-white/80 border border-white/40'
                    }`}
                  >
                    {d}m
                  </button>
                ))}
              </div>
            </div>

            {/* Sound */}
            <div className="mb-4">
              <div className="flex items-center text-slate-700 font-bold mb-3">
                <Music className="w-4 h-4 mr-2 opacity-60" /> Sound
              </div>
              <div className="grid grid-cols-4 gap-2">
                {soundsOptions.map(snd => (
                  <button key={snd} onClick={() => setSound(snd)}
                    className={`p-2 rounded-lg font-bold text-xs uppercase tracking-wide transition-all duration-300 ${
                      sound === snd ? 'bg-white text-slate-800 shadow-sm border-2 border-slate-200' : 'bg-white/30 text-slate-500 border-2 border-white/40 hover:bg-white/60'
                    }`}
                  >
                    {snd}
                  </button>
                ))}
              </div>
            </div>

            <button onClick={handleStartWrapper} disabled={isStarting}
              className={`w-full py-4 rounded-2xl font-extrabold text-lg text-white ${mode.bgPrimary} shadow-[0_8px_30px_-10px_rgba(0,0,0,0.3)] hover:scale-[1.02] active:scale-95 transition-all flex items-center justify-center disabled:opacity-75 disabled:scale-100 `}
            >
              {isStarting ? "Loading Audio..." : "Begin Journey"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// --- SESSION VIEW ---
function SessionView({ mode, onEnd, isPlaying, setIsPlaying, duration, sound, bpm }) {
  const [sessionTimeLeft, setSessionTimeLeft] = useState(duration * 60);
  const [phaseIndex, setPhaseIndex] = useState(0); // 0:Inhale, 1:HoldIn, 2:Exhale, 3:HoldOut
  const [phaseTimeLeft, setPhaseTimeLeft] = useState(0);
  const [scale, setScale] = useState(0.6); // Bubble scale
  
  // Animation refs
  const lastUpdateRef = useRef(Date.now());
  const reqRef = useRef(null);
  
  const pattern = breathingEngine.getScaledPattern(mode.id, bpm);
  
  // Audio playback effect
  useEffect(() => {
    if (isPlaying) {
      audioManager.playBackground(sound);
    } else {
      audioManager.stopBackground();
    }
    return () => audioManager.stopBackground();
  }, [isPlaying, sound]);

  // Main Breathing Loop
  useEffect(() => {
    // Start initial phase
    setPhaseTimeLeft(pattern[0]);
    setScale(0.6); 
    
    // Play initial phase sound
    if (isPlaying) audioManager.playPhaseSound(0, pattern[0]);
  }, []); // Only on mount

  useEffect(() => {
    if (!isPlaying) {
      cancelAnimationFrame(reqRef.current);
      lastUpdateRef.current = Date.now();
      return;
    }

    const animate = () => {
      const now = Date.now();
      const dt = (now - lastUpdateRef.current) / 1000;
      lastUpdateRef.current = now;

      setSessionTimeLeft(prev => {
        const next = Math.max(0, prev - dt);
        if (next === 0) {
          audioManager.playComplete();
          setTimeout(onEnd, 2000); // end shortly after
        }
        return next;
      });

      setPhaseTimeLeft(prev => {
        let nextTime = prev - dt;
        let pIndex = phaseIndex;
        
        if (nextTime <= 0) {
          // Move to next phase that has a duration > 0
          do {
            pIndex = (pIndex + 1) % 4;
          } while (pattern[pIndex] === 0);
          
          setPhaseIndex(pIndex);
          nextTime = pattern[pIndex];
          audioManager.playPhaseSound(pIndex, pattern[pIndex]);
        }

        // Calculate dynamic scale interpolaration
        const phaseDuration = pattern[pIndex];
        const progress = 1 - (nextTime / phaseDuration); // 0 to 1

        let newScale = scale;
        if (pIndex === 0) { // Inhale: 0.6 -> 1.1
          newScale = 0.6 + (0.5 * progress);
        } else if (pIndex === 1) { // Hold In
          newScale = 1.1;
        } else if (pIndex === 2) { // Exhale: 1.1 -> 0.6
          newScale = 1.1 - (0.5 * progress);
        } else if (pIndex === 3) { // Hold Out
          newScale = 0.6;
        }
        
        setScale(newScale);
        return nextTime;
      });

      reqRef.current = requestAnimationFrame(animate);
    };

    lastUpdateRef.current = Date.now();
    reqRef.current = requestAnimationFrame(animate);

    return () => cancelAnimationFrame(reqRef.current);
  }, [isPlaying, phaseIndex, pattern, scale, onEnd]);

  // Format time (mm:ss)
  const formatTime = (seconds) => {
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return `${m < 10 ? '0' : ''}${m}:${s < 10 ? '0' : ''}${s}`;
  };

  const progressTotal = duration * 60;
  const progressPercent = ((progressTotal - sessionTimeLeft) / progressTotal) * 100;

  return (
    <div className="fixed inset-0 flex flex-col animate-in fade-in duration-1000 bg-white/20 backdrop-blur-md z-50">
      <div className="flex justify-between items-center p-6 z-20">
        <button onClick={onEnd} className="w-12 h-12 bg-white/30 backdrop-blur-lg border border-white/40 rounded-full hover:bg-white/60 transition-colors flex items-center justify-center">
          <X className="w-6 h-6 text-slate-700" strokeWidth={2} />
        </button>
        <div className="px-4 py-2 bg-white/40 backdrop-blur-lg border border-white/50 rounded-full flex items-center">
           <span className={`w-2 h-2 rounded-full ${mode.bgPrimary} animate-pulse mr-2`}></span>
           <span className="text-xs font-bold tracking-widest uppercase text-slate-700">{mode.name}</span>
        </div>
      </div>

      {/* Bubble Lens Area */}
      <div className="flex-1 flex flex-col items-center justify-center relative z-10">
        <div className="relative w-80 h-80 flex items-center justify-center">
          
          <div 
            className="absolute inset-8 rounded-full bg-white/40 backdrop-blur-xl border-solid border-white/60 shadow-[0_0_40px_rgba(255,255,255,0.3)] transition-all ease-linear"
            style={{ 
              transform: `scale(${scale})`,
              borderWidth: `${scale * 8}px`,
            }}
          ></div>

          <div className="z-10 text-center pointer-events-none drop-shadow-md">
            <h2 className="text-5xl font-extrabold text-slate-800 tracking-tight transition-opacity duration-300">
              {!isPlaying ? 'Paused' : breathingEngine.phaseNames[phaseIndex]}
            </h2>
          </div>
        </div>
      </div>

      <div className="p-8 pb-12 flex flex-col items-center gap-10 z-20">
        <div className="w-full max-w-[260px]">
          <div className="flex justify-between text-sm font-bold text-slate-600 mb-3">
            <span>{formatTime(progressTotal - sessionTimeLeft)}</span>
            <span>{formatTime(progressTotal)}</span>
          </div>
          <div className="w-full h-3 bg-white/30 backdrop-blur-sm rounded-full overflow-hidden border border-white/40">
             <div className={`h-full ${mode.bgPrimary} rounded-full transition-all duration-200`} style={{width: `${progressPercent}%`}}></div>
          </div>
        </div>
        
        <button 
          onClick={() => setIsPlaying(!isPlaying)}
          className="w-20 h-20 flex items-center justify-center bg-white/80 backdrop-blur-2xl text-slate-800 rounded-[2rem] hover:scale-105 active:scale-95 transition-all shadow-xl border border-white"
        >
          {isPlaying 
            ? <Pause className="w-8 h-8" fill="currentColor" /> 
            : <Play className="w-8 h-8 ml-1" fill="currentColor" />
          }
        </button>
      </div>
    </div>
  );
}

