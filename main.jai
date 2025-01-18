#import "Basic";
#import "String";
#import "System";
#import "Window_Creation";
Simp :: #import "Simp";
#import "Math";
#import "Input";

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
ship_width := 32.0;
ship_height := 32.0;
ship_pos := Vector2.{300, 300};
ship_theta := 0.0;
ship_force := Vector2.{0, 0};
ship_velocity := Vector2.{0, 0};

key_left: bool;
key_right: bool;
key_space: bool;
key_shift: bool;

delta_time: float32;

main :: () {
  base_path := path_strip_filename(get_path_of_running_executable());
  data_folder = join(base_path, "data");

  window := create_window(window_name="Asteroids", width=WINDOW_WIDTH, height=WINDOW_HEIGHT);
  Simp.set_render_target(window);

  init_textures();
  init_fonts();

  delta_time = 0.016;
  last_time: float64 = 0;

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

    draw_ship_at(ship_pos);
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
      if key == .ARROW_LEFT  then key_left  = cast(bool)event.key_pressed;
      if key == .ARROW_RIGHT then key_right = cast(bool)event.key_pressed;
      if key == .SPACEBAR    then key_space = cast(bool)event.key_pressed;
      if key == .SHIFT       then key_shift = cast(bool)event.key_pressed;
    }
  }
}

load_texture :: (name: string) -> Simp.Texture, bool {
  file_name := tprint("%/%", data_folder, name);
  result: Simp.Texture;
  success := Simp.texture_load_from_file(*result, file_name);
  return result, success;
}

init_textures :: () {
  ship_texture = load_texture("ship.png");
}

draw_ship_at :: (pos: Vector2) {
  Simp.set_shader_for_images(*ship_texture);

  h := Vector2.{ship_width, 0};
  v := Vector2.{0, ship_height};

  radians := (TAU / 360.0) * ship_theta;

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