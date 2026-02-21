const MARQUEE_PHRASES = [
  "Yap yap yap... paste! ✨",
  "Your brain types faster than your fingers. Fact.",
  "Um. Uh. Like. So. [Deleted]",
  "100% less typing, 100% more coffee ☕",
  "Your fingers can finally take a nap",
  "Rambling is a feature, not a bug",
  "Ums? What ums?",
  "From mouth to document in 0.5 seconds",
  "Words: spoken. Filler: gone. Vibes: immaculate.",
  "The keyboard is jealous ⌨️",
  "Finally, your mouth can keep up with your brain",
  "Yap responsibly",
  "Open Yapper: because typing is overrated",
  "Say it. Clean it. Paste it. Done.",
  "Filler words? We don't know her.",
  "Powered by the sound of your voice (and caffeine)",
  "Your keyboard called. It wants fewer hours.",
  "Talk → Clean → Paste → Profit",
  "100X faster. We did the math.",
  "Dictation without the uh... you know.",
];

function MarqueeContent() {
  return (
    <span
      className="flex shrink-0 items-center gap-0 px-8 text-2xl font-normal uppercase tracking-widest text-[#D4FF00] md:text-3xl"
      style={{ fontFamily: "var(--font-anton), sans-serif" }}
    >
      {MARQUEE_PHRASES.map((phrase, i) => (
        <span key={i} className="flex shrink-0 items-center whitespace-nowrap">
          {phrase}
          {i < MARQUEE_PHRASES.length - 1 && (
            <span className="mx-6 shrink-0 opacity-60">•</span>
          )}
        </span>
      ))}
      <span className="ml-6 shrink-0 opacity-60">•</span>
    </span>
  );
}

export function MarqueeStrip() {
  return (
    <section
      className="overflow-hidden border-y-4 border-[#D4FF00] bg-[#0A0A0A] py-4"
      aria-hidden
    >
      <div className="flex w-max animate-marquee">
        <MarqueeContent />
        <MarqueeContent />
      </div>
    </section>
  );
}
