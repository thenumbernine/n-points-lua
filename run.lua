#!/usr/bin/env luajit
local range = require 'ext.range'
local table = require 'ext.table'
local gl = require 'gl'
local ig = require 'imgui'
local bit = bit32 or require 'bit'
local vec3d = require 'vec-ffi.vec3d'

local App = require 'imguiapp.withorbit'()
App.title = 'n points on a sphere'
App.viewDist = 2

-- global for ig table access
numPoints = 4
dt = .1

local pts, vels
local function reset()
	pts = range(numPoints):mapi(function(i)
		if i == 1 then return vec3d(1,0,0) end
		return (vec3d(math.random(), math.random(), math.random())*.2 - vec3d(1,1,1)):normalize()
	end)
	vels = range(numPoints):mapi(function(i)
		return vec3d()
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

	gl.glColor3f(.5, .5, .5)
	gl.glBegin(gl.GL_LINES)
	for i=1,#pts-1 do
		for j=i+1,#pts do
			gl.glVertex3d(pts[i]:unpack())
			gl.glVertex3d(pts[j]:unpack())
		end
	end
	gl.glEnd()
	gl.glPointSize(3)
	gl.glColor3f(1, 1, 1)
	gl.glBegin(gl.GL_POINTS)
	for _,p in ipairs(pts) do
		gl.glVertex3d(p:unpack())
	end
	gl.glEnd()

	-- accum vels before normalize = converges without constantly spinning
	for i=1,#pts do
		vels[i]:set(0,0,0)
	end
	for i=1,#pts-1 do
		for j=i+1,#pts do
			local d = (pts[i] - pts[j]):normalize()
			vels[i] = vels[i] + d
			vels[j] = vels[j] - d
		end
	end
	for i=1,#pts do
		pts[i] = (pts[i] + vels[i] * dt):normalize()
	end

	App.super.update(self)
end

function App:updateGUI()
	if ig.igButton'reset' then reset() end
	if ig.luatableInputInt('numPoints', _G, 'numPoints') then reset() end
	ig.luatableInputFloat('dt', _G, 'dt')
end

return App():run()
