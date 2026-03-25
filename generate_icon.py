#!/usr/bin/env python3
"""
Generate macOS-style app icon for VIP F2E Tool
Requires: pip install Pillow
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import os

def create_rounded_squircle_mask(size, corner_radius=None):
    """Create a macOS Big Sur style squircle mask"""
    if corner_radius is None:
        corner_radius = int(size * 0.22)  # macOS uses ~22% corner radius
    
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    
    # Draw rounded rectangle
    draw.rounded_rectangle(
        [(0, 0), (size - 1, size - 1)],
        radius=corner_radius,
        fill=255
    )
    return mask

def create_gradient(size, color1, color2, direction='diagonal'):
    """Create a gradient background"""
    img = Image.new('RGBA', (size, size), color1)
    
    for y in range(size):
        for x in range(size):
            if direction == 'diagonal':
                ratio = (x + y) / (2 * size)
            else:
                ratio = y / size
            
            r = int(color1[0] + (color2[0] - color1[0]) * ratio)
            g = int(color1[1] + (color2[1] - color1[1]) * ratio)
            b = int(color1[2] + (color2[2] - color1[2]) * ratio)
            img.putpixel((x, y), (r, g, b, 255))
    
    return img

def draw_rocket(draw, center_x, center_y, size, color=(255, 255, 255)):
    """Draw a simplified rocket icon"""
    # Scale factor - smaller to leave room for text
    s = size / 120
    
    # Offset up to make room for text
    offset_y = -8 * s
    center_y = center_y + offset_y
    
    # Rocket body (pointed oval shape)
    body_points = [
        (center_x, center_y - 35 * s),  # Top tip
        (center_x + 15 * s, center_y + 5 * s),   # Right side
        (center_x + 12 * s, center_y + 25 * s),  # Bottom right
        (center_x - 12 * s, center_y + 25 * s),  # Bottom left
        (center_x - 15 * s, center_y + 5 * s),   # Left side
    ]
    draw.polygon(body_points, fill=color)
    
    # Rocket window (circle)
    window_radius = 6 * s
    window_center_y = center_y - 8 * s
    draw.ellipse([
        center_x - window_radius, window_center_y - window_radius,
        center_x + window_radius, window_center_y + window_radius
    ], fill=(100, 150, 255))  # Light blue window
    
    # Rocket fins (left)
    fin_left = [
        (center_x - 12 * s, center_y + 12 * s),
        (center_x - 25 * s, center_y + 30 * s),
        (center_x - 12 * s, center_y + 25 * s),
    ]
    draw.polygon(fin_left, fill=color)
    
    # Rocket fins (right)
    fin_right = [
        (center_x + 12 * s, center_y + 12 * s),
        (center_x + 25 * s, center_y + 30 * s),
        (center_x + 12 * s, center_y + 25 * s),
    ]
    draw.polygon(fin_right, fill=color)
    
    # Rocket flame
    flame_points = [
        (center_x - 8 * s, center_y + 25 * s),
        (center_x, center_y + 42 * s),
        (center_x + 8 * s, center_y + 25 * s),
    ]
    draw.polygon(flame_points, fill=(255, 150, 50))  # Orange flame
    
    # Inner flame
    inner_flame = [
        (center_x - 4 * s, center_y + 25 * s),
        (center_x, center_y + 35 * s),
        (center_x + 4 * s, center_y + 25 * s),
    ]
    draw.polygon(inner_flame, fill=(255, 220, 100))  # Yellow inner flame

def draw_text(draw, center_x, bottom_y, size, text="VIP F2E"):
    """Draw text below the rocket"""
    s = size / 100
    font_size = int(10 * s)
    
    try:
        # Try to use a nice font
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", font_size)
        except:
            font = ImageFont.load_default()
    
    # Get text bounding box
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Position text at center-bottom
    text_x = center_x - text_width // 2
    text_y = bottom_y - text_height - (5 * s)
    
    # Draw text with slight shadow
    draw.text((text_x + 1, text_y + 1), text, font=font, fill=(0, 0, 0, 80))
    draw.text((text_x, text_y), text, font=font, fill=(255, 255, 255, 230))

def generate_icon(size, output_path):
    """Generate the complete app icon with proper macOS padding"""
    # macOS icons should have ~8-10% padding
    padding = int(size * 0.08)
    inner_size = size - (padding * 2)
    
    # Colors (blue to purple gradient)
    color1 = (3, 129, 254)     # #0381FE - Electric blue
    color2 = (123, 77, 255)    # #7B4DFF - Purple
    
    # Create gradient background at inner size
    gradient = create_gradient(inner_size, color1, color2, 'diagonal')
    
    # Add slight inner glow/highlight at top
    overlay = Image.new('RGBA', (inner_size, inner_size), (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    
    # Top highlight
    for i in range(int(inner_size * 0.3)):
        alpha = int(50 * (1 - i / (inner_size * 0.3)))
        overlay_draw.line([(0, i), (inner_size, i)], fill=(255, 255, 255, alpha))
    
    gradient = Image.alpha_composite(gradient, overlay)
    
    # Draw rocket and text
    draw = ImageDraw.Draw(gradient)
    center = inner_size // 2
    
    # Draw rocket (smaller to fit text)
    draw_rocket(draw, center, center - int(inner_size * 0.05), inner_size * 0.8)
    
    # Draw VIP F2E text
    draw_text(draw, center, inner_size - int(inner_size * 0.08), inner_size)
    
    # Apply squircle mask to gradient
    mask = create_rounded_squircle_mask(inner_size)
    
    # Create masked gradient
    masked = Image.new('RGBA', (inner_size, inner_size), (0, 0, 0, 0))
    masked.paste(gradient, mask=mask)
    
    # Create final image with padding (transparent background)
    final = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    final.paste(masked, (padding, padding))
    
    # Save
    final.save(output_path, 'PNG')
    print(f"Generated: {output_path}")
    return final

def main():
    # Output directory
    base_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(base_dir, 'macos/Runner/Assets.xcassets/AppIcon.appiconset')
    
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    # Generate icons at all required sizes for macOS
    sizes = [
        (16, 'app_icon_16.png'),
        (32, 'app_icon_16@2x.png'),
        (32, 'app_icon_32.png'),
        (64, 'app_icon_32@2x.png'),
        (128, 'app_icon_128.png'),
        (256, 'app_icon_128@2x.png'),
        (256, 'app_icon_256.png'),
        (512, 'app_icon_256@2x.png'),
        (512, 'app_icon_512.png'),
        (1024, 'app_icon_512@2x.png'),
    ]
    
    print("Generating VIP F2E Tool app icons...")
    print("=" * 40)
    
    # Generate largest size first
    master_icon = generate_icon(1024, os.path.join(output_dir, 'app_icon_512@2x.png'))
    
    for size, filename in sizes:
        if size == 1024 and filename == 'app_icon_512@2x.png':
            continue  # Already generated
        
        output_path = os.path.join(output_dir, filename)
        resized = master_icon.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(output_path, 'PNG')
        print(f"Generated: {filename} ({size}x{size})")
    
    print("=" * 40)
    print("Done! All icons generated successfully.")
    print(f"Output directory: {output_dir}")

if __name__ == '__main__':
    main()
