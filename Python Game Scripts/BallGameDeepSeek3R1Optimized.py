import pygame
import math
import random
from pygame.math import Vector2

# Initialize Pygame
pygame.init()
pygame.display.set_caption("Quantum Bouncer v1.0 (Fixed)")

class QuantumSquare:
    def __init__(self, center, size):
        self.center = Vector2(center)
        self.base_size = size
        self.angle = 0
        self.rotation_speed = 0.2
        self.color = self.generate_gradient()
        self.pulse_phase = 0
        self.current_size = float(size)  # Initialize as float

    def generate_gradient(self):
        return (
            random.randint(50, 200),
            random.randint(50, 200),
            random.randint(50, 200)
        )

    def update(self, dt, mouse_pos):
        # Dynamic rotation based on mouse position
        mouse_influence = (self.center.x - mouse_pos[0]) / 600
        self.rotation_speed = 0.2 + mouse_influence * 0.3
        self.angle += self.rotation_speed * dt

        # Size pulsation effect (keep as float for smooth animation)
        self.pulse_phase += dt * 0.05
        self.current_size = self.base_size + 10 * math.sin(self.pulse_phase)

    def draw(self, surface):
        # Convert to integer for drawing operations
        current_size_int = int(round(self.current_size))
        
        # Create gradient surface with integer size
        gradient_surf = pygame.Surface((current_size_int, current_size_int), pygame.SRCALPHA)
        
        # Draw gradient with integer range
        for i in range(current_size_int):
            alpha = int(255 * (i/current_size_int))
            pygame.draw.line(
                gradient_surf, 
                (*self.color, alpha), 
                (i, 0), 
                (i, current_size_int)
            )

        # Rotate and draw
        rotated = pygame.transform.rotate(gradient_surf, self.angle)
        rect = rotated.get_rect(center=self.center)
        surface.blit(rotated, rect.topleft)

# ... (Rest of the EntangledBall class and main function remain the same) ...

class EntangledBall:
    def __init__(self, center, radius):
        self.pos = Vector2(center)
        self.radius = radius
        self.velocity = Vector2(5, 4).rotate(random.uniform(-15, 15))
        self.trail = []
        self.max_trail_length = 15

    def update(self, square, dt):
        self.pos += self.velocity * dt * 60
        self.resolve_collisions(square)
        self.trail.append((self.pos.copy(), pygame.time.get_ticks()))
        self.trail = [entry for entry in self.trail 
                     if pygame.time.get_ticks() - entry[1] < 500][-self.max_trail_length:]

    def resolve_collisions(self, square):
        local_pos = self.pos - square.center
        local_pos.rotate_ip(-square.angle)
        
        # Use the original float size for accurate collision detection
        bounds = square.current_size / 2 - self.radius
        collision_normal = Vector2(0, 0)

        if abs(local_pos.x) > bounds:
            collision_normal.x = 1 if local_pos.x < 0 else -1
            local_pos.x = bounds * (1 if local_pos.x > 0 else -1)

        if abs(local_pos.y) > bounds:
            collision_normal.y = 1 if local_pos.y < 0 else -1
            local_pos.y = bounds * (1 if local_pos.y > 0 else -1)

        if collision_normal.length() > 0:
            global_pos = local_pos.rotate(square.angle) + square.center
            self.pos.update(global_pos)
            self.velocity = self.velocity.reflect(collision_normal.normalize())
            self.velocity *= 0.98

    def draw(self, surface):
        for i, (pos, timestamp) in enumerate(self.trail):
            alpha = int(255 * (i/len(self.trail)))
            size = self.radius * (0.3 + 0.7 * (i/len(self.trail)))
            trail_surface = pygame.Surface((size*2, size*2), pygame.SRCALPHA)
            pygame.draw.circle(trail_surface, (255, 255, 0, alpha), (size, size), size)
            surface.blit(trail_surface, (pos.x - size, pos.y - size))
        pygame.draw.circle(surface, (255, 255, 0), self.pos, self.radius)

def main():
    screen_size = (800, 800)
    screen = pygame.display.set_mode(screen_size)
    clock = pygame.time.Clock()
    square = QuantumSquare(screen_size[0]//2, 500)
    ball = EntangledBall(square.center, 25)

    running = True
    while running:
        dt = clock.tick(60) / 16.667
        mouse_pos = pygame.mouse.get_pos()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_r:
                    square.color = square.generate_gradient()

        square.update(dt, mouse_pos)
        ball.update(square, dt)

        screen.fill((15, 15, 25))
        square.draw(screen)
        ball.draw(screen)
        pygame.display.flip()

    pygame.quit()

if __name__ == "__main__":
    main()