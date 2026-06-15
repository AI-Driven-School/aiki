// aiki core — declarative business-operations runtime.
// Define agents (role + schedule + run) and execute them under a safety budget.
import type { Safety } from "./safety";

export type AgentResult = { agent: string; output: string; ok: boolean; costUsd?: number };

export type Ctx = {
  state: SharedState;
  /** charge estimated cost; throws via Safety if the cycle budget is exceeded */
  charge: (usd: number) => void;
};

export interface Agent {
  name: string;
  role?: string;
  schedule?: string; // cron expression (executed by GitHub Actions / cron)
  run(ctx: Ctx): Promise<AgentResult>;
}

export type OpsConfig = {
  budgetUsd: number;
  requireApproval?: boolean;
  agents: Agent[];
};

/** Identity helper for typed, declarative ops configs. */
export function defineOps(cfg: OpsConfig): OpsConfig {
  return cfg;
}

export class SharedState {
  private data = new Map<string, string>();
  log: string[] = [];
  get(k: string): string | undefined {
    return this.data.get(k);
  }
  set(k: string, v: string): void {
    this.data.set(k, v);
    this.log.push(`${k}=${v.slice(0, 60)}`);
  }
  snapshot(): Record<string, string> {
    return Object.fromEntries(this.data);
  }
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
function withTimeout<T>(p: Promise<T>, ms: number): Promise<T> {
  return Promise.race([
    p,
    new Promise<T>((_, reject) => setTimeout(() => reject(new Error("timeout")), ms)),
  ]);
}

/** Call an external tool with bounded retry + timeout + backoff. */
export async function callTool(
  tool: (input: string) => Promise<string>,
  input: string,
  opts: { retries?: number; timeoutMs?: number } = {},
): Promise<string> {
  const { retries = 2, timeoutMs = 3000 } = opts;
  let lastErr: unknown;
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      return await withTimeout(tool(input), timeoutMs);
    } catch (e) {
      lastErr = e;
      await sleep(100 * (attempt + 1));
    }
  }
  throw new Error(`tool failed after ${retries + 1} attempts: ${String(lastErr)}`);
}

/** Run one cycle of the ops config under the given safety policy. */
export async function runOps(
  cfg: OpsConfig,
  safety: Safety,
): Promise<{ results: AgentResult[]; state: SharedState; totalCostUsd: number }> {
  const state = new SharedState();
  const results: AgentResult[] = [];
  for (const a of cfg.agents) {
    if (!safety.canProceed()) {
      results.push({ agent: a.name, output: "skipped (circuit open / budget reached)", ok: false });
      continue;
    }
    try {
      const r = await a.run({ state, charge: (usd) => safety.charge(usd) });
      results.push(r);
      safety.record(r.ok);
    } catch (e) {
      // failure isolation: one agent must not crash the whole cycle
      results.push({ agent: a.name, output: String(e), ok: false });
      safety.record(false);
    }
  }
  return { results, state, totalCostUsd: safety.spentUsd() };
}
