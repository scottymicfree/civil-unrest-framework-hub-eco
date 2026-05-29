import React, { useEffect, useState } from 'react';
import { Settings } from 'lucide-react';
import { LeftPanel } from './components/panels/LeftPanel';
import { CenterPanel } from './components/panels/CenterPanel';
import { RightPanel } from './components/panels/RightPanel';
import { BottomPanel } from './components/panels/BottomPanel';
import { ScriptGenerator } from './components/panels/ScriptGenerator';
import { SettingsModal } from './components/SettingsModal';
import { CodingStation } from './components/panels/CodingStation';
import { IntelMessage } from './types';

export default function App() {
  const [events, setEvents] = useState<IntelMessage[]>([]);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [activeView, setActiveView] = useState<'dashboard' | 'ide'>('dashboard');
  const [activeCode, setActiveCode] = useState<string>('');

  useEffect(() => {
    // Connect to SSE stream
    const eventSource = new EventSource('/api/stream');

    eventSource.onmessage = (event) => {
      try {
        const parsed = JSON.parse(event.data) as IntelMessage;
        setEvents((prev) => [...prev, parsed].slice(-50)); // keep last 50 events
      } catch (err) {
        console.error("Error parsing event data", err);
      }
    };

    eventSource.onerror = (err) => {
      console.error("EventSource failed:", err);
    };

    return () => {
      eventSource.close();
    };
  }, []);

  return (
    <div className="flex flex-col h-screen w-screen overflow-hidden bg-slate-950 text-slate-200 font-sans selection:bg-indigo-500/30 relative">
      <div className="flex flex-1 overflow-hidden">
        <LeftPanel events={events} />
        {activeView === 'ide' ? (
          <CodingStation initialCode={activeCode} onClose={() => setActiveView('dashboard')} />
        ) : (
          <CenterPanel events={events} />
        )}
        <RightPanel />
      </div>
      <BottomPanel events={events} />
      <ScriptGenerator onOpenInIDE={(code) => {
        setActiveCode(code);
        setActiveView('ide');
      }} />
      
      {/* Settings Action Button */}
      <button 
        onClick={() => setIsSettingsOpen(true)}
        className="fixed top-4 right-4 z-40 p-2 rounded-full bg-slate-900 border border-slate-700/50 text-slate-400 hover:text-slate-100 hover:bg-slate-800 transition-colors shadow-lg"
      >
        <Settings className="w-5 h-5" />
      </button>

      <SettingsModal isOpen={isSettingsOpen} onClose={() => setIsSettingsOpen(false)} />
    </div>
  );
}

