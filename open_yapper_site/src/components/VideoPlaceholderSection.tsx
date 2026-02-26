"use client";

import { useMemo, useRef, useState } from "react";

const YOUTUBE_VIDEO_ID = "-6ms5VWcWrI";

export function VideoPlaceholderSection() {
  const iframeRef = useRef<HTMLIFrameElement | null>(null);
  const [isReady, setIsReady] = useState(false);
  const [hasStarted, setHasStarted] = useState(false);
  const [isPlaying, setIsPlaying] = useState(false);

  const embedUrl = useMemo(() => {
    const params = new URLSearchParams({
      autoplay: "0",
      controls: "0",
      disablekb: "1",
      enablejsapi: "1",
      fs: "0",
      iv_load_policy: "3",
      modestbranding: "1",
      playsinline: "1",
      rel: "0",
    });

    return `https://www.youtube-nocookie.com/embed/${YOUTUBE_VIDEO_ID}?${params.toString()}`;
  }, []);

  const sendPlayerCommand = (func: string, args: unknown[] = []) => {
    if (!iframeRef.current?.contentWindow) return;

    iframeRef.current.contentWindow.postMessage(
      JSON.stringify({
        event: "command",
        func,
        args,
      }),
      "*",
    );
  };

  const handlePlay = () => {
    sendPlayerCommand("playVideo");
    setHasStarted(true);
    setIsPlaying(true);
  };

  const handlePause = () => {
    sendPlayerCommand("pauseVideo");
    setIsPlaying(false);
  };

  const handleReplay = () => {
    sendPlayerCommand("seekTo", [0, true]);
    sendPlayerCommand("playVideo");
    setHasStarted(true);
    setIsPlaying(true);
  };

  return (
    <section className="bg-[#D4FF00] px-6 pb-28 md:px-12 md:pb-36">
      <div className="mx-auto w-fit max-w-full">
        <div className="relative w-[1440px] max-w-full overflow-hidden rounded-3xl border-4 border-[#0A0A0A] bg-white shadow-[10px_10px_0_0_#0A0A0A]">
          <div className="relative aspect-video w-full bg-black">
            <iframe
              ref={iframeRef}
              className="block h-full w-full pointer-events-none"
              src={embedUrl}
              title="Open Yapper demo video"
              loading="lazy"
              allow="autoplay; encrypted-media; picture-in-picture; web-share"
              referrerPolicy="strict-origin-when-cross-origin"
              onLoad={() => setIsReady(true)}
              allowFullScreen
            />

            {!hasStarted && (
              <button
                type="button"
                onClick={handlePlay}
                disabled={!isReady}
                className="absolute inset-0 flex items-center justify-center disabled:cursor-not-allowed"
                aria-label="Play demo video"
              >
                <span className="flex h-32 w-32 items-center justify-center rounded-full border-4 border-[#0A0A0A] bg-[#D4FF00] shadow-[8px_8px_0_0_#0A0A0A] transition-transform hover:scale-105 md:h-40 md:w-40">
                  <span className="ml-1 h-0 w-0 border-y-[18px] border-y-transparent border-l-[28px] border-l-[#0A0A0A] md:border-y-[22px] md:border-l-[34px]" />
                </span>
              </button>
            )}

            {hasStarted && (
              <div className="absolute bottom-4 left-4 flex items-center gap-3">
                {isPlaying ? (
                  <button
                    type="button"
                    onClick={handlePause}
                    className="rounded-full border-2 border-[#0A0A0A] bg-[#D4FF00] px-4 py-2 text-sm font-bold text-[#0A0A0A] shadow-[4px_4px_0_0_#0A0A0A] transition-transform hover:scale-105"
                    aria-label="Pause demo video"
                  >
                    Pause
                  </button>
                ) : (
                  <button
                    type="button"
                    onClick={handlePlay}
                    className="rounded-full border-2 border-[#0A0A0A] bg-[#D4FF00] px-4 py-2 text-sm font-bold text-[#0A0A0A] shadow-[4px_4px_0_0_#0A0A0A] transition-transform hover:scale-105"
                    aria-label="Play demo video"
                  >
                    Play
                  </button>
                )}
                <button
                  type="button"
                  onClick={handleReplay}
                  className="rounded-full border-2 border-[#0A0A0A] bg-white px-4 py-2 text-sm font-bold text-[#0A0A0A] shadow-[4px_4px_0_0_#0A0A0A] transition-transform hover:scale-105"
                  aria-label="Replay demo video"
                >
                  Replay
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
