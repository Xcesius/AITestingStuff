import pygame
import math

# Initialize Pygame
pygame.init()

# Screen dimensions
screen_width = 800
screen_height = 600
screen = pygame.display.set_mode((screen_width, screen_height))
pygame.display.set_caption("Bouncing Yellow Ball in Rotating Square")

# Colors
black = (0, 0, 0)
white = (255, 255, 255)
yellow = (255, 255, 0)

# Ball properties
ball_radius = 20
ball_x = screen_width // 2
ball_y = screen_height // 2
ball_speed_x = 5
ball_speed_y = 5

# Square properties
square_size = 200
half_square_size = square_size / 2 # Pre-calculate half_size
square_center_x = screen_width // 2
square_center_y = screen_height // 2
square_rotation_angle = 0
square_rotation_speed = 0.5  # Degrees per frame

# Clock for controlling frame rate
clock = pygame.time.Clock()
fps = 60

def rotate_point(x, y, center_x, center_y, cos_angle, sin_angle): # Pass pre-calculated cos and sin
    """Rotates a point using pre-calculated cos and sin."""
    rotated_x = cos_angle * (x - center_x) - sin_angle * (y - center_y) + center_x
    rotated_y = sin_angle * (x - center_x) + cos_angle * (y - center_y) + center_y
    return rotated_x, rotated_y

def draw_rotated_square(surface, color, center_x, center_y, size, angle_degrees):
    """Draws a rotated square."""
    points = [
        (-half_square_size, -half_square_size), # Use pre-calculated half_square_size
        (half_square_size, -half_square_size),  # Use pre-calculated half_square_size
        (half_square_size, half_square_size),   # Use pre-calculated half_square_size
        (-half_square_size, half_square_size)   # Use pre-calculated half_square_size
    ]
    rotated_points = []
    for x, y in points:
        rotated_x, rotated_y = rotate_point(x, y, 0, 0, math.cos(math.radians(angle_degrees)), math.sin(math.radians(angle_degrees))) # Calculate cos and sin here for drawing
        rotated_points.append((rotated_x + center_x, rotated_y + center_y))

    pygame.draw.polygon(surface, color, rotated_points, 2)

def is_ball_inside_rotated_square(ball_x, ball_y, square_center_x, square_center_y, square_size, angle_degrees, ball_radius):
    """Checks if the ball is inside the rotated square, considering ball's radius."""
    half_size = half_square_size
    translated_ball_x = ball_x - square_center_x
    translated_ball_y = ball_y - square_center_y

    angle_radians = math.radians(-angle_degrees)
    cos_angle = math.cos(angle_radians)
    sin_angle = math.sin(angle_radians)

    rotated_ball_x, rotated_ball_y = rotate_point(translated_ball_x, translated_ball_y, 0, 0, cos_angle, sin_angle)

    return (-half_size <= rotated_ball_x - ball_radius <= half_size and # Simplified inside check
            -half_size <= rotated_ball_y - ball_radius <= half_size)

def handle_collision_with_rotated_square(ball_x, ball_y, ball_speed_x, ball_speed_y, square_center_x, square_center_y, square_size, angle_degrees, ball_radius):
    """Handles collision of the ball with the rotated square and returns updated ball speeds."""
    half_size = half_square_size

    translated_ball_x = ball_x - square_center_x
    translated_ball_y = ball_y - square_center_y

    angle_radians = math.radians(-angle_degrees)
    cos_angle = math.cos(angle_radians)
    sin_angle = math.sin(angle_radians)

    rotated_ball_x, rotated_ball_y = rotate_point(translated_ball_x, translated_ball_y, 0, 0, cos_angle, sin_angle)

    new_ball_speed_x = ball_speed_x
    new_ball_speed_y = ball_speed_y

    if rotated_ball_x + ball_radius > half_size and ball_speed_x > 0: # Right edge
        new_ball_speed_x = -abs(ball_speed_x)
    if rotated_ball_x - ball_radius < -half_size and ball_speed_x < 0: # Left edge
        new_ball_speed_x = abs(ball_speed_x)
    if rotated_ball_y + ball_radius > half_size and ball_speed_y > 0: # Bottom edge
        new_ball_speed_y = -abs(ball_speed_y)
    if rotated_ball_y - ball_radius < -half_size and ball_speed_y < 0: # Top edge
        new_ball_speed_y = abs(ball_speed_y)

    return new_ball_speed_x, new_ball_speed_y


# Game loop
running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    # Update square rotation
    square_rotation_angle += square_rotation_speed
    if square_rotation_angle >= 360:
        square_rotation_angle -= 360

    # Move ball
    ball_x += ball_speed_x
    ball_y += ball_speed_y

    # Collision detection and handling with rotated square
    if not is_ball_inside_rotated_square(ball_x, ball_y, square_center_x, square_center_y, square_size, square_rotation_angle, ball_radius):
        ball_speed_x, ball_speed_y = handle_collision_with_rotated_square(
            ball_x, ball_y, ball_speed_x, ball_speed_y, square_center_x, square_center_y, square_size, square_rotation_angle, ball_radius
        )

    # Keep ball within screen bounds (optional)
    if ball_x - ball_radius < 0 or ball_x + ball_radius > screen_width:
        ball_speed_x *= -1
        ball_x = max(ball_radius, min(ball_x, screen_width - ball_radius))
    if ball_y - ball_radius < 0 or ball_y + ball_radius > screen_height:
        ball_speed_y *= -1
        ball_y = max(ball_radius, min(ball_y, screen_height - ball_radius))


    # Drawing
    screen.fill(black)
    draw_rotated_square(screen, white, square_center_x, square_center_y, square_size, square_rotation_angle)
    pygame.draw.circle(screen, yellow, (int(ball_x), int(ball_y)), ball_radius)

    pygame.display.flip()

    clock.tick(fps)

pygame.quit()