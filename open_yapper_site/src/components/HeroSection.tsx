"use client";

import { motion } from "motion/react";

export function HeroSection() {
  return (
    <section
      id="features"
      className="relative flex min-h-[80vh] flex-col items-center justify-center overflow-hidden bg-white px-6 py-24 md:px-12 md:py-32"
    >
      <motion.div
        className="relative z-10 flex flex-col items-center text-center"
        initial={{ opacity: 0, y: 40 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8, ease: [0.25, 0.46, 0.45, 0.94] }}
      >
        <h1
          className="flex flex-col items-center gap-1 text-[13vw] font-normal uppercase leading-[0.95] tracking-tight sm:text-[12vw] md:gap-2 md:text-[72px] lg:text-[120px] xl:text-[160px] 2xl:text-[180px]"
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

        <p className="mt-10 max-w-2xl text-base font-medium leading-relaxed opacity-80 sm:text-lg md:mt-14 md:text-2xl lg:text-3xl">
          Voice dictation that removes filler words and refines your text.
          Ramble naturally—AI cleans the mess—paste anywhere.
        </p>

        <div className="mt-12 flex flex-col items-center gap-4 sm:flex-row">
          <motion.a
            href="https://github.com/Matinrahimik/open_yapper/releases/latest/download/open_yapper.dmg"
            download="Open Yapper.dmg"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 rounded-2xl border-2 border-[#0A0A0A] bg-[#D4FF00] px-5 py-2.5 text-sm font-medium uppercase tracking-[0.08em] text-[#0A0A0A] shadow-[5px_5px_0_0_#0A0A0A] transition-all hover:-translate-y-1 hover:shadow-[7px_7px_0_0_#0A0A0A] sm:px-6 sm:py-3 sm:text-base md:px-8 md:py-4 md:text-lg"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <svg
              aria-hidden
              className="h-4 w-4 sm:h-5 sm:w-5"
              viewBox="0 0 24 24"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M12 4V15"
                stroke="currentColor"
                strokeWidth="2.2"
                strokeLinecap="round"
              />
              <path
                d="M7 11L12 16L17 11"
                stroke="currentColor"
                strokeWidth="2.2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <path
                d="M5 20H19"
                stroke="currentColor"
                strokeWidth="2.2"
                strokeLinecap="round"
              />
            </svg>
            Download Open Yapper
          </motion.a>

          <motion.a
            href="https://github.com/Matinrahimik/open_yapper"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 rounded-2xl border-2 border-[#0A0A0A] bg-[#0A0A0A] px-5 py-2.5 text-sm font-medium uppercase tracking-[0.08em] text-[#F4F4F0] shadow-[5px_5px_0_0_#D4FF00] transition-all hover:-translate-y-1 hover:shadow-[7px_7px_0_0_#D4FF00] sm:px-6 sm:py-3 sm:text-base md:px-8 md:py-4 md:text-lg"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <svg
              aria-hidden
              className="h-4 w-4 sm:h-5 sm:w-5"
              viewBox="0 0 24 24"
              fill="currentColor"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path d="M12 2C6.48 2 2 6.58 2 12.22C2 16.73 4.87 20.56 8.84 21.91C9.34 22.01 9.52 21.69 9.52 21.42C9.52 21.17 9.51 20.33 9.5 19.42C6.73 20.04 6.14 18.24 6.14 18.24C5.68 17.04 5.03 16.72 5.03 16.72C4.12 16.08 5.1 16.1 5.1 16.1C6.11 16.17 6.64 17.16 6.64 17.16C7.54 18.74 9 18.28 9.58 18.01C9.67 17.34 9.93 16.88 10.22 16.61C8.01 16.35 5.69 15.46 5.69 11.5C5.69 10.37 6.08 9.45 6.72 8.73C6.62 8.47 6.28 7.43 6.82 6.02C6.82 6.02 7.66 5.74 9.49 7.01C10.29 6.78 11.15 6.66 12 6.66C12.85 6.66 13.71 6.78 14.51 7.01C16.34 5.74 17.18 6.02 17.18 6.02C17.72 7.43 17.38 8.47 17.28 8.73C17.92 9.45 18.31 10.37 18.31 11.5C18.31 15.47 15.98 16.34 13.76 16.6C14.13 16.93 14.46 17.58 14.46 18.58C14.46 20.02 14.45 21.07 14.45 21.42C14.45 21.69 14.63 22.02 15.14 21.91C19.11 20.56 22 16.73 22 12.22C22 6.58 17.52 2 12 2Z" />
            </svg>
            View on GitHub
          </motion.a>
        </div>
      </motion.div>
    </section>
  );
}
