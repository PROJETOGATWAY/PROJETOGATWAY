import { useState, type ImgHTMLAttributes } from "react";
import logo from "../assets/azonpay-logo.png.asset.json";
import originalLogo from "../assets/aron-pay-logo.png.asset.json";

const sources = [logo.url, originalLogo.url, "/favicon.png?v=gold-panther"];

export function BrandImage(props: Omit<ImgHTMLAttributes<HTMLImageElement>, "src" | "alt" | "onError">) {
  const [sourceIndex, setSourceIndex] = useState(0);
  return <img {...props} src={sources[sourceIndex]} alt="Logo AZONPAY" loading="eager" decoding="async" onError={() => setSourceIndex(index => Math.min(index + 1, sources.length - 1))} />;
}