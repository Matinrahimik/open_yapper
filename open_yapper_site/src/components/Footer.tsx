"use client";

import { ArrowRight, Heart } from "lucide-react";
import { motion } from "motion/react";

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
          <motion.button
            type="button"
            className="flex items-center gap-2 rounded-full border-2 border-[#D4FF00] bg-[#0A0A0A] px-8 py-4 text-lg font-bold uppercase text-[#D4FF00] shadow-[6px_6px_0_0_#D4FF00] transition-all hover:-translate-y-1 hover:shadow-[8px_8px_0_0_#D4FF00]"
            style={{ fontFamily: "var(--font-anton), sans-serif" }}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            Get Open Yapper Free
            <ArrowRight className="h-5 w-5 text-[#D4FF00]" aria-hidden />
          </motion.button>
        </div>
        <div className="flex flex-col items-center gap-3 text-center md:items-end md:text-right">
          <p className="text-base font-medium text-gray-300">
            © 2025 Open Yapper. All rights reserved.
          </p>
          <p className="flex items-center justify-center gap-1.5 text-sm text-gray-400 md:justify-end">
            Coded by Matin R in Canada
            <Heart className="h-4 w-4 shrink-0 fill-[#D4FF00] text-[#D4FF00]" aria-hidden />
          </p>
          <a
            href="https://linkedin.com/in/matinrahimi"
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
