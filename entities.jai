Entity :: struct {
  position: Vector2;
  size: Vector2;
  texture: *Simp.Texture;
  theta: float;
}

Asteroid :: struct {
  using entity: Entity;
  type: int;
  velocity: Vector2;
  angular_velocity: float;
}

Bullet :: struct {
  using entity: Entity;
  forward_vector: Vector2; // local vector, according to the rotation
}