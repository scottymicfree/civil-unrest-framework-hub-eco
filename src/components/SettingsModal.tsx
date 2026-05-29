import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Settings, Key, Server, KeySquare, X, Save, ShieldAlert } from 'lucide-react';

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function SettingsModal({ isOpen, onClose }: SettingsModalProps) {
  const [geminiKey, setGeminiKey] = useState('');
  const [shodanKey, setShodanKey] = useState('');
  const [devApiKey, setDevApiKey] = useState('');

  useEffect(() => {
    if (isOpen) {
      setGeminiKey(localStorage.getItem('LUCY_GEMINI_KEY') || '');
      setShodanKey(localStorage.getItem('LUCY_SHODAN_KEY') || '');
      // Fetch Dev API Config endpoint to show the server's current dev webhook key
      fetch('/api/dev/config')
        .then(res => res.json())
        .then(data => setDevApiKey(data.devApiKey || ''))
        .catch(err => console.error("Error fetching Dev API config", err));
    }
  }, [isOpen]);

  const handleSave = () => {
    localStorage.setItem('LUCY_GEMINI_KEY', geminiKey);
    localStorage.setItem('LUCY_SHODAN_KEY', shodanKey);
    onClose();
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm"
        >
          <motion.div
            initial={{ scale: 0.95, opacity: 0, y: 20 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.95, opacity: 0, y: 20 }}
            className="w-full max-w-lg bg-slate-900 border border-slate-700/60 shadow-2xl rounded-xl overflow-hidden flex flex-col font-sans"
          >
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-800 bg-slate-950">
              <div className="flex items-center space-x-3 text-slate-100">
                <Settings className="w-5 h-5 text-indigo-400" />
                <h2 className="text-sm font-bold tracking-widest uppercase">System Configurations</h2>
              </div>
              <button onClick={onClose} className="text-slate-500 hover:text-slate-300 transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6 space-y-6 overflow-y-auto max-h-[70vh]">
              {/* API Keys */}
              <div className="space-y-4">
                <div>
                  <h3 className="text-xs font-mono font-bold tracking-widest text-slate-400 mb-2 flex items-center">
                    <Key className="w-3.5 h-3.5 mr-2" /> GENERATIVE AI ENGINE
                  </h3>
                  <div className="bg-slate-800/50 p-4 border border-slate-700 rounded-lg">
                    <label className="block text-xs font-medium text-slate-300 mb-1.5">Gemini API Key (Optional Override)</label>
                    <input
                      type="password"
                      value={geminiKey}
                      onChange={e => setGeminiKey(e.target.value)}
                      placeholder="Enter custom generative logic key..."
                      className="w-full bg-slate-900 border border-slate-600 text-slate-200 text-xs font-mono rounded pl-3 pr-3 py-2 outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all placeholder:text-slate-600"
                    />
                    <p className="text-[10px] text-slate-500 mt-2">
                      Will override the server's native key if configured. <a href="https://aistudio.google.com/app/apikey" target="_blank" rel="noreferrer" className="text-indigo-400 hover:underline">Get a free Gemini API key</a>
                    </p>
                  </div>
                </div>

                <div>
                  <h3 className="text-xs font-mono font-bold tracking-widest text-slate-400 mb-2 mt-6 flex items-center">
                    <KeySquare className="w-3.5 h-3.5 mr-2" /> OSINT RECONNAISSANCE 
                  </h3>
                  <div className="bg-slate-800/50 p-4 border border-slate-700 rounded-lg">
                    <label className="block text-xs font-medium text-slate-300 mb-1.5">Shodan API Key</label>
                    <input
                      type="password"
                      value={shodanKey}
                      onChange={e => setShodanKey(e.target.value)}
                      placeholder="Enter network scanning telemetry key..."
                      className="w-full bg-slate-900 border border-slate-600 text-slate-200 text-xs font-mono rounded pl-3 pr-3 py-2 outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all placeholder:text-slate-600"
                    />
                  </div>
                </div>

                <div>
                  <h3 className="text-xs font-mono font-bold tracking-widest text-slate-400 mb-2 mt-6 flex items-center">
                    <Server className="w-3.5 h-3.5 mr-2" /> DEV API WEBHOOK SECRETS
                  </h3>
                  <div className="bg-slate-800/50 p-4 border border-indigo-500/20 rounded-lg">
                    <div className="flex justify-between items-start mb-2">
                       <label className="block text-xs font-medium text-slate-300 mb-0.5">Local Server Intel Ingestion Key</label>
                       <span className="text-[9px] bg-emerald-500/10 text-emerald-400 px-1.5 py-0.5 rounded border border-emerald-500/20 mt-0.5 font-bold uppercase">READ-ONLY</span>
                    </div>
                    <p className="text-[10px] text-slate-400 mb-3 leading-relaxed">
                      Use this bearer token when forwarding live events to <code>POST /api/dev/events</code> from external services (e.g., your FiveM server scripts).
                    </p>
                    <div className="flex items-center space-x-2">
                      <input
                        type="text"
                        readOnly
                        value={devApiKey}
                        className="w-full bg-slate-950 border border-slate-700 text-slate-400 text-xs font-mono rounded pl-3 pr-3 py-2 outline-none cursor-not-allowed"
                      />
                    </div>
                  </div>
                </div>

              </div>
            </div>

            <div className="p-4 border-t border-slate-800 bg-slate-950 flex justify-between items-center">
              <div className="flex items-center space-x-2 text-yellow-500 text-[10px] font-mono">
                 <ShieldAlert className="w-3.5 h-3.5" /> Keys stored strictly in local client memory.
              </div>
              <button
                onClick={handleSave}
                className="flex items-center px-4 py-2 bg-indigo-600 text-white text-xs font-bold uppercase tracking-wide rounded hover:bg-indigo-500 transition-colors shadow-[0_0_15px_rgba(79,70,229,0.3)]"
              >
                <Save className="w-4 h-4 mr-2" />
                Save Memory
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
