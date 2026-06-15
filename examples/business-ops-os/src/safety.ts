// aiki safety layer — cost cap, circuit breaker, approval gate.
// Keeps autonomous agents from runaway cost / cascading failure / unapproved destructive actions.

export class Safety {
  private spent = 0;
  private fails = 0;

  constructor(
    private readonly budgetUsd: number,
    private readonly maxFails = 3,
    private readonly requireApproval = false,
  ) {}

  /** Accumulate estimated cost; throws when the cycle budget is exceeded. */
  charge(usd: number): void {
    this.spent += usd;
    if (this.spent > this.budgetUsd) {
      throw new Error(`budget exceeded: $${this.spent.toFixed(3)} > $${this.budgetUsd.toFixed(3)}`);
    }
  }

  record(ok: boolean): void {
    if (!ok) this.fails++;
  }

  /** Circuit breaker: stop scheduling once too many failures or the budget is reached. */
  canProceed(): boolean {
    return this.fails < this.maxFails && this.spent <= this.budgetUsd;
  }

  /** Human-in-the-loop gate for destructive / high-cost actions. */
  approve(action: string): void {
    if (this.requireApproval) {
      throw new Error(`approval required for: ${action} (set AIKI_REQUIRE_APPROVAL=false to auto-run)`);
    }
  }

  spentUsd(): number {
    return this.spent;
  }
}
