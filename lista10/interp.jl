# Jan Mazur 
# 281141
# Zadanie P2.9

bhalf = big"0.5"
bzero = big"0.0"
bone = big"1.0"
btwo = big"2.0"
bthree = big"3.0"
bfour = big"4.0"
bfive = big"5.0"
bsix = big"6.0"
beight = big"8"
bten = big"10.0"


# Funkcja wylicza ilorazy różnicowe.
function difference_quotients(f,args)
    values = map(f,args)
    

    for i in 1:1:length(args)-1
        for j in length(args):-1:1+i
            values[j] = ( values[j] - values[j-1] ) / ( args[j] - args[j-i] )
        end
    end
    
    return values; 
end 


# Funkcje pomocnicze dla funkcji Ms
λ(k,args) = h(k,args)/(h(k+1,args) + h(k,args))
h(k,args) = args[k] - args[k-1]
d(k,f,args) = big"6"*difference_quotients(f,[args[k-1],args[k],args[k+1]])[3]


# Funkcja wyliczająca drugie pochodne naturanej funkcji sklejanej 
# 3 stopnia.
# Rozwiązuje przekątniowy układ równań z dominującą przekątną
# w czasie liniowym.
function Ms(f,args)
    n = length(args)
    q = Array{Any}(n-1)
    u = Array{Any}(n-1)
    
    q[1] = bzero
    u[1] = bzero
    
    for k in 1:1:n-2
        p = λ(k+1,args)*q[k] + btwo
        q[k+1] = ( λ(k+1,args)-bone ) / p
        u[k+1] = ( d(k+1,f,args) - λ(k+1,args)*u[k]) / p
    end
    
    M = Array{Any}(n)
    M[1] = bzero
    M[n] = bzero
    M[n-1] = u[n-1]
    
    for k in n-3:-1:1
        M[k+1] = u[k+1] + q[k+1]*M[k+2]
    end

    return M
end


# Funkcja wyliczająca wartość naturalnej funkcji sklejanej 3 stopnia 
# w punkcie x, interpolującą funkcję f, w punktach args z drugimi 
# pochodnymi M.
function splineValue(x,f,M,args)
    k = 1
    while args[k+1] < x
        k += 1
    end
    
    return ( (M[k]*(args[k+1]-x)^bthree)/bsix + (M[k+1]*(x-args[k])^bthree)/bsix + 
                (f(args[k])-(M[k]*(h(k+1,args)^btwo))/bsix)*(args[k+1] -x) +   
                (f(args[k+1])-(M[k+1]*(h(k+1,args)^btwo))/bsix)*(x-args[k]) ) / 
                h(k+1,args)   
end


# Funkcja zwracająca naturalną funkcję sklejaną 3 stopnia dla funkcji f.
function splineInterp(f,args)
    M = Ms(f,args)
    return x -> splineValue(x,f,M,args)
end

# Funkcja błędu z treści zadania.
function interpError(f,args,method,N)
    s = method(f,args)
    a = args[1]
    b = args[end]
    
    step = (b - a) / (N - bone)
    
    range = a:step:b
    
    max = bzero
    for i in range
        diff = abs(f(i) - s(i))
        if( diff > max )
            max = diff
        end
    end
    
    return max 
end

# Błąd interpolacji z zadania, dla gotowej funkcji interpolacyjnej.
function interpErrorFunction(f,args,interpFunction,N)
    a = args[1]
    b = args[end]
    
    step = (b - a) / (N - bone)
    
    range = a:step:b
    
    max = bzero
    for i in range
        diff = abs(f(i) - interpFunction(i))
        if( diff > max )
            max = diff
        end
    end
    
    return max 
end

# Funkcja zwraca wielomian interpolacyjny, interpolujący funkcję f 
# punktach args.
function newtonInterp(f,args)
    b = difference_quotients(f,args)
    n = length(args)
    
    newt = Array{Function}(n)
    newt[1] = _ -> b[1]
    
    p = Array{Function}(n)
    p[1] = _ -> bone
    
    for i in 2:1:n
        p[i] = x -> p[i-1](x) * (x - args[i-1])
        newt[i] = x ->  newt[i-1](x) + b[i] * p[i](x) 
    end
    
    return newt[n]
end

# Funkcja kreśląca wykres funkcji f i naturalnej funkcji sklejanej 3 
# stopia interpolującej funkcję f w punktach args.
# Argument step opisuje odległość pomiędzy punktami próbkowania obu
# funkcji.
function plotSplineAndFunction(f,args,step,error = false, NArray = [2])
    s = splineInterp(f,args)
    
    plot_args = args[1]:step:args[end]
    
    n = length(plot_args)
    
    func_values = Array{Any}(n)
    spline_values = Array{Any}(n)
    
    func_values = map(f,plot_args)
    spline_values = map(s,plot_args)
    
    func = scatter(;x=plot_args, y=func_values, mode="lines", name = "funkcja interpolowana")
    spli = scatter(;x=plot_args, y=spline_values, mode="lines", name = "funkcja sklejana")
    
    layout = Layout(;title="Interpolacja naturalną funkcją sklejaną III stopnia",xaxis=attr(title="argumenty"),yaxis=attr(title="wartości"))
    
    if error == true
        @printf("Błędy interpolacji funkcją sklejaną:\n")
        testErrorFunction(f,args,s,NArray)
    end

    plot([func, spli],layout)
end

# Funkcja kreśląca wykres funkcji f i wielomianu ją interpolującego w 
# punktach args.
# Argument step opisuje odległość pomiędzy punktami próbkowania obu
# funkcji.
function plotNewton(f,args,step,error = false, NArray = [2])
    n = length(args)
    a=args[1]
    b=args[n]
    
    _args = a:step:b
    
    newton = newtonInterp(f,args)
    
    func_values = map(f,_args)
    newt_values = map(newton,_args)
    
    func = scatter(;x=_args, y=func_values, mode="lines", name = "funkcja interpolowana")
    newt = scatter(;x=_args, y=newt_values, mode="lines", name = "wielomian interpolacyjny")
    
    layout = Layout(;title="Interpolacja wielomianowa",xaxis=attr(title="argumenty"),yaxis=attr(title="wartości"))
    
    if error == true
        @printf("Błędy interpolacji wielomianowej:\n")
        testErrorFunction(f,args,newton,NArray)
    end

    plot([func, newt], layout)
end

# Kreśli splinea i newtona oraz funkcje interpolowaną.
# Opcjonalnie wypisuje błąd zdefiniowany jak w treści
# dla obu interpolacji.
function plotNewtonSpline(f,args,step,error = false, NArray = [2] )
    s = splineInterp(f,args)
    newton = newtonInterp(f,args)
    
    plot_args = args[1]:step:args[end]
    
    n = length(plot_args)
    
    func_values = Array{Any}(n)
    spline_values = Array{Any}(n)
    newton_values = Array{Any}(n)
    
    func_values = map(f,plot_args)
    spline_values = map(s,plot_args)
    newton_values = map(newton,plot_args)
    
    func = scatter(;x=plot_args, y=func_values, mode="lines", name = "funkcja interpolowana")
    spli = scatter(;x=plot_args, y=spline_values, mode="lines", name = "funkcja sklejana")
    newt = scatter(;x=plot_args, y=newton_values, mode="lines", name = "wielomian interpolacyjny")

    layout = Layout(;title="Interpolacja naturalną funkcją sklejaną III stopnia oraz interpolacja wielomianowa",xaxis=attr(title="args"),yaxis=attr(title="values"))
    

    if error == true
        @printf("Błędy interpolacji wielomianowej:\n")
        testErrorFunction(f,args,newton,NArray)
        @printf("Błędy interpolacji funkcją sklejaną:\n")
        testErrorFunction(f,args,s,NArray)
    end

    plot([func, spli, newt],layout)
end

# Funkcja testująca błąd z zadania dla danej funkcji f, przedziału 
# interpolacji args, metody interpolacji InterpMethod oraz
# wartości N z tablicy NArray
function testError(f,args,interpMethod,NArray)
    show_args = collect(args)

    interpFunction = interpMethod(f,args)
    n = length(args) 
    @printf("Błąd liczony w N równoodległych punktach\n")
    @printf("Interpolacja w n węzłach:\n");
    showNodes(show_args)
    for N in NArray
        error = interpErrorFunction(f,args,interpFunction,N)
        @printf("Błąd przy n = %d, N = %d:\t%.5e\n",n,N,error)
    end
end

# Funkcja testująca błąd z zadania dla danej funkcji f, przedziału 
# interpolacji args, funkcji interpolacyjnej interpFunction oraz
# wartości N z tablicy NArray
function testErrorFunction(f,args,interpFunction,NArray)
    show_args = collect(args)

    n = length(args) 
    @printf("Błąd liczony w N równoodległych punktach\n")
    @printf("Interpolacja w n węzłach:\n");
    showNodes(show_args)
    for N in NArray
        error = interpErrorFunction(f,args,interpFunction,N)
        @printf("Błąd przy n = %d, N = %d:\t%.5e\n",n,N,error)
    end 
    @printf("\n")
end

# Funkcja zwracające zera N-tego wielomianu Czebyszewa
# przeskalowane do przedziału [a,b]
function chebyshevNodes(a,b,N)
    rtn = Array{Any}(N)

    for k in N:-bone:bone
         rtn[convert(Int,N+bone-k)] = bhalf*(a+b) + bhalf*(b-a)*cos(((btwo*k-bone)/(btwo*N))*big(pi))
    end

    return rtn
end

function showNodes(nodes)
    @printf("[ ")
    for i in 1:1:length(nodes)-1
        @printf("%.2e, ",nodes[i])
    end
    @printf("%.2e ]\n",nodes[end])
end

function chebyshevExtrema(N)
    rtn = Array{Any}(N+1)
    for k in N:-1:0
        rtn[N-k+1] = cos((k*pi)/N)
    end
    return rtn
end