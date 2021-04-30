function C = GetLineStyleMap(DefaultLineStyleMap,m)

validateattributes(DefaultLineStyleMap,{'cell'},{});
validateattributes(m,{'numeric'},{'scalar','integer','positive'});

DefaultLineStyleMap = DefaultLineStyleMap(:);
if m/numel(DefaultLineStyleMap) > 1
    DefaultLineStyleMap = repmat(DefaultLineStyleMap,ceil(m/numel(DefaultLineStyleMap)),1);
end
C = DefaultLineStyleMap(1:m,:);