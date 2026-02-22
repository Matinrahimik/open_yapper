export function Navbar() {
  return (
    <nav className="fixed inset-x-0 top-0 z-50 flex h-[73px] w-full items-center justify-between border-b-2 border-[#0A0A0A] bg-[#F4F4F0] px-6 md:px-12">
      <div className="flex flex-1 items-center justify-start" aria-hidden />
      <a
        href="/"
        className="absolute left-1/2 flex -translate-x-1/2 items-center justify-center text-2xl font-normal uppercase tracking-[0.15em] text-[#0A0A0A] transition-colors hover:text-[#D4FF00] md:text-3xl"
        style={{ fontFamily: "var(--font-anton), sans-serif" }}
      >
        OpenYapper
      </a>
      <div className="hidden flex-1 items-center justify-end lg:flex">
        <a
          href="https://github.com/Matinrahimik/open_yapper/releases/latest/download/open_yapper.dmg"
          download="Open Yapper.dmg"
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-2 rounded-2xl border-2 border-[#0A0A0A] bg-white px-6 py-2.5 font-semibold text-[#0A0A0A] shadow-[4px_4px_0_0_#0A0A0A] transition-all hover:-translate-y-0.5 hover:bg-[#EFEFE8] hover:shadow-[6px_6px_0_0_#0A0A0A]"
        >
          <svg
            aria-hidden
            className="h-4 w-4"
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
        </a>
      </div>
    </nav>
  );
}
