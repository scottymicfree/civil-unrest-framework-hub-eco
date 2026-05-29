import express from "express";
import path from "path";
import { createServer as createViteServer } from "vite";
import { randomUUID } from "crypto";
import { GoogleGenAI } from "@google/genai";

let ai: GoogleGenAI | null = null;
let aiCustom: GoogleGenAI | null = null;
let currentCustomKey = "";

function getAI(customKey?: string) {
  if (customKey) {
    if (aiCustom && currentCustomKey === customKey) {
      return aiCustom;
    }
    aiCustom = new GoogleGenAI({
      apiKey: customKey,
      httpOptions: { headers: { 'User-Agent': 'aistudio-build' } }
    });
    currentCustomKey = customKey;
    return aiCustom;
  }

  if (!ai) {
    if (!process.env.GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY environment variable is required");
    }
    ai = new GoogleGenAI({ 
      apiKey: process.env.GEMINI_API_KEY,
      httpOptions: {
        headers: {
          'User-Agent': 'aistudio-build',
        }
      } 
    });
  }
  return ai;
}

const DEV_API_KEY = process.env.DEV_API_KEY || "lucy-dev-default-key";

// Event Stream Clients
const streamClients = new Set<express.Response>();

function broadcastToClients(data: any) {
  const payload = `data: ${JSON.stringify(data)}\n\n`;
  streamClients.forEach(client => client.write(payload));
}

async function startServer() {
  const app = express();
  const PORT = 3000;

  app.use(express.json());

  // SSE endpoint for live events / telemetry
  app.get("/api/stream", (req, res) => {
    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");

    streamClients.add(res);

    // Send an initial connected message
    res.write(`data: ${JSON.stringify({ type: "SYSTEM", message: "Intelligence Node Connected" })}\n\n`);

    // Simulated event generator for "live FiveM telemetry"
    const eventInterval = setInterval(() => {
      const events = [
        {
          id: randomUUID(),
          category: "SECURITY",
          event: "weapon_drawn",
          actor: "rawhood_queen_01",
          location: "vespucci_boardwalk",
          risk: 0.65,
          timestamp: new Date().toISOString(),
          context: "Assault Rifle deployed in neutral territory."
        },
        {
          id: randomUUID(),
          category: "ECONOMY",
          event: "large_transaction",
          actor: "syndicate_boss_X",
          location: "maze_bank_tower",
          risk: 0.42,
          timestamp: new Date().toISOString(),
          context: "Suspected money laundering via real estate."
        },
        {
          id: randomUUID(),
          category: "FACTION_MOVEMENT",
          event: "gang_meeting",
          actors: ["rawhood_queen_01", "cartel_03"],
          location: "vespucci",
          risk: 0.82,
          timestamp: new Date().toISOString(),
          context: "Three cartel members entered rival territory."
        },
        {
          id: randomUUID(),
          category: "TELEMETRY",
          event: "police_response_spike",
          actor: "LSPD_Dispatch",
          location: "davis",
          risk: 0.75,
          timestamp: new Date().toISOString(),
          context: "Multiple 10-13 calls. Officer down."
        }
      ];

      const randomEvent = events[Math.floor(Math.random() * events.length)];
      
      // Simulate "Lucy Reasoning"
      let aiAnalysis = null;
      if (randomEvent.risk > 0.7) {
        aiAnalysis = {
          agent: randomEvent.category === "FACTION_MOVEMENT" ? "CROWD_AGENT" : "WATCHER_AGENT",
          predicted_outcome: randomEvent.event === "gang_meeting" ? "territorial_conflict" : "escalation_likely",
          recommendation: "Deploy rapid response units and restrict civilian traffic in the zone."
        };
      }

      broadcastToClients({ type: "INTELLIGENCE", data: randomEvent, analysis: aiAnalysis });
    }, 4500);

    req.on("close", () => {
      streamClients.delete(res);
      clearInterval(eventInterval);
    });
  });

  // External Dev API endpoint to push external server intel events natively
  app.post("/api/dev/events", (req, res) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || authHeader !== `Bearer ${DEV_API_KEY}`) {
      return res.status(401).json({ error: "Unauthorized. Invalid Dev API Key." });
    }
    
    const eventData = req.body;
    broadcastToClients({ type: "INTELLIGENCE", data: { ...eventData, id: eventData.id || randomUUID(), timestamp: eventData.timestamp || new Date().toISOString() } });
    res.json({ success: true, message: "Event broadcasted to Intelligence Core." });
  });

  // Return the configured Dev API key for the settings UI to display
  app.get("/api/dev/config", (req, res) => {
    res.json({ devApiKey: DEV_API_KEY });
  });

  app.get("/api/intel/profiles", (req, res) => {
    res.json([
      {
        id: "HQ-01",
        alias: "rawhood_queen_01",
        discordId: "73928193021",
        ipHistory: ["192.168.1.1", "10.0.0.45"],
        trustScore: 42,
        affiliation: "Hood Queens",
        flags: ["aggressive_driver", "weapon_smuggling"]
      },
      {
        id: "SYN-01",
        alias: "syndicate_boss_X",
        discordId: "84930219432",
        ipHistory: ["45.33.22.11"],
        trustScore: 88,
        affiliation: "The Syndicate",
        flags: ["market_manipulation"]
      }
    ]);
  });

  app.post("/api/generate-script", async (req, res) => {
    try {
      const { prompt } = req.body;
      if (!prompt) {
        return res.status(400).json({ error: "Missing prompt" });
      }

      const customKey = req.headers['x-gemini-key'] as string | undefined;
      const client = getAI(customKey);
      const response = await client.models.generateContent({
        model: "gemini-2.5-flash",
        contents: prompt,
        config: {
          systemInstruction: "You are an expert FiveM Lua developer. The user will ask for a specific script. Write fully functional Lua code. Output only the code and a very brief explanation. Format the code in a markdown block with ```lua",
          temperature: 0.2, // low temperature for code generation
        }
      });

      res.json({ reply: response.text });
    } catch (error: any) {
      console.error("Gemini API Error:", error);
      
      let errorMessage = "Failed to generate script. Check your API key.";
      if (error?.status === 429 || (error?.message && error.message.includes("429"))) {
        errorMessage = "API quota exceeded. Please provide a custom Gemini API key in the System Configurations (Settings) to continue generating scripts.";
      } else if (error?.status === 503 || (error?.message && error.message.includes("503"))) {
        errorMessage = "The AI model is currently experiencing high demand. Spikes are usually temporary. Please try again in just a moment.";
      }

      res.status(500).json({ error: errorMessage });
    }
  });

  app.post("/api/coding-station/run", async (req, res) => {
    try {
      const { code, action, variables } = req.body;
      if (!code) return res.status(400).json({ error: "Missing code" });

      const customKey = req.headers['x-gemini-key'] as string | undefined;
      const client = getAI(customKey);

      let systemInstruction = "";
      let finalPrompt = code;

      const generationConfig: any = {
        temperature: 0.2, 
      };

      if (action === 'test') {
        systemInstruction = "You are a FiveM Lua execution simulator. Analyze the provided Lua code and mock variables. Trace the execution step by step. Respond ONLY with a valid JSON array of objects. Each object MUST have: 'line' (number of line executing, or null), 'log' (string describing action or output), and 'state' (object of current variable values, e.g. {\"x\": \"10\"}). Include any syntax errors in the logs.";
        generationConfig.responseMimeType = "application/json";
        if (variables && variables.length > 0) {
           finalPrompt = `Mock Environment Variables:\n${JSON.stringify(variables, null, 2)}\n\nLua Code to Test:\n${code}`;
        }
      } else if (action === 'suggest') {
        systemInstruction = "You are Lucy, an expert FiveM Lua engineer. Review this script and provide bullet point suggestions on how to improve its performance, security, or feature set. Be friendly and highly technical. Begin with 'Lucy's Modding Suggestions:'.";
      } else if (action === 'apply_suggestions') {
        systemInstruction = "You are Lucy, an expert FiveM Lua engineer. Rewrite the provided Lua script to integrate your best performance, security, and feature upgrades. Return ONLY the raw valid Lua code without markdown formatting (no ```lua wrappers) and without explanations.";
      } else if (action === 'analyze_project') {
        systemInstruction = "You are Lucy, an expert FiveM Lua engineer. The user has uploaded an entire FiveM resource folder. Review all the provided files (designated by --- FILE: <path>) and provide a structured, friendly, and highly technical report outlining automated upgrade or debugging suggestions for the entire resource. Begin with 'Lucy's Resource Analysis:'.";
      } else {
        systemInstruction = "You are Lucy, a FiveM Lua expert. Explain exactly what the provided code does block by block, in a clear and concise terminal-style format. Assume a highly technical modding context.";
      }

      generationConfig.systemInstruction = systemInstruction;

      const response = await client.models.generateContent({
        model: "gemini-2.5-flash",
        contents: finalPrompt,
        config: generationConfig
      });

      res.json({ output: response.text });
    } catch (error: any) {
      console.error("Gemini API Error in Coding Station:", error);
      res.status(500).json({ error: "A.I. Analysis Failed. Check quota or system settings." });
    }
  });

  // Vite middleware for development
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://0.0.0.0:${PORT}`);
  });
}

startServer();
