from PIL import Image
import numpy as np
import sys


def hex_to_image(input_hex, width, height, output_image):

    pixels = []

    # Read hex file
    with open(input_hex, "r") as f:
        for line in f:

            line = line.strip()

            # Skip empty lines
            if line == "":
                continue

            # Skip comment lines
            if line.startswith("//"):
                continue

            # Remove inline comments if present
            if "//" in line:
                line = line.split("//")[0].strip()

            # Remove 0x or 0X prefix
            if line.startswith("0x") or line.startswith("0X"):
                line = line[2:]

            try:
                value = int(line, 16)
                pixels.append(value)
            except ValueError:
                print("Skipping invalid line:", line)

    expected_pixels = width * height

    if len(pixels) != expected_pixels:
        print("Error: Pixel count mismatch")
        print("Expected:", expected_pixels)
        print("Found:", len(pixels))
        sys.exit(1)

    # Convert to numpy array
    img_array = np.array(pixels, dtype=np.uint8)

    # Reshape to image size
    img_array = img_array.reshape((height, width))

    # Create grayscale image
    img = Image.fromarray(img_array, mode='L')

    # Save image
    img.save(output_image)

    print("Image successfully saved as:", output_image)


if __name__ == "__main__":

    if len(sys.argv) != 5:
        print("Usage:")
        print("python hex_to_image.py <input_hex> <width> <height> <output_image>")
        sys.exit(1)

    input_hex = sys.argv[1]
    width = int(sys.argv[2])
    height = int(sys.argv[3])
    output_image = sys.argv[4]

    hex_to_image(input_hex, width, height, output_image)