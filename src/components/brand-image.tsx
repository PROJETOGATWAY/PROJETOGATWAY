import { useEffect, useRef, useState, type ImgHTMLAttributes } from "react";
import logo from "../assets/azonpay-logo.png.asset.json";
import originalLogo from "../assets/aron-pay-logo.png.asset.json";

const sources = [logo.url, originalLogo.url, "/favicon.png?v=gold-panther"];

export function BrandImage(props: Omit<ImgHTMLAttributes<HTMLImageElement>, "src" | "alt" | "onError">) {
  const [sourceIndex, setSourceIndex] = useState(0);
  const imageRef = useRef<HTMLImageElement>(null);
  useEffect(() => {
    const image = imageRef.current;
    // Failed SSR image requests can finish before React attaches onError.
    if (image?.complete && image.naturalWidth === 0) {
      setSourceIndex(index => Math.min(index + 1, sources.length - 1));
    }
  }, [sourceIndex]);
  return <img {...props} ref={imageRef} src={sources[sourceIndex]} alt="Logo AZONPAY" loading="eager" decoding="async" onError={() => setSourceIndex(index => Math.min(index + 1, sources.length - 1))} />;
}