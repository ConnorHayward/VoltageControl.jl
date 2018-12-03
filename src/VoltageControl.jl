__precompile__(true)

module VoltageControl

using Sockets
using Dates
abstract type Device end

include("Devices/iSeqControl.jl")
include("Devices/KeithleyControl.jl")

function query(device::Device,cmd::String;timeout=1.0) end

function set(device::Device,cmd::String;timeout=1.0) end

end # module
