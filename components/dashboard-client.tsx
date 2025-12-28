"use client";

import { useState, useRef } from "react";
import { Button } from "@/components/ui/button";
import { Sparkles, Share2, Download } from "lucide-react";
import { MonthlyRecap } from "@/components/monthly-recap";
import { ShareableRecapCard } from "@/components/shareable-recap-card";
import { getMonthlyRecapAction, MonthlyRecapData } from "@/app/actions/reading-recap";
import { toast } from "sonner";
import { toPng } from "html-to-image";

export function MonthlyRecapButton() {
  const [isOpen, setIsOpen] = useState(false);
  const [recapData, setRecapData] = useState<MonthlyRecapData | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isGeneratingImage, setIsGeneratingImage] = useState(false);
  const shareableCardRef = useRef<HTMLDivElement>(null);

  const handleOpenRecap = async () => {
    setIsLoading(true);
    try {
      const now = new Date();
      const year = now.getFullYear();
      const month = now.getMonth() + 1;

      const data = await getMonthlyRecapAction(year, month);

      if (data.booksFinished === 0) {
        toast.info("No books finished this month yet. Keep reading!");
        return;
      }

      setRecapData(data);
      setIsOpen(true);
    } catch (error) {
      toast.error("Failed to load monthly recap");
    } finally {
      setIsLoading(false);
    }
  };

  const generateShareableImage = async () => {
    // Load data first if not loaded
    let dataToUse = recapData;

    if (!dataToUse) {
      setIsLoading(true);
      try {
        const now = new Date();
        const year = now.getFullYear();
        const month = now.getMonth() + 1;

        const data = await getMonthlyRecapAction(year, month);

        if (data.booksFinished === 0) {
          toast.info("No books finished this month yet. Keep reading!");
          return;
        }

        setRecapData(data);
        dataToUse = data; // Use the loaded data directly
      } catch (error) {
        toast.error("Failed to load monthly recap");
        return;
      } finally {
        setIsLoading(false);
      }
    }

    // Wait for card to render
    await new Promise((resolve) => setTimeout(resolve, 300));

    if (!shareableCardRef.current) {
      toast.error("Failed to generate image. Please try again.");
      return;
    }

    setIsGeneratingImage(true);
    toast.info("Generating image...");

    try {
      const dataUrl = await toPng(shareableCardRef.current, {
        quality: 0.95,
        pixelRatio: 1,
        backgroundColor: "#0f2027",
        width: 1080,
        height: 1920,
        style: {
          transform: "scale(1)",
          transformOrigin: "top left",
        },
      });

      // Convert data URL to blob
      const response = await fetch(dataUrl);
      const blob = await response.blob();

      // Download the image
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.download = `reading-recap-${dataToUse.month}-${dataToUse.year}.png`;
      link.href = url;
      link.click();

      URL.revokeObjectURL(url);
      toast.success("Image downloaded!");
    } catch (error) {
      console.error("Error generating image:", error);
      toast.error("Failed to generate image: " + (error as Error).message);
    } finally {
      setIsGeneratingImage(false);
    }
  };

  return (
    <>
      <div className="flex gap-2">
        <Button
          onClick={handleOpenRecap}
          disabled={isLoading}
          size="sm"
          className="bg-primary"
        >
          <Sparkles className="h-4 w-4 sm:mr-2" />
          <span className="hidden sm:inline">{isLoading ? "Loading..." : "Monthly Recap"}</span>
        </Button>

        <Button
          onClick={generateShareableImage}
          disabled={isLoading || isGeneratingImage}
          size="sm"
          variant="outline"
          className="shrink-0"
          title="Download Monthly Recap Image"
        >
          {isGeneratingImage ? (
            <Download className="h-4 w-4 animate-pulse" />
          ) : (
            <Share2 className="h-4 w-4" />
          )}
          <span className="ml-2 hidden md:inline">Share</span>
        </Button>
      </div>

      {recapData && (
        <>
          <MonthlyRecap
            data={recapData}
            isOpen={isOpen}
            onClose={() => setIsOpen(false)}
          />

          {/* Off-screen card for image generation */}
          <div className="fixed -left-[9999px] -top-[9999px] pointer-events-none">
            <ShareableRecapCard ref={shareableCardRef} data={recapData} />
          </div>
        </>
      )}
    </>
  );
}
