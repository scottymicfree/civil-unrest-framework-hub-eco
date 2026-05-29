import React, { useMemo } from 'react';
import { motion } from 'motion/react';
import { Target, Shield, RadioReceiver } from 'lucide-react';
import * as d3 from 'd3';
import { IntelMessage } from '../../types';

interface CenterPanelProps {
  events: IntelMessage[];
}

export function CenterPanel({ events }: CenterPanelProps) {
  // Extract high risk zones from recent events
  const intelEvents = events.filter(e => e.type === "INTELLIGENCE" && e.data?.location).map(e => e.data!);
  const activeZones = [...new Set(intelEvents.map(e => e.location))];

  // Map settings
  const width = 800;
  const height = 600;

  // Compute contour density from event data
  const { density, colorScale } = useMemo(() => {
    const points = intelEvents.map((evt) => {
      // Create stable pseudo-random coordinates based on location name
      const hash = evt.location.split('').reduce((acc, char) => char.charCodeAt(0) + acc, 0);
      const x = (50 + Math.sin(hash) * 35) * width / 100;
      const y = (50 + Math.cos(hash) * 35) * height / 100;
      return { x, y, risk: evt.risk || 0.5 };
    });

    const contourData = d3.contourDensity<{x: number, y: number, risk: number}>()
      .x(d => d.x)
      .y(d => d.y)
      .weight(d => d.risk * 3) // weight by risk to push density higher
      .size([width, height])
      .bandwidth(45)
      .thresholds(8)
      (points);

    const maxDensity = d3.max(contourData, d => d.value) || 0.1;
    
    // Scale mapping values to an intense heatmap spectrum (dark red to bright yellow/white)
    const scale = d3.scaleSequential(d3.interpolateYlOrRd)
      .domain([0, maxDensity * 1.5]);

    return { density: contourData, colorScale: scale };
  }, [intelEvents]);

  return (
    <div className="flex-1 flex flex-col bg-slate-950 relative overflow-hidden">
      {/* Top Header */}
      <div className="absolute top-0 left-0 right-0 p-4 flex justify-between items-center z-20 bg-gradient-to-b from-slate-950/90 to-transparent pointer-events-none">
        <div>
          <h1 className="text-xl font-bold text-white tracking-widest flex items-center">
            <RadioReceiver className="w-5 h-5 mr-3 text-red-500 animate-pulse" />
            CITY COMMAND MATRIX
          </h1>
          <p className="text-xs font-mono text-slate-400 mt-1">LUCY A.I. TACTICAL OVERVIEW</p>
        </div>
        <div className="flex space-x-4">
          <div className="text-right">
            <div className="text-[10px] text-slate-500 font-mono tracking-widest">THREAT COND.</div>
            <div className="text-sm font-bold text-red-500 animate-pulse">ELEVATED</div>
          </div>
          <div className="text-right">
            <div className="text-[10px] text-slate-500 font-mono tracking-widest">ACTIVE ZONES</div>
            <div className="text-sm font-bold text-slate-200">{activeZones.length || 0}</div>
          </div>
        </div>
      </div>

      {/* Map / Visualization Area */}
      <div className="flex-1 relative w-full h-full flex items-center justify-center p-8 mt-20 z-0">
        
        {/* Decorative Grid / Map stand-in */}
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px]"></div>
        
        {/* D3 Heatmap Overlay */}
        <svg 
          className="absolute inset-0 w-full h-full pointer-events-none opacity-60 mix-blend-screen"
          viewBox={`0 0 ${width} ${height}`}
          preserveAspectRatio="none"
        >
          {density.map((d, i) => (
            <path 
              key={i}
              d={d3.geoPath()(d) as string}
              fill={colorScale(d.value)}
              stroke="none"
            />
          ))}
        </svg>

        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[80%] h-[80%] border border-slate-800/50 rounded-full opacity-20 pointer-events-none"></div>
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[60%] h-[60%] border border-slate-700/50 rounded-full opacity-30 pointer-events-none"></div>
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[40%] h-[40%] border border-slate-600/50 rounded-full opacity-40 flex items-center justify-center pointer-events-none">
          <div className="w-2 h-2 bg-slate-500 rounded-full shadow-[0_0_15px_rgba(100,116,139,0.5)]"></div>
        </div>
        
        {/* Render Active Nodes based on events */}
        {activeZones.map((zone) => {
          // Recreate exact stable coordinates for the node marker
          const hash = zone.split('').reduce((acc, char) => char.charCodeAt(0) + acc, 0);
          const x = 50 + Math.sin(hash) * 35;
          const y = 50 + Math.cos(hash) * 35;
          
          return (
            <motion.div
              key={zone}
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              className="absolute flex flex-col items-center"
              style={{ top: `${y}%`, left: `${x}%`, transform: 'translate(-50%, -50%)' }}
            >
              <div className="relative flex items-center justify-center">
                <div className="absolute w-10 h-10 rounded-full bg-red-500/20 animate-ping"></div>
                <div className="absolute w-6 h-6 rounded-full bg-red-500/40 animate-pulse"></div>
                <div className="w-3 h-3 bg-red-500 border border-red-300 rounded-full z-10 shadow-[0_0_15px_rgba(239,68,68,1)]"></div>
              </div>
              <div className="mt-4 px-2 py-1 bg-black/80 border border-red-900/60 rounded text-[9px] font-mono tracking-widest text-red-200 backdrop-blur-md whitespace-nowrap z-10">
                {zone.toUpperCase().replace(/_/g, ' ')}
              </div>
            </motion.div>
          );
        })}

        <div className="absolute bottom-8 left-8 right-8 pointer-events-none z-20">
          <h3 className="text-xs font-mono text-slate-500 mb-2">ACTIVE INCIDENTS ({intelEvents.length})</h3>
          <div className="flex gap-2 w-full overflow-hidden">
            {intelEvents.slice(-4).map(evt => (
              <div key={evt.id} className="flex-1 bg-slate-900/80 border-l border-red-500 p-2 backdrop-blur-md">
                <div className="text-[10px] text-slate-400 font-mono">{evt.category}</div>
                <div className="text-xs text-slate-100 font-medium truncate">{evt.event}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
