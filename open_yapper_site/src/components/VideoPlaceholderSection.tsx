"use client";

export function VideoPlaceholderSection() {
  return (
    <section className="bg-[#D4FF00] px-6 pb-28 md:px-12 md:pb-36">
      <div className="mx-auto max-w-6xl">
        <div className="overflow-hidden rounded-3xl border-4 border-[#0A0A0A] bg-white shadow-[10px_10px_0_0_#0A0A0A]">
          <div className="relative aspect-video w-full bg-[#0A0A0A]">
            <div className="absolute inset-0 flex flex-col items-center justify-center gap-4 text-center">
              <div className="flex h-16 w-16 items-center justify-center rounded-full border-2 border-[#D4FF00] bg-[#0A0A0A]">
                <div className="ml-1 h-0 w-0 border-y-[10px] border-y-transparent border-l-[16px] border-l-[#D4FF00]" />
              </div>
              <p
                className="text-lg uppercase tracking-[0.08em] text-[#D4FF00] md:text-2xl"
                style={{ fontFamily: "var(--font-anton), sans-serif" }}
              >
                Video Placeholder
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
