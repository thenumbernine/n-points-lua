#!/usr/bin/env luajit
require 'ext'
require 'vec'
local ffi = require 'ffi'
local ImGuiApp = require 'imguiapp'
local gl = require 'gl'
local ig = require 'ffi.imgui'
local bit = bit32 or require 'bit'

local View = require 'glapp.view'
local Orbit = require 'glapp.orbit'

local App = class(Orbit(View.apply(ImGuiApp)))

App.title = 'n points on a sphere'
App.viewDist = 2

local numPoints = ffi.new('int[1]', 4)
local dt = ffi.new('float[1]', .001)

function reset()
	pts = range(numPoints[0]):map(function(i)
		if i == 1 then 
			return {
				pos = vec3(1,0,0),
				vel = vec3(),
			}
		end
		return {
			pos = (vec3(math.random(), math.random(), math.random())*.2-vec3(1,1,1)):normalize(),
			vel = vec3(),
		}
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
		gl.glVertex3d(p.pos:unpack())
	end
	gl.glEnd()

	for i=1,#pts-1 do
		for j=i+1,#pts do
			local d = pts[i].pos - pts[j].pos
			pts[i].vel = pts[i].vel + d * dt[0]
			pts[j].vel = pts[j].vel - d * dt[0]
		end
	end
	-- normalize pos / constrain to sphere
	for i=1,#pts do
		pts[i].pos = (pts[i].pos + pts[i].vel * dt[0]):normalize()
	end
	-- project out pos from vel / enforce tangent vel
	for i,p in ipairs(pts) do
		local s = p.vel:length()
		p.vel = p.vel - p.pos * p.pos:dot(p.vel)
		p.vel = p.vel:normalize() * s
	end

	App.super.update(self)
end

function App:updateGUI()
	if ig.igButton'reset' then reset() end
	if ig.igInputInt('numPoints', numPoints) then reset() end
	ig.igInputFloat('dt', dt)
end

App():run()
