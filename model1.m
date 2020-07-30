% population is the size of the population that is to be modeled
% errorValues is the error with which a child inherits a strategy from its parent
% generations is the number of generations that are to be modeled
function [ps,qs]=model1(population,errorValues,generations)
% each row represents a player with a strategy defined by two numbers
% first column represents the offer (p)that a player will make to the other
% players so it's the amount that will offet to them to take 
% and the second column represents the minimum amount that another player
% has to offer in order to accept the offer(q)
%initialize with random numbers all the strategies
populationMatrix=rand(population,2);
%initialize matrixs to strore mean value of p and q of all players 
% and the std of theese values in each generation
pmean=zeros(91,1);
qmean=zeros(91,1);
pstd=zeros(91,1);
qstd=zeros(91,1);
pval=zeros(1000,1);
qval=zeros(1000,1);
%calculate a row vector with ones here to avoid costly calculations in 
%loop to minimize execution time
onesRowVector=ones(1,population);
%same for onesMatrix
onesMatrix=ones(population,population);
triangleMatrix=tril(ones(population,population));
% irretate through all generations
for j=1:1:generations
    % calculat mean of p and q and the standar deviation of p and q
if j>=100000 && mod(j,10000)==0
k=(j-100000)/10000+1;
pmean(k,1)=mean(populationMatrix(:,1));
qmean(k,1)=mean(populationMatrix(:,2));
pstd(k,1)=std(populationMatrix(:,1));
qstd(k,1)=std(populationMatrix(:,2));
end
if j<1001
pval(j,1)=mean(populationMatrix(:,1));
qval(j,1)=mean(populationMatrix(:,2));
end
%matrix with the offer each player will make to all the other players
%now each row has the offer each player will make to the other player
%so offerMatrix(i,j) represents the offer the i player will make to j


offerMatrix=populationMatrix(:,1)*onesRowVector;
% matrix with the minimun accepted offer values from each player against
% all the others. So each row represents the minimun accepted offer for the
%the player in order to accept the offer from the column player
%acceptMatrix(i,j) represents q of i player against j player
acceptMatrix=populationMatrix(:,2)*onesRowVector;
% payOfMatrix(i,j) represends the difference between the p of i player and
%the q of j player so in order to consider that the offer o i player was 
%accepted by j the payOfMatrix(i,j) is equal or greater to zero
payOffMatrix=offerMatrix-acceptMatrix';
%create logical matrix so value logicalPayOffMatrix(i,j) means that the
%offer i player made to j was accepted
logicalPayOffMatrix= payOffMatrix >=0;
% set the diagonal to zero since no player plays against himself
offerMatrix=offerMatrix- diag(diag(offerMatrix));
% each row of this matrix has the offer the i player has made to other
% players but only to those that accepted the split. So offerGain(i,j) is
% equal to either the p of i player or 0;
% so each column represends the offers that a player has accepted so the
% sum j column represends the gain of the j as responder
offerGain=offerMatrix.*logicalPayOffMatrix;
%initialize the matrix that will give the gain of each player as a proposer
%with the value 1 that means the whole gift and set its diagonal to zero
acceptGain=onesMatrix;
acceptGain=acceptGain-diag(diag(acceptGain));
% set to zero the offers that weren't accepted
acceptGain=acceptGain.*logicalPayOffMatrix;
% abstract from 1 the amount that was offered to the other player so i-th
% row now represents the gain i player had as a proposer against all the
% other players
acceptGain=acceptGain-offerGain;
% calculate total gain of each player by suming its gain both as responder
% and as proposer
playerGain=(sum(acceptGain,2))'+sum(offerGain);
%calculate the propability of each player to reproduce
offspringProb=playerGain/sum(playerGain);
% this multiplication seperates the distance 0-1 according to the
% propability of each player to reproduce. So if for example the
% propabiliity of the first player to reproduce is 0.03 the first element
% of column vector that will ocur will be 0.03 and if the second player has
%probability to reproduce 0.01 the second value of the column vector will
% so the interval 0-0.03 belongs to player 1 and 0.03-0.04 belongs to
% player 2. 
thresholds=triangleMatrix*offspringProb';
% after this muliplication each column has the interavals of each player
% and each i-th models the selection of offspring for the i-th place
thresholdsMatrix=thresholds*onesRowVector;
% generate random numbers from 0-1 so the interval the interval that the
% i-th number belongs shows which will be the parent for i-th place
reproduction= rand(population,1);
% now each row contains the key-value for the i-th place that determines 
% which will be the parent
reproduction= reproduction*onesRowVector;
% abstracting all the key values from the intervals values will show which
% will be the parent for each place. This information will be in each
% column
thresholdsMatrix=thresholdsMatrix-reproduction';
% set all values less or equal to zero to be infinity so in next step the
% index of min value of each column will show which will be the parent for
% the i place
thresholdsMatrix(thresholdsMatrix<=0)=Inf;
% find parent for each place
[~,parents]=min(thresholdsMatrix,[],1);
%calculate p and q erros
errorp=(errorValues)*rand(population,1)-errorValues/2;
errorq=(errorValues)*rand(population,1)-errorValues/2;
% update the p and q values of its place
populationMatrix(:,1)=populationMatrix(parents,1)+errorp;
populationMatrix(:,2)=populationMatrix(parents,2)+errorq;
% set any values greater to 1 to be 1 or less to 0 to 0
populationMatrix(populationMatrix<0)=0;
populationMatrix(populationMatrix>1)=1;
end
figure(1)
plot(log10(1:1:1000),pval(1:1:1000));
ylim([0 1])
figure(2)
plot(log10(1:1:1000),qval(1:1:1000));
ylim([0 1])
ps=[mean(pmean),mean(pstd)];
qs=[mean(qmean),mean(qstd)];
end
