% Reset Workspace and Command Window
close all;
clear all;
clc;

data = importdata('Madrid_Speed.xlsx');    % Import data

% Creation of matrix to calculate and hold daily mean wind speed data 
dailyData = zeros(366,1);
k=1;
for i = 1 : 366
    dailyData(i,:) = mean(data(k:(k+23)))';
    k = k + 24;
end

dailyDataSize = max(size(dailyData));                % Number of rows in data

trainingSamples = 330;     % Number of data points to train (250 days)
testingSamples = 36;      % Number of data points to predict (116 days)
numOfInputs = 1;            % Number of network inputs
testingPoint = dailyDataSize - testingSamples - numOfInputs;   % Point to start prediction from

normalized_data = (dailyData - mean(dailyData))/std(dailyData);    % Zero mean, unit variance normalization

% Creation of matrix for the network to train and predict
netData = zeros(dailyDataSize-numOfInputs,numOfInputs+1);
for i = 1:dailyDataSize-numOfInputs
    netData(i,:) = normalized_data(i:(i+numOfInputs))';
end

% Creation of training matrices
P = netData(1:trainingSamples-numOfInputs,1:numOfInputs);   % Input samples
T = netData(1:trainingSamples-numOfInputs,numOfInputs+1);   % Expected targets

clearvars normalized_data;      % To free memory of variables no longer needed

net = newrb(P',T',0,1,30);     % newrb(P,T,GOAL,SPREAD,MN,DF)

% Declaration of matrices to calculate training forecast errors
training_actualOutput = zeros(trainingSamples-numOfInputs,1);
training_expectedOutput = zeros(trainingSamples-numOfInputs,1);
trainingError = zeros(trainingSamples-numOfInputs,1);

for j = 1:trainingSamples-numOfInputs
training_actualOutput(j,1) = sim(net,netData(j,1:numOfInputs)');    % Use network to predict training data
training_expectedOutput(j,1) = netData(j,numOfInputs+1);            % Expected outputs for comparison

% Denormalization of expected and predicted values
training_actualOutput(j,1) = (training_actualOutput(j,1)*std(dailyData))+mean(data);
training_expectedOutput(j,1) = (training_expectedOutput(j,1)*std(dailyData))+mean(data);

trainingError(j,1) = abs(training_actualOutput(j,1) - training_expectedOutput(j,1));
end

% To display figure on the left half of the screen
screen_size = get(0, 'ScreenSize');    %To obtain the screen resolution
set(figure('name','Time Series Performance of Training Time Series'), 'Position', [0 0 screen_size(3)/2 screen_size(4)] );    % Make use of screen width and height

% To plot training expected and predicted time series
plot(training_expectedOutput(1:trainingSamples-numOfInputs),'r-')
hold on;
plot(training_actualOutput(1:trainingSamples-numOfInputs),'b')

xlim([0 trainingSamples]);
xlabel('Time (Hours)','FontWeight','bold','FontSize',16,...
    'FontName','Verdana');
ylabel('Wind Speed Forecast (Knots)','FontWeight','bold','FontSize',16,...
    'FontName','Verdana');
title('Time Series Performance of Training Time Series','FontWeight','bold',...
    'FontSize',18,...
    'FontName','Verdana');
legend('Expected', 'Predicted');

% Calculate and display training performance paramters
trainingRMS = sqrt((sum(trainingError.^2))/trainingSamples)
trainingMAE = mae(trainingError,training_actualOutput)
trainingMAPE = (sum(trainingError./training_actualOutput))/trainingSamples

% Declaration of matrices to calculate testing forecast errors
testing_actualOutput = zeros(testingSamples-numOfInputs,1);
testing_expectedOutput = zeros(testingSamples-numOfInputs,1);
testingError = zeros(testingSamples-numOfInputs,1);

for k = 1:testingSamples-numOfInputs 
testing_actualOutput(k,1) = sim(net,netData(k+testingPoint,1:numOfInputs)');    % Use network to predict testing data
testing_expectedOutput(k,1) = netData(k+testingPoint,numOfInputs+1);            % Expected outputs for comparison

% Denormalization of expected and predicted values
testing_actualOutput(k,1) = (testing_actualOutput(k,1)*std(dailyData))+mean(data);
testing_expectedOutput(k,1) = (testing_expectedOutput(k,1)*std(dailyData))+mean(data);

testingError(k,1) = abs(testing_actualOutput(k,1) - testing_expectedOutput(k,1));
end

% To display figure on the right half of the screen
screen_size = get(0, 'ScreenSize');    %To obtain the screen resolution
set(figure('name','Time Series Performance of Training Time Series'), 'Position', [screen_size(3)/2 0 screen_size(3)/2 screen_size(4)] );  % Make use of screen width and height
                               
% To plot training expected and predicted time series
plot(testing_expectedOutput(1:testingSamples-numOfInputs),'r-')
hold on;
plot(testing_actualOutput(1:testingSamples-numOfInputs),'b')

xlim([0 testingSamples]);
xlabel('Time (Hours)','FontWeight','bold','FontSize',16,...
    'FontName','Verdana');
ylabel('Wind Speed Forecast (Knots)','FontWeight','bold','FontSize',16,...
    'FontName','Verdana');
title('Time Series Performance of Testing Time Series','FontWeight','bold',...
    'FontSize',18,...
    'FontName','Verdana');
legend('Expected', 'Predicted');

% Calculate and display training performance paramters
testingRMS = sqrt((sum(testingError.^2))/testingSamples)
testingMAE = mae(testingError,testing_actualOutput)
testingMAPE = (sum(testingError./testing_actualOutput))/testingSamples