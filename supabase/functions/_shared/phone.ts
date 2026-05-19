export function normalizePhone(phone?: string): string | null {
  if (!phone) return null;
  const digits = phone.replace(/[^\d+]/g, "");
  if (digits.length < 10) return null;
  return digits.startsWith("+") ? digits : `+${digits}`;
}
