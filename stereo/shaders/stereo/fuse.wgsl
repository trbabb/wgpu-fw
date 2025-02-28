// #include "../kalman.wgsl"
// #include "stereo_structs.wgsl"
// #include "camera.wgsl"

// todo: could do basis-conditioning steps on both parent and child;
//   ensure: child < min_size(updated parent cov) < parent < max_size(updated parent cov)
// todo: need to figure and store the "quality" estimate (probs the normalization factor).
//   - could also use the quantified_update formula, and incorporate this

// number of invocations for samples
// @id(1000) override Sample_Invocations: u32 = 4; // wgpu support for constants still IP

// sync with generate_samples.wgsl:
const Sample_Invocations: u32 = 4;

alias FuseMode = u32;

const FuseMode_TimeUpdate:   FuseMode = 0;
const FuseMode_StereoUpdate: FuseMode = 1;
const FuseMode_StereoInit:   FuseMode = 2;

struct FuseUniforms {
    fuse_mode:   FuseMode,
    multiple:    u32,
    cam_a:       CameraState,
    cam_b:       CameraState,
}

@group(0) @binding(0) var<storage,read> samples:       array<WeightedSample>;
@group(0) @binding(1) var<uniform>      uniforms:      FuseUniforms;
@group(0) @binding(2) var<uniform>      feature_range: FeatureRange;

// nb: different bindgroups below!
@group(1) @binding(0) var<storage,read>       src_image_features: array<FeaturePair>;
@group(2) @binding(0) var<storage,read_write> scene_features:     array<SceneFeature>;
@group(3) @binding(0) var<storage,read>       feature_idx_buffer: array<u32>;

@group(4) @binding(0) var<storage,read_write> debug_image_features: array<DebugFeature2D>;

@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) global_id: vec3u) {
    var sample_count: u32 = Sample_Invocations * uniforms.multiple * 2;
    let feature_idx:  u32 = global_id.x;
    let i_idx:        u32 = global_id.x + feature_range.feature_start;
    if i_idx >= arrayLength(&feature_idx_buffer) ||
       i_idx >= feature_range.feature_end
    {
        return;
    }
    let scene_feature_idx: u32 = feature_idx_buffer[i_idx];
    if scene_feature_idx >= arrayLength(&scene_features) { return; }

    // compute the "frequency weighted" covariance and mean of the sample set
    // see https://stats.stackexchange.com/questions/193046/online-weighted-covariance
    // this is a best guess of the distribution of the displacement between the
    // feature endpoints, accounting for both prior predictions and the actual
    // image registration.
    var mu:   vec2f = vec2f(0.);
    var w_sum:  f32 = 0.;
    var C:  mat2x2f = mat2x2f(); // zero matrix
    var q:      f32 = 0.; // quality estimate; a cosine distance
    for (var i: u32 = 0u; i < sample_count; i++) {
        let sample_index: u32 = feature_idx * sample_count + i;
        let sample: WeightedSample = samples[sample_index];
        let w: f32 = sample.w;
        w_sum += w;
        let dx: vec2f = sample.x - mu;
        mu += dx * w / w_sum;
        C  += w * outer2x2(dx, sample.x - mu);
        q  += w * sample.f;
    }
    let k: f32 = 1. / (w_sum - 1.); // weight with bessel correction
    let est_cov: mat2x2f = k * C;
    let est_q:       f32 = q / w_sum;

    let src_image_feature: FeaturePair  = src_image_features[feature_idx];
    let src_scene_feature: SceneFeature = scene_features[scene_feature_idx];

    let fudge_factor: f32 = 1.; // xxx fudge factor

    var updated: Estimate3D;
    if uniforms.fuse_mode == FuseMode_TimeUpdate {
        // perform a time update
        let B: mat2x2f = src_image_feature.b.basis;
        // estimate the mean + covariance in cam-b's view (the current time),
        // in texture coordinates.
        let x: vec2f = src_image_feature.b.st + B * fudge_factor * mu;
        let J_P: Dx3x2 = J_project_dp(uniforms.cam_b, src_scene_feature.x);
        updated = update_ekf_unproject_2d_3d(
            Estimate3D(src_scene_feature.x, src_scene_feature.x_cov),
            J_P.f_x,
            Estimate2D(x, B * est_cov * transpose(B)),
            J_P.J_f
        );
    } else if uniforms.fuse_mode == FuseMode_StereoUpdate {
        // perform a stereo update.
        // the correlogram is just a *correction* to the difference between
        // the two views; add them together. take the difference in kernel-space.
        let tex2kern_a: mat2x2f = inverse2x2(src_image_feature.a.basis);
        let tex2kern_b: mat2x2f = inverse2x2(src_image_feature.b.basis);
        let dx: vec2f = tex2kern_b * src_image_feature.b.st - tex2kern_a * src_image_feature.a.st;
        updated = unproject_kalman_view_difference(
            Estimate3D(src_scene_feature.x, src_scene_feature.x_cov),
            Estimate2D(dx + fudge_factor * mu, est_cov),
            tex2kern_a,
            tex2kern_b,
            uniforms.cam_a,
            uniforms.cam_b
        );
    } else if uniforms.fuse_mode == FuseMode_StereoInit {

        // xxx todo: use update_ekf_unproject_initial_2d_3d()

    }

    let information = 1. / determinant(est_cov);

    // todo: how to update the quality estimate?
    //   - geometric mean of old and new?
    //   - weighted geometric mean, based on quantified overlap?
    //     - i.e., a strong update means the quality is more like the new value,
    //       while a weak estimate is more like the old value.
    //   - consideration: want quality to remain stable in magnitude over time;
    //     this is trivial if we use a geometric mean.
    //   - a raw product would diminish
    scene_features[scene_feature_idx] = SceneFeature(
        // todo: no update to feature orientation for now
        src_scene_feature.q,
        src_scene_feature.q_cov,
        updated.x,
        updated.sigma,
        src_scene_feature.scale,
        sqrt(est_q * src_scene_feature.wt),
        // xxx debug
        src_scene_feature.color,
    );

    debug_image_features[feature_idx] = DebugFeature2D(
        mu,
        est_cov,
        information,
    );
}
