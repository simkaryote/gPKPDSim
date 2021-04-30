function Flag = isCursorOverObj(hFigure,hObj)
% Interrogate whether the mouse cursor is over the object specified

% Default
Flag = false;

% Get the pointer location on the screen
OldUnits = get(0,'Units');
set(0,'Units','pixels');
PPos = get(0,'PointerLocation');
set(0,'Units',OldUnits);

% Get the figure position
FPos = getpixelposition(hFigure);

% Calculate the pointer position within the viewer
PVPos = [(PPos(1)-FPos(1)) (PPos(2)-FPos(2))];

% Check each component
for oIdx = 1:numel(hObj)
    
    % Get the axes position within the figure
    if isprop(hObj(oIdx),'Position')
        Pos = hObj(oIdx).Position;
        
        % See if the pointer is inside
        if (PVPos(1) > Pos(1)) && (PVPos(1) < Pos(1)+Pos(3)) &&...
                (PVPos(2) > Pos(2)) && (PVPos(2) < Pos(2)+Pos(4))
            % It is inside - return the result
            Flag = true;
        end
    end
    
end %for oIdx = 1:numel(hObj)



