
function [V,cost] = CostEval2(IND_NV, IND_OV, Ip, NVLN, OVLN, Feeder, Feeder1, xmin)
%, Nl,Phase

LL_NV = zeros(length(xmin)/2,1);
LL_OV = zeros(length(xmin)/2,1);


for i = 1:length(LL_NV)
    if ~isempty(Feeder.Topology(NVLN(i).a,3))
        LL_NV(i,1) = sum(Feeder.Topology(NVLN(i).a,3))*1000;
    end
end

for i = 1:length(LL_OV)
    if ~isempty(Feeder.Topology(OVLN(i).a,3))
        LL_OV(i,1) = sum(Feeder.Topology(OVLN(i).a,3))*1000;
    end
end

% % DV = [1 2 3 4 5 6 7 8];
% % Topology = [1 2 3 5 6 7 8 9];




% % % C = [0.0254    % Type 1
% % %      0.258     % Type 2
% % %      1.31      % Type 3
% % %      0         % Type 4
% % %      2.08      % Type 5
% % %      5.26      % Type 6
% % %      67.4      % Type 7
% % %      185       % Type 8
% % %      70];      % Type 9

C = [2.00    % Type 1
     2.02     % Type 2
     2.12      % Type 3
     15         % Type 4
     2.37      % Type 5
     2.95      % Type 6
     14.20      % Type 7
     35.48      % Type 8
     14.67] + 100;      % Type 9
 
%  1	0,03 mm²	2,00
% 2	0,26 mm²	2,02
% 3	1,31 mm²	2,12
% 4	35,0 mm²	5,17
% 5	2,08 mm²	2,37
% 6	5,26 mm²	2,95
% 7	67,4 mm²	14,20
% 8	185,0 mm²	35,48
% 9	70,0 mm²	14,67


% Feeder1 = LoadFeeder('European_LV.xlsx');
% Feeder1.Vpu_slack_phase=1.03*[1*exp(-1i*pi/6);exp(-1i*5*pi/6);exp(1i*pi/2)];
% Phase1 = Phase(3,:);

% for i = 1:length(Nl)
%     Feeder1.Loads(i,3+(Phase1(i)-1)*2+1) = Nl(i);
% end


for i = 1:length(IND_NV)
    if ~isempty(NVLN(i).a)
        Feeder1.Topology(NVLN(i).a,4)=Ip(i);
    end
end

for i = 1:length(IND_OV)
    if ~isempty(OVLN(i).a)
        Feeder1.Topology(OVLN(i).a,4)=Ip(9+i);
    end
end


Cost = 0;
for i = 1:length(IND_NV)
    if ~isempty(NVLN(i).a)
        if Ip(i) ~= i
            Cost = Cost + C(Ip(i))*LL_NV(i);
        end
    end
end

for i = 1:length(IND_OV)
    if ~isempty(OVLN(i).a)
        if Ip(9+i) ~= i
            Cost = Cost + C(Ip(9+i))*LL_OV(i);
        end
    end
end 


% Cost = 0;
% 
% for i = 1:length(IND_NV)
%     if ~isempty(NVLN(i).a)
%         if Ip(i) ~=xmin(i)
%             Cost = Cost + C(Ip(i))*LL_NV(i);
%         end
%     end
% end
% 
% for i = 1:length(IND_OV)
%     if ~isempty(OVLN(i).a)
%         if Ip(i) ~=xmin(i)
%             Cost = Cost + C(Ip(i))*LL_OV(i);
%         end
%     end
% end

PF = ThreePhase_LoadFlow(Feeder1);
V = abs(PF.Vpu_line);

Penalty = 10e7*max(0,max(max(V))-1.05);

cost = Cost + Penalty;
end


