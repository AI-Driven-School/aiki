// 事業運用を宣言的に定義する。schedule は GitHub Actions / cron で実行する想定。
import { defineOps } from "../src/core";
import { kpiWatch, japaneseMlbRanking, situationalAnalysis } from "../src/agents";

export default defineOps({
  budgetUsd: 1.0, // 1サイクルのコスト上限（超過で即停止）
  requireApproval: false,
  agents: [
    { ...kpiWatch, schedule: "0 9 * * *" }, // 毎朝9時：事業KPI監視
    { ...japaneseMlbRanking, schedule: "0 10 * * 1" }, // 毎週月曜：日本人MLB OPS（実データ showcase）
    { ...situationalAnalysis, schedule: "0 11 * * 1" }, // 毎週月曜：対左右/得点圏の実データ分析
  ],
});
