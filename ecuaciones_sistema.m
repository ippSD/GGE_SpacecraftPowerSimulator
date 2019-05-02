function f = ecuaciones_sistema(y,t,cdc33,cdc5,cdc15,ipps,ipbus,ipp15v,ipm15v,ipp5v,ipp33v,bateria)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
f = zeros(3,1);
phi = y(1);
ir1 = y(2);
ir2 = y(3);

bateria.i_r1 = ir1;
bateria.i_r2 = ir2;

global i_5 i_33 i_p15 i_m15 i_bus i_ps i_c e_p
global ic1i ic2i ic3i ic1o ic2o ic3o
%global p_33 p_5 p_p15 p_m15 p_bus p_ps
%global switchs
%global conversor_3_3v conversor_5v conversor_15v

p_33 = ipp33v.eval(t);
i_33 = p_33 / 3.3e0;
p_5 = ipp5v.eval(t);
i_5 = p_5 / 5e0;
p_m15 = ipm15v.eval(t);
i_m15 = p_m15 /-15e0;
p_p15 = ipp15v.eval(t);
i_p15 = p_p15 / 15e0;
p_bus = ipbus.eval(t);
p_ps = ipps.eval(t);

ic1o = i_33;
ic1i = cdc33.corriente_entrada(ic1o);
p_inp_3 = ic1i * 15e0;

ic2o = i_5;
ic2i = cdc5.corriente_entrada(ic2o);
p_inp_2 = ic2i * 15e0;

p_out_1 = p_p15 + p_m15 + p_inp_2 + p_inp_3;
ic3o = p_out_1 / 15.0;
ic3i = cdc15.corriente_entrada(ic3o);
p_inp_1 = ic3i * 22.5;

p_sys = p_bus + p_inp_1;
p_t = p_ps - p_sys;
if ( p_ps > 1e-3)
    % Paneles Solares funcionando.
    if ( phi < 0e0 )
        % Bateria cargada, desconectarla.
        p_t = 0e0;
    end
end

%if ( and( p_t > 0e0, p_t < 1e0) )
%    %Charge at 1W, assume no charge at all.
%    p_t = 0e0;
%end

%if ( and( p_t < 0e0, p_t < 2e0) )
%    %Charge at 1W, assume no charge at all.
%    p_t = 0e0;
%end

p_t;

%if ( abs(p_t) < 1e-3 )
%    i_c = 0e0;
%    e_p = 0e0;
if ( p_t > 0e0 )
    %% Charge
    ff = @(x) p_t + x * bateria.voltage_dynamic(phi, x, 3);
    i_c = fzero(ff, -p_t / 22.5e0);
    %i_c = - p_t / 12.5e0;
    if (i_c < -1e1)
        i_c;
    end
    %fff = @(x) abs(p_t + x * bateria.voltage_dynamic(phi, x, 3));
    %[i_c, fer] = fmincon(fff, [-20e0],[],[],[],[],[-5e2],[0e0]);
    e_p = bateria.voltage_dynamic(phi, i_c, 3);
    p_t / i_c;
else
    %% Discharge
    ff = @(x) p_t + x * bateria.voltage_dynamic(phi, x, 3);
    try
      i_c = fzero(ff, -p_t / 22.5e0);
    catch e
      disp(e);
    end
    %i_c = - p_t / 12.5e0;
    %fff = @(x) abs(p_t + x * bateria.voltage_dynamic(phi, x, 3));
    %i_c = fminsearch(fff, [2e0]);
    e_p = bateria.voltage_dynamic(phi, i_c, 3);
    p_t / i_c;
    if (i_c > 8e0)
        i_c;
    end
end

f(1) = i_c * bateria.battery_voltage_static(phi, i_c, 3);
f(2) = (i_c - ir1) / (bateria.r_1 * bateria.c_1);
f(3) = (i_c - ir2) / (bateria.r_2 * bateria.c_2);

i_ps = p_ps / e_p;
v_ps = e_p;
i_prima = p_sys / v_ps;
i_bus = i_prima * p_bus/ (p_bus + p_inp_1);
ic3i = i_prima - i_bus;
