export interface IntelEvent {
  id: string;
  category: "SECURITY" | "ECONOMY" | "FACTION_MOVEMENT" | "TELEMETRY";
  event: string;
  actor?: string;
  actors?: string[];
  location: string;
  risk: number;
  timestamp: string;
  context: string;
}

export interface AIAnalysis {
  agent: string;
  predicted_outcome: string;
  recommendation: string;
}

export interface IntelMessage {
  type: "INTELLIGENCE" | "SYSTEM";
  message?: string;
  data?: IntelEvent;
  analysis?: AIAnalysis | null;
}

export interface PlayerProfile {
  id: string;
  alias: string;
  discordId: string;
  ipHistory: string[];
  trustScore: number;
  affiliation: string;
  flags: string[];
}
