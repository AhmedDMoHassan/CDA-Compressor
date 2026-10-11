clc; close all; clearvars;
%% gas properties
gamma=1.4; % specific heat ratio
R_g=287; % air gas constant
Cp=gamma*R_g/(gamma-1);
%% inlet conditions
Tt0=288 ; % total inlet temperature in k
Pt1= 1e5; % total pressure in pascal
Tt1=Tt0;
m_dot=0.5; % mass flow in kg
%% compressor parameters
chord=0.01;
N = 110*1e3; % rotational speed in rpm
phi=0.64; % flow coefficient
epsi=0.25; % loading coefficient
R=0.5; % Degree of reaction
Mr1=0.75;
DF=0.45;
alpha1=atan2d((1-R-epsi/2),phi);
beta1=atan2d((R+epsi/2),phi);
alpha2=atan2d((1-R+epsi/2),phi);
beta2=atan2d((R-epsi/2),phi);
alpha3=alpha1; % repeating stages
C1=fsolve(@(x) x*cosd(alpha1)/cosd(beta1)/sqrt(gamma*R_g*(Tt1-x^2/2/Cp))-Mr1,100);
C3=C1;
Cx=C1*cosd(alpha1);
W1=C1*cosd(alpha1)/cosd(beta1);
C2=Cx/cosd(alpha2);
W2=Cx/cosd(beta2);
U=C1*sind(alpha1)+W1*sind(beta1);
r_m=60*U/2/pi/N;
T1=Tt1-C1^2/2/Cp;
pressure_ratioIGV=1;
%  %% inlet gide vanes
% if alpha1 ~= 0
%    C0=Cx;
%    T0=Tt0-C0^2/2/Cp;
%    P0=Pt0*(T0/Tt0)^(gamma/(gamma-1));
%    M1=C1/sqrt(gamma*R_g*T1);
%    a=(1+(gamma-1)/2*M1^2)^(gamma/(gamma-1));
%    % IGV blade angles
%    alpha0_dash=0; % for opimum incidence 0
%    alpha1_dash=fsolve(@(x) (-0.00000023148*(x/2)^3+0.00003125*(x/2)^2-0.00164351852*(x/2)+19/90)*x/sqrt(1.25*sind(2*abs(alpha1))/cosd(x/2))-x+abs(alpha1),alpha1);% carter deviation correlation
%    beta_s_IGV=-alpha1_dash/2;
%    sigma_IGV=1.25*sind(2*abs(alpha1))/cosd(beta_s_IGV);
%    epsilon_IGV=alpha1;
%    % -----------------------------------------------------------%
%    loss=0.04+0.06*(epsilon_IGV/100)^2; %soderburg correlation
%    Y_IGV=(1+loss)*(0.93+0.021*cosd(beta_s_IGV)*1.8)-1; %soderburg correlation
%    P1=fsolve(@(x) Y_IGV-(Pt0-a*x)/(a*x-x),Pt0);
%    Pt1=a*P1; 
%    pressure_ratioIGV=Pt1/Pt0;
% end
 %% completion of stage 1
P1=Pt1*(T1/Tt1)^(gamma/(gamma-1));
Ttr1=T1+W1^2/2/Cp;
Ttr2=Ttr1; % rothalpy is constant across the rotor
Ptr1=P1*(Ttr1/T1)^(gamma/(gamma-1));
W_theta=W1*sind(beta1)-W2*sind(beta2);
sigmaR= W_theta/2/W1/(DF-1+W2/W1);
sigmaS= W_theta/2/C2/(DF-1+C3/C2);
y_c_R=0.08*DF-8e-3; %0.1447493264*DF_vec.^4-0.2682061239*.DF_vec^3+0.2228839917*DF_vec^2-0.01455315662*DF_vec+8e-3; % 0.08*DF-8e-3 for DF range 0.4 to 0.6
y_c_S=0.06*DF-4e-3; %14.1065*DF_vec^6-23.4385*DF_vec^5+15.0696*DF_vec^4-4.6918*DF_vec^3+0.7752*DF_vec^2-0.0383*DF_vec+8e-3; % 0.06*DF-4e-3 for DF range 0.4 to 0.5
w_loss_rotor=y_c_R*2*sigmaR/cosd(beta2);
w_loss_stator=y_c_S*2*sigmaS/cosd(alpha3);
Ptr2=Ptr1-w_loss_rotor*(Ptr1-P1);
T2=Ttr2-W2^2/2/Cp;
Tt2=T2+C2^2/2/Cp;
check=epsi*U^2/Cp/(Tt2-Tt1); % a good check on the code to have a value 1
P2=Ptr2*(T2/Ttr2)^(gamma/(gamma-1));
Pt2=Ptr2*(Tt2/Ttr2)^(gamma/(gamma-1));
Pt3=Pt2-w_loss_stator*(Pt2-P2);
Tt3=Tt2;
pressure_ratio1=Pt3/Pt1; % stage pressure ratio pi_c
% we will assume the second will do the same effect as the first stage (i.e. have the same R epsi phi)
%% second stage
   T3=Tt3-C3^2/2/Cp;
   P3=Pt3*(T3/Tt3)^(gamma/(gamma-1));
   Ttr3=T3+W1^2/2/Cp;
   Ttr4=Ttr3;
   Ptr3=P3*(Ttr3/T3)^(gamma/(gamma-1));
   Ptr4=Ptr3-w_loss_rotor*(Ptr3-P3);
   T4=Ttr4-W2^2/2/Cp;
   Tt4=T4+C2^2/2/Cp;
   P4=Ptr4*(T4/Ttr4)^(gamma/(gamma-1));
   Pt4=Ptr4*(Tt4/Ttr4)^(gamma/(gamma-1));
   Pt5=Pt4-w_loss_stator*(Pt4-P4);
   Tt5=Tt4;
   T5=Tt5-C3^2/2/Cp;
   P5=Pt5*(T5/Tt5)^(gamma/(gamma-1));
   pressure_ratio2=Pt5/Pt3; % stage pressure ratio pi_c
%% total output
   pi_2stage=pressure_ratio1*pressure_ratio2*pressure_ratioIGV;
   taw_c_2stage=Tt5/Tt1;
   eta_2stage=(pi_2stage^((gamma-1)/gamma)-1)/(taw_c_2stage-1);
   SR=chord/sigmaR; % spacing of the rotor
   n_blades_rotor=ceil(2*pi*r_m/SR) ;% number of blades of rotor disc
   SS=chord/sigmaS;% spacing of the stator
   n_blades_stator=ceil(2*pi*r_m/SS);% number of blades of stator disc
   A_vec=nan(1,5);
    zeta_vec=A_vec;
    zeta_vec(1)=(4*pi*r_m^2*P1*Cx-m_dot*R_g*T1)/(m_dot*R_g*T1+4*pi*r_m^2*P1*Cx);
    A_vec(1)=4*pi*r_m^2*(1-zeta_vec(1))/(1+zeta_vec(1));
    P_vec=[P1,P2,P3,P4,P5];
    T_vec=[T1,T2,T3,T4,T5];
    for p=2:5
        A_vec(p)=A_vec(p-1)*P_vec(p-1)*T_vec(p)/P_vec(p)/T_vec(p-1);
        zeta_vec(p)=(4*pi*r_m^2-A_vec(p))/(4*pi*r_m^2+A_vec(p));
    end
rt_vec=2*r_m./(1+zeta_vec);
rh_vec=zeta_vec.*rt_vec;
h_c_vec=(rt_vec-rh_vec)/chord;
specific_work=Cp*(Tt4-Tt1);
power=m_dot*specific_work;
total_number_of_blades=n_blades_stator+n_blades_rotor*2;
%% use airfoil Naca 65 for stator and rotor with optimum incidence and carter correlation <rotor1 and 2>
n1=-1.005e-6*beta1^3+6.758e-5*beta1^2-0.006038*beta1-0.01398; % for sigma = 0.5
n2=-1.198e-6*beta1^3+8.017e-5*beta1^2-0.004556*beta1-0.002289; % for sigma = 1
n3=-7.272e-7*beta1^3+1.557e-5*beta1^2-0.0009442*beta1-0.01721; % for sigma = 1.5
n4=-6.931e-7*beta1^3+1.234e-5*beta1^2-0.000144*beta1-0.006293; % for sigma = 2
i04=-4.963e-8*beta1^5+1.002e-5*beta1^4-0.0007843*beta1^3+0.02947*beta1^2-0.372*beta1+3.529;% for sigma = 2
i03=-1.345e-5*beta1^3+0.001251*beta1^2+0.08313*beta1+0.1545; % for sigma = 1.5
i02=-7.237e-6*beta1^3+0.0008285*beta1^2+0.04552*beta1+0.3192; % for sigma = 1
i01=-4.399e-6*beta1^3+0.0005018*beta1^2+0.01771*beta1+0.1913; % for sigma = 0.5
m=-2.436e-7*beta2^3+4.44e-5*beta2^2+0.0006728*beta2+0.2147; % for sigma = 0.5
if sigmaR > 2
    error(' use other design method as sigmaR >2')
elseif sigmaR>1.5
    n=n3+(n4-n3)*(sigmaR-1.5)/(2-1.5);
    i0=i03+(i04-i03)*(sigmaR-1.5)/(2-1.5);
elseif sigmaR> 1
    n= n2+(n3-n2)*(sigmaR-1)/(1.5-1);
    i0=i02+(i03-i02)*(sigmaR-1)/(1.5-1);
elseif sigmaR>= 0.5
    n=n1+(n2-n1)*(sigmaR-0.5)/(1-0.5);
    i0=i01+(i02-i01)*(sigmaR-0.5)/(1-0.5);
else 
    error(' use other design method as sigmaR <0.5')
end
A1=[1+n -n;m/sqrt(sigmaR) 1-m/sqrt(sigmaR)];
B1=[beta1-i0;beta2];
X=linsolve(A1,B1);
beta1_dash=X(1);
beta2_dash=X(2);

%% use airfoil Naca 65 for stator and rotor with optimum incidence and carter correlation <stator1>
n1=-1.005e-6*alpha2^3+6.758e-5*alpha2^2-0.006038*alpha2-0.01398; % for sigma = 0.5
n2=-1.198e-6*alpha2^3+8.017e-5*alpha2^2-0.004556*alpha2-0.002289; % for sigma = 1
n3=-7.272e-7*alpha2^3+1.557e-5*alpha2^2-0.0009442*alpha2-0.01721; % for sigma = 1.5
n4=-6.931e-7*alpha2^3+1.234e-5*alpha2^2-0.000144*alpha2-0.006293; % for sigma = 2
i04=-4.963e-8*alpha2^5+1.002e-5*alpha2^4-0.0007843*alpha2^3+0.02947*alpha2^2-0.372*alpha2+3.529;% for sigma = 2
i03=-1.345e-5*alpha2^3+0.001251*alpha2^2+0.08313*alpha2+0.1545; % for sigma = 1.5
i02=-7.237e-6*alpha2^3+0.0008285*alpha2^2+0.04552*alpha2+0.3192; % for sigma = 1
i01=-4.399e-6*alpha2^3+0.0005018*alpha2^2+0.01771*alpha2+0.1913; % for sigma = 0.5
m=-2.436e-7*alpha3^3+4.44e-5*alpha3^2+0.0006728*alpha3+0.2147; % for sigma = 0.5
if sigmaS > 2
    error(' use other design method as sigmaS >2')
elseif sigmaS>1.5
    n=n3+(n4-n3)*(sigmaS-1.5)/(2-1.5);
    i0=i03+(i04-i03)*(sigmaS-1.5)/(2-1.5);
elseif sigmaS> 1
    n= n2+(n3-n2)*(sigmaS-1)/(1.5-1);
    i0=i02+(i03-i02)*(sigmaS-1)/(1.5-1);
elseif sigmaS>= 0.5
    n=n1+(n2-n1)*(sigmaS-0.5)/(1-0.5);
    i0=i01+(i02-i01)*(sigmaS-0.5)/(1-0.5);
else 
    error(' use other design method as sigmaS <0.5')
end
A1=[1+n -n;m/sqrt(sigmaS) 1-m/sqrt(sigmaS)];
B1=[alpha2-i0;alpha3];
X=linsolve(A1,B1);
alpha1_dash=X(1);
alpha2_dash=X(2);
%% plot section
plot(rt_vec)
hold on 
plot(rh_vec)
yline(0,'--','LineWidth',3)

deviation = beta2 - beta2_dash;
incidence = beta1 - beta1_dash;
deflection = beta1 - beta2;
n_stages = 2;
% for the off-design app (Koch stall criterion): blade-row solidities and chord
sigma_rotor = sigmaR;
sigma_stator = sigmaS;
save("Max_eta_Compressor_design_rs_with_last_stator.mat", 'alpha1','n_stages','A_vec', 'beta1_dash', 'beta2_dash', ...
    'deviation', 'incidence', "deflection",'m_dot','U','w_loss_rotor','w_loss_stator','sigma_rotor','sigma_stator','chord');