"use client";

import { ArrowRight, Github, Heart } from "lucide-react";
import { motion } from "motion/react";

const DOWNLOAD_URL =
  process.env.NEXT_PUBLIC_DOWNLOAD_URL ||
  "https://github.com/Matinrahimik/open_yapper/releases/latest/download/open_yapper.dmg";

export function Footer() {
  return (
    <footer className="bg-[#0A0A0A] px-6 py-20 md:px-12">
      <div className="mx-auto flex max-w-6xl flex-col items-center gap-12 md:flex-row md:items-end md:justify-between">
        <div className="flex flex-col items-center gap-8 text-center md:items-start md:text-left">
          <h2
            className="text-4xl font-normal uppercase text-[#D4FF00] md:text-5xl lg:text-6xl"
            style={{ fontFamily: "var(--font-anton), sans-serif" }}
          >
            Ready to yap?
          </h2>
          <div className="flex flex-col items-center gap-4 sm:flex-row">
            <motion.a
              href={DOWNLOAD_URL}
              download="Open Yapper.dmg"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 rounded-2xl border-2 border-[#D4FF00] bg-[#0A0A0A] px-8 py-4 text-base font-bold uppercase text-[#D4FF00] shadow-[6px_6px_0_0_#D4FF00] transition-all hover:-translate-y-1 hover:shadow-[8px_8px_0_0_#D4FF00] md:text-lg"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              Get Open Yapper Free
              <ArrowRight className="h-5 w-5 text-[#D4FF00]" aria-hidden />
            </motion.a>

            <motion.a
              href="https://github.com/Matinrahimik/open_yapper"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 rounded-2xl border-2 border-[#F4F4F0] bg-[#0A0A0A] px-8 py-4 text-base font-bold uppercase text-[#F4F4F0] shadow-[6px_6px_0_0_#F4F4F0] transition-all hover:-translate-y-1 hover:shadow-[8px_8px_0_0_#F4F4F0] md:text-lg"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              View Latest Updates on GitHub
              <Github className="h-5 w-5 text-[#F4F4F0]" aria-hidden />
            </motion.a>
          </div>
        </div>
        <div className="flex flex-col items-center gap-3 text-center md:items-end md:text-right">
          <p className="text-base font-medium text-gray-300">
            © 2025 Open Yapper. All rights reserved.
          </p>
          <p
            className="max-w-[34ch] text-sm font-medium leading-relaxed text-gray-400 md:max-w-[42ch]"
            style={{ textWrap: "balance" }}
          >
            Coded by Matin R in Canada{" "}
            <Heart
              className="mb-0.5 inline h-4 w-4 shrink-0 fill-[#D4FF00] text-[#D4FF00]"
              aria-hidden
            />{" "}
            — built in 4 hours at Cursor Hackathon Vancouver, winner (2026).
          </p>
          <a
            href="https://www.linkedin.com/in/matinrhmk"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm font-medium text-gray-400 transition-colors hover:text-[#D4FF00]"
          >
            LinkedIn
          </a>
        </div>
      </div>
    </footer>
  );
}
