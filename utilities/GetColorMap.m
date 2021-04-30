function C = GetColorMap(DefaultColorMap,m)

validateattributes(DefaultColorMap,{'numeric'},{'size',[nan 3]});
validateattributes(m,{'numeric'},{'scalar','integer','positive'});

if m/size(DefaultColorMap,1) > 1
    DefaultColorMap = repmat(DefaultColorMap,ceil(m/size(DefaultColorMap,1)),1);
end
C = DefaultColorMap(1:m,:);