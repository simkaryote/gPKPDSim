
newUnitTable = [
    "fold", "dimensionless";
    "normalized", "dimensionless";
    "fraction", "dimensionless";
    "nM", "nanomole / litre";
    "cell", "dimensionless"];

for i = 1:size(newUnitTable, 1)
    newUnitName = newUnitTable(i, 1);
    newUnitComposition = newUnitTable(i, 2);
    
    % if new unit name does not exist
    if isempty(sbioselect(sbioroot, 'Name', newUnitName))
        unitObj = sbiounit(newUnitName, newUnitComposition);
        sbioaddtolibrary(unitObj);
    end
end
