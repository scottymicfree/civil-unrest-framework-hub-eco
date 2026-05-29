import React, { useEffect, useState } from 'react';
import { Shield, Fingerprint, Database, Users, Wrench, MessageSquare, BookOpen, Github, Download } from 'lucide-react';
import { PlayerProfile } from '../../types';

export function RightPanel() {
  const [profiles, setProfiles] = useState<PlayerProfile[]>([]);

  useEffect(() => {
    // Fetch profiles from backend
    fetch('/api/intel/profiles')
      .then(r => r.json())
      .then(data => setProfiles(data))
      .catch(err => console.error("Could not fetch profiles", err));
  }, []);

  return (
    <div className="flex flex-col h-full bg-slate-900 border-l border-slate-800 hidden lg:flex w-80">
      <div className="p-4 border-b border-slate-800 bg-slate-950">
        <div className="flex items-center text-indigo-400 mb-3">
          <Wrench className="h-4 w-4 mr-2" />
          <h2 className="text-sm font-bold tracking-widest uppercase">Modding Toolbelt</h2>
        </div>
        <div className="grid grid-cols-2 gap-2">
          <a href="https://discord.com" target="_blank" rel="noreferrer" className="flex flex-col items-center justify-center p-3 rounded-lg bg-slate-800 border border-slate-700 hover:bg-indigo-600/20 hover:border-indigo-500 transition-colors text-slate-300 hover:text-indigo-400 group">
            <MessageSquare className="w-5 h-5 mb-1.5" />
            <span className="text-[10px] font-bold uppercase tracking-wider">Discord</span>
          </a>
          <a href="https://forum.cfx.re/" target="_blank" rel="noreferrer" className="flex flex-col items-center justify-center p-3 rounded-lg bg-slate-800 border border-slate-700 hover:bg-orange-500/20 hover:border-orange-500 transition-colors text-slate-300 hover:text-orange-400 group">
            <Users className="w-5 h-5 mb-1.5" />
            <span className="text-[10px] font-bold uppercase tracking-wider">FiveM Docs</span>
          </a>
          <a href="https://github.com" target="_blank" rel="noreferrer" className="flex flex-col items-center justify-center p-3 rounded-lg bg-slate-800 border border-slate-700 hover:bg-slate-600/50 hover:border-slate-500 transition-colors text-slate-300 hover:text-white group">
            <Github className="w-5 h-5 mb-1.5" />
            <span className="text-[10px] font-bold uppercase tracking-wider">Publish</span>
          </a>
          <a href="https://www.gta5-mods.com/" target="_blank" rel="noreferrer" className="flex flex-col items-center justify-center p-3 rounded-lg bg-slate-800 border border-slate-700 hover:bg-emerald-500/20 hover:border-emerald-500 transition-colors text-slate-300 hover:text-emerald-400 group">
            <Download className="w-5 h-5 mb-1.5" />
            <span className="text-[10px] font-bold uppercase tracking-wider">GTA5 Mods</span>
          </a>
        </div>
      </div>

      <div className="p-4 border-b border-slate-800/50 flex items-center justify-between">
        <div className="flex items-center text-slate-100">
          <Database className="h-4 w-4 mr-2 text-indigo-400" />
          <h2 className="text-sm font-bold tracking-widest uppercase">Intel Database</h2>
        </div>
        <div className="text-xs bg-slate-800 text-slate-400 px-2 py-1 rounded font-mono">
          {profiles.length} DOSSIERS
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {profiles.map(profile => (
          <div key={profile.id} className="bg-slate-800/30 border border-slate-700/50 rounded-lg p-3">
            <div className="flex items-center justify-between border-b border-slate-700/50 pb-2 mb-2">
              <div className="flex items-center">
                <div className="w-8 h-8 rounded bg-slate-700 flex items-center justify-center mr-3">
                  <Fingerprint className="w-4 h-4 text-slate-400" />
                </div>
                <div>
                  <div className="text-sm font-bold text-slate-200">{profile.alias}</div>
                  <div className="text-[10px] font-mono text-slate-500">ID: {profile.id}</div>
                </div>
              </div>
              <div className={`text-xs px-2 py-1 rounded font-bold ${profile.trustScore < 50 ? 'bg-red-500/10 text-red-400' : 'bg-emerald-500/10 text-emerald-400'}`}>
                {profile.trustScore} TS
              </div>
            </div>

            <div className="space-y-2">
              <div className="flex items-start">
                <Users className="w-3 h-3 text-slate-500 mr-2 mt-0.5" />
                <div className="text-xs text-slate-300">
                  <span className="text-slate-500 mr-1">Affiliation:</span>
                  {profile.affiliation}
                </div>
              </div>
              
              <div className="flex items-start">
                <Shield className="w-3 h-3 text-slate-500 mr-2 mt-0.5" />
                <div className="text-xs text-slate-300">
                  <span className="text-slate-500 mr-1">Flags:</span>
                  <div className="flex flex-wrap gap-1 mt-1">
                    {profile.flags.map(f => (
                      <span key={f} className="text-[9px] uppercase px-1.5 py-0.5 bg-amber-500/10 border border-amber-500/20 text-amber-400 rounded-sm">
                        {f.replace(/_/g, ' ')}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
