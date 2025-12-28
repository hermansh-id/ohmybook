"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { exportReadingLogToCsvAction } from "@/app/actions/settings";
import { Download } from "lucide-react";
import { toast } from "sonner";

export function ExportCsvButton() {
  const [isExporting, setIsExporting] = useState(false);

  const handleExport = async () => {
    setIsExporting(true);

    try {
      const result = await exportReadingLogToCsvAction();

      if (result.success && result.data) {
        // Create a blob and download
        const blob = new Blob([result.data], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.href = url;
        link.download = `bookjet-reading-log-${new Date().toISOString().split("T")[0]}.csv`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);

        toast.success("Reading log exported successfully!");
      } else {
        toast.error(result.error || "Failed to export");
      }
    } catch (error) {
      toast.error("Failed to export reading log");
    } finally {
      setIsExporting(false);
    }
  };

  return (
    <Button
      onClick={handleExport}
      disabled={isExporting}
      variant="outline"
      className="w-full"
    >
      <Download className="mr-2 h-4 w-4" />
      {isExporting ? "Exporting..." : "Export to Goodreads CSV"}
    </Button>
  );
}
