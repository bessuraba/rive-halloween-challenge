// Eerie ground fog for the Lurker.
// Domain-warped fbm noise, thick near the floor, with a few slow ghost wisps.
// `scare` (0..1) speeds the fog up and bleeds it from lavender to sickly green.

struct Params {
    time: f32,
    scare: f32,
    res: vec2<f32>,
};

@group(0) @binding(0) var<uniform> u: Params;

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
};

// One oversized triangle that covers the whole target.
@vertex
fn vs_main(@builtin(vertex_index) idx: u32) -> VertexOutput {
    var out: VertexOutput;
    let x = f32((idx << 1u) & 2u);
    let y = f32(idx & 2u);
    out.position = vec4<f32>(x * 2.0 - 1.0, y * 2.0 - 1.0, 0.0, 1.0);
    out.uv = vec2<f32>(x, y);
    return out;
}

fn hash21(p: vec2<f32>) -> f32 {
    var q = fract(p * vec2<f32>(123.34, 456.21));
    q = q + dot(q, q + 45.32);
    return fract(q.x * q.y);
}

fn vnoise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let s = f * f * (3.0 - 2.0 * f);
    let a = hash21(i);
    let b = hash21(i + vec2<f32>(1.0, 0.0));
    let c = hash21(i + vec2<f32>(0.0, 1.0));
    let d = hash21(i + vec2<f32>(1.0, 1.0));
    return mix(mix(a, b, s.x), mix(c, d, s.x), s.y);
}

fn fbm(p_in: vec2<f32>) -> f32 {
    var p = p_in;
    var amp = 0.5;
    var sum = 0.0;
    for (var i = 0; i < 5; i = i + 1) {
        sum = sum + amp * vnoise(p);
        p = p * 2.03 + vec2<f32>(17.1, 9.2);
        amp = amp * 0.5;
    }
    return sum;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    // uv.y = 0 is the bottom of the image on this target; flip so 0 is the floor.
    let uv = vec2<f32>(in.uv.x, in.uv.y);
    let aspect = u.res.x / max(u.res.y, 1.0);
    let speed = 0.06 + 0.22 * u.scare;
    let t = u.time * speed;

    // domain warp: fog curls around itself
    var p = vec2<f32>(uv.x * aspect, uv.y) * 2.6;
    let w = vec2<f32>(fbm(p + vec2<f32>(t, 0.0)), fbm(p + vec2<f32>(0.0, -t) + 5.2));
    let n = fbm(p + 1.8 * w + vec2<f32>(t * 0.7, 0.0));

    // density: heavy at the floor, wispy halfway up, gone at the top
    let floor_w = smoothstep(0.62, 0.0, uv.y);
    let mid_w = smoothstep(0.85, 0.2, uv.y) * 0.35;
    var density = (floor_w + mid_w) * smoothstep(0.28, 0.85, n);

    // soft ghost wisps drifting across the middle of the frame
    let wisp_y = 0.45 + 0.08 * sin(u.time * 0.4 + uv.x * 5.0);
    let wisp = exp(-pow((uv.y - wisp_y) * 7.0, 2.0)) * smoothstep(0.45, 0.8, n) * 0.28;
    density = clamp(density + wisp, 0.0, 0.85);

    let calm = vec3<f32>(0.52, 0.42, 0.78);
    let angry = vec3<f32>(0.55, 0.9, 0.25);
    let col = mix(calm, angry, u.scare);

    // premultiplied alpha output
    let a = density * 0.72;
    return vec4<f32>(col * a, a);
}
