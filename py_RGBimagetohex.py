from PIL import Image
import sys

def png_to_hex(input_image, output_hex):

    img = Image.open(input_image).convert("RGB")
    width, height = img.size

    pixels = list(img.getdata())

    with open(output_hex, "w") as f:
        for r, g, b in pixels:
            f.write(f"{r:02x}{g:02x}{b:02x}\n")

    print("Image size:", width, "x", height)
    print("HEX file written to:", output_hex)


if __name__ == "__main__":

    if len(sys.argv) != 3:
        print("Usage: python png_to_hex_rgb.py input.png output.hex")
        exit()

    input_image = sys.argv[1]
    output_hex = sys.argv[2]

    png_to_hex(input_image, output_hex)