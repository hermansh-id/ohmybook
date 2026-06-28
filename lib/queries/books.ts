"use client";

import { useQuery } from "@tanstack/react-query";
import { getBooksAction } from "@/actions/books";

export function useBooks() {
  return useQuery({
    queryKey: ["books"],
    queryFn: () => getBooksAction(),
    staleTime: 1000 * 60 * 2,
  });
}
