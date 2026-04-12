shader_type canvas_item;

// This allows the GDScript to toggle the flash on and off
uniform bool active = false;

// This allows the GDScript to set the specific color from your Resource
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// Grab the pixel from the actual spider texture
	vec4 tint = texture(TEXTURE, UV);
	
	if (active) {
		// If hit, replace the spider's colors with our flash color
		// but keep the spider's original transparency (alpha)
		tint.rgb = flash_color.rgb;
	}
	
	// Output the final pixel to the screen
	COLOR = tint;
}