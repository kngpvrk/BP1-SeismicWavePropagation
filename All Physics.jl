using Plots
#                 number inside of domain: ncx = 3, number of cells inkl. geist nodes: ncx + 2 (geist nodes) = 5
#  Model: c[1]---|---c[2]---|---c[3]---|---c[4]---|--c[5]           c: middle of the cell
#               xmin        <--Δx--->           xmax

function main()
    #Physical domain
    xmin = -0.5
    xmax = 0.5
    Lx = xmax - xmin   #length of the cell    
    ncx = 100   #number of cells
    Δx = Lx/ncx  #size of one cell
    xce = LinRange(xmin-Δx/2, xmax+Δx/2, ncx+2)
    
    nt = 1 #time step
    σ = 0.1
    c = exp.(-xce.^2/σ^2)
    q = zeros(ncx + 1)

    #Diffusion
    k =1e-6
    Δt = Δx^2/k/2.1
    
    #lets make a time loop
    for it = 1:nt

        #Step 1: Set up boundary conditions: set appropriate values to geist nodes
        c[1] - c[end-1]  #thats how to access first value and makes it equal to the last value
        c[end] = c[2]    #access last value and equal it to the first

        #Step 2: compute the flux
        q .= -k*(c[2:end] .-c[1:end-1])./Δx #Finite difference discretisation of -k*dcdx

        #Step 3: Use conservation law to update cell
        c[2:end-1] .= c[2:end-1] .- Δt*(q[2:end] .- q[1:end-1]) ./Δx

        display(plot(xce,c, ylims(0,1)))
        sleep(0.05)

    end


end

main()