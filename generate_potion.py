from PIL import Image, ImageDraw
import numpy as np

def generate_potion_texture(filename="potion_texture.png", size=256):
    """Generates a grayscale circular texture with a radial gradient."""
    img = Image.new('L', (size, size), 0) # 'L' mode for grayscale, fill with black (0)
    draw = ImageDraw.Draw(img)

    center_x, center_y = size // 2, size // 2
    radius = size // 2 - 10 # Slightly smaller radius

    for i in range(radius, 0, -1): # Radial gradient from outside to center
        gray_value = int((radius - i) / radius * 255) # Gradient from 0 to 255
        draw.ellipse((center_x - i, center_y - i, center_x + i, center_y + i), fill=gray_value)

    # Add a bit of noise for visual interest (optional, but let's add it)
    noise = np.random.randint(-20, 20, size=(size, size)) # Small noise range
    img_array = np.array(img)
    noisy_img_array = np.clip(img_array + noise, 0, 255).astype(np.uint8) # Clip values to 0-255
    noisy_img = Image.fromarray(noisy_img_array)


    noisy_img.save(filename)
    print(f"Potion texture saved as '{filename}'")

generate_potion_texture()