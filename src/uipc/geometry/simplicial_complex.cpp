#include <uipc/geometry/simplicial_complex.h>
#include <uipc/common/log.h>
#include <uipc/builtin/attribute_name.h>

namespace uipc::geometry
{
backend::BufferView backend_view(const SimplicialComplexTopo<VertexSlot>&& v) noexcept
{
    return backend_view(v.m_topology);
}

span<IndexT> view(SimplicialComplexTopo<VertexSlot>&& v)
{
    return view(v.m_topology);
}

bool SimplicialComplexTopo<VertexSlot>::is_shared() && noexcept
{
    return m_topology.is_shared();
}

SimplicialComplexTopo<VertexSlot>::SimplicialComplexTopo(VertexSlot& v)
    : m_topology{v}
{
}

SimplicialComplex::SimplicialComplex(const AbstractSimplicialComplex& asc,
                                     span<const Vector3>              positions)
    : m_asc{asc}
{
    UIPC_ASSERT(positions.size() == m_asc.vertices().size(),
                "Number of vertices in the simplicial complex ({}) does not match the number of positions ({}).",
                m_asc.vertices().size(),
                positions.size());

    m_vertex_attributes.resize(m_asc.vertices().size());
    m_edge_attributes.resize(m_asc.edges().size());
    m_triangle_attributes.resize(m_asc.triangles().size());
    m_tetrahedron_attributes.resize(m_asc.tetrahedra().size());

    auto pos   = m_vertex_attributes.create<Vector3, false>(builtin::position,
                                                          Vector3::Zero());
    auto view_ = view(*pos);
    std::copy(positions.begin(), positions.end(), view_.begin());
}

AttributeSlot<Vector3>& SimplicialComplex::positions()
{
    return *m_vertex_attributes.find<Vector3>(builtin::position);
}

const AttributeSlot<Vector3>& SimplicialComplex::positions() const
{
    return *m_vertex_attributes.find<Vector3>(builtin::position);
}

auto SimplicialComplex::vertices() -> VertexAttributes
{
    return VertexAttributes(m_asc.m_vertices, m_vertex_attributes);
}

auto SimplicialComplex::edges() -> EdgeAttributes
{
    return EdgeAttributes(m_asc.m_edges, m_edge_attributes);
}

auto SimplicialComplex::triangles() -> TriangleAttributes
{
    return TriangleAttributes(m_asc.m_triangles, m_triangle_attributes);
}

auto SimplicialComplex::tetrahedra() -> TetrahedronAttributes
{
    return TetrahedronAttributes(m_asc.m_tetrahedra, m_tetrahedron_attributes);
}

IndexT SimplicialComplex::dim() const
{
    if(m_asc.m_tetrahedra.size() > 0)
        return 3;
    if(m_asc.m_triangles.size() > 0)
        return 2;
    if(m_asc.m_edges.size() > 0)
        return 1;
    return 0;
}

std::string_view SimplicialComplex::get_type() const
{
    return "SimplicialComplex";
}
}  // namespace uipc::geometry