-- Runs fogfx.wgsl into a GPU canvas and draws the result across the artboard.
-- `scared` is bound to the view model's `hover` flag, so the fog turns sickly
-- green and churns faster while the Lurker is being poked.

type Fog = {
    context: Context?,
    canvas: GPUCanvas?,
    pipeline: GPUPipeline?,
    group: GPUBindGroup?,
    ubo: GPUBuffer?,
    params: buffer,
    sampler: ImageSampler,
    size: Vector,
    scale: number,
    time: number,
    scare: number,
    scared: Input<boolean>,
}

function init(self: Fog, context: Context): boolean
    self.context = context
    local shader = context:shader('fogfx')
    if shader == nil then
        print('fog: shader "fogfx" not found')
        return true
    end
    local pipeline = GPUPipeline.new({
        vertex = shader,
        fragment = shader,
        vertexLayout = {},
        colorTargets = { { format = 'rgba8unorm' } },
    })
    local ubo = GPUBuffer.new({ size = 16, usage = 'uniform' })
    self.pipeline = pipeline
    self.ubo = ubo
    self.group = GPUBindGroup.new({
        layout = pipeline:getBindGroupLayout(0),
        ubos = { { slot = 0, buffer = ubo } },
    })
    self.canvas = context:gpuCanvas()
    return true
end

function resize(self: Fog, size: Vector, scale: number)
    self.size = size
    self.scale = scale
    local canvas = self.canvas
    if canvas ~= nil then
        canvas:resize(math.max(1, math.floor(size.x * scale)), math.max(1, math.floor(size.y * scale)))
    end
end

function advance(self: Fog, seconds: number): boolean
    self.time += seconds
    local target = if self.scared then 1 else 0
    self.scare += (target - self.scare) * math.min(1, seconds * 5)
    return true
end

function draw(self: Fog, renderer: Renderer)
    local canvas = self.canvas
    local pipeline = self.pipeline
    local group = self.group
    local ubo = self.ubo
    if canvas == nil or pipeline == nil or group == nil or ubo == nil or canvas.width == 0 then
        return
    end

    buffer.writef32(self.params, 0, self.time)
    buffer.writef32(self.params, 4, self.scare)
    buffer.writef32(self.params, 8, canvas.width)
    buffer.writef32(self.params, 12, canvas.height)
    ubo:write(self.params)

    local pass = canvas:beginRenderPass({
        color = { { loadOp = 'clear', storeOp = 'store', clearColor = { 0, 0, 0, 0 } } },
    })
    pass:setPipeline(pipeline)
    pass:setBindGroup(0, group)
    pass:draw(3)
    pass:finish()

    -- the canvas is in device pixels; the artboard is in points
    renderer:save()
    renderer:transform(Mat2D.withScale(1 / self.scale))
    renderer:drawImage(canvas.image, self.sampler, 'srcOver', 1)
    renderer:restore()
end

return function(context: Context): Layout<Fog>
    return {
        context = nil,
        canvas = nil,
        pipeline = nil,
        group = nil,
        ubo = nil,
        params = buffer.create(16),
        sampler = ImageSampler('clamp', 'clamp', 'bilinear'),
        size = Vector.xy(0, 0),
        scale = 1,
        time = 0,
        scare = 0,
        scared = false,
        init = init,
        resize = resize,
        advance = advance,
        draw = draw,
    }
end
