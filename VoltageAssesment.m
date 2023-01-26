clc
clear
%% Case A
uiopen('C:\Naser\Dr pedro\Selina\PV+Bifacial\PV+Bifacial\csv\PV_input.csv',1)
uiopen('C:\Naser\Dr pedro\Selina\PV+Bifacial\PV+Bifacial\csv\Bifacial_input.csv',1)
uiopen('C:\Naser\Dr pedro\Selina\PV+Bifacial\PV+Bifacial\csv\Demand_houses.csv',1)
uiopen('C:\Naser\Dr pedro\Selina\PV+Bifacial\PV+Bifacial\invest.csv',1)
%% Case B.t2
uiopen('C:\Naser\Dr pedro\Selina\Case B.t2\Case B.t2\csv\PV_input.csv',1)
uiopen('C:\Naser\Dr pedro\Selina\Case B.t2\Case B.t2\csv\Bifacial_input.csv',1)
uiopen('C:\Naser\Dr pedro\Selina\Case B.t2\Case B.t2\csv\Demand_houses.csv',1)
uiopen('C:\Naser\Dr pedro\Selina\Case B.t2\Case B.t2\invest.csv',1)
%%
DEM = table2array(Demandhouses);
clear Demandhouses
Bifacialinput = table2array(Bifacialinput);
PVinput = table2array(PVinput);
%           PVB	        PV
invest = table2array(invest);
Decisions = invest(:,3:4);

%%
for i=1: length(Decisions)
    PV(:,i) = PVinput(:,i+1)*Decisions(i,2);
    PVB(:,i) = Bifacialinput(:,i+1)*Decisions(i,1);
end
%%
Phase = xlsread('C:\Naser\Dr pedro\firstIdea\clustering_loadflow\newtry\ThreePhaseP2P\OneWeek\InputDataOneWeek.xlsx',7);
Phase1 = Phase(3,:);
a=xlsread('C:\Naser\CaseStudies\European_LV_Test_Feeder_v2\European_LV_CSV\Buscoords.csv');
b=xlsread('C:\Naser\CaseStudies\European_LV_Test_Feeder_v2\European_LV_CSV\Lines.csv',1);
HouseNodes=[34;47;70;73;74;83;178;208;225;248;249;264;276;289;314;320;327;337;342;349;387;388;406;458;502;522;539;556;562;563;611;614;619;629;639;676;682;688;701;702;755;778;780;785;813;817;835;860;861;886;896;898;899;900;906];
Vth = 1.05;
Feeder = LoadFeeder('European_LV.xlsx');
Feeder.Vpu_slack_phase=1.03*[1*exp(-1i*pi/6);exp(-1i*5*pi/6);exp(1i*pi/2)];
%%
for t = 1:3015
%     t = 1263;
Nl = (DEM(t,2:end) - (PVB(t,:)+PV(t,:)))*1000;

% figure
% plot(a(:,2),a(:,3),'.')
% hold on
% plot(a(1,2),a(1,3),'ko','LineWidth',7,'MarkerSize',2)
% 
% for i=1:length(b)
%     plot([a(b(i,1),2) a(b(i,2),2)],[a(b(i,1),3) a(b(i,2),3)],'k')
% end
%
for i = 1:length(Nl)
    Feeder.Loads(i,3+(Phase1(i)-1)*2+1) = Nl(i);
end

PF = ThreePhase_LoadFlow(Feeder);
V = abs(PF.Vpu_line);
VMAX = max(V,[],2);
vvmax(t) = max(VMAX);
end
%%
plot(vvmax)
xlabel('Time-step')
ylabel('Max Voltage [PU]')
% title('Case A')
grid on
xlim([0 3050])
ylim([1.025 1.08])
%%
t = 2451;
Nl = (DEM(t,2:end) - (PVB(t,:)+PV(t,:)))*1000;
for i = 1:length(Nl)
    Feeder.Loads(i,3+(Phase1(i)-1)*2+1) = Nl(i);
end

PF = ThreePhase_LoadFlow(Feeder);
V = abs(PF.Vpu_line);


Vh = V(HouseNodes,:);    % Houses with overvoltage
for i = 1:3
    Hov(i).a = find(Vh(:,i)>Vth);
end

A = union( Hov(1).a,Hov(2).a );
B = union( A,Hov(3).a ); 