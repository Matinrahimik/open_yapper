"use client";

import { motion } from "motion/react";

export function HeroSection() {
  return (
    <section
      id="features"
      className="relative flex min-h-[80vh] flex-col items-center justify-center overflow-hidden px-6 py-24 md:px-12 md:py-32"
    >
      {/* Blurred lime blob */}
      <div
        className="pointer-events-none absolute left-1/2 top-1/2 h-[800px] w-[800px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#D4FF00] opacity-40 blur-[120px]"
        aria-hidden
      />

      <motion.div
        className="relative z-10 flex flex-col items-center text-center"
        initial={{ opacity: 0, y: 40 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8, ease: [0.25, 0.46, 0.45, 0.94] }}
      >
        <h1
          className="flex flex-col items-center gap-1 text-[15vw] font-normal uppercase leading-[0.95] tracking-tight md:gap-2 md:text-[180px]"
          style={{ fontFamily: "var(--font-anton), sans-serif" }}
        >
          <span className="whitespace-nowrap">Stop typing,</span>
          <span className="relative inline-block">
            <span className="flex items-center justify-center gap-2 whitespace-nowrap">
              Start{" "}
              <span aria-hidden>📣</span>
              Yapping!
            </span>
            {/* Decorative underline - positioned below text */}
            <svg
              className="absolute left-0 top-full mt-1 w-full"
              viewBox="0 0 200 12"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
              aria-hidden
            >
              <path
                d="M2 8C40 2 80 10 120 4C160 -2 198 6 198 6"
                stroke="#D4FF00"
                strokeWidth="4"
                strokeLinecap="round"
              />
            </svg>
          </span>
        </h1>

        <p className="mt-12 max-w-2xl text-xl font-medium leading-relaxed opacity-80 md:mt-16 md:text-3xl">
          Voice dictation that removes filler words and refines your text.
          Ramble naturally—AI cleans the mess—paste anywhere.
        </p>

        <motion.button
          type="button"
          className="mt-12 flex items-center gap-2 rounded-full border-2 border-[#0A0A0A] bg-[#D4FF00] px-8 py-4 text-lg font-bold uppercase text-[#0A0A0A] shadow-[6px_6px_0_0_#0A0A0A] transition-all hover:-translate-y-1 hover:shadow-[8px_8px_0_0_#0A0A0A]"
          style={{ fontFamily: "var(--font-anton), sans-serif" }}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
        >
          Download Open Yapper now
        </motion.button>
      </motion.div>
    </section>
  );
}
