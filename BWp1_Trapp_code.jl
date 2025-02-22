# ==============================================================================================================
# PACKAGES USED
# ==============================================================================================================
using Plots
using Measures
using PyPlot

# ==============================================================================================================
# UTILITY FUNCTIONS
# ==============================================================================================================

#Creating the disturbance
function gaussian_function(a, x, x0, y, y0, σ)
        return a * exp(-((x - x0)^2 + (y - y0)^2) / (2 * σ^2))
end

function apply_gaussian_to_field!(simulation_field, x, y; a = 1e6, σ = 1e3, x0 = 0.0, y0 = -3e3)
       for j in eachindex(y)
        for i in eachindex(x)
            simulation_field[i, j] = gaussian_function(a, x[i], x0, y[j], y0, σ)
        end
    end
end

# Finding peaks of the incoming P-waves to determine arrival time
function search_p_arrival(t, signal; limit = 1e-5)
        for i in eachindex(signal)
        if abs(signal[i]) > limit
            return t[i]
        end
    end
    return NaN
end

# Finding peaks of the incoming S-waves to determine arrival time: S-wave should arrive after P-wave
function search_s_arrival(t, signal; limit = 1e-6, tmin = 0.0, window = 1.0)
    indexrange = findall(x -> x >= tmin && x <= tmin + window, t)      # Search time window for s-wave: time between tmin and tmin + window  --> 0 to 1 s
    if isempty(indexrange)   # If no index found, then the array is empty and "not a number" will be printed
        return NaN
    end
 
    for k in indexrange      # Checking, if the value of signal for each index reaches the given limit
                if abs(signal[k]) > limit
            return t[k] # --> if true: arrival time of s-wave
        end
    end
    return NaN
end

# ==============================================================================================================
# MAIN FUNCTION: Simulation of 2-dimensional seismic wave propagation
# ==============================================================================================================

function wave_propagation_2D()
  
    #------------------------------------------------------------------------------------------------------------
    # Creating the physical 2D domain (asymmetric) and initializing the arrays
    #------------------------------------------------------------------------------------------------------------
    
    xmin, xmax = 0, 80e3  # [m]
    ymin, ymax = -30e3, 8 # [m]
    ncx, ncy = 400, 250   # Grid
    Δx, Δy = (xmax -xmin) / ncx, (ymax -ymin) / ncy

    # Ghost nodes for edges
    x_vertices = LinRange(xmin, xmax, ncx + 1)  
    y_vertices = LinRange(ymin, ymax, ncy + 1)
    
    # Cell centers without Ghost Nodes
    x_center  = LinRange(xmin +Δx /2, xmax -Δx /2, ncx + 0) 
    y_center  = LinRange(ymin +Δy /2, ymax -Δy /2, ncy + 0)
    
    # Arrays for velocity
    velocity_x = zeros(ncx + 1, ncy + 2)    
    velocity_y = zeros(ncx + 2, ncy + 1) 

    # Arrays for pressure and shear stress  
    P   = zeros(ncx, ncy)
    τxy = zeros(ncx + 1, ncy + 1)
   
    # Initializing P- and τxy-fields with Gaussian function --> starting disturbance
    apply_gaussian_to_field!(P, x_center, y_center, a = 1e6, σ = 1e3, x0 = 0.0, y0 = -30e3)
    apply_gaussian_to_field!(τxy, x_vertices, y_vertices, a = 1e6, σ = 1e3, x0 = 0.0, y0 = -30e3)
    
    #------------------------------------------------------------------------------------------------------------
    # Material Parameters & Theoretical P- and S-wave speeds
    #------------------------------------------------------------------------------------------------------------

    K = 5e10 # [Pa]
    G = 3e10 # [Pa]
    ρ = 2700 # [kg/m^3]
    
    vp = sqrt((K + 4/3*G) / ρ)
    vs = sqrt(G / ρ)
    
    #------------------------------------------------------------------------------------------------------------
    # Time loop 
    #------------------------------------------------------------------------------------------------------------
   
    ndim = 2
    t = 0.0
    Δt = Δx / vp / (2.1 * ndim) # Time step based on the CFL-criteria
    nt = 4000
    time_array = zeros(nt)

    #------------------------------------------------------------------------------------------------------------
    # Initialization of Velocity Magnitude
    #------------------------------------------------------------------------------------------------------------

    velocity_magnitude = zeros(ncx, ncy)
    velocity_xc = zeros(ncx, ncy) 
    velocity_yc = zeros(ncx, ncy)

    #------------------------------------------------------------------------------------------------------------
    # Kinematics: Creating Arrays for strain rates (ϵ) and stresses (τ)
    #------------------------------------------------------------------------------------------------------------

    v_div = zeros(ncx, ncy)
    ε̇xy  = zeros(ncx +1, ncy +1)
    ε̇xx  = zeros(ncx, ncy)
    ε̇yy  = zeros(ncx, ncy)
    τxy  = zeros(ncx +1, ncy +1)
    τxx  = zeros(ncx, ncy)
    τyy  = zeros(ncx, ncy)
      
    #------------------------------------------------------------------------------------------------------------
    # Synthetic seismograms recorded at surface stations (x = 20 and 40 km)
    #------------------------------------------------------------------------------------------------------------

    xst1, yst1 = 20e3, 0.0 # [m], Station 1
    xst2, yst2 = 40e3, 0.0 # [m], Station 2

    # Finding the closest grid cell for the seismic stations
    i_st1 = argmin(abs.(x_center .- xst1))
    j_st1 = argmin(abs.(y_center .- yst1))
    i_st2 = argmin(abs.(x_center .- xst2))
    j_st2 = argmin(abs.(y_center .- yst2))

    Ux_st1 = zeros(nt) #Empty arrays for displacement
    Ux_st2 = zeros(nt)
    
    #------------------------------------------------------------------------------------------------------------
    # visualisation
    #------------------------------------------------------------------------------------------------------------
    
    # Main time loop
    for it in 1:nt
        t += Δt # Updating time with Δt
        time_array[it] = t   
                      
        #------------------------------------------------------------------------------------------------------------
        # Boundary Conditions (Neumann)
        #------------------------------------------------------------------------------------------------------------

        velocity_x[:, 1] .= velocity_x[:, 2]
        velocity_x[:, end] .= velocity_x[:, end - 1]
        velocity_y[1, :] .= velocity_y[2, :]
        velocity_y[end, :] .= velocity_y[end - 1, :]
        
        #------------------------------------------------------------------------------------------------------------
        # Divergence and strain rates
        #------------------------------------------------------------------------------------------------------------

        v_div .= diff(velocity_x[:, 2:end-1], dims = 1) / Δx + diff(velocity_y[2:end-1, :], dims = 2) / Δy
        ε̇xx .= diff(velocity_x[:, 2:end-1], dims = 1) / Δx - v_div / 3
        ε̇yy .= diff(velocity_y[2:end-1, :], dims = 2) / Δy - v_div / 3
        ε̇xy .= 0.5 * (diff(velocity_x, dims = 2) / Δy + diff(velocity_y, dims = 1) / Δx)
    
        #------------------------------------------------------------------------------------------------------------
        # Updating the stress components
        #------------------------------------------------------------------------------------------------------------
       
        τxx  .+= 2 * G .* Δt .* ε̇xx
        τyy  .+= 2 * G .* Δt .* ε̇yy
        τxy  .+= 2 * G .* Δt .* ε̇xy
        P    .-= K .* Δt .* v_div
    
        #------------------------------------------------------------------------------------------------------------
        # Updating the velocities
        #------------------------------------------------------------------------------------------------------------
      
        velocity_x[2:end-1, 2:end -1] .+= Δt / ρ .* (diff(τxx .- P, dims = 1) ./Δx + diff(τxy[2:end-1,:], dims = 2) ./Δy )
        velocity_y[2:end-1, 2:end -1] .+= Δt / ρ .* (diff(τyy .- P, dims = 2) ./Δy + diff(τxy[:,2:end-1], dims = 1) ./Δx )
    
        #------------------------------------------------------------------------------------------------------------
        # Updating the velocity magnitude for each cell
        #------------------------------------------------------------------------------------------------------------

        velocity_xc .= 0.5*(velocity_x[1:end-1,2:end-1] .+ velocity_x[2:end,2:end-1])
        velocity_yc .= 0.5*(velocity_y[2:end-1,1:end-1] .+ velocity_y[2:end-1,2:end])
        velocity_magnitude  .= sqrt.( velocity_xc.^2 .+ velocity_yc.^2)

        #------------------------------------------------------------------------------------------------------------
        # Updating station seismograms: displacement calculated as v_x * Δt
        #------------------------------------------------------------------------------------------------------------
        
        velocity_xc .= 0.5 .* (velocity_x[1:end-1,2:end-1] .+ velocity_x[2:end,2:end-1]) # Interpolation of average velocity
 
        vx_st1 = velocity_xc[i_st1, j_st1]
        vx_st2 = velocity_xc[i_st2, j_st2]

        if it == 1
          Ux_st1[it] = 0.0  # No displacement at first time step 
          Ux_st2[it] = 0.0
  
        else
          Ux_st1[it] = vx_st1 * Δt  # Instantaneous displacement for each time step Δt
          Ux_st2[it] = vx_st2 * Δt           
        end

        # -------------------------------------------------
        # Plot only every 100 time step.
        # -------------------------------------------------

        # Nesting loop
        if mod(it, 100) == 0
                            
            fig, axes = PyPlot.subplots(2, 1, figsize = (10, 8))
            fig.subplots_adjust(hspace=0.8) 
    
            # Heatmap of wave propagation
            ax1 = axes[1]
            cax = ax1.imshow(velocity_magnitude', extent=(xmin / 1000, xmax / 1000, ymin / 1000, ymax / 1000),
                origin = "lower", aspect = "auto", cmap = "inferno", vmin = 0, vmax = 0.006)
            ax1.set_title("|v| - time = $(round(it * Δt, digits=2)) s", fontsize = 20, weight = "bold", pad = 15)
            ax1.set_xlabel("x [km]", fontsize = 16)
            ax1.set_ylabel("y [km]", fontsize = 16)
            ax1.set_xticks(collect(0:20:80))  
            ax1.set_yticks(collect(-30:10:0))
            ax1.tick_params(axis = "both", which = "major", labelsize = 14) 
            cbar = fig.colorbar(cax, ax = ax1, label = "|v| [km/s]", pad = 0.1)
            cbar.ax.yaxis.labelpad = 15
            cbar.ax.tick_params(labelsize = 14)  
            cbar.ax.set_ylabel("|v| [km/s]", fontsize = 16)
           
            # Marking the seismic stations at the surface
            station_x_position = [20, 40] # [km]
            station_y_position = 0 
            station_color = ["lightgreen", "darkgreen"] 
            station_markers = ["o", "s"] 

            for (i, number) in enumerate(station_x_position)
                ax1.scatter(number, station_y_position, color = station_color[i], edgecolor = "black", 
                marker = station_markers[i], s = 200, label = "Station $i")
            end
            ax1.legend(loc = "upper left", bbox_to_anchor = (1.4, 1), fontsize = 14)

            # Seismogram of displacement 
            ax2 = axes[2]
            ax2.plot(time_array, Ux_st1 .* 1000, label = "Ux of Station 1", color = "blue", linewidth=2)
            ax2.plot(time_array, Ux_st2 .* 1000, label = "Ux of Station 2", linewidth=2, color="orange")
            ax2.set_xlim(0, 20)
            ax2.set_ylim(-0.025, 0.05)
            ax2.set_xlabel("t [s]", fontsize = 16)
            ax2.set_ylabel("Displacement Ux [mm]", fontsize=16, labelpad=10)
            ax2.legend(loc = "upper right", fontsize = 12)
            ax2.set_title("Surface Displacement Time Series at Stations", weight = "bold", pad = 15, fontsize = 20)
            ax2.set_xticks(collect(0:5:20))  
            ax2.set_yticks(collect(-0.02:0.01:0.05)) 
            ax2.tick_params(axis = "both", which = "major", labelsize = 14)
            ax2.grid("on") 
                
            PyPlot.tight_layout(pad=2.0, h_pad=2.0)
            PyPlot.savefig("timestep_$(it).png")
            PyPlot.close(fig)

        end # end of nesting loop
       
    end # of main time loop  
    
    # -------------------------------------------------
    # Analyzing the P- and S-wave of the seismogram.
    # -------------------------------------------------
    
    time_p_st1 = search_p_arrival(time_array, Ux_st1)
    time_p_st2 = search_p_arrival(time_array, Ux_st2)

    time_s_st1 = search_s_arrival(time_array, Ux_st1; limit = 1e-6, tmin = time_p_st1 + 1, window = 3.0) # time_p_st1 + 1 --> S-wave should arrive after P-Wave
    time_s_st2 = search_s_arrival(time_array, Ux_st2; limit = 1e-6, tmin = time_p_st2 + 1, window = 3.0)

    println("\n===== P- and S-waves arrival times =====\n")

    println("Arrival of P-Wave at Station 1 (20 km) = $time_p_st1 s, Arrival of P-Wave at Station 2 (40 km) = $time_p_st2 s")
    println("Arrival of S-Wave at Station 1 (20 km) = $time_s_st1 s, Arrival of S-Wave at Station 2 (40 km) = $time_s_st2 s")

    return vp, vs, time_p_st1, time_p_st2, time_s_st1, time_s_st2 # From local to global 

end # Of the wave_propagation_2D() function

# -------------------------------------------------
# Peak and velocity of P- and S-wave of seismograms.
# -------------------------------------------------

vp, vs, time_p_st1, time_p_st2, time_s_st1, time_s_st2 = wave_propagation_2D()

# Station 1 at 20 km
dist1 = sqrt((20e3 - 0)^2 + (0 - (-30e3))^2)  # Distance of station 1 from seismic origin
measured_vp_1 = (dist1 / time_p_st1) / 1e3
measured_vs_1 = (dist1 / time_s_st1) / 1e3

# Station 2 at 40 km
dist2 = sqrt((40e3 - 0)^2 + (0 - (-30e3))^2)  # Distance of station 2 from seismic origin
measured_vp_2 = (dist2 / time_p_st2) / 1e3
measured_vs_2 = (dist2 / time_s_st2) / 1e3

println("\n===== P- and S-waves velocities =====\n")

println("Calculated P-wave velocity = ", vp / 1e3, " km/s")
println("Measured P-wave velocity at station 1 = ", measured_vp_1, " km/s")
println("Measured P-wave velocity at station 2 = ", measured_vp_2, " km/s")

println("Calculated S-wave velocity = ", vs / 1e3, " km/s")
println("Measured S-wave velocity at station 1 = ", measured_vs_1, " km/s")
println("Measured S-wave velocity at station 2 = ", measured_vs_2, " km/s")
        