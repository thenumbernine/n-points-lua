#!/usr/bin/env luajit
local ffi = require 'ffi'
local table = require 'ext.table'
local gl = require 'gl.setup'(... or 'OpenGLES3')
local ig = require 'imgui'
local vec3f = require 'vec-ffi.vec3f'
local vector = require 'ffi.cpp.vector-lua'
local GLSceneObject = require 'gl.sceneobject'

local App = require 'imguiapp.withorbit'()
App.title = 'n points on a sphere'
App.viewUseBuiltinMatrixMath = true
App.viewDist = 2

-- global for ig table access
numPoints = 4
dt = .1

local ptsCPU = vector'vec3f_t'
local velsCPU = vector'vec3f_t'

local function reset()
	ptsCPU:resize(numPoints)
	ptsCPU.v[0] = vec3f(1,0,0)
	for i=1,numPoints-1 do
		ptsCPU.v[i] = (vec3f(math.random(), math.random(), math.random())*.2 - vec3f(1,1,1)):normalize()
	end

	velsCPU:resize(numPoints)
	for i=0,numPoints-1 do
		velsCPU.v[i] = vec3f()
	end

	vertexBuf = require 'gl.arraybuffer'{
		data = ptsCPU.v,
		size = numPoints * 3 * ffi.sizeof'float',
		usage = gl.GL_DYNAMIC_DRAW,
	}:unbind()

	pointSceneObj = GLSceneObject{
		program = program,
		geometry = {
			mode = gl.GL_POINTS,
			count = numPoints,
		},
		attrs = {
			vertex = {
				buffer = vertexBuf,
			},
		},
	}

	local indexes = table()
	for i=0,numPoints-2 do
		for j=i+1,numPoints-1 do
			indexes:insert(i)
			indexes:insert(j)
		end
	end
	indexesBuf = require 'gl.elementarraybuffer'{
		type = gl.GL_UNSIGNED_INT,
		data = indexes,
	}:unbind()

	lineSceneObj = GLSceneObject{
		program = program,
		geometry = {
			mode = gl.GL_LINES,
			indexes = indexesBuf,
		},
		attrs = {
			vertex = {
				buffer = vertexBuf,
			},
		},
	}
end

function App:initGL()
	App.super.initGL(self)

	-- do this before the first reset()
	program = require 'gl.program'{
		version = 'latest',
		header = 'precision highp float;',
		vertexCode = [[
in vec3 vertex;
uniform mat4 mvProjMat;
uniform float pointSize;
void main() {
	gl_PointSize = pointSize;
	gl_Position = mvProjMat * vec4(vertex, 1.);
}
]],
		fragmentCode = [[
uniform float lum;
out vec4 fragColor;
void main() {
	fragColor = vec4(lum, lum, lum, 1.);
}
]],
	}:useNone()

	reset()

	gl.glEnable(gl.GL_BLEND)
	gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA)
	gl.glDisable(gl.GL_CULL_FACE)
	gl.glEnable(gl.GL_DEPTH_TEST)
end

function App:update()
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))

	gl.glLineWidth(1)
	lineSceneObj.uniforms.mvProjMat = self.view.mvProjMat.ptr
	lineSceneObj.uniforms.pointSize = 1
	lineSceneObj.uniforms.lum = .5
	lineSceneObj:draw()

	-- still doesn't affect point size like https://gamedev.stackexchange.com/a/126118 says
	gl.glLineWidth(3)
	pointSceneObj.uniforms.mvProjMat = self.view.mvProjMat.ptr
	pointSceneObj.uniforms.pointSize = 3
	pointSceneObj.uniforms.lum = 1
	pointSceneObj:draw()

	-- accum vels before normalize = converges without constantly spinning
	for i=0,#ptsCPU-1 do
		velsCPU.v[i]:set(0,0,0)
	end
	for i=0,#ptsCPU-2 do
		for j=i+1,#ptsCPU-1 do
			local d = (ptsCPU.v[i] - ptsCPU.v[j]):normalize()
			velsCPU.v[i] = velsCPU.v[i] + d
			velsCPU.v[j] = velsCPU.v[j] - d
		end
	end
	for i=0,#ptsCPU-1 do
		ptsCPU.v[i] = (ptsCPU.v[i] + velsCPU.v[i] * dt):normalize()
	end
	vertexBuf
		:bind()
		:updateData()
		:unbind()

	App.super.update(self)
end

function App:updateGUI()
	if ig.igButton'reset' then reset() end
	if ig.luatableInputInt('numPoints', _G, 'numPoints') then reset() end
	ig.luatableInputFloat('dt', _G, 'dt')
end

return App():run()
