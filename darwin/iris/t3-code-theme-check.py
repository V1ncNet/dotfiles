"""Verify the generated T3 Code theme against the Claude palette.

Usage: t3-code-theme-check.py THEME_JSON PALETTE_JSON
"""
import json
import sys

MINIMUM_CONTRAST = 4.5
SINGLE_SOURCE = {
    "canvas": "background",
    "text": "foreground",
    "accent": "cursor",
}
SURFACE_PAIRS = [
    ("errorForeground", "errorSurface"),
    ("warningForeground", "warningSurface"),
    ("updateForeground", "updateSurface"),
    ("accentForeground", "accent"),
    ("accentSurfaceForeground", "accentSurface"),
    ("messageForeground", "messageSurface"),
    ("messageActionForeground", "messageAction"),
    ("searchMatchForeground", "searchMatchBackground"),
    ("searchMatchActiveForeground", "searchMatchActiveBackground"),
]


def luminance(hex_color):
    channels = [int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(foreground, background):
    lighter, darker = sorted((luminance(foreground), luminance(background)), reverse=True)
    return (lighter + 0.05) / (darker + 0.05)


def check_variant(name, colors, palette):
    failures = []
    for t3_key, palette_key in SINGLE_SOURCE.items():
        if colors.get(t3_key) != palette[palette_key]:
            failures.append(f"{name}: {t3_key} {colors.get(t3_key)} != palette {palette_key} {palette[palette_key]}")
    for background in ("canvas", "surface"):
        ratio = contrast(colors["text"], colors[background])
        if ratio < MINIMUM_CONTRAST:
            failures.append(f"{name}: text on {background} contrast {ratio:.2f} < {MINIMUM_CONTRAST}")
    for foreground, background in SURFACE_PAIRS:
        ratio = contrast(colors[foreground], colors[background])
        if ratio < MINIMUM_CONTRAST:
            failures.append(f"{name}: {foreground} on {background} contrast {ratio:.2f} < {MINIMUM_CONTRAST}")
    return failures


def main(theme_path, palette_path):
    theme = json.load(open(theme_path))
    palette = json.load(open(palette_path))
    failures = []
    failures += check_variant("light", theme["colors"], palette["light"])
    failures += check_variant("dark", theme["variants"]["dark"], palette["dark"])
    if theme["appearance"] != "light":
        failures.append("base appearance must be light")
    if set(theme["colors"]) != set(theme["variants"]["dark"]):
        failures.append("light and dark must define the same keys")
    for failure in failures:
        print(failure, file=sys.stderr)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:3]))
