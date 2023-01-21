% IND_NV = [1 3 6 7 8];
% IND_OV = [2 3 5 6];
% Ip = Ipop(1,:);
% NVLN
% OVLN
% Feeder1 = Feeder;
% xmin

function cost = CostEval2(IND_NV, IND_OV, Ip, NVLN, OVLN, Feeder1, Feeder, xmin)

k = 0;
for i = IND_NV
    k = k + 1;
    LL_NV(k,1) = sum(Feeder.Topology(NVLN(i).a,3))*1000;
end

k = 0;
for i = IND_OV
    k = k + 1;
    LL_OV(k,1) = sum(Feeder.Topology(OVLN(i).a,3))*1000;
end


C = [0.0254    % Type 1
     0.258     % Type 2
     1.31      % Type 3
     0         % Type 4
     2.08      % Type 5
     5.26      % Type 6
     67.4      % Type 7
     185       % Type 8
     70];      % Type 9
k=0;
for i = IND_NV
    k=k+1;
    Feeder1.Topology(NVLN(i).a,4)=Ip(k);
end

for i = IND_OV
    k=k+1;
    Feeder1.Topology(OVLN(i).a,4)=Ip(k);
end

Cost = 0;
k = 0;
for i = 1:length(IND_NV)
    k = k + 1;
    if Ip(k) ~=xmin(k)
        Cost = Cost + C(Ip(k))*LL_NV(i);
    end
end

for i = 1:length(IND_OV)
    k = k + 1;
    if Ip(k) ~=xmin(k)
        Cost = Cost + C(Ip(k))*LL_OV(i);
    end
end

PF = ThreePhase_LoadFlow(Feeder1);
V = abs(PF.Vpu_line);

Penalty = 10e10*max(0,max(max(V))-1.05);

cost = Cost + Penalty;
end


k=0;
for i = IND_NV
    k=k+1;
    Feeder1.Topology(NVLN(i).a,4)=gbest(k);
end

for i = IND_OV
    k=k+1;
    Feeder1.Topology(OVLN(i).a,4)=gbest(k);
end
PF = ThreePhase_LoadFlow(Feeder1);
V = abs(PF.Vpu_line);
plot(V)