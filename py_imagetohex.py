from PIL import Image
import numpy as np
import sys

def image_to_hex(input_image, output_file):

    # Load image and force grayscale
    img = Image.open(input_image).convert("L")

    # Convert image to numpy array
    img_array = np.array(img)

    height, width = img_array.shape

    with open(output_file, "w") as f:
        for y in range(height):
            for x in range(width):
                pixel = img_array[y, x]
                f.write("{:02X}\n".format(pixel))

    print("HEX file generated:", output_file)


if __name__ == "__main__":

    if len(sys.argv) != 3:
        print("Usage: python image_to_hex.py <input_image> <output_hex>")
        sys.exit(1)

    input_image = sys.argv[1]
    output_hex = sys.argv[2]

    image_to_hex(input_image, output_hex)