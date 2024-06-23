function [C,timingfile,userdefined_trialholder] = preDisambiguationUserloop(MLConfig,TrialRecord)

% default return value
C = [];
timingfile = 'disambiguationProtocolTiming.m';
userdefined_trialholder = '';

% Load the image stimuli and return timing file if it the very first call
persistent timing_filename_returned
persistent imageList
persistent conTable
persistent stim2img
persistent conList                  % List of conditions left to display in a block
persistent conPrev                  % Condition displayed in the prev trial
if isempty(timing_filename_returned)
    imageDir = dir(fullfile('Images', 'ambiguous'));                % get the folder content of "Images/ambiguous"
    filename = {imageDir.name};                                     % get the filenames in "Images/ambiguous"
    imageList = filename(contains(filename, '.tif'));               % select only tif files (the list is not sorted by the image number order)
    conTable = table('Size', [length(imageList), 7], 'VariableNames', ["condition", "img1", "img2", "img3", "stim1", "stim2", "stim3"], ...
        'VariableTypes', ["double", "string", "string", "string", "double", "double", "double"]);
    stim2img = table('Size', [length(imageList)*3, 2], 'VariableNames', ["stim", "img"], ...
        'VariableTypes', ["double", "string"]);
    for i = 1:length(imageList)
        img1 = "A"+num2str(i);
        if mod(i,2)==0
            img2 = "A"+num2str(i-1);
        else
            img2 = "A"+num2str(i+1);
        end
        img3 = img1;
        s1 = 3*(i-1)+1;
        s2 = 3*(i-1)+2;
        s3 = 3*(i-1)+3;

        conTable{i,:} = [i, img1, img2, img3, s1, s2, s3];
        stim2img{3*(i-1)+1, :} = [3*(i-1)+1, img1];
        stim2img{3*(i-1)+2, :} = [3*(i-1)+2, img2];
        stim2img{3*(i-1)+3, :} = [3*(i-1)+3, img3];
    end
    timing_filename_returned = true;
    return
end

% get current block and current condition
block = TrialRecord.CurrentBlock;
condition = TrialRecord.CurrentCondition;

if isempty(TrialRecord.TrialErrors)                                         % If its the first trial
    condition = 1;                                                          % set the condition # to 1
elseif ~isempty(TrialRecord.TrialErrors) && 0==TrialRecord.TrialErrors(end) % If the last trial is a success
    conList = setdiff(conList, conPrev);                                    % remove previous trial condition from the list of conditions
    condition = mod(condition, length(imageList))+1;                        % increment the condition #
end

% Initialize the conditions for a new block
if isempty(conList)                                                         % If there are no stimuli left in the block
    conList = 1:length(imageList);
    block=block+1;
end

conCurrent = datasample(conList, 1, 'Replace',false);                       % randomly sample a stimuli from the list
conPrev = conCurrent;

% Set the stimuli
stim1 = fullfile('Images', 'ambiguous', conTable.img1(conCurrent)+".tif");
stim2 = fullfile('Images', 'ambiguous', conTable.img2(conCurrent)+".tif");
stim3 = fullfile('Images', 'ambiguous', conTable.img3(conCurrent)+".tif");

C = {sprintf('pic(%s,0,0)',stim1), ...
    sprintf('pic(%s,0,0)',stim2), ...
    sprintf('pic(%s,0,0)',stim3)};

stimCurrent = [conTable.stim1(conCurrent), conTable.stim2(conCurrent), conTable.stim3(conCurrent)];
TrialRecord.User.Stimuli = stimCurrent;                     % save the stimuli for the next trial in user variable
TrialRecord.User.Condition = conCurrent;                    % save the condition for the next trial in user variable
TrialRecord.User.conTable = conTable;
TrialRecord.User.stim2img = stim2img;
% Set the block number and the condition number of the next trial
TrialRecord.NextBlock = block;
TrialRecord.NextCondition = condition;