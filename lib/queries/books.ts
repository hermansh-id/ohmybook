"use client";

import { useQuery } from "@tanstack/react-query";
import { getBooksAction } from "@/app/actions/books";

export function useBooks() {
  return useQuery({
    queryKey: ["books"],
    queryFn: () => getBooksAction(),
  });
}
