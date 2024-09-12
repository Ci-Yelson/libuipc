#include <finite_element/codim_2d_constitution.h>
#include <finite_element/constitutions/shell_neo_hookean_2d_function.h>
#include <kernel_cout.h>
#include <muda/ext/eigen/log_proxy.h>
#include <Eigen/Dense>
#include <muda/ext/eigen/inverse.h>
#include <utils/codim_thickness.h>

namespace uipc::backend::cuda
{
class ShellNeoHookean2D final : public Codim2DConstitution
{
  public:
    // Constitution UID by libuipc specification
    static constexpr U64 ConstitutionUID = 11;

    using Codim2DConstitution::Codim2DConstitution;

    vector<Float> h_kappas;
    vector<Float> h_lambdas;

    muda::DeviceBuffer<Float> kappas;
    muda::DeviceBuffer<Float> lambdas;

    virtual U64 get_constitution_uid() const override
    {
        return ConstitutionUID;
    }

    virtual void do_build(BuildInfo& info) override {}

    virtual void do_retrieve(FiniteElementMethod::Codim2DFilteredInfo& info) override
    {

        auto geo_slots = world().scene().geometries();

        auto N = info.primitive_count();

        h_kappas.resize(N);
        h_lambdas.resize(N);

        SizeT I = 0;

        info.for_each(
            geo_slots,
            [](geometry::SimplicialComplex& sc) -> auto
            {
                auto mu     = sc.triangles().find<Float>("mu");
                auto lambda = sc.triangles().find<Float>("lambda");

                return zip(mu->view(), lambda->view());
            },
            [&](SizeT vi, auto mu_and_lambda)
            {
                auto&& [mu, lambda] = mu_and_lambda;
                h_kappas[I]         = mu;
                h_lambdas[I]        = lambda;
                I++;
            });

        kappas.resize(N);
        kappas.view().copy_from(h_kappas.data());

        lambdas.resize(N);
        lambdas.view().copy_from(h_lambdas.data());
    }

    virtual void do_compute_energy(ComputeEnergyInfo& info) override
    {
        using namespace muda;
        namespace NH = sym::shell_neo_hookean_2d;

        ParallelFor()
            .kernel_name(__FUNCTION__)
            .apply(info.indices().size(),
                   [mus        = kappas.cviewer().name("mus"),
                    lambdas    = lambdas.cviewer().name("lambdas"),
                    rest_areas = info.rest_areas().viewer().name("rest_area"),
                    thicknesses = info.thicknesses().viewer().name("thicknesses"),
                    element_energies = info.element_energies().viewer().name("energies"),
                    indices = info.indices().viewer().name("indices"),
                    xs      = info.xs().viewer().name("xs"),
                    x_bars  = info.x_bars().viewer().name("x_bars"),
                    dt      = info.dt()] __device__(int I)
                   {
                       Vector9  X;
                       Vector3i idx = indices(I);
                       for(int i = 0; i < 3; ++i)
                           X.segment<3>(3 * i) = xs(idx(i));

                       Vector9 X_bar;
                       for(int i = 0; i < 3; ++i)
                           X_bar.segment<3>(3 * i) = x_bars(idx(i));

                       Matrix2x2 IB;
                       NH::A(IB, X_bar);
                       IB = muda::eigen::inverse(IB);

                       if constexpr(RUNTIME_CHECK)
                       {
                           Matrix2x2 A;
                           NH::A(A, X);
                           Float detA = A.determinant();
                       }

                       Float mu        = mus(I);
                       Float lambda    = lambdas(I);
                       Float rest_area = rest_areas(I);
                       Float thickness = triangle_thickness(thicknesses(idx(0)),
                                                            thicknesses(idx(1)),
                                                            thicknesses(idx(2)));

                       Float E;
                       NH::E(E, mu, lambda, X, IB);
                       element_energies(I) = E * rest_area * thickness * dt * dt;
                   });
    }

    virtual void do_compute_gradient_hessian(ComputeGradientHessianInfo& info) override
    {
        using namespace muda;
        namespace NH = sym::shell_neo_hookean_2d;

        ParallelFor()
            .kernel_name(__FUNCTION__)
            .apply(info.indices().size(),
                   [mus     = kappas.cviewer().name("mus"),
                    lambdas = lambdas.cviewer().name("lambdas"),
                    indices = info.indices().viewer().name("indices"),
                    xs      = info.xs().viewer().name("xs"),
                    x_bars  = info.x_bars().viewer().name("x_bars"),
                    thicknesses = info.thicknesses().viewer().name("thicknesses"),
                    G9s        = info.gradient().viewer().name("gradient"),
                    H9x9s      = info.hessian().viewer().name("hessian"),
                    rest_areas = info.rest_areas().viewer().name("volumes"),
                    dt         = info.dt()] __device__(int I)
                   {
                       Vector9  X;
                       Vector3i idx = indices(I);
                       for(int i = 0; i < 3; ++i)
                           X.segment<3>(3 * i) = xs(idx(i));

                       Vector9 X_bar;
                       for(int i = 0; i < 3; ++i)
                           X_bar.segment<3>(3 * i) = x_bars(idx(i));

                       Matrix2x2 IB;
                       NH::A(IB, X_bar);
                       IB = muda::eigen::inverse(IB);

                       Float mu        = mus(I);
                       Float lambda    = lambdas(I);
                       Float rest_area = rest_areas(I);
                       Float thickness = triangle_thickness(thicknesses(idx(0)),
                                                            thicknesses(idx(1)),
                                                            thicknesses(idx(2)));

                       Float Vdt2 = rest_area * thickness * dt * dt;

                       Vector9 G;
                       NH::dEdX(G, mu, lambda, X, IB);
                       G9s(I) = G * Vdt2;

                       Matrix9x9 H;
                       NH::ddEddX(H, mu, lambda, X, IB);

                       H9x9s(I) = H * Vdt2;
                   });
    }
};

REGISTER_SIM_SYSTEM(ShellNeoHookean2D);
}  // namespace uipc::backend::cuda
