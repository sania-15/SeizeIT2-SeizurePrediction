function layer = flattenLayer(varargin)
% flattenLayer creates a custom layer that flattens the input
% from [H x W x C x B] to [C*H*W x B]

layer = functionLayer(@(X) flatten(X), ...
    'Name','flatten', ...
    'Formattable', true);
end

function Y = flatten(X)
% Reshape input to [features x batch]
Y = reshape(X, [], size(X,4));
end
