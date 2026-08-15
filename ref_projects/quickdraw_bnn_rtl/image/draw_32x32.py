import tkinter as tk
from tkinter import filedialog, messagebox
from pathlib import Path

GRID_SIZE = 32
CELL_SIZE = 16
CANVAS_SIZE = GRID_SIZE * CELL_SIZE

# 0 = black background, 1 = white stroke
pixels = [[0 for _ in range(GRID_SIZE)] for _ in range(GRID_SIZE)]


def draw_cell(x: int, y: int, value: int) -> None:
    if not (0 <= x < GRID_SIZE and 0 <= y < GRID_SIZE):
        return

    pixels[y][x] = value
    color = "white" if value else "black"

    x0 = x * CELL_SIZE
    y0 = y * CELL_SIZE
    x1 = x0 + CELL_SIZE
    y1 = y0 + CELL_SIZE

    canvas.create_rectangle(
        x0, y0, x1, y1,
        fill=color,
        outline="#404040"
    )


def event_to_cell(event):
    return event.x // CELL_SIZE, event.y // CELL_SIZE


def paint(event):
    x, y = event_to_cell(event)
    draw_cell(x, y, 1)


def erase(event):
    x, y = event_to_cell(event)
    draw_cell(x, y, 0)


def clear_canvas():
    for y in range(GRID_SIZE):
        for x in range(GRID_SIZE):
            draw_cell(x, y, 0)


def invert_canvas():
    for y in range(GRID_SIZE):
        for x in range(GRID_SIZE):
            draw_cell(x, y, 0 if pixels[y][x] else 1)


def save_raw():
    """
    Saves 1024 bytes:
      pixel 0 -> byte 0
      pixel 1 -> byte 1
      ...
      pixel 1023 -> byte 1023

    Pixel value:
      white stroke = 255
      black background = 0
    """
    path = filedialog.asksaveasfilename(
        title="Save 32x32 RAW image",
        defaultextension=".raw",
        initialfile="drawing_32x32.raw",
        filetypes=[
            ("RAW image", "*.raw"),
            ("All files", "*.*"),
        ],
    )
    if not path:
        return

    raw = bytearray()
    for y in range(GRID_SIZE):
        for x in range(GRID_SIZE):
            raw.append(255 if pixels[y][x] else 0)

    Path(path).write_bytes(raw)

    messagebox.showinfo(
        "Saved",
        f"Saved RAW image:\n{path}\n\nSize: {len(raw)} bytes"
    )


def save_packed():
    """
    Saves 128 bytes, 1 bit per pixel.

    Bit order:
      byte 0 bit 0 = pixel (0, 0)
      byte 0 bit 1 = pixel (1, 0)
      ...
      byte 3 bit 7 = pixel (31, 0)
      byte 4 bit 0 = pixel (0, 1)

    This matches:
      BYTE0_AT_LSB = 1
      BIT0_AT_LSB  = 1
    """
    path = filedialog.asksaveasfilename(
        title="Save packed 1-bit image",
        defaultextension=".bin",
        initialfile="drawing_32x32_packed.bin",
        filetypes=[
            ("Packed binary", "*.bin"),
            ("All files", "*.*"),
        ],
    )
    if not path:
        return

    packed = bytearray(GRID_SIZE * GRID_SIZE // 8)

    pixel_index = 0
    for y in range(GRID_SIZE):
        for x in range(GRID_SIZE):
            if pixels[y][x]:
                byte_index = pixel_index // 8
                bit_index = pixel_index % 8
                packed[byte_index] |= (1 << bit_index)
            pixel_index += 1

    Path(path).write_bytes(packed)

    messagebox.showinfo(
        "Saved",
        f"Saved packed image:\n{path}\n\nSize: {len(packed)} bytes"
    )


def load_raw():
    path = filedialog.askopenfilename(
        title="Open 32x32 RAW image",
        filetypes=[
            ("RAW image", "*.raw"),
            ("All files", "*.*"),
        ],
    )
    if not path:
        return

    data = Path(path).read_bytes()
    if len(data) != GRID_SIZE * GRID_SIZE:
        messagebox.showerror(
            "Invalid file",
            f"Expected 1024 bytes, but file has {len(data)} bytes."
        )
        return

    index = 0
    for y in range(GRID_SIZE):
        for x in range(GRID_SIZE):
            draw_cell(x, y, 1 if data[index] >= 128 else 0)
            index += 1


root = tk.Tk()
root.title("32x32 QuickDraw Image Creator")
root.resizable(False, False)

instructions = tk.Label(
    root,
    text=(
        "Left mouse: draw white | Right mouse: erase | "
        "Image: 32x32 pixels"
    ),
    padx=8,
    pady=8,
)
instructions.pack()

canvas = tk.Canvas(
    root,
    width=CANVAS_SIZE,
    height=CANVAS_SIZE,
    bg="black",
    highlightthickness=1,
    highlightbackground="gray",
)
canvas.pack(padx=8, pady=4)

canvas.bind("<Button-1>", paint)
canvas.bind("<B1-Motion>", paint)
canvas.bind("<Button-3>", erase)
canvas.bind("<B3-Motion>", erase)

button_frame = tk.Frame(root)
button_frame.pack(padx=8, pady=8)

tk.Button(
    button_frame,
    text="Clear",
    width=12,
    command=clear_canvas
).grid(row=0, column=0, padx=4, pady=4)

tk.Button(
    button_frame,
    text="Invert",
    width=12,
    command=invert_canvas
).grid(row=0, column=1, padx=4, pady=4)

tk.Button(
    button_frame,
    text="Load RAW",
    width=12,
    command=load_raw
).grid(row=0, column=2, padx=4, pady=4)

tk.Button(
    button_frame,
    text="Save RAW",
    width=12,
    command=save_raw
).grid(row=1, column=0, padx=4, pady=4)

tk.Button(
    button_frame,
    text="Save Packed",
    width=12,
    command=save_packed
).grid(row=1, column=1, padx=4, pady=4)

tk.Button(
    button_frame,
    text="Exit",
    width=12,
    command=root.destroy
).grid(row=1, column=2, padx=4, pady=4)

clear_canvas()
root.mainloop()
