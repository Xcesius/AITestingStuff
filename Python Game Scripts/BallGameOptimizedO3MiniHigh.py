import pygame
import math
import random
from pygame.math import Vector2

pygame.init()
pygame.display.set_caption("Optimized Rotating Square with Bouncing Ball")

# ===============================
# RotatingSquare Class Definition
# ===============================
class RotatingSquare:
    def __init__(self, center, base_size):
        self.center = Vector2(center)
        self.base_size = base_size
        self.angle = 0
        self.rotation_speed = 0.2
        self.color = self.generate_gradient()
        self.pulse_phase = 0
        self.current_size = float(base_size)

    def generate_gradient(self):
        # Generate a random color gradient
        return (
            random.randint(50, 200),
            random.randint(50, 200),
            random.randint(50, 200)
        )

    def update(self, dt, mouse_pos):
        # Adjust rotation speed based on mouse position (dynamic effect)
        mouse_influence = (self.center.x - mouse_pos[0]) / 600
        self.rotation_speed = 0.2 + mouse_influence * 0.3
        self.angle = (self.angle + self.rotation_speed * dt) % 360
        
        # Pulsation effect for the square size
        self.pulse_phase += dt * 0.05
        self.current_size = self.base_size + 10 * math.sin(self.pulse_phase)

    def draw(self, surface):
        # Create a square surface with a vertical gradient
        size_int = int(round(self.current_size))
        square_surf = pygame.Surface((size_int, size_int), pygame.SRCALPHA)
        for i in range(size_int):
            alpha = int(255 * (i / size_int))
            pygame.draw.line(square_surf, (*self.color, alpha), (i, 0), (i, size_int))
        # Rotate the square surface and center it at self.center
        rotated = pygame.transform.rotate(square_surf, self.angle)
        rect = rotated.get_rect(center=self.center)
        surface.blit(rotated, rect.topleft)

# ============================
# BouncingBall Class Definition
# ============================
class BouncingBall:
    def __init__(self, center, radius):
        self.pos = Vector2(center)
        self.radius = radius
        # Start with an initial velocity; add a slight random rotation for variation
        self.velocity = Vector2(5, 4).rotate(random.uniform(-15, 15))
        self.trail = []
        self.max_trail_length = 15

    def update(self, square, dt):
        # Update ball position based on velocity and normalized delta time
        self.pos += self.velocity * dt * 60
        
        # Handle collision with the square
        self.handle_collision(square)
        
        # Append current position to the trail (for visual effect)
        self.trail.append((self.pos.copy(), pygame.time.get_ticks()))
        # Keep only the recent trail entries
        self.trail = [entry for entry in self.trail if pygame.time.get_ticks() - entry[1] < 500][-self.max_trail_length:]

    def handle_collision(self, square):
        # Transform the ball's position to the square's local coordinates by rotating by -square.angle
        local_pos = self.pos - square.center
        local_pos = local_pos.rotate(-square.angle)
        
        # Define the effective boundary inside the square (accounting for the ball's radius)
        bounds = square.current_size / 2 - self.radius
        collision_normal = Vector2(0, 0)
        
        # Check horizontal collision in local space
        if abs(local_pos.x) > bounds:
            collision_normal.x = 1 if local_pos.x < 0 else -1
            local_pos.x = bounds * (1 if local_pos.x > 0 else -1)
        # Check vertical collision in local space
        if abs(local_pos.y) > bounds:
            collision_normal.y = 1 if local_pos.y < 0 else -1
            local_pos.y = bounds * (1 if local_pos.y > 0 else -1)
        
        # If a collision occurred, update position and reflect the velocity vector
        if collision_normal.length() > 0:
            # Transform the corrected local position back to global coordinates
            self.pos = square.center + local_pos.rotate(square.angle)
            # Reflect the velocity vector across the collision normal
            self.velocity = self.velocity.reflect(collision_normal.normalize())
            # Apply slight damping
            self.velocity *= 0.98

    def draw(self, surface):
        # Draw the trail for a fading effect
        for i, (pos, timestamp) in enumerate(self.trail):
            alpha = int(255 * (i / len(self.trail)))
            size = self.radius * (0.3 + 0.7 * (i / len(self.trail)))
            trail_surf = pygame.Surface((size * 2, size * 2), pygame.SRCALPHA)
            pygame.draw.circle(trail_surf, (255, 255, 0, alpha), (size, size), size)
            surface.blit(trail_surf, (pos.x - size, pos.y - size))
        # Draw the ball itself
        pygame.draw.circle(surface, (255, 255, 0), (int(self.pos.x), int(self.pos.y)), self.radius)

# ======================
# Main Game Loop
# ======================
def main():
    screen_size = (800, 800)
    screen = pygame.display.set_mode(screen_size)
    clock = pygame.time.Clock()

    # Initialize the square and ball
    square = RotatingSquare((screen_size[0] // 2, screen_size[1] // 2), 500)
    ball = BouncingBall(square.center, 25)

    running = True
    while running:
        dt = clock.tick(60) / 16.667  # Normalize delta time (approx. 60 FPS)
        mouse_pos = pygame.mouse.get_pos()

        # Event handling
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            # Optionally change the square's color with the R key
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_r:
                    square.color = square.generate_gradient()

        # Update game objects
        square.update(dt, mouse_pos)
        ball.update(square, dt)

        # Draw everything
        screen.fill((15, 15, 25))  # Dark background
        square.draw(screen)
        ball.draw(screen)
        pygame.display.flip()

    pygame.quit()

if __name__ == "__main__":
    main()
