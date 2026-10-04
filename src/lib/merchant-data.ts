export type WithdrawalMethod = {
  id: string;
  type: "MBWAY" | "IBAN";
  label: string;
  value: string;
  currency: "EUR";
  primary?: boolean;
};

export type Payment = {
  id: string;
  customer: string;
  amount: number;
  status: "pending" | "approved" | "paid";
  createdAt: string;
};

export type MerchantData = {
  methods: WithdrawalMethod[];
  payments: Payment[];
  withdrawals: { id: string; amount: number; method: string; status: "pending" | "completed"; createdAt: string }[];
};

const storageKey = (userId?: string) => `jaguar-pay-merchant-${userId || "demo"}`;

const initialData: MerchantData = {
  methods: [
    { id: "mbway", type: "MBWAY", label: "MB WAY", value: "+351 936 926 112", currency: "EUR", primary: true },
    { id: "iban", type: "IBAN", label: "IBAN", value: "BE17905927728821", currency: "EUR" },
  ],
  payments: [
    { id: "seed-1", customer: "Venda inicial", amount: 30, status: "approved", createdAt: new Date().toISOString() },
  ],
  withdrawals: [],
};

export function readMerchantData(userId?: string): MerchantData {
  if (typeof window === "undefined") return initialData;
  try {
    const raw = localStorage.getItem(storageKey(userId));
    if (!raw) {
      localStorage.setItem(storageKey(userId), JSON.stringify(initialData));
      return initialData;
    }
    return JSON.parse(raw) as MerchantData;
  } catch {
    return initialData;
  }
}

export function writeMerchantData(data: MerchantData, userId?: string) {
  if (typeof window !== "undefined") localStorage.setItem(storageKey(userId), JSON.stringify(data));
}

export function totals(data: MerchantData) {
  const approved = data.payments.filter((p) => p.status === "approved" || p.status === "paid").reduce((sum, p) => sum + p.amount, 0);
  const pending = data.payments.filter((p) => p.status === "pending").reduce((sum, p) => sum + p.amount, 0);
  const withdrawn = data.withdrawals.filter((w) => w.status === "completed").reduce((sum, w) => sum + w.amount, 0);
  return { approved, pending, available: Math.max(0, approved - withdrawn), risk: Math.round(approved * 0.5 * 100) / 100 };
}
