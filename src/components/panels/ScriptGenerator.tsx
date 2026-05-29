import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Terminal, Send, Code, X, Bot, User, Loader2, Download, Library, ChevronRight } from 'lucide-react';

const SCRIPT_TEMPLATES = [
  { name: 'Event Listener', prompt: 'Write a basic FiveM script that listens for a custom client event and prints a message to the console.' },
  { name: 'NPC Spawner', prompt: 'Write a basic FiveM client script that spawns an NPC (ped) at specific coordinates.' },
  { name: 'UI Trigger / NUI', prompt: 'Write a basic FiveM script that registers a command to send an NUI message to a frontend UI.' },
  { name: 'Vehicle Spawn', prompt: 'Write a basic FiveM client script to spawn a vehicle by model name and place the player in the driver seat.' }
];

const handleExport = (code: string) => {
  const blob = new Blob([code], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `fivem_script_${Date.now()}.lua`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
};

const renderMessageContent = (content: string) => {
  const parts = content.split(/```(?:lua)?\n([\s\S]*?)```/g);
  return parts.map((part, index) => {
    if (index % 2 === 0) {
      return <span key={index} className="whitespace-pre-wrap">{part}</span>;
    } else {
      return (
        <div key={index} className="mt-2 mb-2 rounded border border-slate-700 overflow-hidden bg-black/50">
          <div className="flex justify-between items-center px-3 py-1.5 bg-slate-800/80 border-b border-slate-700">
            <span className="text-[10px] text-slate-400 uppercase tracking-widest font-bold">LUA SCRIPT</span>
            <button
              onClick={() => handleExport(part)}
              className="flex items-center text-[10px] text-emerald-400 hover:text-emerald-300 transition-colors uppercase font-bold tracking-wider"
            >
              <Download className="w-3 h-3 mr-1" />
              Export
            </button>
          </div>
          <pre className="p-3 overflow-x-auto text-emerald-400 text-[10px] leading-relaxed">
            <code>{part}</code>
          </pre>
        </div>
      );
    }
  });
};

interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
}

export function ScriptGenerator({ onOpenInIDE }: { onOpenInIDE: (code: string) => void }) {
  const [isOpen, setIsOpen] = useState(false);
  const [isLibraryOpen, setIsLibraryOpen] = useState(false);
  const [messages, setMessages] = useState<ChatMessage[]>([{
    id: '1',
    role: 'assistant',
    content: 'Hello. I am Lucy. Describe the FiveM script you need, and I will generate the Lua code for you.'
  }]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isOpen]);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isLoading) return;

    const userMsg: ChatMessage = { id: Date.now().toString(), role: 'user', content: input };
    setMessages(prev => [...prev, userMsg]);
    setInput('');
    setIsLoading(true);

    try {
      const customKey = localStorage.getItem('LUCY_GEMINI_KEY') || '';
      const res = await fetch('/api/generate-script', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          ...(customKey ? { 'x-gemini-key': customKey } : {})
        },
        body: JSON.stringify({ prompt: userMsg.content }),
      });
      
      const data = await res.json();
      
      if (data.error) {
        throw new Error(data.error);
      }

      const generatedContent = data.code || data.reply;
      
      setMessages(prev => [...prev, {
        id: Date.now().toString(),
        role: 'assistant',
        content: generatedContent,
      }]);
      
      // Auto-extract code and open in IDE
      const codeMatch = generatedContent.match(/```(?:lua)?\n([\s\S]*?)```/);
      if (codeMatch && codeMatch[1]) {
         onOpenInIDE(codeMatch[1].trim());
      } else if (generatedContent && generatedContent.length > 50) {
         onOpenInIDE(generatedContent); // fallback
      }
    } catch (err: any) {
      setMessages(prev => [...prev, {
        id: Date.now().toString(),
        role: 'assistant',
        content: `[SYSTEM ERROR]: ${err.message || 'Failed to generate script.'}`
      }]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      {/* Floating Toggle Button */}
      <button
        onClick={() => setIsOpen(true)}
        className={`fixed bottom-6 right-6 p-4 rounded-full bg-indigo-600 text-white shadow-[0_0_20px_rgba(79,70,229,0.5)] hover:bg-indigo-500 transition-all z-40 ${isOpen ? 'scale-0 opacity-0' : 'scale-100 opacity-100'}`}
      >
        <Code className="w-6 h-6" />
      </button>

      {/* Floating Chat Window */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: 50, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 50, scale: 0.9 }}
            className="fixed bottom-6 right-6 w-96 h-[32rem] bg-slate-900 border border-slate-700/60 rounded-xl shadow-2xl flex flex-col z-50 overflow-hidden"
          >
            {/* Header */}
            <div className="p-3 border-b border-slate-800 flex justify-between items-center bg-slate-950 px-4">
              <div className="flex items-center text-indigo-400 font-mono text-sm tracking-widest">
                <Terminal className="w-4 h-4 mr-2" />
                LUCY A.I.
              </div>
              <div className="flex items-center space-x-3">
                <button 
                  onClick={() => setIsLibraryOpen(!isLibraryOpen)}
                  className={`text-slate-500 hover:text-indigo-400 transition-colors ${isLibraryOpen ? 'text-indigo-400' : ''}`}
                  title="Template Library"
                >
                  <Library className="w-4 h-4" />
                </button>
                <button 
                  onClick={() => setIsOpen(false)}
                  className="text-slate-500 hover:text-slate-300 transition-colors"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Library Pane */}
            <AnimatePresence>
              {isLibraryOpen && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: 'auto', opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  className="border-b border-slate-800 bg-slate-900/50 overflow-hidden"
                >
                  <div className="p-3">
                     <h3 className="text-[10px] text-slate-400 uppercase tracking-widest font-bold mb-2">Build Templates</h3>
                     <div className="grid grid-cols-2 gap-2">
                       {SCRIPT_TEMPLATES.map((template, idx) => (
                         <button
                           key={idx}
                           onClick={() => {
                             setInput(template.prompt);
                             setIsLibraryOpen(false);
                           }}
                           className="flex items-center justify-between p-2 rounded bg-slate-800/80 border border-slate-700 hover:border-indigo-500 hover:bg-slate-800 text-left transition-colors text-[10px] font-mono text-slate-300"
                         >
                           <span className="truncate">{template.name}</span>
                           <ChevronRight className="w-3 h-3 text-indigo-400 opacity-50 shrink-0" />
                         </button>
                       ))}
                     </div>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4 font-mono text-[11px] leading-relaxed relative">
              {messages.map(msg => (
                <div key={msg.id} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                  <div className={`max-w-[85%] flex items-start space-x-2 ${msg.role === 'user' ? 'flex-row-reverse space-x-reverse' : ''}`}>
                    <div className={`p-1.5 rounded-md shrink-0 ${msg.role === 'user' ? 'bg-indigo-500/20 text-indigo-400' : 'bg-slate-800 text-emerald-400'}`}>
                      {msg.role === 'user' ? <User className="w-3 h-3" /> : <Bot className="w-3 h-3" />}
                    </div>
                    <div className={`p-3 rounded-lg ${msg.role === 'user' ? 'bg-indigo-600 text-white' : 'bg-slate-800 text-slate-300 border border-slate-700'}`}>
                      {msg.role === 'assistant' && msg.content.includes('```') ? (
                        renderMessageContent(msg.content)
                      ) : (
                        <span className="whitespace-pre-wrap">{msg.content}</span>
                      )}
                    </div>
                  </div>
                </div>
              ))}
              {isLoading && (
                <div className="flex justify-start">
                  <div className="flex items-center space-x-2">
                     <div className="p-1.5 rounded-md bg-slate-800 text-emerald-400">
                        <Bot className="w-3 h-3" />
                     </div>
                     <div className="p-3 bg-slate-800 rounded-lg border border-slate-700 text-slate-400 flex items-center">
                       <Loader2 className="w-3 h-3 animate-spin mr-2" /> Generating native logic...
                     </div>
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Input */}
            <div className="p-3 bg-slate-950 border-t border-slate-800">
              <form onSubmit={handleSend} className="relative">
                <input
                  type="text"
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  placeholder="Request a FiveM script..."
                  className="w-full bg-slate-900 border border-slate-700 text-slate-200 text-xs font-mono rounded-lg pl-3 pr-10 py-2.5 outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all placeholder:text-slate-600"
                  disabled={isLoading}
                />
                <button
                  type="submit"
                  disabled={!input.trim() || isLoading}
                  className="absolute right-2 top-1/2 -translate-y-1/2 p-1.5 text-indigo-400 hover:text-indigo-300 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  <Send className="w-3.5 h-3.5" />
                </button>
              </form>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
