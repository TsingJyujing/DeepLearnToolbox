function net = scnnff(net, x)
%% DOCUMENT
%{
type of x: cell_array<sparse<double>(x,y)>(n)
%}
n = numel(net.layers);
net.layers{1}.a{1} = x;
inputmaps = 1;

for l = 2 : n   %  for each layer
    if strcmp(net.layers{l}.type, 'c')
        %  !!below can probably be handled by insane matrix operations
        for j = 1 : net.layers{l}.outputmaps   %  for each output map
            %  create temp output map
            z = sptzeros(sptsize(net.layers{l - 1}.a{1}) - [net.layers{l}.kernelsize - 1 net.layers{l}.kernelsize - 1 0]);
            temp_matrix = cell(1,inputmaps);
            for i = 1 : inputmaps   %  for each input map
                %  convolve with corresponding kernel and add to temp output map
                temp_matrix{i} = spconvn(net.layers{l - 1}.a{i}, net.layers{l}.k{i}{j}, 'valid');
            end
            for i = 1 : inputmaps 
                z = spcell_add(z,temp_matrix{i});
            end
            %  add bias, pass through nonlinearity
            net.layers{l}.a{j} = spcell_sigm(spcell_add(z,net.layers{l}.b{j}));
        end
        %  set number of input maps to this layers number of outputmaps
        inputmaps = net.layers{l}.outputmaps;
    elseif strcmp(net.layers{l}.type, 's')
        %  downsample
        for j = 1 : inputmaps
            z = spconvn(net.layers{l - 1}.a{j}, ones(net.layers{l}.scale) / (net.layers{l}.scale ^ 2), 'valid');   %  !! replace with variable
            net.layers{l}.a{j} = sptsubsample(z,net.layers{l}.scale);
        end
    end
end

%  concatenate all end layer feature maps into vector
net.fv = [];
for j = 1 : numel(net.layers{n}.a)
    % sa = sptsize(net.layers{n}.a{j});
    net.fv = [net.fv; sptflatten(net.layers{n}.a{j})];
end
%  feedforward into output perceptrons
net.o = sigm(net.ffW * net.fv + repmat(net.ffb, 1, size(net.fv, 2)));
end
