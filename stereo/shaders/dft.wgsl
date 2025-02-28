// dft.wgsl
// Functions for computing the discrete Fourier transform and cross-correlation
// of a 4x4 discrete (complex) signal.

struct cmat4 {
    real: mat4x4f,
    imag: mat4x4f,
}

struct cvec4 {
    real: vec4f,
    imag: vec4f,
}

struct Correlation {
    // correlogram
    correlation: mat4x4f,
    // product of mag2 of the multiplicands
    mag2_ab: f32,
}

fn mul_mm(p: cmat4, q: cmat4) -> cmat4 {
    let real: mat4x4f = p.real * q.real - p.imag * q.imag;
    let imag: mat4x4f = p.real * q.imag + p.imag * q.real;
    return cmat4(real, imag);
}

fn mul_mv(m: cmat4, v: cvec4) -> cvec4 {
    let real: vec4f = m.real * v.real - m.imag * v.imag;
    let imag: vec4f = m.real * v.imag + m.imag * v.real;
    return cvec4(real, imag);
}

fn transpose_c(m: cmat4) -> cmat4 {
    return cmat4(transpose(m.real), transpose(m.imag));
}

fn hadamard_mm(m0: mat4x4f, m1: mat4x4f) -> mat4x4f {
    // wgsl sadly doesn't support element-wise multiplication for matrices
    return mat4x4f(
        m0[0] * m1[0],
        m0[1] * m1[1],
        m0[2] * m1[2],
        m0[3] * m1[3],
    );
}

fn hadamard_cc(m0: cmat4, m1: cmat4) -> cmat4 {
    let real: mat4x4f = hadamard_mm(m0.real, m1.real) - hadamard_mm(m0.imag, m1.imag);
    let imag: mat4x4f = hadamard_mm(m0.real, m1.imag) + hadamard_mm(m0.imag, m1.real);
    return cmat4(real, imag);
}

fn complex_mod2(m: cmat4) -> mat4x4f {
    return mat4x4f(
        m.real[0] * m.real[0] + m.imag[0] * m.imag[0],
        m.real[1] * m.real[1] + m.imag[1] * m.imag[1],
        m.real[2] * m.real[2] + m.imag[2] * m.imag[2],
        m.real[3] * m.real[3] + m.imag[3] * m.imag[3],
    );
}

fn conj(m: cmat4) -> cmat4 {
    return cmat4(m.real, -1. * m.imag);
}

fn add(m0: cmat4, m1: cmat4) -> cmat4 {
    return cmat4(m0.real + m1.real, m0.imag + m1.imag);
}

// sum(a . a^†)
fn cnorm2(m: cmat4) -> f32 {
    return dot(vec4f(1.), complex_mod2(m) * vec4f(1.));
}

fn dft4x4(img: cmat4) -> cmat4 {
    let dft: cmat4 = cmat4(
        mat4x4f(
            1.,  1.,  1.,  1.,
            1.,  0., -1.,  0.,
            1., -1.,  1., -1.,
            1.,  0., -1.,  0.
        ),
        mat4x4f(
            0.,  0.,  0.,  0.,
            0., -1.,  0.,  1.,
            0.,  0.,  0.,  0.,
            0.,  1.,  0., -1.
        )
    );
    // DFT * img * DFT^T;
    // except the above is transposed (written row-major, but actually col-major)
    return mul_mm(transpose_c(dft), mul_mm(img, dft));
}

fn inv_dft4x4(X: cmat4) -> cmat4 {
    // DFT^1(X) = (1/N) * swap(DFT(swap(X)));
    // swap(x) := exchange real and imag parts of x
    let result: cmat4 = dft4x4(cmat4(X.imag, X.real));
    let i_16: f32 = 1. / 16.;
    return cmat4(result.imag * i_16, result.real * i_16);
}

fn cross_correlation(img_0: cmat4, img_1: cmat4) -> cmat4 {
    let dft_0: cmat4 = dft4x4(img_0);
    let dft_1: cmat4 = dft4x4(img_1);
    let xcor:  cmat4 = hadamard_cc(conj(dft_0), dft_1);
    return inv_dft4x4(xcor);
}

fn normed_cross_correlation(img_0: cmat4, img_1: cmat4) -> mat4x4f {
    let xcor: cmat4 = cross_correlation(img_0, img_1);
    let m2: mat4x4f = complex_mod2(xcor);
    let sum:    f32 = dot(vec4f(1.), m2 * vec4f(1.));
    if sum == 0. {
        let e:  f32   = 1. / 16.;
        let ev: vec4f = vec4f(e);
        return mat4x4f(ev, ev, ev, ev);
    } else {
        return m2 * (1. / sum);
    }
}

fn quantified_cross_correlation(img_0: cmat4, img_1: cmat4) -> Correlation {
    let xcor: cmat4 = cross_correlation(img_0, img_1);
    let m2: mat4x4f = complex_mod2(xcor);
    let sum:    f32 = dot(vec4f(1.), m2 * vec4f(1.));
    if sum == 0. {
        let e:  f32   = 1. / 16.;
        let ev: vec4f = vec4f(e);
        return Correlation(
            mat4x4f(ev, ev, ev, ev),
            1.,
        );
    } else {
        return Correlation(
            m2,
            cnorm2(img_0) * cnorm2(img_1),
        );
    }
}
