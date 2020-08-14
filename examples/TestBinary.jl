# Imports
using Tempotrons
using Tempotrons.InputGen
using Tempotrons.Optimizers
using Plots

# Set parameters
N = 10
T = 500
dt = 1
t = collect(0:dt:T)
method = :∇
# method = :corr
λ = 1e-4
opt = SGD(λ, momentum = 0.99)
ν = 3
n_samples = 10
n_steps = 20000
tmp = Tempotron(N)

# Generate input samples
base_samples = [poisson_spikes_input(N, ν = ν, T = T) for j = 1:2]
samples = [(x = spikes_jitter(base_samples[2(j - 1) ÷ n_samples + 1], σ = 5),
            y = Bool(2(j - 1) ÷ n_samples)) for j = 1:n_samples]

# Get the tempotron's output before training
out_b = [tmp(s.x, t = t) for s ∈ samples]

# Train the tempotron
@time for i = 1:n_steps
    s = rand(samples)
    train!(tmp, s.x, s.y, optimizer = opt, method = method)
end

# Get the tempotron's output after training
out_a = [tmp(s.x, t = t) for s ∈ samples]

# Plots
gr(size = (800, 1200))
cols = collect(1:2)#palette(:rainbow, 2)

inp_plots = map(samples) do s
    return plot(s.x, color = cols[1 + s.y], markersize = sqrt(5))
end
train_plots = map(zip(samples, out_b, out_a)) do (s, ob, oa)
    p = plot(tmp, t, oa.V, color = cols[1 + s.y])
    plot!(tmp, t, ob.V, color = cols[1 + s.y], linestyle = :dash)
    txt, clr = Tempotrons.get_progress_annotations(length(oa.spikes) > 0,
                                                   N_b = length(ob.spikes) > 0,
                                                   N_t = s.y)
    annotate!(xlims(p)[1], ylims(p)[2], text(txt, 10, :left, :bottom, clr))
    return p
end
ip = plot(inp_plots..., layout = (length(inp_plots), 1), link = :all)
tp = plot(train_plots..., layout = (length(train_plots), 1), link = :all)
p = plot(ip, tp, layout = (1, 2))
display(p)
