// Example agents. These show "business operations" automation on aiki.
// Replace the in-memory data / stubbed tools with real APIs, DBs, or MCP tools.
import type { Agent } from "./core";
import { rankByOps, fetchSituational, JP_MLB_HITTERS } from "./mlb";

// --- KPI 監視エージェント -------------------------------------------------
export const kpiWatch: Agent = {
  name: "kpi-watch",
  role: "監視",
  async run(ctx) {
    ctx.charge(0.005); // 推定コスト（LLM/API想定）
    const mrr = 1_234_567;
    const target = 1_000_000;
    const ok = mrr >= target;
    ctx.state.set("kpi", `MRR ${mrr.toLocaleString()} / target ${target.toLocaleString()}`);
    return {
      agent: "kpi-watch",
      output: `MRR ${mrr.toLocaleString()} → ${ok ? "達成" : "未達"}`,
      ok: true,
      costUsd: 0.005,
    };
  },
};

// --- 野球分析エージェント（aiki の showcase デモ） -------------------------
// sabermetrics の OPS (= OBP + SLG) を計算し、ランキングを返す。
// ※ 公開データ/サンプルの「分析・可視化」用途。賭けやオッズ予想は対象外。
type Batter = { name: string; ab: number; h: number; bb: number; tb: number };

// オフライン用の汎用サンプル（テスト/ネット不要デモ。実名ではない）。
const SAMPLE: Batter[] = [
  { name: "Player A", ab: 497, h: 151, bb: 91, tb: 325 },
  { name: "Player B", ab: 458, h: 133, bb: 78, tb: 300 },
  { name: "Player C", ab: 540, h: 178, bb: 35, tb: 240 },
  { name: "Player D", ab: 510, h: 140, bb: 60, tb: 295 },
];

export function obp(b: Batter): number {
  return (b.h + b.bb) / (b.ab + b.bb);
}
export function slg(b: Batter): number {
  return b.tb / b.ab;
}
export function ops(b: Batter): number {
  return obp(b) + slg(b);
}

export const baseballAnalytics: Agent = {
  name: "baseball-analytics",
  role: "アナリスト",
  async run(ctx) {
    ctx.charge(0.01);
    const ranked = SAMPLE.map((b) => ({ name: b.name, ops: +ops(b).toFixed(3) })).sort(
      (a, b) => b.ops - a.ops,
    );
    ctx.state.set("baseball_top", `${ranked[0].name} OPS ${ranked[0].ops}`);
    return {
      agent: "baseball-analytics",
      output: `OPSランキング: ${ranked.map((r) => `${r.name}:${r.ops}`).join(" / ")}`,
      ok: true,
      costUsd: 0.01,
    };
  },
};

// --- 日本人MLB野手 OPSランキング（実データ・showcase本命） ---------------
// MLB公開API(statsapi.mlb.com)から実名選手の実スタッツを取得して並べる。
// AIKI_MLB_SEASON で対象シーズンを指定（既定=今年）。
export const japaneseMlbRanking: Agent = {
  name: "jp-mlb-ops",
  role: "アナリスト",
  async run(ctx) {
    ctx.charge(0.01);
    const season = Number(process.env.AIKI_MLB_SEASON ?? new Date().getFullYear());
    const ranked = await rankByOps(season);
    if (ranked.length === 0) {
      return { agent: "jp-mlb-ops", output: `MLBデータ取得不可（オフライン/シーズン前: ${season}）`, ok: false };
    }
    ctx.state.set("jp_mlb_top", `${ranked[0].name} OPS ${ranked[0].ops.toFixed(3)}`);
    const line = ranked.map((h) => `${h.name} ${h.ops.toFixed(3)}(HR${h.hr})`).join(" / ");
    return { agent: "jp-mlb-ops", output: `${season} 日本人MLB OPS: ${line}`, ok: true, costUsd: 0.01 };
  },
};

// --- シチュエーション別 分析エージェント（対左右 / 得点圏 を実データで比較） ---
export const situationalAnalysis: Agent = {
  name: "situational-analysis",
  role: "アナリスト",
  async run(ctx) {
    ctx.charge(0.02);
    const season = Number(process.env.AIKI_MLB_SEASON ?? new Date().getFullYear());
    const lines: string[] = [];
    for (const [name, id] of Object.entries(JP_MLB_HITTERS)) {
      try {
        const sp = await fetchSituational(id, season);
        const pick = (kw: string) => sp.find((s) => s.label.includes(kw));
        const vl = pick("Left");
        const vr = pick("Right");
        const risp = pick("Scoring");
        const f = (n?: number) => (n != null && !Number.isNaN(n) ? n.toFixed(3) : "-");
        lines.push(`${name} 対左${f(vl?.ops)}/対右${f(vr?.ops)}/得点圏${f(risp?.ops)}`);
      } catch {
        /* skip this player on transient error */
      }
    }
    if (lines.length === 0) {
      return { agent: "situational-analysis", output: `取得不可（${season}）`, ok: false };
    }
    ctx.state.set("situational", lines.join(" | "));
    return { agent: "situational-analysis", output: `${season} シチュ別OPS — ${lines.join(" / ")}`, ok: true, costUsd: 0.02 };
  },
};
