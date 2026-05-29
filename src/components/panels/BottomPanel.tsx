import React from 'react';
import { Terminal, Activity } from 'lucide-react';
import { IntelMessage } from '../../types';
import { format } from 'date-fns';

interface BottomPanelProps {
  events: IntelMessage[];
}

export function BottomPanel({ events }: BottomPanelProps) {
  const systemLogs = events.slice(-10);

  return (
    <div className="h-48 bg-slate-950 border-t border-slate-800 flex">
      {/* Telemetry charts could go here but using simple stats for now */}
      <div className="w-1/3 border-r border-slate-800 p-4 flex flex-col justify-between">
        <div>
          <h3 className="text-xs font-bold text-slate-400 uppercase tracking-widest flex items-center mb-4">
            <Activity className="w-4 h-4 mr-2" /> Server Telemetry
          </h3>
          <div className="space-y-3">
            <div>
              <div className="flex justify-between text-xs mb-1">
                <span className="text-slate-500 font-mono">CPU LOAD</span>
                <span className="text-emerald-400 font-mono">24%</span>
              </div>
              <div className="w-full bg-slate-800 h-1.5 rounded-full overflow-hidden">
                <div className="bg-emerald-500 w-[24%] h-full"></div>
              </div>
            </div>
            <div>
              <div className="flex justify-between text-xs mb-1">
                <span className="text-slate-500 font-mono">THREAT INDEX</span>
                <span className="text-amber-400 font-mono">68%</span>
              </div>
              <div className="w-full bg-slate-800 h-1.5 rounded-full overflow-hidden">
                <div className="bg-amber-500 w-[68%] h-full"></div>
              </div>
            </div>
          </div>
        </div>
        
        <div className="flex items-center space-x-2">
          <div className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse shadow-[0_0_10px_rgba(16,185,129,0.5)]"></div>
          <span className="text-xs font-mono text-emerald-500">SYSTEM ONLINE</span>
        </div>
      </div>

      {/* Terminal / Logs */}
      <div className="flex-1 p-4 bg-black overflow-y-auto font-mono text-[10px] space-y-1">
        <h3 className="text-slate-600 uppercase tracking-widest flex items-center mb-2 border-b border-slate-800 pb-2">
          <Terminal className="w-3 h-3 mr-2" /> Live Console Output
        </h3>
        {systemLogs.map((log, i) => (
          <div key={i} className="flex space-x-3">
            <span className="text-slate-600 w-16 shrink-0">
              {format(new Date(), 'HH:mm:ss')}
            </span>
            <span className={log.type === "SYSTEM" ? "text-indigo-400" : "text-emerald-400"}>
              [{log.type}]
            </span>
            <span className="text-slate-300">
              {log.message || (log.data && `Received ${log.data.category} event: ${log.data.event}`)}
            </span>
          </div>
        ))}
        {systemLogs.length === 0 && (
          <div className="text-slate-600">Waiting for data stream...</div>
        )}
      </div>
    </div>
  );
}
