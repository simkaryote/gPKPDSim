function javaColor = getJavaColor( color )
%getRGBTriplet Returns Java color
%
% Usage: javaColor = getJavaColor( color )
%
% Inputs
% color: Either a string with the color or a triplet with the RGB values
%
% Output
%   javaColor: java.awt.Color object

argClass = class(color);
switch argClass
    case 'char'
        switch lower(color)
            case 'yellow'
                rgbTriplet = [1,1,0];
            case 'magenta'
                rgbTriplet = [1,0,1];
            case 'cyan'
                rgbTriplet = [0,1,1];
            case 'red'
                rgbTriplet = [1,0,0];
            case 'green'
                rgbTriplet = [0,1,0];
            case 'blue'
                rgbTriplet = [0,0,1];
            case 'white'
                rgbTriplet = [1,1,1];
            case 'black'
                rgbTriplet = [0,0,0];
            otherwise
                error('getRGBTriplet:NotImpl', 'Color %s not implemented', ...
            color)
        end
    case 'double'
        if size(color(:),1)~=3 || min(color)<0 || max(color)>1
            error('getRGBTriplet:BadArg', ...
                'color must be a vector of 3 elements with entries between 0 and 1')
        end
        rgbTriplet = color;
    otherwise
        error('getRGBTriplet:NotImpl', 'Argument type %s not implemented', ...
            argClass)
end
javaColor = java.awt.Color(rgbTriplet(1),rgbTriplet(2),rgbTriplet(3));
end %getRGBTriplet