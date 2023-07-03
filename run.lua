#!/usr/bin/env luajit
require 'ext'
local gl = require 'gl'
local ig = require 'imgui'
local bit = bit32 or require 'bit'
local vec3d = require 'vec-ffi.vec3d'

local App = require 'imguiapp.withorbit'()
App.title = 'n points on a sphere'
App.viewDist = 2

numPoints = 4
dt = .1

function reset()
	pts = range(numPoints):map(function(i)
		if i == 1 then return vec3d(1,0,0) end
		return (vec3d(math.random(), math.random(), math.random())*.2-vec3d(1,1,1)):normalize()
	end)
end

function App:init()
	App.super.init(self)
	reset()
end

function App:initGL()
	App.super.initGL(self)
	gl.glEnable(gl.GL_BLEND)
	gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA)
	gl.glDisable(gl.GL_CULL_FACE)
	gl.glEnable(gl.GL_DEPTH_TEST)
end

function App:update()
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))

	gl.glPointSize(3)
	gl.glBegin(gl.GL_POINTS)
	for _,p in ipairs(pts) do
		gl.glVertex3d(p:unpack())
	end
	gl.glEnd()

	for i=1,#pts do
		for j=1,#pts do
			if i ~= j then
				local d = (pts[i] - pts[j]):normalize()
				pts[i] = (pts[i] + d * dt):normalize()
				pts[j] = (pts[j] - d * dt):normalize()
			end
		end
	end

	App.super.update(self)
end

function App:updateGUI()
	if ig.igButton'reset' then reset() end
	if ig.luatableInputInt('numPoints', _G, 'numPoints') then reset() end
	ig.luatableInputFloat('dt', _G, 'dt')
end

return App():run()
