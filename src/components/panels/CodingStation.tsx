import React, { useState, useEffect, useRef } from 'react';
import { motion } from 'motion/react';
import { X, Play, Info, FileCode, Code, CheckCircle, AlertTriangle, TerminalSquare, Upload, Lightbulb, Plus, Trash2, Wand2 } from 'lucide-react';
import Editor from 'react-simple-code-editor';
import Prism from 'prismjs';
import 'prismjs/components/prism-lua';
import 'prismjs/themes/prism-tomorrow.css'; 

interface CodingStationProps {
  initialCode: string;
  onClose: () => void;
}

export interface ProjectFile {
  path: string;
  content: string;
}

export function CodingStation({ initialCode, onClose }: CodingStationProps) {
  const [projectFiles, setProjectFiles] = useState<ProjectFile[]>([
    { path: 'script.lua', content: initialCode || '-- Lucy\'s FiveM Modding\n\nprint("Hello World")' }
  ]);
  const [activeFilePath, setActiveFilePath] = useState<string>('script.lua');
  const activeContent = projectFiles.find(f => f.path === activeFilePath)?.content || '';

  const setCode = (newContent: string) => {
    setProjectFiles(prev => prev.map(f => f.path === activeFilePath ? { ...f, content: newContent } : f));
  };

  const [terminalOutput, setTerminalOutput] = useState<string[]>([
    "[SYSTEM] Lucy's Coding Station Ready.",
    "[SYSTEM] Waiting for execution or analysis..."
  ]);
  const [mockVariables, setMockVariables] = useState<{key: string, value: string}[]>([]);
  const [activeLine, setActiveLine] = useState<number | null>(null);
  const [activeState, setActiveState] = useState<Record<string, any>>({});
  const [isProcessing, setIsProcessing] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (initialCode) {
      setProjectFiles([{ path: 'script.lua', content: initialCode }]);
      setActiveFilePath('script.lua');
    }
  }, [initialCode]);

  const handleImport = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (event) => {
        const text = event.target?.result;
        if (typeof text === 'string') {
          const path = file.name;
          setProjectFiles(prev => {
            const exists = prev.find(f => f.path === path);
            if (exists) return prev.map(f => f.path === path ? { ...f, content: text } : f);
            return [...prev, { path, content: text }];
          });
          setActiveFilePath(path);
          setTerminalOutput(prev => [...prev, `[SYSTEM] Imported file: ${file.name}`]);
        }
      };
      reader.readAsText(file);
    }
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };
  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleDrop = async (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);

    const items = e.dataTransfer.items;
    if (!items) return;

    const files: ProjectFile[] = [];
    
    const readFile = (entry: any): Promise<ProjectFile | null> => {
      return new Promise((resolve) => {
        if (entry.isFile) {
          entry.file((file: File) => {
             if (file.name.endsWith('.lua') || file.name.endsWith('.txt') || file.name.endsWith('.json') || file.name.endsWith('.js') || file.name.endsWith('.html') || file.name.endsWith('.css')) {
               const reader = new FileReader();
               reader.onload = (ev) => {
                  resolve({
                     path: entry.fullPath.replace(/^\//, ''),
                     content: ev.target?.result as string
                  });
               };
               reader.readAsText(file);
             } else {
               resolve(null);
             }
          });
        } else {
          resolve(null);
        }
      });
    };

    const traverseEntry = async (entry: any) => {
        if (entry.isFile) {
            const file = await readFile(entry);
            if (file) files.push(file);
        } else if (entry.isDirectory) {
            const dirReader = entry.createReader();
            const entries = await new Promise<any[]>((resolve) => {
                dirReader.readEntries((results: any[]) => resolve(results));
            });
            for (const child of entries) {
                await traverseEntry(child);
            }
        }
    };

    setTerminalOutput(prev => [...prev, "[SYSTEM] Reading dropped files..."]);
    
    for (let i = 0; i < items.length; i++) {
        const item = items[i];
        if (item.webkitGetAsEntry) {
            const entry = item.webkitGetAsEntry();
            if (entry) {
                await traverseEntry(entry);
            }
        }
    }

    if (files.length > 0) {
        setProjectFiles(files);
        setActiveFilePath(files[0].path);
        setTerminalOutput(prev => [...prev, `[SYSTEM] Imported project with ${files.length} files.`]);
        
        handleAnalyzeProject(files);
    }
  };

  const handleAnalyzeProject = async (files: ProjectFile[]) => {
      setIsProcessing(true);
      setTerminalOutput(prev => [...prev, "> Starting Full Resource Analysis via Lucy..."]);
      
      try {
        const customKey = localStorage.getItem('LUCY_GEMINI_KEY') || '';
        const combinedCode = files.map(f => `--- FILE: ${f.path}\n${f.content}`).join('\n\n');
        
        const res = await fetch('/api/coding-station/run', {
          method: 'POST',
          headers: { 
            'Content-Type': 'application/json',
            ...(customKey ? { 'x-gemini-key': customKey } : {})
          },
          body: JSON.stringify({ code: combinedCode, action: 'analyze_project' }),
        });
        const data = await res.json();
        if (data.error) throw new Error(data.error);
        
        setTerminalOutput(prev => [...prev, data.output || "Project analysis completed."]);
      } catch (err: any) {
        setTerminalOutput(prev => [...prev, `[ERROR]: ${err.message}`]);
      } finally {
        setIsProcessing(false);
      }
  };

  const handleTestScript = async () => {
    setIsProcessing(true);
    setTerminalOutput(prev => [...prev, "> Starting Static Analysis & Simulated Execution..."]);
    setActiveLine(null);
    setActiveState({});
    
    try {
      const customKey = localStorage.getItem('LUCY_GEMINI_KEY') || '';
      const res = await fetch('/api/coding-station/run', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          ...(customKey ? { 'x-gemini-key': customKey } : {})
        },
        body: JSON.stringify({ code: activeContent, action: 'test', variables: mockVariables }),
      });
      const data = await res.json();
      if (data.error) throw new Error(data.error);
      
      try {
        const trace = JSON.parse(data.output);
        setTerminalOutput(prev => [...prev, "> Starting Line-by-Line Execution Trace..."]);
        
        for (const step of trace) {
          await new Promise(r => setTimeout(r, 800));
          if (step.line) setActiveLine(step.line);
          if (step.state) setActiveState(step.state);
          setTerminalOutput(p => [...p, `[Line ${step.line || 'SYS'}] ${step.log}`]);
        }
        
        await new Promise(r => setTimeout(r, 500));
        setTerminalOutput(p => [...p, "> Execution Trace Completed."]);
        setActiveLine(null);
      } catch (e) {
        setTerminalOutput(prev => [...prev, data.output || "Test executed successfully."]);
      }
    } catch (err: any) {
      setTerminalOutput(prev => [...prev, `[ERROR]: ${err.message}`]);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleExplainCode = async () => {
    setIsProcessing(true);
    setTerminalOutput(prev => [...prev, "> Requesting Lucy's Code Analysis & Breakdown..."]);
    
    try {
      const customKey = localStorage.getItem('LUCY_GEMINI_KEY') || '';
      const res = await fetch('/api/coding-station/run', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          ...(customKey ? { 'x-gemini-key': customKey } : {})
        },
        body: JSON.stringify({ code: activeContent, action: 'explain' }),
      });
      const data = await res.json();
      if (data.error) throw new Error(data.error);
      
      setTerminalOutput(prev => [...prev, data.output || "Analysis completed."]);
    } catch (err: any) {
      setTerminalOutput(prev => [...prev, `[ERROR]: ${err.message}`]);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleSuggestions = async () => {
    setIsProcessing(true);
    setTerminalOutput(prev => [...prev, "> Asking Lucy for upgrade suggestions..."]);
    
    try {
      const customKey = localStorage.getItem('LUCY_GEMINI_KEY') || '';
      const res = await fetch('/api/coding-station/run', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          ...(customKey ? { 'x-gemini-key': customKey } : {})
        },
        body: JSON.stringify({ code: activeContent, action: 'suggest' }),
      });
      const data = await res.json();
      if (data.error) throw new Error(data.error);
      
      setTerminalOutput(prev => [...prev, data.output || "No suggestions available."]);
    } catch (err: any) {
      setTerminalOutput(prev => [...prev, `[ERROR]: ${err.message}`]);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleApplySuggestions = async () => {
    setIsProcessing(true);
    setTerminalOutput(prev => [...prev, "> Asking Lucy to apply upgrades and auto-fix the code..."]);
    
    try {
      const customKey = localStorage.getItem('LUCY_GEMINI_KEY') || '';
      const res = await fetch('/api/coding-station/run', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          ...(customKey ? { 'x-gemini-key': customKey } : {})
        },
        body: JSON.stringify({ code: activeContent, action: 'apply_suggestions' }),
      });
      const data = await res.json();
      if (data.error) throw new Error(data.error);
      
      setCode(data.output);
      setTerminalOutput(prev => [...prev, "> Lucy has applied the suggested upgrades to your code."]);
    } catch (err: any) {
      setTerminalOutput(prev => [...prev, `[ERROR]: ${err.message}`]);
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <div 
      className={`flex-1 flex flex-col bg-[#1e1e1e] border-x border-slate-800 relative z-10 w-full h-full overflow-hidden text-slate-300 font-sans ${isDragging ? 'border-4 border-indigo-500 rounded-lg' : ''}`}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      {/* Top Header */}
      <div className="flex items-center justify-between px-4 py-2 bg-[#181818] border-b border-slate-700/50 block">
        <div className="flex items-center space-x-3">
          <Code className="w-4 h-4 text-indigo-400" />
          <span className="text-xs font-mono font-bold tracking-widest text-slate-200">LUCY'S CODING STATION</span>
        </div>
        <div className="flex items-center space-x-2">
          <input
            type="file"
            accept=".lua,.txt"
            ref={fileInputRef}
            onChange={handleImport}
            className="hidden"
          />
          <button 
            disabled={isProcessing}
            onClick={() => fileInputRef.current?.click()}
            className="flex items-center px-3 py-1.5 text-[10px] font-bold tracking-wider uppercase bg-slate-600/20 text-slate-300 hover:bg-slate-600/40 rounded transition-colors"
          >
            <Upload className="w-3 h-3 mr-1.5" />
            Import
          </button>
          <button 
            disabled={isProcessing}
            onClick={handleSuggestions}
            className="flex items-center px-3 py-1.5 text-[10px] font-bold tracking-wider uppercase bg-purple-600/20 text-purple-400 hover:bg-purple-600/40 rounded transition-colors"
          >
            <Lightbulb className="w-3 h-3 mr-1.5" />
            Lucy's Suggestions
          </button>
          <button 
            disabled={isProcessing}
            onClick={handleApplySuggestions}
            className="flex items-center px-3 py-1.5 text-[10px] font-bold tracking-wider uppercase bg-pink-600/20 text-pink-400 hover:bg-pink-600/40 rounded transition-colors"
          >
            <Wand2 className="w-3 h-3 mr-1.5" />
            Apply Auto-Fix
          </button>
          <button 
            disabled={isProcessing}
            onClick={handleExplainCode}
            className="flex items-center px-3 py-1.5 text-[10px] font-bold tracking-wider uppercase bg-blue-600/20 text-blue-400 hover:bg-blue-600/40 rounded transition-colors"
          >
            <Info className="w-3 h-3 mr-1.5" />
            Explain Code
          </button>
          <button 
            disabled={isProcessing}
            onClick={handleTestScript}
            className="flex items-center px-3 py-1.5 text-[10px] font-bold tracking-wider uppercase bg-emerald-600/20 text-emerald-400 hover:bg-emerald-600/40 rounded transition-colors"
          >
            <Play className="w-3 h-3 mr-1.5" />
            Run / Test
          </button>
          <button 
            onClick={onClose}
            className="ml-4 p-1.5 text-slate-500 hover:text-slate-300 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      </div>

      <div className="flex flex-1 overflow-hidden">
        {/* Left Sidebar (VS Code style files) */}
        <div className="w-64 bg-[#181818] border-r border-[#2b2b2b] flex flex-col">
          <div className="p-3 text-[10px] font-mono tracking-widest text-slate-500 uppercase">Explorer</div>
          <div className="pb-4 max-h-48 overflow-y-auto">
             {projectFiles.map(file => (
               <div 
                 key={file.path}
                 onClick={() => setActiveFilePath(file.path)}
                 className={`flex items-center px-4 py-1.5 text-xs cursor-pointer ${activeFilePath === file.path ? 'bg-[#37373d] text-slate-200' : 'text-slate-400 hover:bg-[#2a2d2e]'}`}
               >
                  <FileCode className={`w-3.5 h-3.5 mr-2 shrink-0 ${activeFilePath === file.path ? 'text-indigo-400' : 'text-slate-500'}`} />
                  <span className="truncate">{file.path}</span>
               </div>
             ))}
          </div>
          
          {/* Mock Variables Section */}
          <div className="flex-1 flex flex-col border-t border-[#2b2b2b]">
            <div className="p-3 text-[10px] font-mono tracking-widest text-slate-500 uppercase flex justify-between items-center">
              <span>Mock Variables</span>
              <button 
                onClick={() => setMockVariables(prev => [...prev, { key: '', value: '' }])}
                className="hover:text-indigo-400 transition-colors"
                title="Add Variable"
              >
                <Plus className="w-3.5 h-3.5" />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto px-2 space-y-2 pb-2">
              {mockVariables.length === 0 && (
                <div className="text-[10px] text-slate-600 px-2 italic">No variables defined.</div>
              )}
              {mockVariables.map((v, i) => (
                <div key={i} className="flex flex-col space-y-1 bg-[#1e1e1e] p-2 rounded border border-[#2b2b2b]">
                  <div className="flex space-x-1">
                     <input 
                       type="text" 
                       placeholder="Variable name"
                       value={v.key}
                       onChange={e => {
                         const newVars = [...mockVariables];
                         newVars[i].key = e.target.value;
                         setMockVariables(newVars);
                       }}
                       className="w-full bg-[#111] text-[10px] text-slate-300 border border-[#333] rounded px-1.5 py-1 focus:outline-none focus:border-indigo-500 font-mono"
                     />
                     <button
                       onClick={() => {
                         const newVars = [...mockVariables];
                         newVars.splice(i, 1);
                         setMockVariables(newVars);
                       }}
                       className="p-1 text-slate-500 hover:text-red-400"
                     >
                       <Trash2 className="w-3 h-3" />
                     </button>
                  </div>
                  <input 
                    type="text" 
                    placeholder="Value (e.g. 'Jane Doe', 100)"
                    value={v.value}
                    onChange={e => {
                      const newVars = [...mockVariables];
                      newVars[i].value = e.target.value;
                      setMockVariables(newVars);
                    }}
                    className="w-full bg-[#111] text-[10px] text-emerald-400 border border-[#333] rounded px-1.5 py-1 focus:outline-none focus:border-indigo-500 font-mono"
                  />
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Main Editor Area */}
        <div className="flex-1 flex flex-col overflow-hidden bg-[#1e1e1e]">
          <div className="flex items-center text-xs text-slate-400 px-4 py-2 border-b border-[#2b2b2b] bg-[#1e1e1e]">
            {activeFilePath}
          </div>
          <div className="flex-1 overflow-y-auto w-full">
            <Editor
              value={activeContent}
              onValueChange={setCode}
              highlight={code => Prism.highlight(code, Prism.languages.lua, 'lua')}
              padding={16}
              style={{
                fontFamily: '"JetBrains Mono", "Fira Code", monospace',
                fontSize: 12,
                minHeight: '100%',
                lineHeight: '1.5'
              }}
              textareaClassName="focus:outline-none"
              className="editor-container"
            />
          </div>
        </div>
      </div>

      {/* Terminal & Debugger Area */}
      <div className="h-72 bg-[#111111] border-t border-[#2b2b2b] flex">
        {/* Terminal Left */}
        <div className="flex-1 flex flex-col border-r border-[#2b2b2b]">
          <div className="flex items-center px-4 py-2 border-b border-[#2b2b2b] bg-[#181818] space-x-4">
             <div className="flex items-center text-[10px] uppercase font-mono tracking-widest text-slate-300">
               <TerminalSquare className="w-3.5 h-3.5 mr-1.5" /> Output / Analysis Console
             </div>
          </div>
          <div className="flex-1 p-4 font-mono text-[11px] text-slate-400 overflow-y-auto space-y-2">
             {terminalOutput.map((output, idx) => (
                <div key={idx} className="whitespace-pre-wrap leading-relaxed shadow-sm pb-2 border-b border-[#2b2b2b]/50 last:border-0">{output}</div>
             ))}
             {isProcessing && (
                <div className="flex items-center text-indigo-400 animate-pulse">
                   Processing A.I. execution request...
                </div>
             )}
          </div>
        </div>

        {/* Debugger State Right */}
        <div className="w-80 flex flex-col bg-[#181818]">
          <div className="flex items-center px-4 py-2 border-b border-[#2b2b2b] bg-[#181818]">
             <div className="flex items-center text-[10px] uppercase font-mono tracking-widest text-indigo-400">
               <AlertTriangle className="w-3.5 h-3.5 mr-1.5" /> Live Execution State
             </div>
          </div>
          <div className="flex-1 p-4 overflow-y-auto font-mono text-[10px]">
             {activeLine !== null && (
               <div className="mb-4 p-2 bg-indigo-500/10 border border-indigo-500/30 rounded text-indigo-300">
                 <strong className="text-indigo-400 uppercase">Executing Line:</strong> {activeLine}
               </div>
             )}
             <div className="text-slate-500 uppercase tracking-widest mb-2 font-bold">Memory / Variables</div>
             {Object.keys(activeState).length === 0 && (
               <div className="text-slate-600 italic">No variables in memory...</div>
             )}
             {Object.entries(activeState).map(([k, v]) => (
               <div key={k} className="flex justify-between items-center bg-[#111] border border-[#2b2b2b] px-2 py-1.5 rounded mb-1.5">
                 <span className="text-blue-400">{k}</span>
                 <span className="text-emerald-400 truncate max-w-[120px]" title={String(v)}>{String(v)}</span>
               </div>
             ))}
          </div>
        </div>
      </div>
    </div>
  );
}
