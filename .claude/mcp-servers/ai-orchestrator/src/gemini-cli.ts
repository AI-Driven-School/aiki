import { spawn } from 'child_process';
import { promisify } from 'util';
import { exec as execCallback } from 'child_process';

const exec = promisify(execCallback);

export interface GeminiResult {
  success: boolean;
  output: string;
  error?: string;
}

export class GeminiCLI {
  private projectDir: string;

  constructor(projectDir?: string) {
    this.projectDir = projectDir || process.cwd();
  }

  /**
   * Check if Gemini CLI is installed
   */
  async isAvailable(): Promise<boolean> {
    try {
      await exec('which gemini');
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Execute a prompt using Gemini CLI
   */
  async execute(prompt: string): Promise<GeminiResult> {
    return new Promise((resolve) => {
      // Gemini CLI uses stdin for prompts
      const child = spawn('gemini', [], {
        cwd: this.projectDir,
        shell: true,
      });

      let stdout = '';
      let stderr = '';

      child.stdout?.on('data', (data) => {
        stdout += data.toString();
      });

      child.stderr?.on('data', (data) => {
        stderr += data.toString();
      });

      child.on('close', (code) => {
        resolve({
          success: code === 0,
          output: stdout || stderr,
          error: code !== 0 ? stderr : undefined,
        });
      });

      child.on('error', (err) => {
        resolve({
          success: false,
          output: '',
          error: err.message,
        });
      });

      // Send prompt to stdin
      child.stdin?.write(prompt);
      child.stdin?.end();
    });
  }

  /**
   * Research a topic
   */
  async research(topic: string, depth: 'quick' | 'detailed' = 'detailed'): Promise<GeminiResult> {
    const prompt = depth === 'quick'
      ? `Briefly explain: ${topic}\n\nProvide:\n- Key points (3-5 bullets)\n- Main pros/cons\n- Quick recommendation`
      : `Provide comprehensive research on: ${topic}\n\nInclude:\n1. Overview\n2. Key concepts\n3. Current trends\n4. Comparison of options\n5. Best practices\n6. Recommendations`;

    return this.execute(prompt);
  }

  /**
   * Compare options
   */
  async compare(options: string[], criteria?: string[]): Promise<GeminiResult> {
    const criteriaText = criteria?.length
      ? `Criteria: ${criteria.join(', ')}`
      : 'Use standard criteria (performance, ease of use, documentation, community)';

    const prompt = `Compare these options:\n${options.map((o, i) => `${i + 1}. ${o}`).join('\n')}\n\n${criteriaText}\n\nProvide:\n1. Feature comparison table\n2. Analysis of each\n3. Use case recommendations\n4. Final recommendation`;

    return this.execute(prompt);
  }

  /**
   * Analyze codebase
   */
  async analyzeCodebase(description: string, files?: string[]): Promise<GeminiResult> {
    const filesContext = files?.length ? `\n\nKey files:\n${files.join('\n')}` : '';
    const prompt = `Analyze this codebase:\n${description}${filesContext}\n\nProvide:\n1. Architecture overview\n2. Tech stack analysis\n3. Code quality assessment\n4. Improvement suggestions\n5. Security considerations`;

    return this.execute(prompt);
  }

  /**
   * Suggest architecture
   */
  async suggestArchitecture(requirements: string): Promise<GeminiResult> {
    const prompt = `Based on these requirements:\n${requirements}\n\nSuggest an architecture including:\n1. Recommended pattern\n2. Tech stack\n3. Component diagram (text-based)\n4. Data flow\n5. Scalability considerations`;

    return this.execute(prompt);
  }
}
