"use client";

import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { updateReadingGoalAction } from "@/app/actions/settings";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";
import { Target, BookOpen } from "lucide-react";

interface SettingsFormProps {
  currentGoal: {
    targetBooks: number;
    targetPages: number;
    year: number;
  };
}

export function SettingsForm({ currentGoal }: SettingsFormProps) {
  const [targetBooks, setTargetBooks] = useState(currentGoal.targetBooks);
  const [targetPages, setTargetPages] = useState(currentGoal.targetPages);

  const updateMutation = useMutation({
    mutationFn: updateReadingGoalAction,
    onSuccess: (result) => {
      if (result.success) {
        toast.success("Reading goal updated successfully!");
      } else {
        toast.error(result.error || "Failed to update goal");
      }
    },
    onError: () => {
      toast.error("Failed to update reading goal");
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (targetBooks < 0 || targetPages < 0) {
      toast.error("Targets must be positive numbers");
      return;
    }

    updateMutation.mutate({
      year: currentGoal.year,
      targetBooks,
      targetPages,
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="targetBooks" className="flex items-center gap-2">
          <BookOpen className="h-4 w-4" />
          Books Target
        </Label>
        <Input
          id="targetBooks"
          type="number"
          min="0"
          value={targetBooks}
          onChange={(e) => setTargetBooks(parseInt(e.target.value) || 0)}
          placeholder="e.g., 52"
        />
        <p className="text-xs text-muted-foreground">
          Number of books you want to read this year
        </p>
      </div>

      <div className="space-y-2">
        <Label htmlFor="targetPages" className="flex items-center gap-2">
          <Target className="h-4 w-4" />
          Pages Target (Optional)
        </Label>
        <Input
          id="targetPages"
          type="number"
          min="0"
          value={targetPages}
          onChange={(e) => setTargetPages(parseInt(e.target.value) || 0)}
          placeholder="e.g., 10000"
        />
        <p className="text-xs text-muted-foreground">
          Total pages you want to read this year
        </p>
      </div>

      <Button
        type="submit"
        className="w-full"
        disabled={updateMutation.isPending}
      >
        {updateMutation.isPending ? "Saving..." : "Save Goal"}
      </Button>
    </form>
  );
}
