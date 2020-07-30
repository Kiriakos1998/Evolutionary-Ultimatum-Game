% This function models the spatial 2-D evolutionary ultimatum game
% grid is the dimension of the matrix that population is arranged
% e is the mutation error
% generations is the number of the generations that are modeled
% every player plays with the directly above below left and right to it
function [ps,qs]=model3(grid,e,generations)
%special case in spatial set that have not for example parent on their left
%or their right. From now on let it be that parent with index 1 means
%player of the left index 2 player on the right index 3 player above index
% 4 player below and index 5 player of the same spot
upEdge=[1,2,4,5];
lowEdge=[1,2,3,5];
rightEdge=[1,3,4,5];
cornerLU=[2,4,5];
cornerLL=[2,3,5];
cornerRL=[1,3,5];
cornerRU=[1,4,5];
%initialize vectors that will be used to collect data from population
%thougth time
pmean=zeros(91,1);
qmean=zeros(91,1);
pstd=zeros(91,1);
qstd=zeros(91,1);
% calculate population
N=grid*grid;
% initialize p and q values
p=rand(N+1,1);
q=rand(N+1,1);
% initialize for speed vector that holds the total gain of each player
playerGain=zeros(N+1,1);
%total gain per position (sum of all the competetors for that position
%gain)
totalGainPerPosition=zeros(N+1,1);
%each row of this matrix has the opponents of each player
opponents=zeros(N,4);
% triangle matrix that will be used to assign to each player a interval
% analogous to its gain compared to other player's gain that compete for
% the same place
triangleMatrix=tril(ones(5,5))';
% matrix that holds the competetors of each place
competetors=zeros(N,5);
% N+1 value models invalid match ups for example player 1 doesn't have any
% player on its left so competetors will have N+1 value as its first
% element. This saves model a lot of time as it is very costly to calculate
% seperately these cases
p(N+1,1)=Inf;
q(N+1,1)=Inf;
% useful vectors that when multiplie with a column vector reproduce 5 or 4
% times each element on each row. 
oneRow=ones(1,5);
oneRows=ones(1,4);
% initialize here matrix to save time
onesMatrix=ones(N,4);
%calculate oponents and competetors of each player
for i=1:1:N
    opponents(i,1)=i-1;
    opponents(i,2)=i+1;
    opponents(i,3)=i-grid;
    opponents(i,4)=i+grid;
    competetors(i,1:1:4)=opponents(i,1:1:4);
    competetors(i,5)=i;
end
% make sure invalid match ups are set to N+1
for i=1:grid:grid*(grid-1)+1
opponents(i,1)=N+1;
opponents(i+grid-1,2)=N+1;
competetors(i,1)=N+1;
competetors(i+grid-1,2)=N+1;
end
% all negative numbers or greater than N indicate invalid match up
competetors(competetors<1| competetors>N)=N+1;
opponents(opponents<1| opponents>N)=N+1;
% correction because later when calulating parents will only have values
% from 1-5
parentsCorrection=0:5:N*5-5;
parentsCorrection=parentsCorrection';
%competetors inverse matrix will be used later is cheaper to save it from
%now
competetorsT=competetors';
% matrix that has the indexs of each players gain as responder in a matrix
% that will occur later 
cheatMatrix=zeros(N,4);
%find all the indexes of i player opponents
for i=1:1:N
x=find(opponents==i);
x=x';
% if x has not 2*n length make it have by assigning as opponent's index the
% value 1 which points to no valid  deal
if length(x)<4
for j=1:1:4-length(x)
x=[x,1];
end
end
%set x value to the cheatMatrix
cheatMatrix(i,:)=x;
end
% iretate through every generation
for j=1:1:generations
%sample from 100000-1000000 at 10000 intervals
if j>=100000 && mod(j,10000)==0
k=(j-100000)/10000+1;
pmean(k,1)=mean(p(1:1:N));
qmean(k,1)=mean(q(1:1:N));
pstd(k,1)=std(p(1:1:N));
qstd(k,1)=std(q(1:1:N));
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
% calculate correctZeroSums to be random numbers between 1-5
correctZeroSums=ceil(rand(length(zeroGains),1)*5);
%now take all the special case lef edge right edge upper edge and lowe edge
% also the corners and calculate accepted parents
correctZeroSums(zeroGains<grid)=upEdge(ceil(rand(length(zeroGains(zeroGains<grid)),1)*4));
correctZeroSums(mod(zeroGains,grid)==1)=ceil(rand(length(zeroGains(mod(zeroGains,grid)==1)),1)*4+1);
correctZeroSums(mod(zeroGains,grid)==0)=rightEdge(ceil(rand(length(zeroGains(mod(zeroGains,grid)==0)),1)*4));
correctZeroSums(zeroGains>grid*(grid-1)+1)=lowEdge(ceil(rand(length(zeroGains(zeroGains>grid*(grid-1)+1)),1)*4));
correctZeroSums(zeroGains==1)=cornerLU(ceil(rand()*3));
correctZeroSums(zeroGains==grid)=cornerRU(ceil(rand()*3));
correctZeroSums(zeroGains==grid*(grid-1)+1)=cornerLL(ceil(rand()*3));
correctZeroSums(zeroGains==N)=cornerRL(ceil(rand()*3));
%calculate competetors gains
competetorsGains=playerGain(competetors);
% each row now has every positions total gain five times
expandedTotalGainPerPossiton=totalGainPerPosition(1:1:N,1)*oneRow;
% perform element wise division now each element of each row has the
% propability of each of the competetors for that position to leave an
% offspring
thresholdMatrix=competetorsGains./expandedTotalGainPerPossiton;
% now assign to each competetor and interval in each row inside 0-1
thresholdMatrix=thresholdMatrix*triangleMatrix;
%produce random numbers to determine parent of each position
reproduction= rand(N,1);
% each row now has the reproduction value calculated above 5 times 
reproductionExpanded=reproduction*oneRow;
% abstract so now in each row the index of the minimun positive number is
% the parent for tha position but careful it is going to be 1-5 which means
% up left right etc correction will be needed to take the right values
thresholdMatrix=thresholdMatrix-reproductionExpanded;
% set zero and negative values to Inf
thresholdMatrix(thresholdMatrix<=0)=Inf;
% find indexes of min values of each row 
[~,parents]=min(thresholdMatrix,[],2);
% make correction as it concerns the zero gains
parents(zeroGains)=correctZeroSums;
% make correction to go from 1-5 to the real indexes of the parents
parents=parents+parentsCorrection;
% calculate mutation error
errorp=(e)*rand(N,1)-e/2;
errorq=(e)*rand(N,1)-e/2;
% set new p and q values
p(1:1:N,1)=p(competetorsT(parents),1)+errorp;
q(1:1:N,1)=q(competetorsT(parents),1)+errorq;
% any p greater than 1 set to 1 and less than 0 to 0
p(p<0)=0;
q(q<0)=0;
p(p>1)=1;
q(q>1)=1;
% correct N+1 value of p and q 
p(N+1,1)=Inf;
q(N+1,1)=Inf;

end
% calculate means
ps=[mean(pmean),mean(pstd)];
qs=[mean(qmean),mean(qstd)];
end