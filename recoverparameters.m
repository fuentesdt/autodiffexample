clear all
close all
clc


%% Choose Excitation Angle
FAType = {'OED','Const'};
idoed = 1;
idcst = 2;

solverType = {'adj','sqp','interior-point'};
gpList = [3, 4,5]
gpList = [3]
uncertainList = [3]
snrList = [10]
numsolves = numel(solverType) * length(gpList) * length(uncertainList) * length(snrList) +1
solnList(numsolves) = struct('gp',[],'snr',[],'numberuncertain',[],'FaList',[],'solver',[], 'params', [], 'Mxy', [], 'Mz', []);
icount  = 0;
for isolver = 1:numel(solverType)
 for igp = 1:length(gpList)
  for inu = 1:length(uncertainList)
   for isnr = 1:length(snrList)
      worktmp = load(sprintf('poptNG%dNu%d%sSNR%02d.mat',gpList(igp),uncertainList(inu),solverType{isolver},snrList(isnr)));
      icount= icount+1;
      solnList (icount) = struct('gp',gpList(igp),'snr',snrList(isnr),'numberuncertain',uncertainList(inu),'FaList',worktmp.popt.FaList,'solver',solverType{isolver},'params',worktmp.params, 'Mxy',worktmp.Mxyopt, 'Mz',worktmp.Mzopt);
   end
  end
 end
end

solnList (numsolves) = struct('gp',-1,'snr',-1,'numberuncertain',-1,'FaList',worktmp.params.FaList,'solver','const','params',worktmp.params, 'Mxy',worktmp.Mxy, 'Mz',worktmp.Mz);

% extract timehistory info
num_trials = 25;
Ntime = 23;
Nspecies = 2;
timehistory  = zeros(Ntime,Nspecies,num_trials+1,length(solnList) );

for jjj =1:length(solnList)
  % NOTE - image noise is at the single image - signu is for the sum over time ==> divide by Ntime
  imagenoise = solnList(jjj).signu/Ntime;
  %disp([xroi(jjj),yroi(jjj),zroi(jjj)]);
  timehistory(:,1,num_trials+1,jjj) = solnList(jjj).Mz(1,:);
  timehistory(:,2,num_trials+1,jjj) = solnList(jjj).Mz(2,:);
  % add noise for num_trials
  for kkk = 1:num_trials
      realchannel = imagenoise *randn(Ntime,1);
      imagchannel = imagenoise *randn(Ntime,1);
      timehistory(:,1,kkk,jjj)= timehistory(:,1,num_trials+1,jjj) + sqrt( realchannel.^2 + imagchannel.^2); 
      realchannel = imagenoise *randn(Ntime,1);
      imagchannel = imagenoise *randn(Ntime,1);
      timehistory(:,2,kkk,jjj)= timehistory(:,2,num_trials+1,jjj) + sqrt( realchannel.^2 + imagchannel.^2);  
  end
end

TR_list = solnList(1).params.TRList 
figure(1)
plot( TR_list, timehistory(:,1,1,1), 'b', ...
      TR_list, timehistory(:,2,1,1), 'b-.', ...
      TR_list, timehistory(:,1,1,2), 'g', ...
      TR_list, timehistory(:,2,1,2), 'g-.', ...
      TR_list, timehistory(:,1,1,3), 'r', ...
      TR_list, timehistory(:,2,1,3), 'r-.', ...
      TR_list, timehistory(:,1,1,4), 'c', ...
      TR_list, timehistory(:,2,1,4), 'c-.')
title('noise added')
figure(2)
plot( TR_list, timehistory(:,1,num_trials+1,1), 'b', ...
      TR_list, timehistory(:,2,num_trials+1,1), 'b-.', ...
      TR_list, timehistory(:,1,num_trials+1,2), 'g', ...
      TR_list, timehistory(:,2,num_trials+1,2), 'g-.', ...
      TR_list, timehistory(:,1,num_trials+1,3), 'r', ...
      TR_list, timehistory(:,2,num_trials+1,3), 'r-.', ...
      TR_list, timehistory(:,1,num_trials+1,4), 'c', ...
      TR_list, timehistory(:,2,num_trials+1,4), 'c-.')
title('original data')

%% store soln
storekplopt   = zeros(num_trials+1,length(solnList));
storekveqpopt = zeros(num_trials+1,length(solnList));
storeT1Popt   = zeros(num_trials+1,length(solnList));
storeT1Lopt   = zeros(num_trials+1,length(solnList));
storeA0opt    = zeros(num_trials+1,length(solnList));
for idesign = 1:length(solnList)

   % setup optimization variables
   numberParameters = 2
   switch (numberParameters)
       case(1) 
         kpl = optimvar('kpl','LowerBound',0);
         kveqp =   kve/ ve ;
         T1P = initT1a;
         T1L = initT1b;
         A0  = jmA0;
         % ground truth 
         xstar.kpl        = initKpl;
%%        case(2) 
%%          kpl = optimvar('kpl','LowerBound',0);
%%          kveqp = optimvar('kveqp','LowerBound',0);
%%          T1P = initT1a;
%%          T1L = initT1b;
%%          A0  = jmA0;
%%          % ground truth 
%%          xstar.kpl        = initKpl;
%%          xstar.kveqp      = kve/ ve;
%%        case(4) 
%%          kpl = optimvar('kpl','LowerBound',0);
%%          kveqp = optimvar('kveqp','LowerBound',0);
%%          T1P = optimvar('T1P','LowerBound',0);
%%          T1L = optimvar('T1L','LowerBound',0);
%%          A0  = jmA0;
%%          % ground truth 
%%          xstar.kpl        = initKpl;
%%          xstar.kveqp      = kve/ ve;
%%          xstar.T1P        = initT1a;
%%          xstar.T1L        = initT1b;
%%        case(5) 
%%          kpl = optimvar('kpl','LowerBound',0);
%%          kveqp = optimvar('kveqp','LowerBound',0);
%%          T1P = optimvar('T1P','LowerBound',0);
%%          T1L = optimvar('T1L','LowerBound',0);
%%          A0  = optimvar('A0' ,'LowerBound',0);
%%          % ground truth 
%%          xstar.kpl        = initKpl;
%%          xstar.kveqp      = kve/ ve;
%%          xstar.T1P        = initT1a;
%%          xstar.T1L        = initT1b;
%%          xstar.A0         = initT1b;
   end
   statevariable  = optimexpr([Nspecies,Ntime]);
%%
%%
%%    disp('build constraints')
%%    disp('expm not available for AD.... ')
%%    disp('TODO: verify matrix exponent impelmented with sylvester formula')
%%    statevariable(:,1 )=0;
%%    for iii = 1:Ntime-1
%%      disp([Nspecies*(iii-1)+1 , Nspecies*(iii-1)+2 ,Ntime* Nspecies])
%%      klpqp =    0 ;     % @cmwalker where do I get this from ? 
%%      %A = [-1/T1P - kpl - kveqp,  klpqp; kpl, -1/T1L - klpqp];
%%      %[V,D] = eig(A);
%%      %traceA = A(1,1) + A(2,2);
%%      %detA = A(1,1)*A(2,2) - A(1,2)*A(1,2)  ;
%%      %lambda1 =traceA  + sqrt(traceA*traceA - 4 * detA) ;
%%      %lambda2 =traceA  - sqrt(traceA*traceA - 4 * detA) ;
%%      %V = [ A(1,2), A(2,2) - lambda2 ; A(1,1) - lambda1 ,-A(2,1)]; 
%%      %Vinv = 1/(V(2,2)* V(1,1)  -V(2,1)* V(1,2))*[V(2,2), -V(2,1); -V(1,2), V(1,1)];
%%      %expATR = V*[exp(lambda1 * TR) 0 ; 0 exp(lambda2 * TR)]*Vinv;
%%      % 
%%      currentTR = params.TRList(iii+1) - params.TRList(iii);
%%      nsubstep = 5;
%%      deltat = currentTR /nsubstep ;
%%      integratedt = [params.TRList(iii):deltat:params.TRList(iii+1)] +deltat/2  ;
%%      integrand = A0 *gampdf(integratedt(1:nsubstep )'-jmt0,jmalpha,jmbeta) ;
%%      % >> syms a  kpl d currentTR    T1P kveqp T1L 
%%      % >> expATR = expm([a,  0; kpl, d ] * currentTR )
%%      % 
%%      % expATR =
%%      % 
%%      % [                                     exp(a*currentTR),                0]
%%      % [(kpl*exp(a*currentTR) - kpl*exp(currentTR*d))/(a - d), exp(currentTR*d)]
%%      % 
%%      % >> a = -1/T1P - kpl - kveqp
%%      % >> d = -1/T1L
%%      % >> eval(expATR)
%%      % 
%%      % ans =
%%      % 
%%      % [                                                              exp(-currentTR*(kpl + kveqp + 1/T1P)),                   0]
%%      % [(kpl*exp(-currentTR/T1L) - kpl*exp(-currentTR*(kpl + kveqp + 1/T1P)))/(kpl + kveqp - 1/T1L + 1/T1P), exp(-currentTR/T1L)]
%%      %    
%%      %expATR = fcn2optimexpr(@expm,A*currentTR );
%%      % A = [-1/T1P - kpl - kveqp,  0; kpl, -1/T1L ];
%%      expATR = [ exp(-currentTR*(kpl + kveqp + 1/T1P)),                   0; (kpl*exp(-currentTR/T1L) - kpl*exp(-currentTR*(kpl + kveqp + 1/T1P)))/(kpl + kveqp - 1/T1L + 1/T1P), exp(-currentTR/T1L)];
%%      % mid-point rule integration
%%      aifterm = kveqp * deltat * [ exp((-1/T1P - kpl - kveqp)*deltat*[.5:1:nsubstep] );
%%    (kpl*exp((-1/T1P - kpl - kveqp)*deltat*[.5:1:nsubstep] ) - kpl*exp(-1/T1L *deltat*[.5:1:nsubstep] ))/((-1/T1P - kpl - kveqp) + 1/T1L )] * integrand ;
%%      statevariable(:,iii+1) =  expATR *( statevariable(:,iii ))   + aifterm     ;
%%      statevariable(:,iii+1) =  cos(params.FaList(:,iii+1)).* statevariable(:,iii+1);
%%      %statevariable(:,iii+1) =  expATR *( cos(params.FaList(:,iii)).* statevariable(:,iii ))   + aifterm     ;
%%    end
%%    truthstate = evaluate(statevariable ,xstar);
%%    %A = [-1/initT1a - initKpl - kveqp,  0; initKpl , -1/initT1b ];
%%    % model.getVIF(params)
%%    %walkerfun = @(t,y)A*y+(kveqp).*[A0 *gampdf(t-jmt0,jmalpha,jmbeta) ;0]; % A0 *gampdf(params.TRList-jmt0,jmalpha,jmbeta) 
%%    %for iii = 1:Ntime-1
%%    %  [~,Y] = ode45(walkerfun,[params.TRList(iii),params.TRList(iii+1)],truthstate(:,iii));
%%    %  truthstate(:,iii+1) = Y(end,:)';
%%    %  truthstate(:,iii+1)= cos(params.FaList(:,iii+1)).* truthstate(:,iii+1);
%%    %end 
%%    %for iii = 1:Ntime-1
%%    %  [~,Y] = ode45(walkerfun,[params.TRList(iii),params.TRList(iii+1)],cos(params.FaList(:,iii)).* truthstate(:,iii));
%%    %  truthstate(:,iii+1) = Y(end,:)';
%%    %end 
%%
%%    %% 
%%    % Create an optimization problem using these converted optimization expressions.
%%    disp('build objective function')
%%    %for idpixel = 1:100
%%    %  for idtrial = 1:num_trials 
%%    for idpixel = nroipixel+1:nroipixel+1
%%      for idtrial = num_trials+1:num_trials+1
%%        tic;
%%        disp(sprintf('pixel = %d, trial = %d, %s',idpixel, idtrial , FAType{idesign}));
%%        mycostfcn = sum( (statevariable(1,:)'- timehistory(:,1,idpixel,idtrial,idesign ) ).^2) + sum( (statevariable(2,:)'- timehistory(:,2,idpixel,idtrial,idesign ) ).^2);
%%        %mycostfcn = sum( (statevariable(1,:)'- walkerMz(1,:)' ).^2) + sum( (statevariable(2,:)'- walkerMz(2,:)' ).^2);
%%
%%        disp('create optim prob')
%%        convprob = optimproblem('Objective',mycostfcn );
%%        %% 
%%        % View the new problem.
%%        
%%        %show(convprob)
%%        problem = prob2struct(convprob,'ObjectiveFunctionName','generatedObjective');
%%        %% 
%%        % Solve the new problem. The solution is essentially the same as before.
%%        
%%
%%        %myoptions = optimoptions(@fmincon,'Display','iter-detailed','SpecifyObjectiveGradient',true, 'SpecifyConstraintGradient', true)
%%        %myoptions = optimoptions(@fmincon,'Display','iter-detailed','MaxFunctionEvaluations' , 3.000000e+04)
%%        myoptions = optimoptions(@lsqnonlin,'Display','iter-detailed');
%%            
%%        %[popt,fval,exitflag,output] = solve(convprob,x0,'Options',myoptions, 'ObjectiveDerivative', 'auto-reverse' , 'ConstraintDerivative', 'auto-reverse', 'solver', 'fmincon' )
%%        %[popt,fval,exitflag,output] = solve(convprob,x0,'Options',myoptions, 'ObjectiveDerivative', 'finite-differences','solver', 'fmincon' )
%%        % random initial guess
%%        switch (numberParameters)
%%           case(1) 
%%             x0.kpl        = unifrnd(.01,10);
%%           case(2) 
%%             x0.kpl        = unifrnd(.01,10);
%%             x0.kveqp      = unifrnd(.02,10);
%%           case(4) 
%%             x0.kpl        = unifrnd(.01,10);
%%             x0.kveqp      = unifrnd(.02,10);
%%             x0.T1P        = unifrnd(20 ,40);
%%             x0.T1L        = unifrnd(15 ,35);
%%           case(5) 
%%             x0.kpl        = unifrnd(.01,10);
%%             x0.kveqp      = unifrnd(.02,10);
%%             x0.T1P        = unifrnd(20 ,40);
%%             x0.T1L        = unifrnd(15 ,35);
%%             x0.A0         = unifrnd(1  ,100);
%%        end
%%        initialstate = evaluate(statevariable ,x0);
%%        [popt,fval,exitflag,output] = solve(convprob,x0,'Options',myoptions, 'solver','lsqnonlin' )
%%        switch (numberParameters)
%%           case(1) 
%%             storekplopt(  idpixel,idtrial,idesign)  = popt.kpl;
%%             storekveqpopt(idpixel,idtrial,idesign)  = kve/ ve ;
%%             storeT1Popt(  idpixel,idtrial,idesign)  = initT1a ; 
%%             storeT1Lopt(  idpixel,idtrial,idesign)  = initT1b ; 
%%             storeA0opt (  idpixel,idtrial,idesign)  = jmA0    ; 
%%           case(2) 
%%             storekplopt(  idpixel,idtrial,idesign)  = popt.kpl;
%%             storekveqpopt(idpixel,idtrial,idesign)  = popt.kveqp;
%%             storeT1Popt(  idpixel,idtrial,idesign)  = initT1a ; 
%%             storeT1Lopt(  idpixel,idtrial,idesign)  = initT1b ; 
%%             storeA0opt (  idpixel,idtrial,idesign)  = jmA0    ; 
%%           case(4) 
%%             storekplopt(  idpixel,idtrial,idesign)  = popt.kpl;
%%             storekveqpopt(idpixel,idtrial,idesign)  = popt.kveqp;
%%             storeT1Popt(  idpixel,idtrial,idesign)  = popt.T1P;
%%             storeT1Lopt(  idpixel,idtrial,idesign)  = popt.T1L;
%%             storeA0opt (  idpixel,idtrial,idesign)  = jmA0    ; 
%%           case(5) 
%%             storekplopt(  idpixel,idtrial,idesign)  = popt.kpl;
%%             storekveqpopt(idpixel,idtrial,idesign)  = popt.kveqp;
%%             storeT1Popt(  idpixel,idtrial,idesign)  = popt.T1P;
%%             storeT1Lopt(  idpixel,idtrial,idesign)  = popt.T1L;
%%             storeA0opt (  idpixel,idtrial,idesign)  = popt.A0 ; 
%%        end
%%
%%        slnstate = evaluate(statevariable ,popt);
%%    
%%        idplot = (nroipixel+1)*(num_trials+1)*(idesign-1) + (num_trials+1)*(idpixel-1) + idtrial ;
%%        figure(idplot )
%%        plot( params.TRList, timehistory(:,1,idpixel,idtrial,idesign), 'b', ...
%%              params.TRList, timehistory(:,2,idpixel,idtrial,idesign), 'b-.', ...
%%              params.TRList, timehistory(:,1,idpixel,num_trials+1,idesign), 'c', ...
%%              params.TRList, timehistory(:,2,idpixel,num_trials+1,idesign), 'c-.', ...
%%              params.TRList, initialstate(1,:), 'g', ...
%%              params.TRList, initialstate(2,:), 'g-.', ...
%%              params.TRList, walkerMz(1,:), 'r', ...
%%              params.TRList, walkerMz(2,:), 'r-.', ...
%%              params.TRList, truthstate(1,:), 'm', ...
%%              params.TRList, truthstate(2,:), 'm-.', ...
%%              params.TRList, slnstate(1,:), 'k', ...
%%              params.TRList, slnstate(2,:), 'k-.')
%%        ylabel('Mz')
%%        xlabel('sec')
%%        title('curvefit ')
%%        legend('jha+rice','','jha','','ic','','walker','','truth','','df','')
%%        pause(.1)
%%
%%        toc;
%%      end 
%%    end 
%%
end 
%%
%%
%%figure(6)
%%disp([ mean(storekplopt(:,:,1),2) var(storekplopt(:,:,1),0,2) mean(storekplopt(:,:,2),2) var(storekplopt(:,:,2),0,2) ])
%%disp([ var(storekplopt(nroipixel:nroipixel+1,1:num_trials,1),0,2) var(storekplopt(nroipixel:nroipixel+1,1:num_trials,2),0,2) ])
%%    
%%boxplot( [storekplopt(nroipixel+1,1:num_trials,1)',  storekplopt(nroipixel+1,1:num_trials,2)'], FAType)
%%