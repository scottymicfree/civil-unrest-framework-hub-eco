import React from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ShieldAlert, Cpu, Activity, AlertTriangle } from 'lucide-react';
import { IntelMessage } from '../../types';
import { format } from 'date-fns';

interface LeftPanelProps {
  events: IntelMessage[];
}

export function LeftPanel({ events }: LeftPanelProps) {
  const intelEvents = events.filter(e => e.type === "INTELLIGENCE") as (IntelMessage & { data: Exclude<IntelMessage["data"], undefined> })[];

  return (
    <div className="flex flex-col h-full bg-slate-900 border-r border-slate-800 hidden md:flex">
      <div className="p-4 border-b border-slate-800/50 flex items-center space-x-3">
        <Activity className="h-5 w-5 text-indigo-400" />
        <h2 className="text-sm font-bold tracking-widest text-slate-100 uppercase">Live Intel Feed</h2>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        <AnimatePresence initial={false}>
          {intelEvents.slice().reverse().map((evt) => (
            <motion.div
              key={evt.data.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              className="bg-slate-800/40 rounded-lg p-3 border border-slate-700/50 shadow-sm"
            >
              <div className="flex justify-between items-start mb-2">
                <span className="text-[10px] font-mono text-slate-400 px-2 py-0.5 bg-slate-900 rounded">
                  {format(new Date(evt.data.timestamp), 'HH:mm:ss')}
                </span>
                {evt.data.risk > 0.7 && (
                  <span className="flex items-center text-xs text-red-400 font-medium tracking-wide">
                    <AlertTriangle className="w-3 h-3 mr-1" /> HIGH RISK
                  </span>
                )}
              </div>
              
              <h3 className="text-sm font-semibold text-slate-200 mb-1">{evt.data.event.replace(/_/g, ' ').toUpperCase()}</h3>
              <p className="text-xs text-slate-400 mb-2">{evt.data.context}</p>

              <div className="grid grid-cols-2 gap-2 text-xs font-mono text-slate-500 bg-slate-900/50 p-2 rounded">
                <div>Actors: <span className="text-slate-300">{evt.data.actor || evt.data.actors?.join(', ')}</span></div>
                <div>Zone: <span className="text-slate-300">{evt.data.location}</span></div>
              </div>

              {evt.analysis && (
                <div className="mt-3 p-2 bg-indigo-900/20 border border-indigo-500/20 rounded-md">
                  <div className="flex items-center text-xs text-indigo-300 font-mono mb-1">
                    <Cpu className="w-3 h-3 mr-1" />
                    {evt.analysis.agent} COGNITION
                  </div>
                  <p className="text-xs text-indigo-200/80 leading-relaxed">
                    Outcome: <span className="text-indigo-100">{evt.analysis.predicted_outcome}</span><br />
                    Rec: {evt.analysis.recommendation}
                  </p>
                </div>
              )}
            </motion.div>
          ))}
        </AnimatePresence>
        
        {intelEvents.length === 0 && (
          <div className="h-full flex flex-col items-center justify-center text-slate-500">
            <Activity className="h-8 w-8 mb-2 opacity-20 animate-pulse" />
            <p className="text-xs font-mono">AWAITING LIVE TELEMETRY...</p>
          </div>
        )}
      </div>
    </div>
  );
}
