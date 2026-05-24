/// Basic email format check — requires `name@domain.tld`.
bool isValidEmailAddress(String? raw) {
  final email = raw?.trim() ?? '';
  if (email.isEmpty || email.length > 254) return false;
  return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
}
