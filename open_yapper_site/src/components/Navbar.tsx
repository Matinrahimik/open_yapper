export function Navbar() {
  return (
    <nav className="flex w-full items-center justify-between border-b-2 border-[#0A0A0A] px-6 py-4 md:px-12">
      <div className="flex items-center gap-3">
        <div
          className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full border-2 border-[#0A0A0A] bg-[#D4FF00] text-xl font-bold shadow-[4px_4px_0_0_#0A0A0A]"
          style={{ fontFamily: "var(--font-anton), sans-serif" }}
        >
          O
        </div>
        <span
          className="text-2xl font-normal uppercase tracking-tight md:text-3xl"
          style={{ fontFamily: "var(--font-anton), sans-serif" }}
        >
          Open Yapper
        </span>
      </div>
      <div className="hidden items-center gap-8 md:flex">
        <a
          href="#features"
          className="text-lg font-medium transition-all hover:text-[#D4FF00] hover:drop-shadow-[0_0_8px_rgba(212,255,0,0.5)]"
        >
          Features
        </a>
        <a
          href="#how-it-works"
          className="text-lg font-medium transition-all hover:text-[#D4FF00] hover:drop-shadow-[0_0_8px_rgba(212,255,0,0.5)]"
        >
          How it works
        </a>
        <button
          type="button"
          className="rounded-full border-2 border-[#0A0A0A] bg-[#0A0A0A] px-6 py-2.5 font-semibold text-[#D4FF00] shadow-[4px_4px_0_0_#0A0A0A] transition-all hover:-translate-y-0.5 hover:shadow-[6px_6px_0_0_#0A0A0A]"
        >
          Get Started
        </button>
      </div>
    </nav>
  );
}
