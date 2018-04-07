function loop_closing()

global Map
global State
global Params
global Debug

i = Map.covisibilityGraph.NumViews;
features1 = Map.covisibilityGraph.Descriptors{i};
points1 = Map.covisibilityGraph.Points{i};
if i > Params.numFramesApart
    % Candidates detection
    d2 = hist_diff(Map.bow(1:(i - Params.numFramesApart), :), Map.bow(i, :));
    [~, j] = min(d2);
    
    features2 = Map.covisibilityGraph.Descriptors{j};
    points2 = Map.covisibilityGraph.Points{j};
    
    matchedIdx = matchFeatures(features1, features2, 'unique', true);

    ni = length(features1);
    nj = length(features2);
    matchRatio = numel(matchedIdx) / (ni + nj);
    
    if matchRatio > Params.minMatchRatioRatio
        try
            matchedPoints1 = points1(matchedIdx(:, 1));
            matchedPoints2 = points2(matchedIdx(:, 2));
            
            [orient, loc, inlierIdx, ~] = estimate_relative_motion(...
                matchedPoints1, matchedPoints2, Params.cameraParams);

            Map.covisibilityGraph = addConnection(Map.covisibilityGraph, ...
                i, j, 'Matches', matchedIdx(inlierIdx, :));
            
            ne = size(Map.covisibilityGraph.Connections, 1);
            Map.vOdom.rot{ne} = orient;
            Map.vOdom.trans{ne} = loc;
            
            fprintf('[!] Found a loop closure between %d and %d.\n', i, j);
        catch
            fprintf('[!] Loop closure proposal (%d, %d) rejected.\n', i, j);
        end
    end

end

% Compute Sim3
% Loop fusion
% Optimize essential graph

end

%%
function d2 = hist_diff(h1, h2)
d2 = sum((h1 - h2).^2 ./ (h1 + h2 + 1e-6), 2);
end