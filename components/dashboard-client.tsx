"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Sparkles } from "lucide-react";
import { MonthlyRecap } from "@/components/monthly-recap";
import { getMonthlyRecapAction, MonthlyRecapData } from "@/app/actions/reading-recap";
import { toast } from "sonner";

export function MonthlyRecapButton() {
  const [isOpen, setIsOpen] = useState(false);
  const [recapData, setRecapData] = useState<MonthlyRecapData | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleOpenRecap = async () => {
    setIsLoading(true);
    try {
      const now = new Date();
      const year = now.getFullYear();
      const month = now.getMonth() + 1; // getMonth() returns 0-11

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

  return (
    <>
      <Button
        onClick={handleOpenRecap}
        disabled={isLoading}
        size="sm"
        className="bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700"
      >
        <Sparkles className="mr-2 h-4 w-4" />
        {isLoading ? "Loading..." : "Monthly Recap"}
      </Button>

      {recapData && (
        <MonthlyRecap
          data={recapData}
          isOpen={isOpen}
          onClose={() => setIsOpen(false)}
        />
      )}
    </>
  );
}
