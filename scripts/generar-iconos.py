"""Genera el ícono de Sella (launcher, ficha de Play y splash de Android).

Marca: un sello postal (disco ámbar con dentado) con una S carbón en el centro.
Uso: python scripts/generar-iconos.py   (requiere Pillow)
"""

import math
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
ANDROID_RES = os.path.join(ROOT, "app", "android", "app", "src", "main", "res")
PLAY_DIR = os.path.join(ROOT, "docs", "play-store")

INK = (20, 22, 27)
AMBER = (245, 196, 81)
FONT_BOLD = "C:/Windows/Fonts/arialbd.ttf"
SUPERSAMPLE = 4
TEETH = 16


def stamp(size, background):
    """Dibuja el sello en un lienzo cuadrado de `size` px.

    background: color RGBA del fondo, o None para transparente (splash).
    """
    big = size * SUPERSAMPLE
    base = (0, 0, 0, 0) if background is None else background + (255,)
    img = Image.new("RGBA", (big, big), base)
    draw = ImageDraw.Draw(img)

    center = big / 2
    radius = big * 0.34
    draw.ellipse(
        [center - radius, center - radius, center + radius, center + radius],
        fill=AMBER + (255,),
    )

    # Dentado tipo sello postal: pequeños discos del color del fondo sobre el borde.
    tooth = big * 0.034
    ink_for_teeth = INK + (255,) if background is None else base
    for i in range(TEETH):
        angle = 2 * math.pi * i / TEETH
        x = center + radius * math.cos(angle)
        y = center + radius * math.sin(angle)
        draw.ellipse([x - tooth, y - tooth, x + tooth, y + tooth], fill=ink_for_teeth)

    font = ImageFont.truetype(FONT_BOLD, int(big * 0.46))
    bbox = draw.textbbox((0, 0), "S", font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(
        ((big - w) / 2 - bbox[0], (big - h) / 2 - bbox[1]),
        "S",
        font=font,
        fill=INK + (255,),
    )

    return img.resize((size, size), Image.LANCZOS)


def rounded_icon(size):
    """Versión con esquinas redondeadas para el launcher clásico de Android."""
    big = size * SUPERSAMPLE
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, big - 1, big - 1], radius=int(big * 0.22), fill=255)
    base = stamp(size, INK)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask.resize((size, size), Image.LANCZOS))
    return out


def main():
    legacy = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for name, px in legacy.items():
        path = os.path.join(ANDROID_RES, f"mipmap-{name}", "ic_launcher.png")
        rounded_icon(px).save(path)

    # Ficha de Play: cuadrado completo, Play aplica su propia máscara.
    stamp(512, INK).convert("RGB").save(os.path.join(PLAY_DIR, "icono-512.png"))

    # Splash de Android: sello sobre fondo transparente, centrado por launch_background.xml.
    os.makedirs(os.path.join(ANDROID_RES, "drawable-nodpi"), exist_ok=True)
    stamp(512, None).save(os.path.join(ANDROID_RES, "drawable-nodpi", "splash_mark.png"))

    print("Iconos generados.")


if __name__ == "__main__":
    main()
