#include <pyuipc/core/scene_io.h>
#include <uipc/io/scene_io.h>
namespace pyuipc::core
{
using namespace uipc::core;
PySceneIO::PySceneIO(py::module& m)
{
    auto class_SceneIO = py::class_<SceneIO>(m, "SceneIO");
    class_SceneIO.def(py::init<Scene&>(), py::arg("scene"));
    class_SceneIO.def("write_surface", &SceneIO::write_surface, py::arg("filename"));
    class_SceneIO.def(
        "simplicial_surface",
        [](SceneIO& self, IndexT dim) { return self.simplicial_surface(dim); },
        py::arg("dim") = -1);
}
}  // namespace pyuipc::core
