// #include "stereo_structs.wgsl"
// #include "../kalman.wgsl"

// nb: different bindgroups each!
@group(0) @binding(0) var<uniform>            feature_range:       FeatureRange;
@group(1) @binding(0) var<storage,read>       src_child_features:  array<SceneFeature>;
@group(2) @binding(0) var<storage,read_write> dst_parent_features: array<SceneFeature>;
@group(3) @binding(0) var<storage,read>       parent_nodes:        array<TreeNode>;
@group(4) @binding(0) var<storage,read>       parent_idx_buffer:   array<u32>;


fn is_nan_f(v: f32) -> bool {
    return v != v;
}

fn is_nan_v3(v: vec3f) -> bool {
    return is_nan_f(v.x) || is_nan_f(v.y) || is_nan_f(v.z);
}

fn is_nan_m3(m: mat3x3f) -> bool {
    return is_nan_v3(m[0]) || is_nan_v3(m[1]) || is_nan_v3(m[2]);
}

@compute @workgroup_size(32)
fn main(@builtin(global_invocation_id) global_id: vec3u) {
    let i_idx: u32 = global_id.x + feature_range.feature_start;
    if i_idx >= arrayLength(&parent_idx_buffer) ||
       i_idx >= feature_range.feature_end
    {
        return;
    }
    let parent_idx: u32 = parent_idx_buffer[i_idx];
    if parent_idx >= arrayLength(&dst_parent_features) { return; }
    
    let parent_node:    TreeNode = parent_nodes[parent_idx];
    let parent_feature: SceneFeature = dst_parent_features[parent_idx];
    
    if parent_node.child_begin >= parent_node.child_end { return; } // no children
    
    // aggregate the covariance of all the children
    let first_child  = src_child_features[parent_node.child_begin];
    var e: WeightedEstimate3D = WeightedEstimate3D(
        first_child.x,
        first_child.x_cov,
        1. // xxx first_child.wt,
    );
    var c: vec3f = first_child.color; // xxx first_child.wt * first_child.color;
    for (var i: u32 = parent_node.child_begin + 1; i < parent_node.child_end; i++) {
        let child: SceneFeature = src_child_features[i];
        e = aggregate_3d(e, WeightedEstimate3D(child.x, child.x_cov, 1.)); // xxx child.wt));
        c += child.color; // child.wt * child.color;
    }
    
    // compute the aggregated quality
    let n: f32 = f32(parent_node.child_end - parent_node.child_begin);
    // we are weighting children by quality, so we can think of the 
    // quality as the "sample size" of each child. so the average quality
    // of the children is just the "average size" of the samples:
    let wt_children = e.wt / n;
    // parent quality is the geometric mean of itself and its children,
    // where each node gets a weight of one. the parent itself adds information
    // to the system; its weight reflects how well the feature matches at this scale.
    let new_wt = pow(
        pow(wt_children, n) * parent_feature.wt,
        1. / (n + 1.)
    );
    
    if is_nan_m3(e.sigma) || is_nan_f(e.wt) || is_nan_v3(e.x) {
        // there's a nan. mark this guy as fucky and early exit
        dst_parent_features[parent_idx].color = vec3(1.);
        return;
    }
    
    // write out the result
    dst_parent_features[parent_idx].x     = e.x;
    dst_parent_features[parent_idx].x_cov = e.sigma;
    dst_parent_features[parent_idx].wt    = e.wt; // new_wt;
    dst_parent_features[parent_idx].color = c / e.wt;
}
