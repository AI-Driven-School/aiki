// Entry point: run one ops cycle under the safety policy.
// Usage: npm run ops
import cfg from "../examples/ops.config";
import { runOps } from "./core";
import { Safety } from "./safety";

const budget = Number(process.env.AIKI_BUDGET_USD ?? cfg.budgetUsd);
const requireApproval = (process.env.AIKI_REQUIRE_APPROVAL ?? String(cfg.requireApproval ?? false)) === "true";

const safety = new Safety(budget, 3, requireApproval);
const { results, state, totalCostUsd } = await runOps(cfg, safety);

console.table(
  results.map((r) => ({ agent: r.agent, ok: r.ok, output: r.output.slice(0, 64) })),
);
console.log(`cost: $${totalCostUsd.toFixed(3)} / budget $${budget.toFixed(2)}`);
console.log("state:", state.snapshot());
