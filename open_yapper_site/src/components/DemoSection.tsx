"use client";

import { useState, useEffect, useCallback } from "react";
import { Mic, Square, Sparkles } from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { demoRaw, demoRefined } from "@/data/demo";

export function DemoSection() {
  const [isRecording, setIsRecording] = useState(false);
  const [demoStage, setDemoStage] = useState<
    "idle" | "recording" | "refining" | "done"
  >("idle");
  const [rawText, setRawText] = useState("");
  const [refinedText, setRefinedText] = useState("");

  const words = demoRaw.split(" ");
  const wordIndexRef = { current: 0 };
  const intervalRef = {
    current: null as ReturnType<typeof setInterval> | null,
  };

  const startRecording = useCallback(() => {
    setDemoStage("recording");
    setIsRecording(true);
    setRawText("");
    setRefinedText("");
    wordIndexRef.current = 0;

    intervalRef.current = setInterval(() => {
      if (wordIndexRef.current < words.length) {
        setRawText(
          (prev) => prev + (prev ? " " : "") + words[wordIndexRef.current]
        );
        wordIndexRef.current += 1;
      } else {
        if (intervalRef.current) clearInterval(intervalRef.current);
        intervalRef.current = null;
        setIsRecording(false);
        setDemoStage("refining");
        setTimeout(() => {
          setRefinedText(demoRefined);
          setDemoStage("done");
        }, 1500);
      }
    }, 200);
  }, []);

  const stopRecording = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
    setIsRecording(false);
    setDemoStage("refining");
    setTimeout(() => {
      setRefinedText(demoRefined);
      setDemoStage("done");
    }, 1500);
  }, []);

  const resetDemo = useCallback(() => {
    setDemoStage("idle");
    setRawText("");
    setRefinedText("");
  }, []);

  useEffect(() => {
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, []);

  return (
    <section
      id="how-it-works"
      className="bg-[#D4FF00] px-6 py-32 md:px-12"
    >
      <div className="mx-auto grid max-w-6xl gap-16 lg:grid-cols-2 lg:gap-20">
        {/* Left column */}
        <div className="flex flex-col items-center justify-center text-center lg:items-start lg:text-left">
          <h2
            className="text-4xl font-normal uppercase text-[#0A0A0A] md:text-5xl lg:text-6xl"
            style={{ fontFamily: "var(--font-anton), sans-serif" }}
          >
            See Your Yap in Action
          </h2>
          <p className="mt-6 text-lg font-medium text-[#0A0A0A]/90 md:text-xl">
            Bring your own API key, start talking, and let Open Yapper do the
            cleanup. Your raw thoughts turn into polished text you can paste
            wherever you are working.
          </p>
          <ul className="mt-10 flex flex-col gap-4">
            {[
              "Bring your own API key",
              "Ramble Naturally",
              "AI Cleans Up the Mess",
              "Paste anywhere that you are working",
            ].map(
              (step, i) => (
                <li key={i} className="flex items-center justify-center gap-4 lg:justify-start">
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-[#0A0A0A] text-sm font-bold text-[#D4FF00]">
                    {i + 1}
                  </span>
                  <span className="text-lg font-semibold text-[#0A0A0A] md:text-xl">
                    {step}
                  </span>
                </li>
              )
            )}
          </ul>
        </div>

        {/* Right column - Mock app */}
        <div
          className="flex h-[600px] flex-col overflow-hidden rounded-3xl border-4 border-[#0A0A0A] bg-[#F4F4F0] shadow-[8px_8px_0_0_#0A0A0A]"
        >
          {/* Mock header */}
          <div className="flex items-center gap-3 border-b-2 border-[#0A0A0A] bg-[#0A0A0A] px-4 py-3">
            <div className="flex gap-2">
              <div className="h-3 w-3 rounded-full bg-red-500" />
              <div className="h-3 w-3 rounded-full bg-yellow-500" />
              <div className="h-3 w-3 rounded-full bg-green-500" />
            </div>
          </div>

          {/* Mock body */}
          <div className="flex flex-1 flex-col gap-4 overflow-hidden p-6">
            <label className="text-sm font-semibold uppercase text-[#0A0A0A]">
              Raw Input
            </label>
            <div className="min-h-[120px] flex-1 rounded-xl border-2 border-[#0A0A0A] bg-white p-4">
              <p className="min-h-[80px] whitespace-pre-wrap font-medium text-[#0A0A0A]">
                {rawText || "Press the mic and start talking..."}
                {demoStage === "recording" && (
                  <span
                    className="ml-1 inline-block h-5 w-0.5 animate-pulse bg-[#D4FF00]"
                    aria-hidden
                  />
                )}
              </p>
            </div>

            {/* Refined output panel */}
            <AnimatePresence mode="wait">
              {(demoStage === "refining" || demoStage === "done") && (
                <motion.div
                  key="refined-panel"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  transition={{ duration: 0.3 }}
                  className="flex flex-col gap-2 rounded-xl border-2 border-[#0A0A0A] bg-[#D4FF00] p-4"
                >
                  <div className="flex items-center gap-2">
                    <Sparkles className="h-4 w-4 text-[#0A0A0A]" aria-hidden />
                    <span className="text-sm font-semibold uppercase text-[#0A0A0A]">
                      Refined Output
                    </span>
                  </div>
                  {demoStage === "refining" ? (
                    <div className="flex items-center gap-3 py-4">
                      <motion.div
                        className="h-5 w-5 rounded-full border-2 border-[#0A0A0A] border-t-transparent"
                        animate={{ rotate: 360 }}
                        transition={{
                          duration: 1,
                          repeat: Infinity,
                          ease: "linear",
                        }}
                      />
                      <span className="font-medium text-[#0A0A0A]">
                        Refining your words...
                      </span>
                    </div>
                  ) : (
                    <p className="py-2 font-medium text-[#0A0A0A]">
                      {refinedText}
                    </p>
                  )}
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Bottom controls */}
          <div className="flex justify-center border-t-2 border-[#0A0A0A] bg-[#F4F4F0] p-6">
            {demoStage === "idle" && (
              <motion.button
                type="button"
                onClick={startRecording}
                className="flex h-16 w-16 items-center justify-center rounded-full border-4 border-[#0A0A0A] bg-[#D4FF00] shadow-[4px_4px_0_0_#0A0A0A] transition-all hover:-translate-y-1 hover:shadow-[6px_6px_0_0_#0A0A0A]"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                aria-label="Start recording"
              >
                <Mic className="h-8 w-8 text-[#0A0A0A]" aria-hidden />
              </motion.button>
            )}
            {demoStage === "recording" && (
              <motion.button
                type="button"
                onClick={stopRecording}
                className="flex h-16 w-16 items-center justify-center rounded-full border-4 border-[#0A0A0A] bg-red-500 shadow-[4px_4px_0_0_#0A0A0A]"
                animate={{ scale: [1, 1.05, 1] }}
                transition={{ duration: 1.5, repeat: Infinity }}
                aria-label="Stop recording"
              >
                <Square
                  className="h-6 w-6 fill-[#0A0A0A] text-[#0A0A0A]"
                  aria-hidden
                />
              </motion.button>
            )}
            {(demoStage === "refining" || demoStage === "done") && (
              <button
                type="button"
                onClick={resetDemo}
                disabled={demoStage === "refining"}
                className={`flex h-16 w-16 items-center justify-center rounded-full border-4 border-[#0A0A0A] ${
                  demoStage === "refining"
                    ? "cursor-not-allowed bg-gray-300 opacity-60"
                    : "bg-[#D4FF00] shadow-[4px_4px_0_0_#0A0A0A] transition-all hover:-translate-y-1 hover:shadow-[6px_6px_0_0_#0A0A0A]"
                }`}
                aria-label={
                  demoStage === "refining" ? "Processing" : "Start over"
                }
              >
                <Mic className="h-8 w-8 text-[#0A0A0A]" aria-hidden />
              </button>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
