import { spawn } from 'child_process';
import { promisify } from 'util';
import { exec as execCallback } from 'child_process';

const exec = promisify(execCallback);

export interface CodexResult {
  success: boolean;
  output: string;
  error?: string;
}

export class CodexCLI {
  private projectDir: string;

  constructor(projectDir?: string) {
    this.projectDir = projectDir || process.cwd();
  }

  /**
   * Check if Codex CLI is installed
   */
  async isAvailable(): Promise<boolean> {
    try {
      await exec('which codex');
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Execute a task using Codex CLI (full-auto mode)
   */
  async executeTask(task: string): Promise<CodexResult> {
    return new Promise((resolve) => {
      const args = ['exec', '--full-auto', task];
      const child = spawn('codex', args, {
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
    });
  }

  /**
   * Code review using Codex CLI
   */
  async review(options?: { base?: string; uncommitted?: boolean }): Promise<CodexResult> {
    return new Promise((resolve) => {
      const args = ['review'];
      if (options?.uncommitted) {
        args.push('--uncommitted');
      }
      if (options?.base) {
        args.push('--base', options.base);
      }

      const child = spawn('codex', args, {
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
    });
  }

  /**
   * Generate tests for specific file(s)
   */
  async generateTests(files: string[]): Promise<CodexResult> {
    const task = `Generate comprehensive unit tests for: ${files.join(', ')}`;
    return this.executeTask(task);
  }

  /**
   * Refactor code
   */
  async refactor(instructions: string, files?: string[]): Promise<CodexResult> {
    const filesPart = files?.length ? ` in files: ${files.join(', ')}` : '';
    const task = `Refactor${filesPart}: ${instructions}`;
    return this.executeTask(task);
  }

  /**
   * Implement a feature
   */
  async implement(feature: string): Promise<CodexResult> {
    return this.executeTask(`Implement: ${feature}`);
  }
}
