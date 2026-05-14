from PIL import Image
import sys
import math

def hex_to_image(input_hex, output_png, width, height):

    pixels = []

    with open(input_hex, "r") as f:
        for line in f:
            line = line.strip()

            if line.startswith("//") or line == "":
                continue

            hex_val = line.lower()

            r = int(hex_val[0:2], 16)
            g = int(hex_val[2:4], 16)
            b = int(hex_val[4:6], 16)

            pixels.append((r,g,b))

    if len(pixels) != width*height:
        print("Pixel count mismatch!")
        print("Expected:", width*height)
        print("Found:", len(pixels))
        return

    img = Image.new("RGB",(width,height))
    img.putdata(pixels)

    img.save(output_png)

    print("Image written to:",output_png)


if __name__ == "__main__":

    if len(sys.argv) != 5:
        print("Usage: python hex_to_png_rgb.py input.hex output.png width height")
        exit()

    input_hex = sys.argv[1]
    output_png = sys.argv[2]
    width = int(sys.argv[3])
    height = int(sys.argv[4])

    hex_to_image(input_hex, output_png, width, height)
    