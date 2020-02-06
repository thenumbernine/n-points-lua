#!/usr/bin/env luajit
require 'ext'
local ffi = require 'ffi'
local gl = require 'gl'
local ig = require 'ffi.imgui'
local bit = bit32 or require 'bit'
local vec3d = require 'vec-ffi.vec3d'

local App = class(require 'glapp.orbit'(require 'imguiapp'))
App.title = 'n points on a sphere'
App.viewDist = 2

local numPoints = ffi.new('int[1]', 4)
local dt = ffi.new('float[1]', .1)

function reset()
	pts = range(numPoints[0]):map(function(i)
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
				pts[i] = (pts[i] + d * dt[0]):normalize()
				pts[j] = (pts[j] - d * dt[0]):normalize()
			end
		end
	end

	App.super.update(self)
end

function App:updateGUI()
	if ig.igButton'reset' then reset() end
	if ig.igInputInt('numPoints', numPoints) then reset() end
	ig.igInputFloat('dt', dt)
end

App():run()
