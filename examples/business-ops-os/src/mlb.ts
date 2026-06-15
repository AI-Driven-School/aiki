// Fetches REAL MLB hitting stats from the public MLB Stats API (statsapi.mlb.com).
// No API key required. Used by the Japanese-MLB showcase agent.

export type Hitting = {
  name: string;
  team: string;
  ops: number;
  obp: number;
  slg: number;
  avg: number;
  hr: number;
  ab: number;
};

// 話題の日本人MLB野手を公開 person ID で固定（name→id 解決の曖昧さを避ける）。
// 好きな選手のIDに差し替えるだけでランキング対象を変えられる。
export const JP_MLB_HITTERS: Record<string, number> = {
  "大谷翔平 (Ohtani)": 660271,
  "村上宗隆 (Murakami)": 808959,
  "鈴木誠也 (Suzuki)": 673548,
  "吉田正尚 (Yoshida)": 807799,
};

const API = "https://statsapi.mlb.com/api/v1";

export async function fetchHitting(name: string, id: number, season: number): Promise<Hitting | null> {
  const res = await fetch(`${API}/people/${id}/stats?stats=season&group=hitting&season=${season}`);
  if (!res.ok) throw new Error(`MLB API ${res.status}`);
  const data = (await res.json()) as {
    stats?: { splits?: { team?: { name?: string }; stat: Record<string, string> }[] }[];
  };
  const split = data.stats?.[0]?.splits?.[0];
  if (!split) return null; // そのシーズンに打撃データ無し（投手 / 在籍前など）
  const s = split.stat;
  return {
    name,
    team: split.team?.name ?? "",
    ops: Number(s.ops),
    obp: Number(s.obp),
    slg: Number(s.slg),
    avg: Number(s.avg),
    hr: Number(s.homeRuns),
    ab: Number(s.atBats),
  };
}

/** 指定シーズンの OPS 降順ランキング。取得失敗した選手はスキップ（データ層の失敗隔離）。 */
export async function rankByOps(season: number, roster = JP_MLB_HITTERS): Promise<Hitting[]> {
  const out: Hitting[] = [];
  for (const [name, id] of Object.entries(roster)) {
    try {
      const h = await fetchHitting(name, id, season);
      if (h && !Number.isNaN(h.ops)) out.push(h);
    } catch {
      /* transient error: skip this player, keep the rest */
    }
  }
  return out.sort((a, b) => b.ops - a.ops);
}

// --- シチュエーション別 splits（対左右投手 / 得点圏 など実データ） -----------
export type Split = { label: string; ops: number; obp: number; slg: number; avg: number; hr: number; ab: number };

export async function fetchSplits(id: number, season: number, sitCodes: string): Promise<Split[]> {
  const res = await fetch(
    `${API}/people/${id}/stats?stats=statSplits&group=hitting&season=${season}&sitCodes=${sitCodes}`,
  );
  if (!res.ok) throw new Error(`MLB API ${res.status}`);
  const data = (await res.json()) as {
    stats?: { splits?: { split?: { description?: string; code?: string }; stat: Record<string, string> }[] }[];
  };
  const splits = data.stats?.[0]?.splits ?? [];
  return splits.map((sp) => ({
    label: sp.split?.description ?? sp.split?.code ?? "",
    ops: Number(sp.stat.ops),
    obp: Number(sp.stat.obp),
    slg: Number(sp.stat.slg),
    avg: Number(sp.stat.avg),
    hr: Number(sp.stat.homeRuns),
    ab: Number(sp.stat.atBats),
  }));
}

/** 対左投手(vl) / 対右投手(vr) / 得点圏(risp) を一括取得。 */
export function fetchSituational(id: number, season: number): Promise<Split[]> {
  return fetchSplits(id, season, "vl,vr,risp");
}

/** ホーム/ビジター・デイ/ナイト（h,a,d,n）を一括取得。 */
export function fetchVenueTime(id: number, season: number): Promise<Split[]> {
  return fetchSplits(id, season, "h,a,d,n");
}

export type MonthStat = { month: number; ops: number; hr: number; ab: number };

/** 月別成績。 */
export async function fetchByMonth(id: number, season: number): Promise<MonthStat[]> {
  const res = await fetch(`${API}/people/${id}/stats?stats=byMonth&group=hitting&season=${season}`);
  if (!res.ok) throw new Error(`MLB API ${res.status}`);
  const data = (await res.json()) as { stats?: { splits?: { month?: number; stat: Record<string, string> }[] }[] };
  const splits = data.stats?.[0]?.splits ?? [];
  return splits
    .map((sp) => ({ month: Number(sp.month), ops: Number(sp.stat.ops), hr: Number(sp.stat.homeRuns), ab: Number(sp.stat.atBats) }))
    .sort((a, b) => a.month - b.month);
}
