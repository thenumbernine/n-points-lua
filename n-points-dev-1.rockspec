package = "n-points"
version = "dev-1"
source = {
	url = "git+https://github.com/thenumbernine/n-points-lua"
}
description = {
	summary = "N points on a sphere",
	detailed = "N points on a sphere",
	homepage = "https://github.com/thenumbernine/n-points-lua",
	license = "MIT"
}
dependencies = {
	"lua >= 5.1"
}
build = {
	type = "builtin",
	modules = {
		["n-points.run"] = "run.lua",
		["n-points.run_orbit"] = "run_orbit.lua"
	}
}
