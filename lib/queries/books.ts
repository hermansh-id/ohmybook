"use client";

import { useQuery } from "@tanstack/react-query";
import { getAllBooksAction, getBooksAction } from "@/actions/books";

export function useBooks() {
  return useQuery({
    queryKey: ["books"],
    queryFn: () => getBooksAction(),
    staleTime: 1000 * 60 * 2,
  });
}

/** Every book (id + title), for pickers. */
export function useAllBooks() {
  return useQuery({
    queryKey: ["all-books"],
    queryFn: () => getAllBooksAction(),
    staleTime: 1000 * 60 * 2,
  });
}
