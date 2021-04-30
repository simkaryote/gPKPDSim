function updateLeftLayoutSizes(app)

% Get max height (should be about the same)
CardLayoutHeight = max([...
    app.h.SimulationPanel.Height,...
    app.h.FittingPanel.Height,...
    app.h.PopulationPanel.Height]);
CardLayoutHeight = CardLayoutHeight + 65; % Radio button group

% Adjust sizes - NOTE: size of the card panel will change based on the
% number of parameters - this is fixed
if app.h.TopLeftBoxPanel.Minimized
    set(get(app.h.VTopLeftLayout,'Children'),'Visible','off')
    app.h.VTopLeftLayout.Heights = zeros(1,6);
    Buffer = 20;
    app.h.VLeftLayout.Heights = [sum(app.h.VTopLeftLayout.Heights)+Buffer CardLayoutHeight];
else
    set(get(app.h.VTopLeftLayout,'Children'),'Visible','on')
    app.h.VTopLeftLayout.Heights = [25 25 25 65 120 120];
    Buffer = 20 + numel(app.h.VTopLeftLayout.Children)*app.h.VTopLeftLayout.Spacing + app.h.VTopLeftLayout.Padding*2;
    app.h.VLeftLayout.Heights = [sum(app.h.VTopLeftLayout.Heights)+Buffer CardLayoutHeight];
end
    
% Update heights
Buffer = 100;
Pos = get(app.h.LeftSlider,'Position');
Pos(4) = sum(app.h.VLeftLayout.Heights) + Buffer;
set(app.h.LeftSlider,'Position',Pos);
Pos = get(app.h.LeftPanel,'Position');
Pos(4) = sum(app.h.VLeftLayout.Heights) + Buffer;
set(app.h.LeftPanel,'Position',Pos);