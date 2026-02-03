#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

import { CodexCLI } from './codex-cli.js';
import { GeminiCLI } from './gemini-cli.js';
import {
  classifyTask,
  delegateToCodexSchema,
  delegateToGeminiSchema,
  autoDelegateSchema,
  type DelegateToCodexInput,
  type DelegateToGeminiInput,
  type AutoDelegateInput,
} from './tools.js';

// Initialize CLI clients
const codexCLI = new CodexCLI();
const geminiCLI = new GeminiCLI();

// Create server
const server = new Server(
  {
    name: 'ai-orchestrator',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'delegate_to_codex',
        description: 'Delegate implementation tasks to Codex CLI ($0). Use for: implementing features, writing tests, refactoring code, code review.',
        inputSchema: {
          type: 'object',
          properties: {
            task: { type: 'string', description: 'The implementation task' },
            taskType: {
              type: 'string',
              enum: ['implement', 'test', 'refactor', 'review'],
              description: 'Type of task',
            },
            files: {
              type: 'array',
              items: { type: 'string' },
              description: 'Specific files to work on',
            },
          },
          required: ['task', 'taskType'],
        },
      },
      {
        name: 'delegate_to_gemini',
        description: 'Delegate research/analysis tasks to Gemini CLI (free). Use for: research, comparisons, codebase analysis, architecture suggestions.',
        inputSchema: {
          type: 'object',
          properties: {
            task: { type: 'string', description: 'The research task' },
            taskType: {
              type: 'string',
              enum: ['research', 'compare', 'analyze', 'architecture'],
              description: 'Type of task',
            },
            options: {
              type: 'array',
              items: { type: 'string' },
              description: 'Options to compare',
            },
            criteria: {
              type: 'array',
              items: { type: 'string' },
              description: 'Evaluation criteria',
            },
            files: {
              type: 'array',
              items: { type: 'string' },
              description: 'Files to analyze',
            },
            depth: {
              type: 'string',
              enum: ['quick', 'detailed'],
              description: 'Research depth',
            },
          },
          required: ['task', 'taskType'],
        },
      },
      {
        name: 'auto_delegate',
        description: 'Automatically analyze and delegate a task to the appropriate AI CLI (Claude, Codex, or Gemini).',
        inputSchema: {
          type: 'object',
          properties: {
            message: { type: 'string', description: 'The user message to analyze' },
          },
          required: ['message'],
        },
      },
      {
        name: 'get_orchestration_status',
        description: 'Get the status of available AI CLI tools',
        inputSchema: {
          type: 'object',
          properties: {},
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'delegate_to_codex': {
        const input = delegateToCodexSchema.parse(args) as DelegateToCodexInput;

        // Check if Codex CLI is available
        const isAvailable = await codexCLI.isAvailable();
        if (!isAvailable) {
          return {
            content: [
              {
                type: 'text',
                text: `## Codex CLI Not Found

Codex CLI is not installed. Please install it:

\`\`\`bash
# Option 1: Use ChatGPT Pro web interface
# https://chatgpt.com

# Option 2: Install Codex CLI (if available)
npm install -g @openai/codex
\`\`\`

**Task to execute manually:**
${input.task}`,
              },
            ],
          };
        }

        let result;
        switch (input.taskType) {
          case 'review':
            result = await codexCLI.review({ uncommitted: true });
            break;
          case 'test':
            result = await codexCLI.generateTests(input.files || []);
            break;
          case 'refactor':
            result = await codexCLI.refactor(input.task, input.files);
            break;
          case 'implement':
          default:
            result = await codexCLI.implement(input.task);
        }

        return {
          content: [
            {
              type: 'text',
              text: `## Codex Result (${input.taskType})

${result.success ? '✅ Success' : '❌ Failed'}

${result.output}${result.error ? `\n\n**Error:** ${result.error}` : ''}`,
            },
          ],
        };
      }

      case 'delegate_to_gemini': {
        const input = delegateToGeminiSchema.parse(args) as DelegateToGeminiInput;

        // Check if Gemini CLI is available
        const isAvailable = await geminiCLI.isAvailable();
        if (!isAvailable) {
          return {
            content: [
              {
                type: 'text',
                text: `## Gemini CLI Not Found

Gemini CLI is not installed. Please install it:

\`\`\`bash
# Install Gemini CLI
pip install google-generativeai
# or
npm install -g @google/generative-ai
\`\`\`

**Task to execute manually:**
${input.task}`,
              },
            ],
          };
        }

        let result;
        switch (input.taskType) {
          case 'compare':
            if (!input.options?.length) {
              throw new Error('options are required for compare tasks');
            }
            result = await geminiCLI.compare(input.options, input.criteria);
            break;
          case 'analyze':
            result = await geminiCLI.analyzeCodebase(input.task, input.files);
            break;
          case 'architecture':
            result = await geminiCLI.suggestArchitecture(input.task);
            break;
          case 'research':
          default:
            result = await geminiCLI.research(input.task, input.depth || 'detailed');
        }

        return {
          content: [
            {
              type: 'text',
              text: `## Gemini Result (${input.taskType})

${result.success ? '✅ Success' : '❌ Failed'}

${result.output}${result.error ? `\n\n**Error:** ${result.error}` : ''}`,
            },
          ],
        };
      }

      case 'auto_delegate': {
        const input = autoDelegateSchema.parse(args) as AutoDelegateInput;
        const classification = classifyTask(input.message);

        // Return classification for Claude to handle
        if (classification.aiTarget === 'claude') {
          return {
            content: [
              {
                type: 'text',
                text: `## タスク分類結果

**担当AI**: Claude（このまま処理）
**信頼度**: ${(classification.confidence * 100).toFixed(0)}%
**理由**: ${classification.reasoning}

このタスクはClaudeで処理するのが最適です。`,
              },
            ],
          };
        }

        // For Codex tasks
        if (classification.aiTarget === 'codex') {
          const isAvailable = await codexCLI.isAvailable();
          if (!isAvailable) {
            return {
              content: [
                {
                  type: 'text',
                  text: `## 自動委譲: Codex (CLI未インストール)

**タスクタイプ**: ${classification.suggestedTaskType}
**信頼度**: ${(classification.confidence * 100).toFixed(0)}%

Codex CLI がインストールされていません。
ChatGPT Pro (https://chatgpt.com) で以下を実行してください:

---
${input.message}
---`,
                },
              ],
            };
          }

          const result = await codexCLI.executeTask(input.message);
          return {
            content: [
              {
                type: 'text',
                text: `## 自動委譲: Codex

**タスクタイプ**: ${classification.suggestedTaskType}
**信頼度**: ${(classification.confidence * 100).toFixed(0)}%
**理由**: ${classification.reasoning}

---

### Codex出力:

${result.output}`,
              },
            ],
          };
        }

        // For Gemini tasks
        if (classification.aiTarget === 'gemini') {
          const isAvailable = await geminiCLI.isAvailable();
          if (!isAvailable) {
            return {
              content: [
                {
                  type: 'text',
                  text: `## 自動委譲: Gemini (CLI未インストール)

**タスクタイプ**: ${classification.suggestedTaskType}
**信頼度**: ${(classification.confidence * 100).toFixed(0)}%

Gemini CLI がインストールされていません。
Gemini (https://gemini.google.com) で以下を実行してください:

---
${input.message}
---`,
                },
              ],
            };
          }

          const result = await geminiCLI.execute(input.message);
          return {
            content: [
              {
                type: 'text',
                text: `## 自動委譲: Gemini

**タスクタイプ**: ${classification.suggestedTaskType}
**信頼度**: ${(classification.confidence * 100).toFixed(0)}%
**理由**: ${classification.reasoning}

---

### Gemini出力:

${result.output}`,
              },
            ],
          };
        }

        return {
          content: [
            {
              type: 'text',
              text: 'タスクの分類に失敗しました。',
            },
          ],
        };
      }

      case 'get_orchestration_status': {
        const codexAvailable = await codexCLI.isAvailable();
        const geminiAvailable = await geminiCLI.isAvailable();

        return {
          content: [
            {
              type: 'text',
              text: `## AI Orchestration Status

| AI | CLI Status | Role | Cost |
|----|------------|------|------|
| Claude | ✅ Active | 設計・レビュー | 従量課金 |
| Codex | ${codexAvailable ? '✅ Available' : '❌ Not Installed'} | 実装・テスト | **$0** |
| Gemini | ${geminiAvailable ? '✅ Available' : '❌ Not Installed'} | 調査・分析 | **無料** |

${!codexAvailable ? '\n⚠️ Codex CLI: ChatGPT Pro契約でfull-auto使用可能' : ''}
${!geminiAvailable ? '\n⚠️ Gemini CLI: 無料で使用可能' : ''}`,
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      content: [
        {
          type: 'text',
          text: `Error: ${errorMessage}`,
        },
      ],
      isError: true,
    };
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('AI Orchestrator MCP Server running on stdio');
}

main().catch(console.error);
