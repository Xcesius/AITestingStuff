import pygame
import math

# Initialize Pygame
pygame.init()

# Set up the display
width, height = 600, 600
screen = pygame.display.set_mode((width, height))
pygame.display.set_caption("Bouncing Ball in Rotating Square")
clock = pygame.time.Clock()

# Square parameters
square_size = 400
square_half = square_size // 2
square_center = (width // 2, height // 2)
square_angle = 0
square_rotate_speed = 0.2  # Degrees per frame

# Ball parameters
ball_radius = 20
ball_color = (255, 255, 0)  # Yellow
ball_pos = list(square_center)
ball_speed = [4, 3]
effective_half = square_half - ball_radius  # Account for ball size

def transform_to_local(pos, center, angle):
    """Transform global coordinates to square's local coordinates"""
    x_trans = pos[0] - center[0]
    y_trans = pos[1] - center[1]
    theta = math.radians(angle)
    cos_theta = math.cos(theta)
    sin_theta = math.sin(theta)
    
    x_local = x_trans * cos_theta + y_trans * sin_theta
    y_local = -x_trans * sin_theta + y_trans * cos_theta
    return x_local, y_local

def transform_to_global(local_pos, center, angle):
    """Transform local coordinates back to global coordinates"""
    theta = math.radians(angle)
    cos_theta = math.cos(theta)
    sin_theta = math.sin(theta)
    
    x_local, y_local = local_pos
    x_global = center[0] + (x_local * cos_theta - y_local * sin_theta)
    y_global = center[1] + (x_local * sin_theta + y_local * cos_theta)
    return x_global, y_global

def transform_velocity(velocity, angle):
    """Transform velocity vector between coordinate systems"""
    theta = math.radians(angle)
    cos_theta = math.cos(theta)
    sin_theta = math.sin(theta)
    
    vx, vy = velocity
    vx_local = vx * cos_theta + vy * sin_theta
    vy_local = -vx * sin_theta + vy * cos_theta
    return vx_local, vy_local

def inverse_transform_velocity(vx_local, vy_local, angle):
    """Transform velocity back to global coordinates"""
    theta = math.radians(angle)
    cos_theta = math.cos(theta)
    sin_theta = math.sin(theta)
    
    vx = vx_local * cos_theta - vy_local * sin_theta
    vy = vx_local * sin_theta + vy_local * cos_theta
    return [vx, vy]

# Main loop
running = True
while running:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    # Update square rotation
    square_angle = (square_angle + square_rotate_speed) % 360

    # Move the ball
    ball_pos[0] += ball_speed[0]
    ball_pos[1] += ball_speed[1]

    # Transform to local coordinates
    x_local, y_local = transform_to_local(ball_pos, square_center, square_angle)

    # Collision detection and response
    collision_x = False
    collision_y = False

    # Check X boundaries
    if x_local < -effective_half:
        x_local = -effective_half
        collision_x = True
    elif x_local > effective_half:
        x_local = effective_half
        collision_x = True

    # Check Y boundaries
    if y_local < -effective_half:
        y_local = -effective_half
        collision_y = True
    elif y_local > effective_half:
        y_local = effective_half
        collision_y = True

    # Handle collisions
    if collision_x or collision_y:
        # Transform velocity to local coordinates
        vx_local, vy_local = transform_velocity(ball_speed, square_angle)
        
        # Reverse appropriate components
        if collision_x:
            vx_local *= -1
        if collision_y:
            vy_local *= -1
        
        # Transform velocity back to global coordinates
        ball_speed = inverse_transform_velocity(vx_local, vy_local, square_angle)
        
        # Update ball position
        ball_pos = list(transform_to_global((x_local, y_local), square_center, square_angle))

    # Drawing
    screen.fill((0, 0, 0))  # Clear screen

    # Draw rotating square
    square_surface = pygame.Surface((square_size, square_size), pygame.SRCALPHA)
    pygame.draw.rect(square_surface, (255, 255, 255), (0, 0, square_size, square_size), 2)
    rotated_square = pygame.transform.rotate(square_surface, square_angle)
    rotated_rect = rotated_square.get_rect(center=square_center)
    screen.blit(rotated_square, rotated_rect.topleft)

    # Draw ball
    pygame.draw.circle(screen, ball_color, (int(ball_pos[0]), int(ball_pos[1])), ball_radius)

    pygame.display.flip()
    clock.tick(60)

pygame.quit()