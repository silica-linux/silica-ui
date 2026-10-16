// The edge refraction of Glass/Regular and Glass/Thick (docs/design/amalfi/materials.md): run as
// a backdrop filter over the already blurred backdrop, clipped to the glass shape. Near the rim
// the backdrop is sampled further outward (the shape bends what is behind it) over a band of
// `depth` x half the shorter side, with a small red/blue split; then saturation and brightness
// are applied to the whole surface and a specular highlight is added along the top rim.
//
// The shape is approximated by a rounded rectangle (centre, half size, radius), in the same
// physical-pixel space as the backdrop texture. Samples never leave the shape, so the unblurred
// content outside it does not bleed in. Used only where the engine supports shader image
// filters (Impeller); elsewhere AmalfiGlass blurs and tones with colour filters only.

#version 460 core

#include <flutter/runtime_effect.glsl>

// Set by the engine: the size of the backdrop texture, in physical pixels.
uniform vec2 uSize;
// The shape's centre and half size, in physical pixels.
uniform vec2 uCenter;
uniform vec2 uHalf;
// Physical pixels per logical point.
uniform float uPt;
// The corner radius, in pt.
uniform float uRadius;
// Refraction: distortion, depth (band = depth x half the shorter side) and chromatic split,
// all as in tokens.json.
uniform float uDistortion;
uniform float uDepth;
uniform float uChroma;
// Saturation and brightness of the backdrop.
uniform float uSaturation;
uniform float uBrightness;
// The strength of the specular highlight (0: none).
uniform float uSpecular;
// Set by the engine: the backdrop.
uniform sampler2D uTexture;

out vec4 fragColor;

vec4 tap(vec2 s) {
  vec2 uv = (uCenter + s * uPt) / uSize;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return texture(uTexture, uv);
}

// Distance inside the outline at `q` (pt from the centre; negative outside) and the outward
// direction there.
float inside(vec2 q, vec2 hs, float r, out vec2 dir) {
  vec2 spine = max(hs - vec2(r), vec2(0.0));
  vec2 n = q - clamp(q, -spine, spine);
  float d = length(n);
  dir = d > 0.0 ? n / d : vec2(0.0);
  return r - d;
}

void main() {
  vec2 q = (FlutterFragCoord().xy - uCenter) / uPt;
  vec2 hs = uHalf / uPt;
  float r = min(uRadius, min(hs.x, hs.y));
  vec2 dir;
  float depth = inside(q, hs, r, dir);
  float band = max(uDepth * min(hs.x, hs.y), 0.001);
  // 1 on the outline, 0 at the inner edge of the band; squared, so that the bend is steepest
  // at the rim.
  float t = clamp(1.0 - depth / band, 0.0, 1.0);
  float e = t * t;

  vec2 s = q + dir * uDistortion * band * e;
  vec2 sdir;
  float sd = inside(s, hs, r, sdir);
  if (sd < 0.5) {
    s -= sdir * (0.5 - sd);
  }
  vec2 shift = dir * uChroma * band * e;
  vec4 mid = tap(s);
  vec4 color = vec4(tap(s + shift).r, mid.g, tap(s - shift).b, mid.a);

  float luma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
  color.rgb = mix(vec3(luma), color.rgb, uSaturation) * uBrightness;

  // The specular highlight: a soft light on the upper rim, strongest facing up.
  float facing = clamp(-dir.y, 0.0, 1.0);
  float spec = uSpecular * facing * t * t * t;
  color.rgb += spec * color.a;
  fragColor = vec4(clamp(color.rgb, 0.0, 1.0), color.a);
}
