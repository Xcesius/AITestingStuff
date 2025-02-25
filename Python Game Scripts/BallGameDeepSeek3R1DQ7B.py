import pygame
import sys
import math

# Initialize Pygame
pygame.init()

# Set up the display window
width = 600
height = 400
window = pygame.display.set_mode((width, height))
pygame.display.set_caption("Rotating Square with Bouncing Ball")

# Colors
YELLOW_COLOR = (255, 255, 0)
BLACK_COLOR = (0, 0, 0)

# Create the square and ball objects
square_size = 100
square = pygame.Rect(0, 0, square_size, square_size)
ball_radius = 15
ball_pos = [width // 2 - 30, height // 2 - 30]  # Starting position (x, y)
ball_vel = [4, 4]  # Velocity components (dx, dy)

# Initial setup for rotation
square_center_x = width // 2
square_center_y = height // 2

# Rotation angle in radians
rotation_angle = 0.0

# Main game loop
running = True
while running:
    window.fill(BLACK_COLOR)
    
    # Handle events
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
    
    # Update square rotation
    rotation_angle += 0.1  # Increase by small increments each frame
    rotated_rect = pygame.Rect(
        square_center_x - (square_size // 2),
        square_center_y - (square_size // 2),
        square_size,
        square_size
    ).rotate(rotation_angle)
    
    # Update ball position
    ball_pos[0] += ball_vel[0]
    ball_pos[1] += ball_vel[1]
    
    # Apply velocity damping
    if abs(ball_vel[0]) < 3 or abs(ball_vel[1]) < 3:
        ball_vel[0] *= 0.95  # Decrease speed over time
    
    # Check collision with rotated square
    x, y = ball_pos[0], ball_pos[1]
    if (rotated_rect.x - ball_radius <= x <= rotated_rect.x + ball_radius and 
        math.isclose(y, rotated_rect.y, abs_tol=ball_radius) or
        rotated_rect.y - ball_radius <= y <= rotated_rect.y + ball_radius and 
        math.isclose(x, rotated_rect.x, abs_tol=ball_radius)):
        # Bounce off the square
        if x > ball_radius:
            ball_vel[0] *= -1  # Reverse x velocity
        elif x < width - ball_radius:
            ball_vel[0] *= -1
        
        if y > ball_radius:
            ball_vel[1] *= -1  # Reverse y velocity
        elif y < height - ball_radius:
            ball_vel[1] *= -1
    
    # Keep ball within square boundaries
    x, y = ball_pos[0], ball_pos[1]
    if (x > width - ball_radius or 
        x < 0 + ball_radius or
        y > height - ball_radius or 
        y < 0 + ball_radius):
        # Reset velocity to stop the ball immediately
        ball_vel[0] = 0.0
        ball_vel[1] = 0.0
    
    # Update square position for drawing (non-rotated)
    rotated_rect = pygame.Rect(
        square_center_x - (square_size // 2),
        square_center_y - (square_size // 2),
        square_size,
        square_size
    ).rotate(rotation_angle)
    
    # Draw the square with rounded corners
    pygame.draw.rect(window, YELLOW_COLOR, rotated_rect)
    
    # Draw the ball
    pygame.draw.circle(window, YELLOW_COLOR, [int(x), int(y)], ball_radius)
    
    # Update display
    pygame.display.flip()

# Quit Pygame when done
pygame.quit()
sys.exit()
