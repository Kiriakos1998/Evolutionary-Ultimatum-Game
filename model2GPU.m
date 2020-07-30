% This function models the spatian one dimension evolutionary ultimatum
% game using gpuArrays( for large matrix if you have nvidia will accelarate
% calculations)
% Inputs parameters N is the number of the population 
%n is the range where players play for example if n is 1 then each player
%plays only with those who are directly close to it
%e is the error value or mutation value
%generations is the number of the total generations
function [ps,qs]=model2GPU(N,n,e,generations)
n=n/2;
% initialize the offers of each player p and the minimun accepted offer for
% each player q so that i-th row of p and q have the p and q value for the
% i player except for the N+1 element of each matrix that will hold Inf
p=rand(N+1,1,'gpuArray');
q=rand(N+1,1,'gpuArray');
%initialize matrix to hold on mean and std values of the population in each
%generations
pmean=zeros(91,1,'gpuArray');
qmean=zeros(91,1,'gpuArray');
pstd=zeros(91,1,'gpuArray');
qstd=zeros(91,1,'gpuArray');
%intitialize matrix to take samples fot the plots
samples=zeros(N,2,4,'gpuArray');
% initialize matrix to hold on the gain of each player N+1 position will
% remain as it points to an imaginary player 
playerGain=zeros(N+1,1,'gpuArray');
% initialize matrix to hold the total gain of each position 
totalGainPerPosition=zeros(N,1,'gpuArray');
% calculate a correction to the indexes of the parents that will be
% calculated later
parentsCorrection=-n:1:N-n-1;
parentsCorrection=parentsCorrection';
% initialize matrix to hold the opponents of each player and the
% competerots of each place the players that compete to leave an offspring
opponents=zeros(N,2*n);
competetors=zeros(N,2*n+1);
% initialize triangle matrix that will be used later
triangleMatrix=tril(ones(2*n+1,2*n+1))';
%set N+1 value to Inf 
p(N+1,1)=Inf;
q(N+1,1)=Inf;
% initialize ones rows that will me used later and matrix
oneRow=ones(1,2*n+1,'gpuArray');
oneRows=ones(1,2*n,'gpuArray');
onesMatrix=ones(N,2*n,'gpuArray');
% calculate the opponents of each player as well as the competetors for
% each position
for i=1:1:N
    opponents(i,1:1:n)=i-n:1:i-1;
    opponents(i,n+1:1:2*n)=i+1:1:i+n;
    competetors(i,1:1:2*n+1)=i-n:1:i+n;
end
% negative values or values greater than N mean invalid player for example
% player one doesnt have any player to each left so player one cant playe
% with player 0 because player 0 doest exist so set these values to N+1
competetors(competetors<1| competetors>N)=N+1;
opponents(opponents<1| opponents>N)=N+1;
cheatMatrix=zeros(N,2*n);
%find all the indexes of i player opponents
for i=1:1:N
x=find(opponents==i);
x=x';
% if x has not 2*n length make it have by assigning as opponent's index the
% value 1 which points to no valid  deal
if length(x)<2*n
for j=1:1:2*n-length(x)
x=[x,1];
end
end
%set x value to the cheatMatrix
cheatMatrix(i,:)=x;
end
opponents=gpuArray(opponents);
competetors=gpuArray(competetors);
cheatMatrix=gpuArray(cheatMatrix);
for j=1:1:generations
%collect mean values
if j>=100000 && mod(j,10000)==0
k=(j-100000)/10000+1;
pmean(k,1)=mean(p(1:1:N));
qmean(k,1)=mean(q(1:1:N));
pstd(k,1)=std(p(1:1:N));
qstd(k,1)=std(q(1:1:N));
end
% collect samples for the graphs 
switch j
      case 1
          samples(:,1,1)=p(1:1:N,1);
          samples(:,2,1)=q(1:1:N,1);
      case 100
           samples(:,1,2)=p(1:1:N,1);
          samples(:,2,2)=q(1:1:N,1);
      case 10000
            samples(:,1,3)=p(1:1:N,1);
          samples(:,2,3)=q(1:1:N,1);
      case 100000
           samples(:,1,4)=p(1:1:N,1);
          samples(:,2,4)=q(1:1:N,1);
end

% after this multiplication each row has the offer of the player i to its
% opponents only even to those that are not valid 
offering=p(1:1:N)*oneRows;
% abstract the q values of the oppenents of each player by indexing q
% matrix invalid opponents will point to N+1 which hold Inf value and the
% result will be -Inf
logicalOffering=offering-q(opponents);
% consider that a deal has happened if the offer is greater or equal to q
% of the opponent and the that is with a real player
logicalOffering=logicalOffering>=0;
%initialize offering gain with one. It will be used to find the gain of
%each player as proposer
offeringGain=onesMatrix;
%abstract from  the 1 the p value of each player now every row has the
%gain of each player as proposer. Also multiply with logicalOffering matrix
%so invalid and not accepted proposals are set to zero
offeringGain=(offeringGain-offering).*logicalOffering;
% multiply(element wise) offering with logicalOffering so that only the
% valid offers remain. Now when offering is indexed properly can return the
% gain of each player as responder
offering=offering.*logicalOffering;
% the sum of each row now has the total gain of each player as proposer
proposerGain=sum(offeringGain,2);
% index offering and calculate each players gain
responderGain=sum(offering(cheatMatrix),2);
% calculate each player's gain
playerGain(1:1:N)=proposerGain+responderGain;
% index playerGain with the position of each competetor for each position
% sum of each row has the value of the total payoff of the competetors for
% that position
totalGainPerPosition(1:1:N,1)=sum(playerGain(competetors),2);
% find all the positions that have 0 payoff which means all the competetors
% have equal propability to lay off an offspring 
zeroGains=find(totalGainPerPosition(1:1:N)==0);

%  produce random values for each position
correctZeroSums=ceil(rand(length(zeroGains),1)*(2*n+1));
% take some special cases in case those positions are less than n+1 then
% some values are not accepter give randomly only the accepted values
if(isempty(zeroGains(zeroGains<n+1))==0)
correctZeroSums(zeroGains<n+1)=ceil(rand(1,length(zeroGains(zeroGains<n+1))).*(2*n+1-n-2+zeroGains(zeroGains<n+1)))-zeroGains(zeroGains<n+1)+n+1;
end
% same for positions greater than N-n
if(isempty(zeroGains(zeroGains>N-n))==0)
correctZeroSums(zeroGains>N-n)=ceil(rand(1,length(zeroGains(zeroGains>N-n))).*(2*n+1-n+N-zeroGains(zeroGains>N-n)));
end
%create matrix that each row has the gain of each competetor for that
%position
competetorsGains=playerGain(competetors);
%make a matrix where each row has 2*n+1 times the total payoff o all the
%competetors for that position
expandedTotalGainPerPossiton=totalGainPerPosition(1:1:N,1)*oneRow;
% perform element wise division so that each row has the propabilities of
% each competetor for that place
thresholdMatrix=competetorsGains./expandedTotalGainPerPossiton;
%now every row is has separate the interval 0-1 for example for n=2 i row
%has the values 0.2 0.4 0.8 0.85 1 each interval represents the propability
%of one of the 5 competetors for the i place to leave an offspring
thresholdMatrix=thresholdMatrix*triangleMatrix;
%calculate the N random numbers that will be used to check in which
%interval they belong for example of the i value of reproduction is 0.3 it
%means that the second competetor of the i place will leave an offspring
reproduction= rand(N,1);
% now every row has the 2*n+1 times (as the number of competetors) the
% value that will determine its parent
reproductionExpanded=reproduction*oneRow;
% abstract these matrixs and the index of the minimun positive value of
% each row will point to the parent of that position
thresholdMatrix=thresholdMatrix-reproductionExpanded;
%  first set negative and 0 values to inf 
thresholdMatrix(thresholdMatrix<=0)=Inf;
% find now indexes of min values of each row 
[~,parents]=min(thresholdMatrix,[],2);
% make the correction for the total gains of zero because the division in
% line 144 has produced wrong numbers
parents(zeroGains)=correctZeroSums;
% now correct the indexes again because all indexes are 1-2*n+1 
parents=parents+parentsCorrection;
% calculate mutation error
errorp=(e).*rand(N,1)-e/2;
errorq=(e).*rand(N,1)-e/2;
% update p and q
p(1:1:N,1)=p(parents,1)+errorp;
q(1:1:N,1)=q(parents,1)+errorq;
%set p q less than 0 to zero and greater than 1 to 1
p(p<0)=0;
q(q<0)=0;
p(p>1)=1;
q(q>1)=1;
%but N+1 position has to be inf because represents non existing match ups
p(N+1,1)=Inf;
q(N+1,1)=Inf;
end
% plot p and q collected
figure('Name','t=0 p values','NumberTitle','off')
scatter(1:1:N,samples(:,1,1),'filled');
figure('Name','t=0 q values','NumberTitle','off')
scatter(1:1:N,samples(:,2,1),'filled');
figure('Name','t=100 p values','NumberTitle','off')
scatter(1:1:N,samples(:,1,2),'filled');
ylim([0 1])
figure('Name','t=100 q values','NumberTitle','off')
scatter(1:1:N,samples(:,2,2),'filled');
ylim([0 1])
figure('Name','t=10000 p values','NumberTitle','off')
scatter(1:1:N,samples(:,1,3),'filled');
figure('Name','t=10000 q values','NumberTitle','off')
scatter(1:1:N,samples(:,2,3),'filled');
figure('Name','t=10^5 p values','NumberTitle','off')
scatter(1:1:N,samples(:,1,4),'filled');
figure('Name','t=10^5 q values','NumberTitle','off')
scatter(1:1:N,samples(:,2,4),'filled');
% calculate p and q stats
ps=[mean(pmean),mean(pstd)];
qs=[mean(qmean),mean(qstd)];
end