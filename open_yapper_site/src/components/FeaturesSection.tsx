"use client";

export function FeaturesSection() {
  return (
    <section className="bg-[#D4FF00] px-6 pb-10 pt-28 md:px-12 md:pb-16 md:pt-40">
      <div className="mx-auto max-w-7xl">
        <div className="mb-16 text-center md:mb-20">
          <h2
            className="flex flex-col items-center gap-1 text-[13vw] font-normal uppercase leading-[0.95] tracking-tight text-[#0A0A0A] sm:text-[12vw] md:gap-2 md:text-[72px] lg:text-[120px] xl:text-[160px] 2xl:text-[180px]"
            style={{ fontFamily: "var(--font-anton), sans-serif" }}
          >
            Why Open Yapper?
          </h2>
          <div className="mx-auto mt-12 max-w-3xl space-y-6 text-center">
            <p
              className="mx-auto max-w-[24ch] text-2xl font-bold leading-relaxed text-[#0A0A0A] md:text-3xl"
              style={{ textWrap: "balance" }}
            >
              Because paying $250/year for voice dictation is kind of stupid.
            </p>
            <p className="text-lg font-medium leading-relaxed text-[#0A0A0A]/80 md:text-xl">
              Wispr Flow is cool, but that subscription? No thanks. Open Yapper
              is free, open-source, and does the same thing without holding your
              wallet hostage. You own your data, you see the code, and you keep
              your money. Simple.
            </p>
            <p className="text-sm font-semibold uppercase tracking-widest text-[#0A0A0A]/60">
              Check the README for full specs
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
