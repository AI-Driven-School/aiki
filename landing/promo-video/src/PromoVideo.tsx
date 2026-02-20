import React from 'react';
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  Sequence,
  Easing,
} from 'remotion';

// Colors
const COLORS = {
  bg: '#0a0a0f',
  bgSecondary: '#12121a',
  text: '#e8e8f0',
  muted: '#8888a0',
  claude: '#d4a574',
  codex: '#4ade80',
  gemini: '#60a5fa',
  accent: '#22c55e',
};

// Title Scene Component
const TitleScene: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  const titleOpacity = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: 'clamp',
  });

  const titleY = spring({
    frame,
    fps,
    from: 50,
    to: 0,
    config: {damping: 12},
  });

  const number2xScale = spring({
    frame: frame - 30,
    fps,
    from: 0,
    to: 1,
    config: {damping: 8, mass: 0.5},
  });

  const number75Scale = spring({
    frame: frame - 45,
    fps,
    from: 0,
    to: 1,
    config: {damping: 8, mass: 0.5},
  });

  const subtitleOpacity = interpolate(frame, [60, 80], [0, 1], {
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill
      style={{
        background: COLORS.bg,
        justifyContent: 'center',
        alignItems: 'center',
      }}
    >
      {/* Grid background */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundImage: `
            linear-gradient(rgba(255,255,255,0.02) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,255,255,0.02) 1px, transparent 1px)
          `,
          backgroundSize: '60px 60px',
        }}
      />

      {/* Main title */}
      <div
        style={{
          opacity: titleOpacity,
          transform: `translateY(${titleY}px)`,
          textAlign: 'center',
        }}
      >
        <h1
          style={{
            fontFamily: 'system-ui, sans-serif',
            fontSize: 72,
            fontWeight: 800,
            color: COLORS.text,
            margin: 0,
            lineHeight: 1.2,
          }}
        >
          実装
          <span
            style={{
              display: 'inline-block',
              transform: `scale(${number2xScale})`,
              background: `linear-gradient(135deg, ${COLORS.codex}, ${COLORS.gemini})`,
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              marginLeft: 10,
              marginRight: 10,
            }}
          >
            2倍速
          </span>
        </h1>
        <h1
          style={{
            fontFamily: 'system-ui, sans-serif',
            fontSize: 72,
            fontWeight: 800,
            color: COLORS.text,
            margin: 0,
            marginTop: -10,
            lineHeight: 1.2,
          }}
        >
          コスト
          <span
            style={{
              display: 'inline-block',
              transform: `scale(${number75Scale})`,
              background: `linear-gradient(135deg, ${COLORS.codex}, ${COLORS.gemini})`,
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              marginLeft: 10,
            }}
          >
            75%
          </span>
          削減
        </h1>
      </div>

      {/* Subtitle */}
      <p
        style={{
          opacity: subtitleOpacity,
          fontFamily: 'system-ui, sans-serif',
          fontSize: 28,
          color: COLORS.muted,
          marginTop: 40,
          textAlign: 'center',
        }}
      >
        3つのAIで、開発を加速
      </p>
    </AbsoluteFill>
  );
};

// AI Card Component
const AICard: React.FC<{
  name: string;
  role: string;
  color: string;
  icon: string;
  delay: number;
}> = ({name, role, color, icon, delay}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  const scale = spring({
    frame: frame - delay,
    fps,
    from: 0,
    to: 1,
    config: {damping: 10, mass: 0.8},
  });

  const glow = interpolate(
    Math.sin((frame - delay) * 0.1),
    [-1, 1],
    [0.3, 0.6],
  );

  return (
    <div
      style={{
        transform: `scale(${scale})`,
        width: 200,
        padding: 24,
        background: COLORS.bgSecondary,
        borderRadius: 12,
        textAlign: 'center',
        border: `2px solid ${color}40`,
        boxShadow: `0 0 30px ${color}${Math.round(glow * 100)}`,
      }}
    >
      <div
        style={{
          width: 64,
          height: 64,
          borderRadius: 16,
          background: `linear-gradient(135deg, ${color}, ${color}99)`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          margin: '0 auto 16px',
          fontFamily: 'monospace',
          fontSize: 28,
          fontWeight: 700,
          color: '#fff',
        }}
      >
        {icon}
      </div>
      <h3
        style={{
          fontFamily: 'system-ui, sans-serif',
          fontSize: 24,
          fontWeight: 700,
          color,
          margin: 0,
        }}
      >
        {name}
      </h3>
      <p
        style={{
          fontFamily: 'system-ui, sans-serif',
          fontSize: 16,
          color: COLORS.muted,
          margin: '8px 0 0',
        }}
      >
        {role}
      </p>
    </div>
  );
};

// 3 AI Cards Scene
const AICardsScene: React.FC = () => {
  const frame = useCurrentFrame();

  const titleOpacity = interpolate(frame, [0, 15], [0, 1], {
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill
      style={{
        background: COLORS.bg,
        justifyContent: 'center',
        alignItems: 'center',
      }}
    >
      {/* Grid background */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundImage: `
            linear-gradient(rgba(255,255,255,0.02) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,255,255,0.02) 1px, transparent 1px)
          `,
          backgroundSize: '60px 60px',
        }}
      />

      {/* Cards */}
      <div
        style={{
          display: 'flex',
          gap: 32,
          alignItems: 'center',
        }}
      >
        <AICard
          name="Claude"
          role="設計・判断"
          color={COLORS.claude}
          icon="C"
          delay={10}
        />
        <div
          style={{
            opacity: interpolate(frame, [30, 45], [0, 1]),
            fontSize: 32,
            color: COLORS.muted,
          }}
        >
          →
        </div>
        <AICard
          name="Codex"
          role="実装・テスト"
          color={COLORS.codex}
          icon="X"
          delay={25}
        />
        <div
          style={{
            opacity: interpolate(frame, [45, 60], [0, 1]),
            fontSize: 32,
            color: COLORS.muted,
          }}
        >
          →
        </div>
        <AICard
          name="Gemini"
          role="大規模解析"
          color={COLORS.gemini}
          icon="G"
          delay={40}
        />
      </div>

      {/* Title below */}
      <p
        style={{
          position: 'absolute',
          bottom: 60,
          opacity: interpolate(frame, [60, 80], [0, 1]),
          fontFamily: 'system-ui, sans-serif',
          fontSize: 24,
          color: COLORS.text,
        }}
      >
        適材適所で分業
      </p>
    </AbsoluteFill>
  );
};

// Terminal Animation Scene
const TerminalScene: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  const terminalScale = spring({
    frame,
    fps,
    from: 0.9,
    to: 1,
    config: {damping: 15},
  });

  const lines = [
    {text: '❯ /project ユーザー認証', color: COLORS.codex, frame: 15},
    {text: '', frame: 25},
    {text: '[1/6] 要件定義... (Claude)', color: COLORS.claude, frame: 35},
    {text: '      → docs/requirements/auth.md ✓', color: COLORS.gemini, frame: 45},
    {text: '', frame: 50},
    {text: '[3/6] 実装中... (Codex - full-auto) ★', color: COLORS.codex, frame: 60},
    {text: '      → src/app/login/page.tsx', color: COLORS.gemini, frame: 70},
    {text: '      → src/lib/api/auth.ts', color: COLORS.gemini, frame: 78},
    {text: '', frame: 85},
    {text: '[5/6] レビュー... (Claude) ✓', color: COLORS.claude, frame: 95},
    {text: '', frame: 105},
    {text: '✅ デプロイ完了！', color: COLORS.codex, frame: 115},
    {text: '   https://my-app.vercel.app', color: COLORS.gemini, frame: 125},
  ];

  return (
    <AbsoluteFill
      style={{
        background: COLORS.bg,
        justifyContent: 'center',
        alignItems: 'center',
      }}
    >
      <div
        style={{
          transform: `scale(${terminalScale})`,
          width: 700,
          background: '#161b22',
          borderRadius: 12,
          overflow: 'hidden',
          boxShadow: '0 25px 60px rgba(0,0,0,0.5)',
        }}
      >
        {/* Terminal header */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            padding: '12px 16px',
            background: '#21262d',
          }}
        >
          <div style={{width: 12, height: 12, borderRadius: '50%', background: '#ff5f56'}} />
          <div style={{width: 12, height: 12, borderRadius: '50%', background: '#ffbd2e'}} />
          <div style={{width: 12, height: 12, borderRadius: '50%', background: '#27c93f'}} />
          <span
            style={{
              flex: 1,
              textAlign: 'center',
              fontFamily: 'monospace',
              fontSize: 14,
              color: COLORS.muted,
            }}
          >
            claude — ~/my-app
          </span>
        </div>

        {/* Terminal body */}
        <div
          style={{
            padding: 20,
            fontFamily: 'monospace',
            fontSize: 16,
            lineHeight: 1.8,
            minHeight: 350,
          }}
        >
          {lines.map((line, i) => {
            const opacity = interpolate(
              frame,
              [line.frame, line.frame + 10],
              [0, 1],
              {extrapolateRight: 'clamp', extrapolateLeft: 'clamp'},
            );
            return (
              <div
                key={i}
                style={{
                  opacity,
                  color: line.color || COLORS.text,
                  transform: `translateY(${interpolate(
                    frame,
                    [line.frame, line.frame + 10],
                    [10, 0],
                    {extrapolateRight: 'clamp', extrapolateLeft: 'clamp'},
                  )}px)`,
                }}
              >
                {line.text || '\u00A0'}
              </div>
            );
          })}
        </div>
      </div>
    </AbsoluteFill>
  );
};

// Stats Scene
const StatsScene: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  const stat1 = spring({frame: frame - 10, fps, from: 0, to: 2, config: {damping: 12}});
  const stat2 = spring({frame: frame - 25, fps, from: 0, to: 75, config: {damping: 12}});
  const stat3 = spring({frame: frame - 40, fps, from: 0, to: 6, config: {damping: 12}});

  return (
    <AbsoluteFill
      style={{
        background: COLORS.bg,
        justifyContent: 'center',
        alignItems: 'center',
      }}
    >
      <div style={{display: 'flex', gap: 80}}>
        <div style={{textAlign: 'center'}}>
          <div
            style={{
              fontFamily: 'system-ui, sans-serif',
              fontSize: 100,
              fontWeight: 800,
              color: COLORS.codex,
            }}
          >
            {Math.round(stat1)}x
          </div>
          <div style={{fontSize: 24, color: COLORS.muted}}>実装速度</div>
        </div>
        <div style={{textAlign: 'center'}}>
          <div
            style={{
              fontFamily: 'system-ui, sans-serif',
              fontSize: 100,
              fontWeight: 800,
              color: COLORS.codex,
            }}
          >
            {Math.round(stat2)}%
          </div>
          <div style={{fontSize: 24, color: COLORS.muted}}>コスト削減</div>
        </div>
        <div style={{textAlign: 'center'}}>
          <div
            style={{
              fontFamily: 'system-ui, sans-serif',
              fontSize: 100,
              fontWeight: 800,
              color: COLORS.codex,
            }}
          >
            {Math.round(stat3)}
          </div>
          <div style={{fontSize: 24, color: COLORS.muted}}>承認フェーズ</div>
        </div>
      </div>
    </AbsoluteFill>
  );
};

// CTA Scene
const CTAScene: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  const scale = spring({frame, fps, from: 0.8, to: 1, config: {damping: 10}});
  const opacity = interpolate(frame, [0, 20], [0, 1]);

  const buttonPulse = interpolate(
    Math.sin(frame * 0.15),
    [-1, 1],
    [1, 1.05],
  );

  return (
    <AbsoluteFill
      style={{
        background: COLORS.bg,
        justifyContent: 'center',
        alignItems: 'center',
      }}
    >
      <div
        style={{
          opacity,
          transform: `scale(${scale})`,
          textAlign: 'center',
        }}
      >
        <h2
          style={{
            fontFamily: 'system-ui, sans-serif',
            fontSize: 48,
            fontWeight: 700,
            color: COLORS.text,
            marginBottom: 20,
          }}
        >
          今すぐ試す
        </h2>

        <div
          style={{
            transform: `scale(${buttonPulse})`,
            display: 'inline-block',
            padding: '20px 40px',
            background: `linear-gradient(135deg, ${COLORS.codex}, #16a34a)`,
            borderRadius: 8,
            fontFamily: 'monospace',
            fontSize: 24,
            fontWeight: 600,
            color: '#000',
            boxShadow: `0 0 40px ${COLORS.codex}60`,
          }}
        >
          github.com/AI-Driven-School/aiki
        </div>

        <div
          style={{
            marginTop: 40,
            display: 'flex',
            justifyContent: 'center',
            gap: 16,
          }}
        >
          <div
            style={{
              width: 16,
              height: 16,
              borderRadius: '50%',
              background: COLORS.claude,
            }}
          />
          <div
            style={{
              width: 16,
              height: 16,
              borderRadius: '50%',
              background: COLORS.codex,
            }}
          />
          <div
            style={{
              width: 16,
              height: 16,
              borderRadius: '50%',
              background: COLORS.gemini,
            }}
          />
        </div>

        <p
          style={{
            marginTop: 20,
            fontFamily: 'monospace',
            fontSize: 20,
            color: COLORS.muted,
          }}
        >
          Phase 1: 完全無料
        </p>
      </div>
    </AbsoluteFill>
  );
};

// Main Promo Video
export const PromoVideo: React.FC = () => {
  return (
    <AbsoluteFill style={{background: COLORS.bg}}>
      <Sequence from={0} durationInFrames={120}>
        <TitleScene />
      </Sequence>
      <Sequence from={120} durationInFrames={100}>
        <AICardsScene />
      </Sequence>
      <Sequence from={220} durationInFrames={140}>
        <TerminalScene />
      </Sequence>
      <Sequence from={360} durationInFrames={90}>
        <CTAScene />
      </Sequence>
    </AbsoluteFill>
  );
};
