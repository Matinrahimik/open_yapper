export function Navbar() {
  return (
    <nav className="fixed inset-x-0 top-0 z-50 flex w-full items-center justify-between border-b-2 border-[#0A0A0A] bg-[#F4F4F0] px-6 py-4 md:px-12">
      <div className="flex flex-1 items-center justify-start" aria-hidden />
      <a
        href="/"
        className="absolute left-1/2 flex -translate-x-1/2 items-center justify-center text-2xl font-normal uppercase tracking-[0.15em] text-[#0A0A0A] transition-colors hover:text-[#D4FF00] md:text-3xl"
        style={{ fontFamily: "var(--font-anton), sans-serif" }}
      >
        OpenYapper
      </a>
      <div className="flex flex-1 items-center justify-end">
        <button
          type="button"
          className="rounded-full border-2 border-[#0A0A0A] bg-[#D4FF00] px-6 py-2.5 font-semibold text-[#0A0A0A] shadow-[4px_4px_0_0_#0A0A0A] transition-all hover:-translate-y-0.5 hover:shadow-[6px_6px_0_0_#0A0A0A]"
        >
          Start yapping now
        </button>
      </div>
    </nav>
  );
}
