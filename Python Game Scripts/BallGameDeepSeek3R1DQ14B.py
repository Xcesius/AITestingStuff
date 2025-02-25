import pygame
import math

# Initialize Pygame
pygame.init()

# Set up the window
width = 800
height = 600
screen = pygame.display.set_mode((width, height))
pygame.display.set_caption("Rotating Square with Bouncing Ball")

# Colors
yellow = (255, 255, 0)
black = (0, 0, 0)

# Square properties
square_size = 100
square_x = width // 2 - square_size // 2
square_y = height // 2 - square_size // 2
rotation_speed = 1

# Ball properties
ball_radius = 15
ball_x = square_x + ball_radius
ball_y = square_y + ball_radius
velocity_x = 3
velocity_y = 3

running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    # Rotate the square
    rotation_angle = math.radians(rotation_speed)
    rotated_square_points = [
        (square_x, square_y),
        (square_x + square_size * 2, square_y),
        (square_x + square_size * 2, square_y + square_size * 2),
        (square_x, square_y + square_size * 2)
    ]

    # Update ball position
    ball_x += velocity_x
    ball_y += velocity_y

    # Check collision with the rotating square
    def get_distance(point):
        return math.hypot(ball_x - point[0], ball_y - point[1])

    min_dist = float('inf')
    closest_point = None
    for point in rotated_square_points:
        dist = get_distance(point)
        if dist < min_dist:
            min_dist = dist
            closest_point = point

    # Calculate collision normal
    dx = ball_x - closest_point[0]
    dy = ball_y - closest_point[1]

    if math.hypot(dx, dy) < ball_radius:
        velocity_x = -velocity_x * 0.8
        velocity_y = -velocity_y * 0.8

    # Keep the ball within the square boundaries after rotation
    if ball_x < square_x or ball_x > square_x + square_size * 2:
        velocity_x *= -1
    if ball_y < square_y or ball_y > square_y + square_size * 2:
        velocity_y *= -1

    # Update rotation
    rotation_speed += 0.5

    # Clear the screen
    screen.fill(black)

    # Draw the rotating square
    for i in range(len(rotated_square_points)):
        next_i = (i + 1) % 4
        x1, y1 = rotated_square_points[i]
        x2, y2 = rotated_square_points[next_i]
        pygame.draw.line(screen, yellow, (x1, y1), (x2, y2))

    # Draw the ball
    pygame.draw.circle(screen, yellow, (int(ball_x), int(ball_y)), ball_radius)

    pygame.display.flip()

pygame.quit()
