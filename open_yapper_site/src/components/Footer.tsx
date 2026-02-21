"use client";

import { ArrowRight } from "lucide-react";
import { motion } from "motion/react";

export function Footer() {
  return (
    <footer className="bg-[#0A0A0A] px-6 py-20 md:px-12">
      <div className="mx-auto flex max-w-6xl flex-col items-center gap-12 md:flex-row md:justify-between md:items-start">
        <div className="flex flex-col items-center gap-8 text-center md:items-start md:text-left">
          <h2
            className="text-4xl font-normal uppercase text-[#D4FF00] md:text-5xl lg:text-6xl"
            style={{ fontFamily: "var(--font-anton), sans-serif" }}
          >
            Ready to Talk?
          </h2>
          <motion.button
            type="button"
            className="flex items-center gap-2 rounded-full border-2 border-[#D4FF00] bg-[#D4FF00] px-8 py-4 text-lg font-bold uppercase text-[#0A0A0A] shadow-[6px_6px_0_0_#D4FF00] transition-all hover:-translate-y-1 hover:shadow-[8px_8px_0_0_#D4FF00]"
            style={{ fontFamily: "var(--font-anton), sans-serif" }}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            Get Open Yapper Free
            <ArrowRight className="h-5 w-5" aria-hidden />
          </motion.button>
        </div>
        <div className="flex flex-col items-center gap-4 md:flex-row md:items-center md:gap-12">
          <p className="text-sm text-gray-400">
            © 2025 Open Yapper. All rights reserved.
          </p>
          <div className="flex gap-6">
            <a
              href="#"
              className="text-sm font-medium text-gray-400 transition-colors hover:text-[#D4FF00]"
            >
              Twitter
            </a>
            <a
              href="#"
              className="text-sm font-medium text-gray-400 transition-colors hover:text-[#D4FF00]"
            >
              Instagram
            </a>
            <a
              href="#"
              className="text-sm font-medium text-gray-400 transition-colors hover:text-[#D4FF00]"
            >
              Terms
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
