#import "Basic";
#import "String";
#import "System";
#import "Window_Creation";
Simp :: #import "Simp";
#import "Math";
#import "Input";
#import "Random";

#load "2d_collision.jai";

ASPECT :: (10.0/10.0);
WINDOW_HEIGHT :: cast(s32)1200;
WINDOW_WIDTH :: cast(s32)(WINDOW_HEIGHT * ASPECT);

// Just for fun.
#assert(ASPECT >= 1);

title_font: *Simp.Dynamic_Font;
game_font: *Simp.Dynamic_Font;
data_folder: string;
should_quit_game: bool = false;

ship_texture: Simp.Texture;
ship_size := Vector2.{32, 32};
ship_pos := Vector2.{300, 300};
ship_theta := 0.0;
ship_force := Vector2.{0, 0};
ship_velocity := Vector2.{0, 0};

key_left: bool;
key_right: bool;
key_space: bool;
key_shift: bool;

SMALL_ASTEROID :: 0;
MEDIUM_ATEROID :: 1;
BIG_ASTEROID :: 2;

Asteroid :: struct {
  alive: bool;
  type: int;
  position: Vector2;
  size: Vector2;
  velocity: Vector2;
  theta: float;
  angular_velocity: float;
}

asteroid_textures: [3]Simp.Texture;
asteroids: [..]Asteroid;
time_until_asteroid_spawn := 4.0;

delta_time: float32;

main :: () {
  base_path := path_strip_filename(get_path_of_running_executable());
  data_folder = join(base_path, "data");

  window := create_window(window_name="Asteroids", width=WINDOW_WIDTH, height=WINDOW_HEIGHT);
  Simp.set_render_target(window);

  seed := to_calendar(current_time_consensus()).millisecond;
  random_seed(seed.(u64));

  init_textures();
  init_fonts();

  delta_time = 0.016;
  last_time: float64 = 0;

  // Alloc some space up front for our asteroids array
  array_resize(*asteroids, 250);

  while !should_quit_game {
    reset_temporary_storage();
    update_window_events();
    
    now := seconds_since_init();
    delta_time = (now - last_time).(float32);
    last_time = now;    

    /* RENDER NOW */
    Simp.clear_render_target(0, 0, 0, 1);
    
    {
      text_w := Simp.prepare_text(title_font, "asteroids");
      text_y := WINDOW_HEIGHT - title_font.character_height;
      color := Vector4.{1, 1, 1, 1};
      Simp.draw_prepared_text(title_font, 0, text_y, color);
    }

    {
      ship_debug_str := tprint("force, velocity = {%, %}, {%, %}", ship_force.x.(s64), ship_force.y.(s64), ship_velocity.x.(s64), ship_velocity.y.(s64));
      text_w := Simp.prepare_text(title_font, ship_debug_str);
      text_y := WINDOW_HEIGHT - title_font.character_height*2;
      color := Vector4.{1, 1, 1, 1};
      Simp.draw_prepared_text(title_font, 0, text_y, color);
    }

    draw_ship();
    draw_asteroids();

    Simp.swap_buffers(window);

    /* SIMULATE */
    update_keys();
    if key_right {
      ship_theta -= 120.0 * delta_time;
    }
    else if key_left {
      ship_theta += 120.0 * delta_time;
    }
    if key_space {
      thrust_forward_ship();
    }

    simulate_ship();
    simulate_asteroids();
  }
}

simulate_asteroids :: () {
  time_until_asteroid_spawn -= delta_time;
  if time_until_asteroid_spawn < 0.0 {
    time_until_asteroid_spawn = 4.0;
    spawn_asteroid(MEDIUM_ATEROID);
  }

  for *asteroids {
    it.theta += it.angular_velocity * delta_time;
    it.position += it.velocity * delta_time;
    
    // Check collision between asteroid and ship
    h := Vector2.{ship_size.x, 0};
    v := Vector2.{0, ship_size.y};

    radians := (TAU / 360.0) * ship_theta;

    h = rotate(h, radians);
    v = rotate(v, radians);

    t0 := ship_pos;
    t1 := ship_pos + Vector2.{ship_size.x, 0};
    t2 := ship_pos + Vector2.{ship_size.x/2, ship_size.y};
    if triangle_intersect_circle(it.position, 128, t0, t1, t2) {
      remove it;
    }
  }
}

simulate_ship :: () {
  damping_force := -2.5 * ship_force * delta_time;
  ship_force += damping_force;

  ship_velocity = ship_force * delta_time;
  ship_pos += ship_velocity;
}

thrust_forward_ship :: () {
  up_vector := Vector2.{0, 1};
  radians := (TAU / 360.0) * ship_theta;
  forward_vector := rotate(up_vector, radians);
  ship_force += forward_vector * 1000.0 * delta_time;
}

update_keys :: inline () {
  for event : events_this_frame {
    if event.type == .QUIT {
        should_quit_game = true;
        break;
    }

    if event.type == .KEYBOARD {
      key := event.key_code;
      if key == .ARROW_LEFT  then key_left  = event.key_pressed.(bool);
      if key == .ARROW_RIGHT then key_right = event.key_pressed.(bool);
      if key == .SPACEBAR    then key_space = event.key_pressed.(bool);
      if key == .SHIFT       then key_shift = event.key_pressed.(bool);
    }
  }
}

load_texture :: (name: string) -> Simp.Texture, bool {
  file_name := tprint("%/%", data_folder, name);
  result: Simp.Texture;
  success := Simp.texture_load_from_file(*result, file_name);
  return result, success;
}

get_random_point_outside_of_play_area :: (thing_size: Vector2) -> Vector2 {
  side := random_get_within_range(0, 3.999).(u8); // Ugly
  result: Vector2;
  if side == {
    case 0; // left side
      result.x = -thing_size.x;
      result.y = random_get_within_range(thing_size.y, WINDOW_HEIGHT-thing_size.y);
    case 1; // right side 
      result.x = WINDOW_WIDTH.(float) + thing_size.x;
      result.y = random_get_within_range(thing_size.y, WINDOW_HEIGHT-thing_size.y);
    case 2; // top side
      result.x = random_get_within_range(0, WINDOW_WIDTH-thing_size.x);
      result.y = WINDOW_HEIGHT + thing_size.y;
    case 3; // bottom side
      result.x = random_get_within_range(0, WINDOW_WIDTH-thing_size.x);
      result.y = -thing_size.y;
    case;
      print("wtf this shouldn't happen!?!?");
  }
  
  return result;
}

spawn_asteroid :: (type: int) {
  size := Vector2.{128, 128};
  position := get_random_point_outside_of_play_area(size);
  center := Vector2.{(WINDOW_WIDTH/2).(float), (WINDOW_HEIGHT/2).(float)};
  velocity := normalize(center - position) * 100.0;
  angular_velocity := random_get_within_range(-50.0, 50.0);
  array_add(*asteroids, Asteroid.{
    true,
    type,
    position,
    size,
    velocity,
    0.0,
    angular_velocity
  });
}

draw_asteroids :: () {
  for asteroids {
    my_draw_immediate(*asteroid_textures[it.type], it.position, it.size, it.theta);
  }
}

init_textures :: () {
  ship_texture = load_texture("ship.png");

  // asteroid_textures[SMALL_ASTEROID] = load_texture("");
  asteroid_textures[MEDIUM_ATEROID] = load_texture("asteroid-256-256.png");
  // asteroid_textures[SMALL_ASTEROID] = load_texture("");
}

draw_ship :: () {
  my_draw_immediate(*ship_texture, ship_pos, ship_size, ship_theta);
}

my_draw_immediate :: (texture: *Simp.Texture, pos: Vector2, size: Vector2, theta: float) {
  Simp.set_shader_for_images(texture);

  h := Vector2.{size.x, 0};
  v := Vector2.{0, size.y};

  radians := (TAU / 360.0) * theta;

  h = rotate(h, radians);
  v = rotate(v, radians);

  p0 := pos - h - v;
  p1 := pos + h - v;
  p2 := pos + h + v;
  p3 := pos - h + v;

  Simp.immediate_quad(p0, p1, p2, p3,  Vector4.{1, 1, 1, 1});
}

init_fonts :: () {
  TITLE_PIXEL_SIZE :: 32; 
  title_font = Simp.get_font_at_size(data_folder, "0xProto-Regular.ttf", TITLE_PIXEL_SIZE);
  assert(title_font != null);
  
  GAME_PIXEL_SIZE :: 16;
  game_font = Simp.get_font_at_size(data_folder, "0xProto-Regular.ttf", GAME_PIXEL_SIZE);
  assert(game_font != null);
}