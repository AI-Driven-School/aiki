# Landing Page Assets

Binary assets (`.mp4`, `.gif`) are not tracked in git to keep the repository lightweight.

## How to obtain assets

### Option 1: GitHub Releases

Download pre-built assets from the [Releases page](https://github.com/AI-Driven-School/aiki/releases).

### Option 2: Generate locally

```bash
cd landing/promo-video
npm install
npx remotion render src/index.ts Promo out/promo.mp4
```

### Option 3: Use placeholders

For development, any placeholder image/video will work. The README references `landing/promo.gif`.

## Expected files

| File | Description |
|------|-------------|
| `promo.mp4` | Full promotional video |
| `promo.gif` | Animated GIF for README embed |
| `demo.mp4` | Feature demonstration video |
| `demo.gif` | Feature demonstration GIF |
