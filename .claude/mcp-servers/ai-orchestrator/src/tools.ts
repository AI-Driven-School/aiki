import { z } from 'zod';

// Tool schemas
export const delegateToCodexSchema = z.object({
  task: z.string().describe('The implementation task to delegate'),
  taskType: z.enum(['implement', 'test', 'refactor', 'review']).describe('Type of task'),
  files: z.array(z.string()).optional().describe('Specific files to work on'),
});

export const delegateToGeminiSchema = z.object({
  task: z.string().describe('The research or analysis task'),
  taskType: z.enum(['research', 'compare', 'analyze', 'architecture']).describe('Type of task'),
  options: z.array(z.string()).optional().describe('Options to compare (for compare task)'),
  criteria: z.array(z.string()).optional().describe('Evaluation criteria (for compare task)'),
  files: z.array(z.string()).optional().describe('Files to analyze (for analyze task)'),
  depth: z.enum(['quick', 'detailed']).optional().describe('Research depth'),
});

export const autoDelegateSchema = z.object({
  message: z.string().describe('The user message to analyze and delegate'),
});

// Task classification
export interface TaskClassification {
  aiTarget: 'claude' | 'codex' | 'gemini';
  confidence: number;
  reasoning: string;
  suggestedTaskType: string;
}

export function classifyTask(message: string): TaskClassification {
  const lowerMessage = message.toLowerCase();

  // Codex patterns (implementation)
  const codexPatterns = [
    { pattern: /実装|implement|create|build|write code|コードを書/, weight: 0.9 },
    { pattern: /テスト|test|unit test|integration test/, weight: 0.85 },
    { pattern: /リファクタ|refactor|改善|optimize code/, weight: 0.8 },
    { pattern: /fix|バグ|bug|修正/, weight: 0.7 },
    { pattern: /add feature|機能追加/, weight: 0.85 },
    { pattern: /レビュー|review|チェック/, weight: 0.75 },
  ];

  // Gemini patterns (research/analysis)
  const geminiPatterns = [
    { pattern: /調査|research|investigate|調べ/, weight: 0.9 },
    { pattern: /比較|compare|versus|vs|選定/, weight: 0.9 },
    { pattern: /分析|analyze|analysis/, weight: 0.85 },
    { pattern: /アーキテクチャ|architecture|設計提案/, weight: 0.8 },
    { pattern: /ライブラリ|library|framework|フレームワーク/, weight: 0.75 },
    { pattern: /ベストプラクティス|best practice|推奨/, weight: 0.7 },
    { pattern: /トレンド|trend|最新/, weight: 0.75 },
  ];

  // Claude patterns (design/explanation)
  const claudePatterns = [
    { pattern: /要件|requirement|仕様/, weight: 0.85 },
    { pattern: /説明|explain|解説/, weight: 0.8 },
    { pattern: /質問|question|どう思/, weight: 0.7 },
    { pattern: /設計|design(?!.*アーキテクチャ)/, weight: 0.75 },
  ];

  let codexScore = 0;
  let geminiScore = 0;
  let claudeScore = 0;
  let codexTaskType = 'implement';
  let geminiTaskType = 'research';

  for (const { pattern, weight } of codexPatterns) {
    if (pattern.test(lowerMessage)) {
      codexScore += weight;
      if (/テスト|test/.test(lowerMessage)) codexTaskType = 'test';
      if (/リファクタ|refactor/.test(lowerMessage)) codexTaskType = 'refactor';
      if (/レビュー|review/.test(lowerMessage)) codexTaskType = 'review';
    }
  }

  for (const { pattern, weight } of geminiPatterns) {
    if (pattern.test(lowerMessage)) {
      geminiScore += weight;
      if (/比較|compare/.test(lowerMessage)) geminiTaskType = 'compare';
      if (/分析|analyze/.test(lowerMessage)) geminiTaskType = 'analyze';
      if (/アーキテクチャ|architecture/.test(lowerMessage)) geminiTaskType = 'architecture';
    }
  }

  for (const { pattern, weight } of claudePatterns) {
    if (pattern.test(lowerMessage)) {
      claudeScore += weight;
    }
  }

  const maxScore = Math.max(codexScore, geminiScore, claudeScore);

  if (maxScore < 0.5) {
    return {
      aiTarget: 'claude',
      confidence: 0.5,
      reasoning: 'タスクの分類が不明確なため、Claudeで処理します',
      suggestedTaskType: 'general',
    };
  }

  if (codexScore === maxScore) {
    return {
      aiTarget: 'codex',
      confidence: Math.min(codexScore / 2, 1),
      reasoning: `実装タスクを検出: ${codexTaskType}`,
      suggestedTaskType: codexTaskType,
    };
  }

  if (geminiScore === maxScore) {
    return {
      aiTarget: 'gemini',
      confidence: Math.min(geminiScore / 2, 1),
      reasoning: `調査/分析タスクを検出: ${geminiTaskType}`,
      suggestedTaskType: geminiTaskType,
    };
  }

  return {
    aiTarget: 'claude',
    confidence: Math.min(claudeScore / 2, 1),
    reasoning: '設計/説明タスクを検出',
    suggestedTaskType: 'design',
  };
}

export type DelegateToCodexInput = z.infer<typeof delegateToCodexSchema>;
export type DelegateToGeminiInput = z.infer<typeof delegateToGeminiSchema>;
export type AutoDelegateInput = z.infer<typeof autoDelegateSchema>;
