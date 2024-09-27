% plot_Lorenz3D.m, https://github.com/bhanson10/gbees-hash/tree/main/examples/Lorenz3D
% Copyright 2024 by Benjamin Hanson, published under BSD 3-Clause License.

close all; clc; clear all; 

%% initializing system properties
prop.d = 3; prop.T = 2; prop.dx = 0.5; prop.sigma = 4; prop.b = 1; prop.r = 48;
ic = [-11.5; -10; 9.5]; 

%% initializing figure
initialize_figures(); 

%% truth
options = odeset('MaxStep', 1E-3, 'InitialStep', 1E-3, 'RelTol', 1e-6);
[~, x] = ode87(@(t, x) Lorenz3D(t, x ,prop), [0 50], ic, options);

nexttile(1); 
plot3(x(:,1), x(:,2), x(:,3), 'g-','linewidth', .5, 'HandleVisibility', 'off');  
drawnow;

[~, x] = ode87(@(t, x) Lorenz3D(t, x, prop), [0 prop.T], ic, options);
plot3(x(:,1),x(:,2),x(:,3),'k-','linewidth',2,'DisplayName','Nominal'); drawnow;

nexttile(2); 
plot3(x(:,1),x(:,2),x(:,3),'k-','linewidth',2,'DisplayName','Nominal'); drawnow;

%% GBEES
NM = 2; 
p.color = "cyan"; p.alpha = [0.3, 0.5, 0.7]; 
P_DIR = "./results/c";

count = 1;
for nm=0:NM-1

    P_DIR_SUB = P_DIR + "/P" + num2str(nm); 
    FILE_LIST = dir(fullfile(P_DIR_SUB, '*.txt'));  % List only .txt files
    num_files = numel(FILE_LIST);

    for i=[0:num_files - 1]
        P_FILE = P_DIR_SUB + "/pdf_" + num2str(i) + ".txt";

        [x_gbees, P_gbees, n_gbees, t_gbees(count)] = parse_nongaussian_txt(P_FILE);

        xest_gbees{count} = zeros(size(x_gbees(1,:)));
        for j=1:n_gbees
            xest_gbees{count} = xest_gbees{count}+x_gbees(j,:).*P_gbees(j);
        end

        nexttile(1); 
        plot_nongaussian_surface(x_gbees,P_gbees,[normpdf(1)/normpdf(0), normpdf(2)/normpdf(0), normpdf(3)/normpdf(0)],p);
        nexttile(2);  
        plot_nongaussian_surface(x_gbees,P_gbees,normpdf(3)/normpdf(0), p);
        drawnow; 
        
        count = count + 1;
    end
    p.color = "magenta"; 
end

clear L; clear LH; 
LH(1) = fill(nan, nan, nan, 'FaceAlpha', 0.7, 'FaceColor', 'cyan', 'EdgeColor', 'none');
L{1} = "$p_\mathbf{x}(\mathbf{x}', t_{0+})\,\,\,$";
LH(2) = fill(nan, nan, nan, 'FaceAlpha', 0.7, 'FaceColor', 'magenta', 'EdgeColor', 'none');
L{2} = "$p_\mathbf{x}(\mathbf{x}', t_{1+})\,\,\,$";
leg = legend(LH, L, 'Orientation', 'Horizontal', 'FontSize', 18, 'FontName', 'times', 'Interpreter', 'latex');
leg.Layout.Tile = 'south';
drawnow; 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                              FUNCTIONS                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function f=Lorenz3D(t, x,prop)                          
    f=[prop.sigma*(x(2)-x(1));  -x(2)-x(1)*x(3);  -prop.b*x(3)+x(1)*x(2)-prop.b*prop.r];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function initialize_figures()

    f1 = figure(1); clf; hold all; f1.Position = [150 200 1200 475];
    tiledlayout(1, 2, 'TileSpacing','compact');

    nexttile(1); hold all; 
    view(-109,14); lighting phong; light('Position',[-1 0 0]); 
    set(gca, 'FontName' , 'Times','FontSize',12);
    xlabel("x", 'FontSize', 18, 'FontName', 'Times');
    ylabel("y", 'FontSize', 18, 'FontName', 'Times');
    zlabel("z", 'FontSize', 18, 'FontName', 'Times');
    set(get(gca,'ZLabel'), 'Rotation', 0);
    xlim([-20 20])
    xticks([-20 -10 0 10 20])
    xticklabels({'-20','-10','0','10','20'})
    ylim([-30 30])
    yticks([-30 -20 -10 0 10 20 30])
    yticklabels({'-30','-20','-10','0','10', '20', '30'})
    zlim([-30 30])
    zticks([-30 -20 -10 0 10 20 30])
    zticklabels({'-30','-20','-10','0','10', '20', '30'})
    
    nexttile(2); hold all; 
    view(-109,14); lighting phong; light('Position',[-1 0 0]);
    set(gca, 'FontName' , 'Times','FontSize',12);
    xlabel("x", 'FontSize', 18, 'FontName', 'Times');
    ylabel("y", 'FontSize', 18, 'FontName', 'Times');
    zlabel("z", 'FontSize', 18, 'FontName', 'Times');
    set(get(gca,'ZLabel'), 'Rotation', 0);
    xlim([-20 20])
    xticks([-20 -10 0 10 20])
    xticklabels({'-20','-10','0','10','20'})
    ylim([-30 30])
    yticks([-30 -20 -10 0 10 20 30])
    yticklabels({'-30','-20','-10','0','10', '20', '30'})
    zlim([-30 30])
    zticks([-30 -20 -10 0 10 20 30])
    zticklabels({'-30','-20','-10','0','10', '20', '30'})
    set(gca, 'FontName' , 'Times');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [x, P, n, t] = parse_nongaussian_txt(filename)
    fileID = fopen(filename, 'r'); t = str2double(fgetl(fileID));
    
    count = 1; 
    while ~feof(fileID)
        line = split(fgetl(fileID)); % Read a line as a string
        P(count,1) = str2double(line{1});
        x(count, :) = [str2double(line{2});str2double(line{3});str2double(line{4})];
        count = count + 1; 
    end
    
    % Close the file
    fclose(fileID);
    n = length(P); 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%