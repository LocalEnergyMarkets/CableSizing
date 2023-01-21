clc
clear
uiopen('C:\Naser\Dr pedro\Selina\PV+Bifacial\PV+Bifacial\csv\PV_input.csv',1)
uiopen('C:\Naser\Dr pedro\Selina\PV+Bifacial\PV+Bifacial\csv\Bifacial_input.csv',1)
uiopen('C:\Naser\Dr pedro\Selina\PV+Bifacial\PV+Bifacial\csv\Demand_houses.csv',1)
%%
DEM = table2array(Demandhouses);
clear Demandhouses
Bifacialinput = table2array(Bifacialinput);
PVinput = table2array(PVinput);
%           PVB	        PV
Decisions =[6.025881723	2.095287371
            6.135735368	1.982379527
            6.974231008	2.137018733
            6.520769609	1.885512804
            5.938018154	2.287787189
            6.276268967	2.061866471
            5.932855175	2.074036021
            5.675346038	2.187942432
            6.725084911	2.656073102
            7.229029617	1.606188297
            6.687140996	1.642734557
            6.405554937	2.03624754
            7.207129938	1.651812629
            6.655938995	1.947548334
            7.243472018	1.576099962
            6.180643061	1.955004896
            6.322876619	2.047964377
            7.071784471	1.933782353
            6.862572961	1.568467971
            5.825206146	2.070868596
            6.105954317	1.837524494
            6.623091013	1.721691993
            6.035512884	2.075849413
            6.042104756	2.041939068
            6.597126873	1.815356477
            6.044801419	1.893508789
            6.948504132	1.481149539
            6.041500482	2.214502895
            6.810526584	1.719658472
            6.207497506	1.869575027
            6.957820425	2.171207448
            5.964800734	2.021189388
            5.696308016	2.157756586
            6.629210676	2.145927958
            6.149774152	1.982060274
            6.310795079	2.014854788
            6.491250331	1.815572721
            6.375018017	1.865440371
            5.590233695	2.05709066
            6.173993627	1.950594191
            6.190340641	2.055039438
            7.126737642	1.819296578
            6.020904187	1.97624161
            5.928832459	1.988784876
            6.321134139	1.771026046
            6.228662298	2.252923521
            5.985001227	1.931129855
            6.396884184	1.917320793
            5.885280815	2.209103681
            6.289680993	1.841456394
            6.611049258	1.804347943
            6.329540388	1.877401956
            6.023952094	2.23035458
            6.787292763	1.485254667
            6.706838818	1.845355152
];
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
t = 1263;
Nl = (DEM(t,2:end) - PVB(t,:))*1000;

figure
plot(a(:,2),a(:,3),'.')
hold on
plot(a(1,2),a(1,3),'ko','LineWidth',7,'MarkerSize',2)

for i=1:length(b)
    plot([a(b(i,1),2) a(b(i,2),2)],[a(b(i,1),3) a(b(i,2),3)],'k')
end
%
for i = 1:length(Nl)
    Feeder.Loads(i,3+(Phase1(i)-1)*2+1) = Nl(i);
end

PF = ThreePhase_LoadFlow(Feeder);
V = abs(PF.Vpu_line);
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
IND_NV = [1 3 6 7 8];
IND_OV = [2 3 5 6];
xmin = [IND_NV IND_OV];
n = length(xmin);
N = 5*n;
xmax = ones(1,n)*9;
vmax=0.25*(xmax-xmin);
vmin=-vmax;
c1=2;
c2=2;
Nitr=120;
Feeder1 = Feeder;
Ipop=zeros(N,n);
vel=zeros(N,n);
cost=zeros(N,1);

for i = 1:N
    Ipop(i,:) = round(rand(1,n).*(xmax - xmin) + xmin);
    cost(i,1) = CostEval2(IND_NV, IND_OV, Ipop(i,:), NVLN, OVLN, Feeder1, Feeder, xmin);
    vel(i,:)=rand(1,n).*(vmax-vmin)+vmin;
end

pbest=[Ipop,cost];
loc_min=find(cost==min(cost));
gbest=[Ipop(loc_min(1,1),:),min(cost)];

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
        cost(i,:)=CostEval2(IND_NV, IND_OV, Ipop(i,:), NVLN, OVLN, Feeder1, Feeder, xmin);
        if pbest(i,1+n)>cost(i,1)
            pbest(i,:)=[Ipop(i,:),cost(i,1)];
        end
        if gbest(1,n+1)>cost(i,1)
            gbest=[Ipop(i,:),cost(i,1)];
        end
    end
end

