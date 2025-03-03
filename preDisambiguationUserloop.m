function [C,timingfile,userdefined_trialholder] = preDisambiguationUserloop(MLConfig,TrialRecord)

% default return value
C = [];
timingfile = 'disambiguationProtocolTiming.m';
userdefined_trialholder = '';

% Load the image stimuli and return timing file if it the very first call
persistent timing_filename_returned
persistent imageList
persistent conTable
persistent conList                  % List of conditions left to display in a block
persistent conPrev                  % List of stimuli of the current block displayed in the prev trial
if isempty(timing_filename_returned)
    imageDir = dir('Images');                                       % get the folder content of "Images/"
    filename = {imageDir.name};                                     % get the filenames in "Images/"
    imageList = filename(contains(filename, '.tif'));               % select only tif files (the list is not sorted by the image number order)
    conTable = table('Size', [length(imageList), 6], 'VariableNames', ["img1", "img2", "img3", "stim1", "stim2", "stim3"], ...
        'VariableTypes', ["string", "string", "string", "double", "double", "double"]);
    for i = 1:length(imageList)
        img1 = "A"+num2str(i);
        stim1 = i;
        if mod(i,2)==0
            img2 = "A"+num2str(i-1);
            stim2 = i-1;
        else
            img2 = "A"+num2str(i+1);
            stim2 = i+1;
        end
        img3 = img1;
        stim3 = stim1;

        conTable{i,:} = [img1, img2, img3, stim1, stim2, stim3];
    end
    % imageNum = cellfun(@(x) sscanf(x, 'Image%d.tif'), imageList);   % get the image number
    % [imageNum, idxOrder] = sort(imageNum);                          % sort the image number list
    % imageList = imageList(idxOrder);                                % sort the image list
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

conCurrent = datasample(conList, 1, 'Replace',false);                     % randomly sample a stimuli from the list
conPrev = conCurrent;

% Set the stimuli
stim1 = fullfile('Images', 'ambiguous', [conTable.img1(conCurrent), '.tif']);
stim2 = fullfile('Images', 'ambiguous', [conTable.img2(conCurrent), '.tif']);
stim3 = fullfile('Images', 'ambiguous', [conTable.img3(conCurrent), '.tif']);

C = {sprintf('pic(%s,0,0)',stim1), ...
    sprintf('pic(%s,0,0)',stim2), ...
    sprintf('pic(%s,0,0)',stim3)};

stimCurrent = [conTable.stim1(conCurrent), conTable.stim2(conCurrent), conTable.stim3(conCurrent)];
TrialRecord.User.Stimuli = stimCurrent;                     % save the stimuli for the next trial in user variable
TrialRecord.User.Condition = conCurrent;                    % save the condition for the next trial in user variable
% Set the block number and the condition number of the next trial
TrialRecord.NextBlock = block;
TrialRecord.NextCondition = condition;