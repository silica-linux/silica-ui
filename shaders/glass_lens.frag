// The glass lens of the segmented control (silica_ui GlassLens), run as a backdrop filter: it
// reads the window's own pixels under the lens capsule (the track, its rim, the pill and the
// labels, and the toolbar where the lens overhangs it) and draws them refracted:
//
// - magnified about the lens centre (1.11 x at full presence);
// - bent near the rim: the closer to the edge, the further outward the backdrop is sampled, so
//   what lies just outside the lens is pulled inside it (the track's top and bottom edge lines
//   show ~3 pt inside the lens, measured), and ~0 at the centre;
// - slightly blurred near the rim, with red and blue sampled apart on the curved ends (colour
//   fringes);
// - with a thin dark outer rim and a 1 pt light line inside the top and bottom edges.
//
// Coordinates: FlutterFragCoord() is the pixel in the backdrop texture, which is the window's
// render pass (physical pixels, origin at the top left of the view); the lens geometry comes in
// the same space. Used only where the engine supports shader image filters (Impeller).

#version 460 core

#include <flutter/runtime_effect.glsl>

// Set by the engine: the size of the backdrop texture, in physical pixels.
uniform vec2 uSize;
// The lens centre and half size, in physical pixels.
uniform vec2 uCenter;
uniform vec2 uHalf;
// Physical pixels per logical point.
uniform float uPt;
// The magnification about the centre (1 at presence 0).
uniform float uMag;
// How far outward the backdrop is sampled at the very rim, in pt (0 at the centre, growing
// with the square of the distance towards the edge).
uniform float uDepth;
// The blur radius at the rim, in pt.
uniform float uBlur;
// The red / blue offset on the curved ends, in pt.
uniform float uChroma;
// How much of the rim (dark edge, light lines, lift) shows: the lens presence, 0..1.
uniform float uAmount;
// The lift of the backdrop inside the lens (the glass is a little brighter than the track).
uniform float uLift;
// The dark outer rim and the light line (straight RGBA, 0..1).
uniform vec4 uEdge;
uniform vec4 uHighlight;
// Set by the engine: the backdrop.
uniform sampler2D uTexture;

out vec4 fragColor;

// The backdrop at `s` pt from the lens centre.
vec4 tap(vec2 s) {
  vec2 uv = (uCenter + s * uPt) / uSize;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return texture(uTexture, uv);
}

// The backdrop at `s`, blurred over `r` pt (a five-tap cross, weighted to the centre).
vec4 soft(vec2 s, float r) {
  if (r < 0.05) {
    return tap(s);
  }
  return (2.0 * tap(s) + tap(s + vec2(r, 0.0)) + tap(s - vec2(r, 0.0)) +
          tap(s + vec2(0.0, r)) + tap(s - vec2(0.0, r))) /
         6.0;
}

vec4 over(vec4 under, vec4 color, float a) {
  float k = clamp(color.a * a, 0.0, 1.0);
  return vec4(mix(under.rgb, color.rgb, k), under.a + (1.0 - under.a) * k);
}

void main() {
  vec2 q = (FlutterFragCoord().xy - uCenter) / uPt;
  vec2 hs = uHalf / uPt;
  float r = min(hs.x, hs.y);
  // The capsule's spine: the segment whose rounded offset by r is the outline.
  vec2 spine = max(hs - vec2(r), vec2(0.0));
  vec2 n = q - clamp(q, -spine, spine);
  float d = length(n);
  // Distance inside the outline, in pt (negative outside).
  float depth = r - d;
  if (depth < -1.0 || r <= 0.0) {
    // Outside the lens (clipped away anyway): the backdrop as it is.
    fragColor = tap(q);
    return;
  }
  vec2 dir = d > 0.0 ? n / d : vec2(0.0);
  // 0 at the spine, 1 on the outline.
  float e = clamp(d / r, 0.0, 1.0);
  float e2 = e * e;

  vec2 s = q / uMag + dir * uDepth * e2;
  float blur = uBlur * e2;
  // The colour fringes only on the curved ends.
  float ends = clamp((abs(q.x) - spine.x) / r, 0.0, 1.0) * e2;
  vec2 shift = dir * uChroma * ends;
  vec4 mid = soft(s, blur);
  vec4 color = vec4(soft(s + shift, blur).r, mid.g, soft(s - shift, blur).b, mid.a);
  color.rgb += uLift * uAmount * color.a;

  // The light line: 1 pt wide, centred 2 pt inside the outline, on the top and bottom only.
  float line = 1.0 - smoothstep(0.25, 0.75, abs(depth - 2.0));
  float vertical = smoothstep(0.55, 0.9, abs(dir.y));
  color = over(color, uHighlight, uAmount * line * vertical);
  // The dark outer rim: the outermost 1.5 pt.
  float rim = 1.0 - smoothstep(1.0, 1.75, depth);
  color = over(color, uEdge, uAmount * rim);
  fragColor = color;
}
