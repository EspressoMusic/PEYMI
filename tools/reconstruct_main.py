import json
import os

transcript = r"C:\Users\Nirhdhd\.cursor\projects\empty-window\agent-transcripts\04e7b5ca-6c6d-4a75-9b6f-3d1b340bb661\04e7b5ca-6c6d-4a75-9b6f-3d1b340bb661.jsonl"
out_dir = r"c:\Users\Nirhdhd\bakery_shop_app\tools\extracted_patches"
os.makedirs(out_dir, exist_ok=True)

patches = []
with open(transcript, encoding="utf-8") as f:
    for i, line in enumerate(f):
        obj = json.loads(line)
        for block in obj.get("message", {}).get("content", []):
            if block.get("name") != "ApplyPatch":
                continue
            inp = block.get("input", "")
            if isinstance(inp, str) and "lib/main.dart" in inp.replace("\\", "/"):
                patches.append((i + 1, inp))

print(f"Extracted {len(patches)} patches")


def parse_hunks(patch_text: str) -> list[list[str]]:
    lines = patch_text.splitlines()
    hunks = []
    current = None
    for line in lines:
        if line.startswith("@@"):
            if current:
                hunks.append(current)
            current = []
        elif current is not None and (
            line.startswith("+") or line.startswith("-") or line.startswith(" ")
        ):
            current.append(line)
    if current:
        hunks.append(current)
    return hunks


def apply_hunk(content: str, hunk: list[str]) -> str | None:
    old_parts = []
    new_parts = []
    for l in hunk:
        tag, body = l[0], l[1:]
        if tag == "-":
            old_parts.append(body)
        elif tag == "+":
            new_parts.append(body)
        elif tag == " ":
            old_parts.append(body)
            new_parts.append(body)
    old_text = "\n".join(old_parts)
    new_text = "\n".join(new_parts)
    normalized = content.replace("\r\n", "\n")
    if old_text not in normalized:
        return None
    return normalized.replace(old_text, new_text, 1)


def bootstrap_from_first_patch(patch_text: str) -> str:
    hunks = parse_hunks(patch_text)
    minus = [l[1:] for h in hunks for l in h if l.startswith("-")]
    base = "\n".join(minus)
    for hunk in hunks:
        updated = apply_hunk(base, hunk)
        if updated is not None:
            base = updated
    return base + ("\n" if base and not base.endswith("\n") else "")


def apply_patch_lenient(content: str, patch_text: str) -> tuple[str, int, int]:
    if "*** Add File:" in patch_text:
        added = []
        in_add = False
        for line in patch_text.splitlines():
            if line.startswith("*** Add File:"):
                in_add = True
                continue
            if line.startswith("*** End Patch"):
                break
            if line.startswith("***"):
                in_add = False
            if in_add and line.startswith("+"):
                added.append(line[1:])
        return "\n".join(added) + "\n", 1, 0

    result = content.replace("\r\n", "\n")
    ok = 0
    fail = 0
    for hunk in parse_hunks(patch_text):
        updated = apply_hunk(result, hunk)
        if updated is None:
            fail += 1
        else:
            result = updated
            ok += 1
    if result and not result.endswith("\n"):
        result += "\n"
    return result, ok, fail


content = ""
patch_stats = []
for idx, (ln, p) in enumerate(patches):
    if idx == 0 and not content:
        content = bootstrap_from_first_patch(p)
        patch_stats.append((ln, "bootstrap", 1, 0))
        continue
    content, ok, fail = apply_patch_lenient(content, p)
    patch_stats.append((ln, ok, fail))

out_path = r"c:\Users\Nirhdhd\bakery_shop_app\tools\reconstructed_main.dart"
with open(out_path, "w", encoding="utf-8", newline="\n") as f:
    f.write(content)

line_count = len(content.splitlines())
print(f"Reconstructed {line_count} lines, {len(content)} bytes")
zero_ok = [s for s in patch_stats if isinstance(s[1], int) and s[1] == 0 and s[2] > 0]
print(f"Patches with 0 hunks applied: {len(zero_ok)}")
for k in [
    "BakeryApp",
    "RoleSelectionPage",
    "_AnimatedProductCard",
    "shilohdhd1",
    "SegmentedButton",
    "_SettingsHelpPageState",
    "ManagerHomePage",
    "audioplayers",
    "VarelaRound",
    "1.22",
    "_cartSoundPlayer",
]:
    print(f"  {k}:", k in content)
