#import "Math";

triangle_intersect_circle :: (circle_position: Vector2, circle_radius: float, t0: Vector2, t1: Vector2, t2: Vector2) -> bool {

  circle_radius_squared := circle_radius*circle_radius; // To avoid squaring stuff

  // Test 1: vertex within circle
  distance_to_vertex_check :: (vertex: Vector2, circle_position: Vector2, circle_radius_squared: float) -> bool {
    circle_to_vertex := circle_position - vertex;
    return length_squared(circle_to_vertex) < circle_radius_squared;
  }
  if distance_to_vertex_check(t0, circle_position, circle_radius_squared) {
    return true;
  }
  if distance_to_vertex_check(t1, circle_position, circle_radius_squared) {
    return true;
  }
  if distance_to_vertex_check(t2, circle_position, circle_radius_squared) {
    return true;
  }

  edge0 := t1 - t0;
  edge1 := t2 - t1;
  edge2 := t0 - t2;

  circle_v0 := circle_position - t0;
  circle_v1 := circle_position - t1;
  circle_v2 := circle_position - t2;

  circle_v0_squared := circle_v0.x*circle_v0.x + circle_v0.y*circle_v0.y - circle_radius_squared;
  circle_v1_squared := circle_v1.x*circle_v1.x + circle_v1.y*circle_v1.y - circle_radius_squared;
  circle_v2_squared := circle_v2.x*circle_v2.x + circle_v2.y*circle_v2.y - circle_radius_squared;

  k := dot(circle_v0, edge0);
  if k > 0 {
    edge_length_squared := length_squared(edge0);
    if k < edge_length_squared {
      if circle_v0_squared * edge_length_squared <= k * k {
        return true;
      }
    }
  }

  k = dot(circle_v1, edge1);
  if k > 0 {
    edge_length_squared := length_squared(edge1);
    if k < edge_length_squared {
      if circle_v1_squared * edge_length_squared <= k * k {
        return true;
      }
    }
  }

  k = dot(circle_v2, edge2);
  if k > 0 {
    edge_length_squared := length_squared(edge2);
    if k < edge_length_squared {
      if circle_v2_squared * edge_length_squared <= k * k {
        return true;
      }
    }
  }

  return false; // No intersection detected
}

// Assuming circle positions are centered in the circle
circle_intersects_circle :: (circle1_position: Vector2, circle1_radius: float, circle2_position: Vector2, circle2_radius: float) -> bool {
    circle_to_circle := distance_squared(circle1_position, circle2_position);
    radius_sum := circle1_radius + circle2_radius;
    return circle_to_circle <= radius_sum * radius_sum;
}

resolve_asteroid_collision :: (a1: *Asteroid, a2: *Asteroid) {
    // Calculate a direction between asteroids  and a tangential vector.
    n := normalize(a2.position - a1.position);
    t := Vector2.{-n.y, n.x};

    // Resolve overlap
    // {
    //     dist := length(a2.position - a1.position);
    //     overlap := (a1.size.x + a2.size.y) - dist;
    //     if overlap > 0.0 {
    //         correction := n * (overlap / 2.0);
    //         a1.position -= correction;
    //         a2.position += correction;
    //     }
    // }

    // decompose velocities
    v1n := dot(a1.velocity, n);
    v1t := dot(a1.velocity, t);
    v2n := dot(a2.velocity, n);
    v2t := dot(a2.velocity, t);

    // swap normal velocity components.
    v1n_prime := v2n;
    v2n_prime := v1n;

    // recombine new velocities.
    a1.velocity= v1n_prime * n + v1t * t;
    a2.velocity= v2n_prime * n + v2t * t;
}