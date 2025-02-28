#pragma once

#include <geomc/linalg/LinalgTypes.h>
#include <geomc/shape/ShapeTypes.h>
#include <geomc/function/FunctionTypes.h>

using namespace geom;

namespace stereo {

using uint128_t   = __uint128_t;
using gpu_size_t  = uint32_t;

using vec2        = Vec<float,2>;
using vec3        = Vec<float,3>;
using vec4        = Vec<float,4>;
using vec2d       = Vec<double,2>;
using vec3d       = Vec<double,3>;
using vec4d       = Vec<double,4>;
using vec2i       = Vec<int32_t,2>;
using vec3i       = Vec<int32_t,3>;
using vec4i       = Vec<int32_t,4>;
using vec2ui      = Vec<uint32_t,2>;
using vec3ui      = Vec<uint32_t,3>;
using vec4ui      = Vec<uint32_t,4>;
using vec2ub      = Vec<uint8_t,2>;
using vec3ub      = Vec<uint8_t,3>;
using vec4ub      = Vec<uint8_t,4>;
using vec2ul      = Vec<uint64_t,2>;
using vec3ul      = Vec<uint64_t,3>;
using vec4ul      = Vec<uint64_t,4>;
using range       = Rect<float,1>;
using range2      = Rect<float,2>;
using range3      = Rect<float,3>;
using range4      = Rect<float,4>;
using ranged      = Rect<double,1>;
using range2d     = Rect<double,2>;
using range3d     = Rect<double,3>;
using range4d     = Rect<double,4>;
using range1i     = Rect<int32_t,1>;
using range2i     = Rect<int32_t,2>;
using range3i     = Rect<int32_t,3>;
using range4i     = Rect<int32_t,4>;
using range1ui    = Rect<uint32_t,1>;
using range2ui    = Rect<uint32_t,2>;
using range3ui    = Rect<uint32_t,3>;
using range4ui    = Rect<uint32_t,4>;
using range1ul    = Rect<uint64_t,1>;
using range2ul    = Rect<uint64_t,2>;
using range3ul    = Rect<uint64_t,3>;
using range4ul    = Rect<uint64_t,4>;
using box2        = Box<float,2>;
using box3        = Box<float,3>;
using box2d       = Box<double,2>;
using box3d       = Box<double,3>;
using affinebox2  = AffineBox<float,2>;
using affinebox3  = AffineBox<float,3>;
using affinebox2d = AffineBox<double,2>;
using affinebox3d = AffineBox<double,3>;
using quat        = Quat<float>;
using quatd       = Quat<double>;
using xf2         = AffineTransform<float,2>;
using xf3         = AffineTransform<float,3>;
using xf2d        = AffineTransform<double,2>;
using xf3d        = AffineTransform<double,3>;
using mat2        = SimpleMatrix<float,2,2>;
using mat3        = SimpleMatrix<float,3,3>;
using mat4        = SimpleMatrix<float,4,4>;
using mat2d       = SimpleMatrix<double,2,2>;
using mat3d       = SimpleMatrix<double,3,3>;
using mat4d       = SimpleMatrix<double,4,4>;
using ray2        = Ray<float,2>;
using ray3        = Ray<float,3>;
using ray2d       = Ray<double,2>;
using ray3d       = Ray<double,3>;
using circle2     = Circle<float>;
using sphere3     = Sphere<float,3>;
using circle2d    = Circle<double>;
using sphere3d    = Sphere<double,3>;
using seg2        = Cylinder<float,2>;
using seg2d       = Cylinder<double,2>;
using cyl3        = Cylinder<float,3>;
using cyl3d       = Cylinder<double,3>;
using capsule2    = Capsule<float,2>;
using capsule3    = Capsule<float,3>;
using capsule2d   = Capsule<double,2>;
using capsule3d   = Capsule<double,3>;
using roundrect2  = Dilated<Rect<float,2>>;
using roundrect3  = Dilated<Rect<float,3>>;
using roundrect2d = Dilated<Rect<double,2>>;
using roundrect3d = Dilated<Rect<double,3>>;
using frustum3    = Frustum<range2>;
using frustum3d   = Frustum<range2d>;
using tri         = Simplex<float,2>;
using trid        = Simplex<double,2>;
using tet         = Simplex<float,3>;
using tetd        = Simplex<double,3>;

}  // namespace stereo
