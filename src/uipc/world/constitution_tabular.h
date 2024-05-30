#pragma once
#include <uipc/world/constitution.h>
#include <uipc/common/vector.h>
#include <uipc/common/span.h>

namespace uipc::world
{
class ConstitutionTabular
{
  public:
    ConstitutionTabular() = default;

    template <std::derived_from<IConstitution> T, typename... Args>
    [[nodiscard]] T& create(Args&&...);

    span<U64> uids() const noexcept;

  private:
    vector<U<IConstitution>> m_constitutions;
    mutable bool             m_is_sorted = false;
    mutable vector<U64>      m_uids;
    void                     sort_if_needed() const noexcept;
};
}  // namespace uipc::world

#include "details/consistution_tabular.inl"