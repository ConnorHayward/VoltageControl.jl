struct Keithley_6487 <:Device
    name::String
    ip::String
    port::Int

    function Keithley_6487(name::String, ip::String, port::Int)
        device = new(name, ip, port)
        return device
    end

    function Base.show(io::IO, device::Keithley_6487)
      for n in fieldnames(typeof(device))
        println(io, "$n: $(getfield(device,n))")
      end
    end
end

export Keithley_6487

const Keithley_Module = Union{Keithley_6487}

CRLF = "\r\n"
function query(device::Keithley_Module, cmd::String; timeout=1.0)::String
    c = -1
    while c == -1
        try
            c = connect(device.ip,device.port)
            #println("Connection Successful")
            break
        catch err
            println(err)
        end
        sleep(0.5)
    end

    cmd = "$cmd$CRLF"
    println(c,cmd)

    t0 = time()
    t = 0.
    r=""
    task = @async (r=readline(c);)
    while t < timeout
        if task.state == :done break end
        t = time()-t0
        sleep(0.01)
    end

    close(c)

    if t >= timeout
        error("Timeout! Device did not answer.")
    else
        return split(split(r,"\x13")[2], "\x11")[1]
    end
    sleep(0.1)
end

export query

function set(device::Keithley_Module, cmd::String)
    c = -1
    while c == -1
        try
            c = connect(device.ip,device.port)
            break
        catch err
            println(err)
        end
        sleep(0.5)
    end

    cmd = "$cmd$CRLF"
    for char in cmd
        sleep(0.2)
        write(c, char)
    end
    close(c)
    nothing
end

function set_voltage(device::Keithley_Module,ampl::Real)
    cmd = ":SOURce:VOLTage:AMPLitude $ampl"
    set(device, cmd)
end
export set_voltage

function get_voltage(device::Keithley_Module)
    cmd = ":SOURce:VOLTage?"
    return parse(Float64,query(device, cmd))
end

export get_voltage

function set_voltage_limit(device::Keithley_Module,limit::Real)
    if limit <= 10
        limit = 10
    elseif limit <= 50
        limit = 50
    else
        limit = 500
    end
    cmd = ":SOURce:VOLTage:RANGe $Range"
    set(device,cmd)
end

export set_voltage_limit

function get_voltage_limit(device::Keithley_Module)
    return parse(Float64,query(device,":SOURce:VOLTage:RANGe?"))
end
export get_voltage_limit

function set_current_limit(device::Keithley_Module, limit::Real)
    voltage_limit = get_voltage_limit(device)

    if voltage_limit >= 50
        if limit <= 2.5e-5
            limit = 2.5e-5
        elseif limit >= 2.5e-3
            limit = 2.5e-3
        end
    elseif voltage_limit == 10
        if limit <= 2.5e-5
            limit = 2.5e-5
        elseif limit >= 2.5e-2
            limit = 2.5e-2
        end
    end
    cmd = ":SOURce:VOLTage:ILIMit $limit"
    println(limit)
    set(device,cmd)
end

export set_current_limit

function get_current_limit(device::Keithley_Module)
    return parse(Float64,query(device,":SOURce:VOLTage:ILIMit?"))
end

export get_current_limit

function get_device_information(device::Keithley_Module)
    return query(device,"*IDN?")
end

export get_device_information

function show_device_information(device::Keithley_Module)
    r = split(get_device_information(device),",")
    println("Manufacturer: $(r[1])")
    println("Model: $(r[2])")
    println("Serial number: $(r[3])")
    println("Software release: $(r[4][7:end-10])")
    println("Board version: $(r[4][end-8:end-6])")
end

export show_device_information

function set_power_state(device::Keithley_Module,state::Real)
    cmd = String()
    if state == 0
        cmd = ":SOURce:VOLTage:STATe OFF"
    else
        cmd = ":SOURce:VOLTage:STATe ON"
    end
    set(device, cmd)
end

export set_power_state
function get_power_state(device::Keithley_Module)
    return parse(Float64,query(device,":SOURce:VOLTage:STATe?"))
end
export get_power_state

function show_power_state(device::Keithley_Module)
    if (get_power_state(device)==false)
        println("Power Off")
    else
        println("Power On")
    end
end
export show_power_state

function set_sweep_range(device::Keithley_Module,start::Real,stop::Real)
    if query(device,":SOURce:VOLTage:SWEep:STATe?") == "0"
        set(device, ":SOURce:VOLTage:SWEep:STARt $start")
        set(device, ":SOURce:VOLTage:SWEep:STOP $stop")
    else
        return "Sweep in progress, values not overwritten"
    end
end

function set_sweep_range(device,range::Union{AbstractUnitRange,StepRange})
    if query(device,":SOURce:VOLTage:SWEep:STATe?") == "0"
        set_sweep_range(device,range[1],range[end])
        set_sweep_step(device,step(range))
    else
        return "Sweep in progress, values not overwritten"
    end
end
export set_sweep_range

function get_sweep_range(device::Keithley_Module)
    start = parse(Float64,query(device,":SOURce:VOLTage:SWEep:STARt?"))
    stop = parse(Float64,query(device,":SOURce:VOLTage:SWEep:STOP?"))
    return start:stop
end
export get_sweep_range

function set_sweep_step(device::Keithley_Module,step::Real)
    if query(device,":SOURce:VOLTage:SWEep:STATe?") == "0"
        set(device,":SOURce:VOLTage:SWEep:STEP $step")
    else
        return "Sweep in progress, values not overwritten"
    end
end
export set_sweep_step

function get_sweep_step(device::Keithley_Module)
    return parse(Float64,query(device,":SOURce:VOLTage:SWEep:STEP?"))
end
export get_sweep_step

function set_sweep_delay(device::Keithley_Module,delay::Real)
    if query(device,":SOURce:VOLTage:SWEep:STATe?") == "0"
        set(device, ":SOURce:VOLTage:SWEep:DELay $delay")
    else
        return "Sweep in progress, values not overwritten"
    end
end
export set_sweep_delay

function get_sweep_delay(device::Keithley_Module)
    return parse(Float64,query(device,":SOURce:VOLTage:SWEep:DELay?"))
end
export get_sweep_delay

function get_sweep_params(device::Keithley_Module)
    range = get_sweep_range(device)
    step = get_sweep_step(device)
    delay = get_sweep_delay(device)
    return range[1]:step:range[end], delay
end

export get_sweep_params

function show_sweep_params(device::Keithley_Module)
    params = get_sweep_params(device)
    println("Range: $(params[1][1]):$(params[1][end]) V")
    println("Step: $(params[1][2]) V")
    println("Delay: $(params[2]) s")
end
export show_sweep_params

function toggle_sweep(device::Keithley_Module,switch::Real)
    state = Bool(parse(Float64,query(device,":SOURce:VOLTage:SWEep:STATe?")))

    bool_switch = true
    if switch != 0
        bool_switch = true
    else
        bool_switch = false
    end

    if bool_switch && !state
        set(device,":SOURce:VOLTage:SWEep:INITiate")
        println("Sweep Started")
    elseif !bool_switch && state
        set(device,":SOURce:VOLTage:SWEep:ABORt")
        println("Sweep Aborted")
    else
        println("State not changed")
    end
end

export toggle_sweep

function get_current_settings(device::Keithley_Module)
    amp = get_voltage(device)
    v_max = get_voltage_limit(device)
    i = get_current_limit(device)
    sweep_params = get_sweep_params(device)
    state = get_power_state(device)
    return amp,v_max,i, sweep_params,state
end

function show_all_settings(device::Keithley_Module)
    params = get_current_settings(device)
    println("Voltage: $(params[1]) V")
    println("Voltage Limit: $(params[2]) V")
    println("Current Limit: $(params[3]) A")
    show_power_state(device)
    show_sweep_params(device)
end

export show_all_settings

function save_settings(device::Keithley_Module,slot::Int64)
    set(device,"*SAV $slot")
    return "Settings saved to $slot"
end

export save_settings

function load_settings(device::Keithley_Module,slot::Int64;display::Bool=false)
    set(device,"*RCL $slot")
    if display
        println("Loaded settings from $slot")
        return show_all_settings(device)
    else
        return "Loaded settings from $slot"
    end
end

export load_settings

function clear_buffer(device::Keithley_Module)
    set(device,"*CLR")
end

export clear_buffer


function pause_buffer(device::Keithley_Module)
    set(device,"*WAI")
end
