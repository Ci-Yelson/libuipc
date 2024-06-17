#include <uipc/geometry/utils/apply_instances.h>
#include <uipc/common/enumerate.h>
#include <Eigen/Geometry>

namespace uipc::geometry
{
vector<SimplicialComplex> apply_transform(const SimplicialComplex& complex)
{
    // here we share all the attributes
    vector<SimplicialComplex> Rs(complex.instances().size(), complex);

    for(auto&& [i, R] : enumerate(Rs))
    {
        // resize the instances
        R.instances().resize(1);
        // copy the instance attributes
        R.instances().copy_from(complex.instances(), AttributeCopy::range(0, i, 1));

        // transform the vertices
        auto T  = view(R.transforms());
        auto Vs = view(R.positions());
        std::ranges::transform(Vs,
                               Vs.begin(),
                               [&](auto&& v) -> Vector3
                               { return Transform{T[0]} * v; });

        // clear the transform
        T[0].setIdentity();
    }

    return Rs;
}
}  // namespace uipc::geometry
