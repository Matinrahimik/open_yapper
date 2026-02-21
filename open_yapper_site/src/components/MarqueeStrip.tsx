export function MarqueeStrip() {
  return (
    <section
      className="overflow-hidden border-y-4 border-[#D4FF00] bg-[#0A0A0A] py-4"
      aria-hidden
    >
      <div className="flex w-max animate-marquee">
        <span
          className="shrink-0 px-8 text-2xl font-normal uppercase tracking-widest text-[#D4FF00] md:text-3xl"
          style={{ fontFamily: "var(--font-anton), sans-serif" }}
        >
          NO MORE UMS • NO MORE AHS • JUST PERFECT TEXT • LEARNS YOUR STYLE •
        </span>
        <span
          className="shrink-0 px-8 text-2xl font-normal uppercase tracking-widest text-[#D4FF00] md:text-3xl"
          style={{ fontFamily: "var(--font-anton), sans-serif" }}
        >
          NO MORE UMS • NO MORE AHS • JUST PERFECT TEXT • LEARNS YOUR STYLE •
        </span>
      </div>
    </section>
  );
}
