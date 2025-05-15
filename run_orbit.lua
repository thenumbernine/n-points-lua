#!/usr/bin/env luajit
require 'ext'
local gl = require 'gl'
local ig = require 'imgui'
local bit = bit32 or require 'bit'
local vec3d = require 'vec-ffi.vec3d'

local App = require 'imgui.appwithorbit'()

App.title = 'n points on a sphere'
App.viewDist = 2

numPoints = 4
dt = .001

function reset()
	pts = range(numPoints):map(function(i)
		if i == 1 then 
			return {
				pos = vec3d(1,0,0),
				vel = vec3d(),
			}
		end
		return {
			pos = (vec3d(math.random(), math.random(), math.random())*.2-vec3d(1,1,1)):normalize(),
			vel = vec3d(),
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
			pts[i].vel = pts[i].vel + d * dt
			pts[j].vel = pts[j].vel - d * dt
		end
	end
	-- normalize pos / constrain to sphere
	for i=1,#pts do
		pts[i].pos = (pts[i].pos + pts[i].vel * dt):normalize()
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
	if ig.luatableInputInt('numPoints', _G, 'numPoints') then reset() end
	ig.luatableInputFloat('dt', _G, 'dt')
end

return App():run()
