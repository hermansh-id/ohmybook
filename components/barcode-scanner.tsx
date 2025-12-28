"use client";

import { useEffect, useRef, useState } from "react";
import { Html5Qrcode } from "html5-qrcode";
import { X, Camera } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

interface BarcodeScannerProps {
  onScan: (result: string) => void;
  onClose: () => void;
  isOpen: boolean;
}

export function BarcodeScanner({ onScan, onClose, isOpen }: BarcodeScannerProps) {
  const scannerRef = useRef<Html5Qrcode | null>(null);
  const [isScanning, setIsScanning] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const hasScannedRef = useRef(false);

  useEffect(() => {
    if (!isOpen) {
      stopScanning();
      hasScannedRef.current = false;
      return;
    }

    hasScannedRef.current = false;
    startScanning();

    return () => {
      stopScanning();
    };
  }, [isOpen]);

  async function startScanning() {
    try {
      setError(null);
      setIsScanning(true);

      const scanner = new Html5Qrcode("barcode-reader");
      scannerRef.current = scanner;

      // Try to get the back camera on mobile devices
      // iOS Safari is picky about camera constraints
      const cameraConfig = {
        facingMode: { exact: "environment" }
      };

      try {
        // First try with exact environment (back camera)
        await scanner.start(
          cameraConfig,
          {
            fps: 10,
            qrbox: { width: 250, height: 150 },
            aspectRatio: 1.777778, // 16:9 aspect ratio works better on mobile
            // Scanner will automatically detect EAN-13, EAN-8, UPC-A, UPC-E and other barcode formats
          },
          (decodedText) => {
            // Successfully scanned a barcode
            // Prevent multiple scans
            if (hasScannedRef.current) return;
            hasScannedRef.current = true;

            onScan(decodedText);
            stopScanning();
            onClose();
          },
          () => {
            // Scanning in progress, errors are normal here
            // Don't show these to the user
          }
        );
      } catch (exactError) {
        console.log("Exact facingMode failed, trying ideal:", exactError);
        // If exact fails (some devices don't support it), try with ideal
        await scanner.start(
          { facingMode: "environment" },
          {
            fps: 10,
            qrbox: { width: 250, height: 150 },
            aspectRatio: 1.777778,
          },
          (decodedText) => {
            if (hasScannedRef.current) return;
            hasScannedRef.current = true;

            onScan(decodedText);
            stopScanning();
            onClose();
          },
          () => {
            // Scanning in progress
          }
        );
      }

      setHasPermission(true);
    } catch (err: any) {
      console.error("Scanner error:", err);

      if (err.name === "NotAllowedError" || err.toString().includes("Permission denied")) {
        setError("Camera permission denied. Please allow camera access to scan barcodes.");
        setHasPermission(false);
      } else if (err.name === "NotFoundError" || err.toString().includes("No camera found")) {
        setError("No camera found on this device.");
        setHasPermission(false);
      } else if (err.name === "NotReadableError" || err.toString().includes("not readable")) {
        setError("Camera is being used by another app. Please close other apps and try again.");
        setHasPermission(false);
      } else if (err.name === "OverconstrainedError") {
        setError("Camera configuration not supported on this device. Please try a different device.");
        setHasPermission(false);
      } else {
        setError(`Failed to start camera: ${err.message || "Unknown error"}. Please try again.`);
      }

      setIsScanning(false);
    }
  }

  async function stopScanning() {
    if (scannerRef.current) {
      try {
        const state = scannerRef.current.getState();
        // Only try to stop if scanner is actually running
        if (state === 2) { // 2 = SCANNING state
          await scannerRef.current.stop();
        }
        // Check again if scanner still exists before clearing
        if (scannerRef.current) {
          scannerRef.current.clear();
        }
      } catch (err) {
        // Silently handle transition errors - these are expected when closing quickly
        const errorMessage = err?.toString() || "";
        if (!errorMessage.includes("transition")) {
          console.error("Error stopping scanner:", err);
        }
      } finally {
        scannerRef.current = null;
      }
    }
    setIsScanning(false);
  }

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 bg-background/80 backdrop-blur-sm">
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div className="relative w-full max-w-lg rounded-lg border bg-background p-6 shadow-lg">
          {/* Header */}
          <div className="mb-4 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Camera className="h-5 w-5" />
              <h2 className="text-lg font-semibold">Scan Barcode</h2>
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={() => {
                stopScanning();
                onClose();
              }}
            >
              <X className="h-4 w-4" />
            </Button>
          </div>

          {/* Scanner Area */}
          <div className="relative overflow-hidden rounded-lg border">
            <div id="barcode-reader" className={cn("w-full", error && "hidden")} />

            {error && (
              <div className="flex min-h-[300px] flex-col items-center justify-center p-8 text-center">
                <p className="text-sm text-destructive">{error}</p>
                {hasPermission === false && (
                  <p className="mt-2 text-xs text-muted-foreground">
                    Check your browser settings to enable camera access.
                  </p>
                )}
              </div>
            )}
          </div>

          {/* Instructions */}
          {isScanning && !error && (
            <div className="mt-4 text-center space-y-2">
              <p className="text-sm text-muted-foreground">
                Position the barcode within the frame
              </p>
              <p className="text-xs text-muted-foreground">
                ISBN barcodes are usually on the back cover
              </p>
              <p className="text-xs text-muted-foreground">
                📱 iPhone users: Make sure you're using Safari and allowed camera access
              </p>
            </div>
          )}

          {/* Retry button for errors */}
          {error && (
            <div className="mt-4 flex justify-center">
              <Button
                variant="outline"
                onClick={() => {
                  setError(null);
                  startScanning();
                }}
              >
                Try Again
              </Button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
