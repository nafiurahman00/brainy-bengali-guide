import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { Lang } from "@/lib/i18n";

interface LangCtx {
  lang: Lang;
  setLang: (l: Lang) => void;
  toggle: () => void;
}
const Ctx = createContext<LangCtx>({ lang: "en", setLang: () => {}, toggle: () => {} });

export function LangProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>(() => {
    const saved = typeof window !== "undefined" ? localStorage.getItem("lang") : null;
    return (saved as Lang) || "en";
  });

  useEffect(() => {
    localStorage.setItem("lang", lang);
    document.documentElement.lang = lang;
  }, [lang]);

  return (
    <Ctx.Provider
      value={{
        lang,
        setLang: setLangState,
        toggle: () => setLangState((l) => (l === "en" ? "bn" : "en")),
      }}
    >
      {children}
    </Ctx.Provider>
  );
}

export const useLang = () => useContext(Ctx);
