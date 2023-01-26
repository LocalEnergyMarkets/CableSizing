clc
clear
%% Case A
uiopen('C:\Naser\Dr pedro\Selina\PV+Bifacial\PV+Bifacial\csv\PV_input.csv',1)
uiopen('C:\Naser\Dr pedro\Selina\PV+Bifacial\PV+Bifacial\csv\Bifacial_input.csv',1)
uiopen('C:\Naser\Dr pedro\Selina\PV+Bifacial\PV+Bifacial\csv\Demand_houses.csv',1)
uiopen('C:\Naser\Dr pedro\Selina\PV+Bifacial\PV+Bifacial\invest.csv',1)
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
t = 2451;
Nl = (DEM(t,2:end) - (PVB(t,:)+PV(t,:)))*1000;

figure
plot(a(:,2),a(:,3),'.')
hold on
plot(a(1,2),a(1,3),'ko','LineWidth',7,'MarkerSize',2)

for i=1:length(b)
    plot([a(b(i,1),2) a(b(i,2),2)],[a(b(i,1),3) a(b(i,2),3)],'k')
end


for i = 1:length(Nl)
    Feeder.Loads(i,3+(Phase1(i)-1)*2+1) = Nl(i);
end

PF = ThreePhase_LoadFlow(Feeder);
V = abs(PF.Vpu_line);
%%%%%%
OV1(t).a = find(V(:,1)>Vth);
if ~isempty(OV1(t).a)
    plot(a(OV1(t).a,2),a(OV1(t).a,3),'sk','Linewidth',2)
end

OV2(t).a = find(V(:,2)>Vth);
if ~isempty(OV2(t).a)
    plot(a(OV2(t).a,2),a(OV2(t).a,3),'go','Linewidth',2)
end

OV3(t).a = find(V(:,3)>Vth);
if ~isempty(OV3(t).a)
    plot(a(OV3(t).a,2),a(OV3(t).a,3),'ro','Linewidth',2)
end
%%%%%%%%
VMAX = max(V,[],2);

NV = find(VMAX<=Vth);
OV = find(VMAX>Vth);

for i = 1:max(Feeder.Topology(:,4))
    NVLN(i).a = [];
end

for i = 1:length(NV)
    LN = find(Feeder.Topology(:,2)==NV(i));   % Line number
    if ~isempty(LN)
        NVLN(Feeder.Topology(LN,4)).a = [NVLN(Feeder.Topology(LN,4)).a; LN];
    end
end

for i = 1:max(Feeder.Topology(:,4))
    OVLN(i).a = [];
end

for i = 1:length(OV)
    LN = find(Feeder.Topology(:,2)==OV(i));   % Line number
    if ~isempty(LN)
        OVLN(Feeder.Topology(LN,4)).a = [OVLN(Feeder.Topology(LN,4)).a; LN];
    end
end

%% DecVar
% IND_NV = [1 3 6 7 8];
% IND_OV = [2 3 5 6];
% IND_NV = [1 3 8 8];        % 1, 3, 8, 9
% IND_OV = [1 2 3 5 6 7 8];  % 1, 2, 3, 5, 6, 7, 9 
IND_NV = [1 2 3 4 5 6 7 8 8];
IND_OV = [1 2 3 4 5 6 7 8 8];
xmin = [IND_NV IND_OV]; 
n = length(xmin);
N = 5*n;
xmax = ones(1,n)*9;
vmax=0.25*(xmax-xmin);
vmin=-vmax;
c1=2;
c2=2;
Nitr=100;
Feeder1 = Feeder;


Ipop=zeros(N,n);
vel=zeros(N,n);
cost=zeros(N,1);
% Ipop(1,:) = [5	2	3	4	6	7	7	8	8	5	2	9	8	7	7	8	8	9];
% Ipop(2,:) = [1	2	3	4	6	7	9	8	8	3	2	7	5	8	6	9	8	8];
% 
% for i = 1:2
%     [Vol(i).V, cost(i,1)] = CostEval2(IND_NV, IND_OV, Ipop(i,:), NVLN, OVLN, Feeder, Feeder1, xmin);
%     vel(i,:)=rand(1,n).*(vmax-vmin)+vmin;
% end
for i = 1:N
    Ipop(i,:) = round(rand(1,n).*(xmax - xmin) + xmin);
    [Vol(i).V, cost(i,1)] = CostEval2(IND_NV, IND_OV, Ipop(i,:), NVLN, OVLN, Feeder, Feeder1, xmin);
    vel(i,:)=rand(1,n).*(vmax-vmin)+vmin;
end

pbest=[Ipop,cost];
loc_min=find(cost==min(cost));
gbest=[Ipop(loc_min(1,1),:),min(cost)];
VolBest = Vol(loc_min).V;
%%
for itr=1:Nitr
    itr
    w=rand()*(1-0.4)+0.4;
    for i=1:N
        vel(i,:)=w*vel(i,:)+c1*rand(1,n).*(pbest(i,1:n)-Ipop(i,:))+c2*rand(1,n).*(gbest(1,1:n)-Ipop(i,:));
        vel(i,:)=min(vel(i,:),vmax);
        vel(i,:)=max(vel(i,:),vmin);
        Ipop(i,:)=round(Ipop(i,:)+vel(i,:));
        Ipop(i,:)=max(Ipop(i,:),xmin);
        Ipop(i,:)=min(Ipop(i,:),xmax);
        [Vol(i).V, cost(i,1)]=CostEval2(IND_NV, IND_OV, Ipop(i,:), NVLN, OVLN, Feeder1, Feeder, xmin);
        if pbest(i,1+n)>cost(i,1)
            pbest(i,:)=[Ipop(i,:),cost(i,1)];
        end
        if gbest(1,n+1)>cost(i,1)
            gbest=[Ipop(i,:),cost(i,1)];
            VolBest = Vol(i).V;
        end
    end
end
%%
feeder3 = Feeder;
for i = 1:9
    if ~isempty(NVLN(i).a)
        feeder3.Topology(NVLN(i).a,4)=gbest(i);
    end
end

for i = 1:9
    if ~isempty(OVLN(i).a)
        feeder3.Topology(OVLN(i).a,4)=gbest(9+i);
    end
end



for i = 1:length(Nl)
    feeder3.Loads(i,3+(Phase1(i)-1)*2+1) = Nl(i);
end

PF = ThreePhase_LoadFlow(feeder3);
V = abs(PF.Vpu_line);


%%
% k=0;
% for i = IND_NV
%     k=k+1;
%     Feeder1.Topology(NVLN(i).a,4)=gbest(k);
% end
% 
% for i = IND_OV
%     k=k+1;
%     Feeder1.Topology(OVLN(i).a,4)=gbest(k);
% end
% PF = ThreePhase_LoadFlow(Feeder1);
% V = abs(PF.Vpu_line);
% figure
% plot(V)
% 
% Feeder1.Topology(:,4) = 8;
% PF = ThreePhase_LoadFlow(Feeder1);
% V = abs(PF.Vpu_line);
% figure
% plot(V)
