newUnitName =  'fold' ;
newUnitComposition = 'dimensionless' ;
 
% if new unit name does not exist
if isempty(sbioselect(sbioroot, 'Name', newUnitName))
   
% Create units for the rate constants of a first-order and a second-order reaction.
    unitObj1 = sbiounit(newUnitName, newUnitComposition);
   
% add unit to library
    sbioaddtolibrary(unitObj1);
  
end

newUnitName =  'normalized' ;
newUnitComposition = 'dimensionless' ;
 
% if new unit name does not exist
if isempty(sbioselect(sbioroot, 'Name', newUnitName))
   
% Create units for the rate constants of a first-order and a second-order reaction.
    unitObj1 = sbiounit(newUnitName, newUnitComposition);
   
% add unit to library
    sbioaddtolibrary(unitObj1);
  
end

newUnitName =  'fraction' ;
newUnitComposition = 'dimensionless' ;
 
% if new unit name does not exist
if isempty(sbioselect(sbioroot, 'Name', newUnitName))
   
% Create units for the rate constants of a first-order and a second-order reaction.
    unitObj1 = sbiounit(newUnitName, newUnitComposition);
   
% add unit to library
    sbioaddtolibrary(unitObj1);
  
end

newUnitName =  'nM' ;
newUnitComposition = 'nanomole / litre';
 
% if new unit name does not exist
if isempty(sbioselect(sbioroot, 'Name', newUnitName))
   
% Create units for the rate constants of a first-order and a second-order reaction.
    unitObj1 = sbiounit(newUnitName, newUnitComposition);
   
% add unit to library
    sbioaddtolibrary(unitObj1);
end