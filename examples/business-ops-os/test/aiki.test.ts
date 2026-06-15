import { describe, it, expect } from "vitest";
import { Safety } from "../src/safety";
import { runOps, defineOps, type Agent } from "../src/core";
import { baseballAnalytics, ops } from "../src/agents";

describe("safety", () => {
  it("throws when the cycle budget is exceeded", () => {
    const s = new Safety(0.01);
    expect(() => s.charge(0.02)).toThrow(/budget/);
  });

  it("opens the circuit after maxFails", () => {
    const s = new Safety(1, 2);
    s.record(false);
    s.record(false);
    expect(s.canProceed()).toBe(false);
  });

  it("blocks when approval is required", () => {
    const s = new Safety(1, 3, true);
    expect(() => s.approve("delete prod data")).toThrow(/approval required/);
  });
});

describe("ops", () => {
  it("runs agents and stays within budget", async () => {
    const cfg = defineOps({ budgetUsd: 1, agents: [baseballAnalytics] });
    const { results, totalCostUsd } = await runOps(cfg, new Safety(1));
    expect(results[0].ok).toBe(true);
    expect(totalCostUsd).toBeLessThanOrEqual(1);
  });

  it("isolates a failing agent and keeps the cycle going", async () => {
    const bad: Agent = { name: "bad", async run() { throw new Error("boom"); } };
    const cfg = defineOps({ budgetUsd: 1, agents: [bad, baseballAnalytics] });
    const { results } = await runOps(cfg, new Safety(1));
    expect(results).toHaveLength(2);
    expect(results.find((r) => r.agent === "baseball-analytics")?.ok).toBe(true);
  });
});

describe("baseball sabermetrics", () => {
  it("computes OPS as OBP + SLG", () => {
    const v = ops({ name: "x", ab: 500, h: 150, bb: 50, tb: 300 });
    expect(v).toBeCloseTo((150 + 50) / (500 + 50) + 300 / 500, 5);
  });
});
