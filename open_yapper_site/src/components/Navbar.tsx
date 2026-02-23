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
          href="https://github.com/Matinrahimik/open_yapper"
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-2 rounded-2xl border-2 border-[#0A0A0A] bg-white px-6 py-2.5 font-semibold text-[#0A0A0A] shadow-[4px_4px_0_0_#0A0A0A] transition-all hover:-translate-y-0.5 hover:bg-[#EFEFE8] hover:shadow-[6px_6px_0_0_#0A0A0A]"
        >
          <svg
            aria-hidden
            className="h-4 w-4"
            viewBox="0 0 24 24"
            fill="currentColor"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path d="M12 2C6.48 2 2 6.58 2 12.22C2 16.73 4.87 20.56 8.84 21.91C9.34 22.01 9.52 21.69 9.52 21.42C9.52 21.17 9.51 20.33 9.5 19.42C6.73 20.04 6.14 18.24 6.14 18.24C5.68 17.04 5.03 16.72 5.03 16.72C4.12 16.08 5.1 16.1 5.1 16.1C6.11 16.17 6.64 17.16 6.64 17.16C7.54 18.74 9 18.28 9.58 18.01C9.67 17.34 9.93 16.88 10.22 16.61C8.01 16.35 5.69 15.46 5.69 11.5C5.69 10.37 6.08 9.45 6.72 8.73C6.62 8.47 6.28 7.43 6.82 6.02C6.82 6.02 7.66 5.74 9.49 7.01C10.29 6.78 11.15 6.66 12 6.66C12.85 6.66 13.71 6.78 14.51 7.01C16.34 5.74 17.18 6.02 17.18 6.02C17.72 7.43 17.38 8.47 17.28 8.73C17.92 9.45 18.31 10.37 18.31 11.5C18.31 15.47 15.98 16.34 13.76 16.6C14.13 16.93 14.46 17.58 14.46 18.58C14.46 20.02 14.45 21.07 14.45 21.42C14.45 21.69 14.63 22.02 15.14 21.91C19.11 20.56 22 16.73 22 12.22C22 6.58 17.52 2 12 2Z" />
          </svg>
          View on GitHub
        </a>
      </div>
    </nav>
  );
}
