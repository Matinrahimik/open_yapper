"use client";

import {
  Navbar,
  HeroSection,
  MarqueeStrip,
  DemoSection,
  Footer,
} from "@/components";

export default function OpenYapperPage() {
  return (
    <div
      className="min-h-screen overflow-x-hidden bg-[#F4F4F0] font-sans text-[#0A0A0A] selection:bg-[#D4FF00] selection:text-[#0A0A0A]"
      style={{ fontFamily: "var(--font-space-grotesk), system-ui, sans-serif" }}
    >
      <Navbar />
      <main className="pt-[73px]">
        <HeroSection />
        <MarqueeStrip />
        <DemoSection />
        <Footer />
      </main>
    </div>
  );
}
