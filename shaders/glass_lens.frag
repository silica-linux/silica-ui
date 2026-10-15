// The edge refraction of a glass lens (silica_ui GlassLens), applied as an image filter to the
// magnified content inside the lens capsule. Inside a band along the edge the content is
// sampled closer to the centre, so it bends outward like the rim of a lens; the core is left
// as it is. Used only where the engine supports shader image filters (Impeller).

#version 460 core

#include <flutter/runtime_effect.glsl>

// Set by the engine: the size of the input texture (the lens bounds).
uniform vec2 uSize;
// The refracting band, as a fraction of the capsule's half height.
uniform float uRim;
// How far the band pulls the content inward, as a fraction of the band.
uniform float uStrength;
// Set by the engine: the content under the filter.
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
  vec2 hs = uSize * 0.5;
  vec2 p = FlutterFragCoord().xy - hs;
  float r = min(hs.x, hs.y);
  // The capsule's spine: the inner rectangle whose rounded offset is the outline.
  vec2 spine = max(hs - vec2(r), vec2(0.0));
  vec2 c = clamp(p, -spine, spine);
  vec2 n = p - c;
  float d = length(n);
  // Signed distance to the outline (negative inside).
  float sd = d - r;
  float band = max(uRim * r, 1.0);
  float t = clamp(1.0 + sd / band, 0.0, 1.0);
  vec2 dir = d > 0.0 ? n / d : vec2(0.0);
  vec2 q = p - dir * band * uStrength * t * t;
  vec2 uv = (q + hs) / uSize;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  fragColor = texture(uTexture, uv);
}
