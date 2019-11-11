classdef var_rec < handle
% ���Ƽ��㷽��

    properties (GetAccess = public, SetAccess = private)
        buff %����
        k    %�����С
        n    %����ָ��
        E    %��ֵ
        D    %����
    end
    
    methods
        function obj = var_rec(k)
            obj.buff = zeros(1,k);
            obj.k = k;
            obj.n = 1; %��1��ʼ
            obj.E = 0;
            obj.D = 0;
        end
        
        function init(obj, k)
            obj.buff = zeros(1,k);
            obj.k = k;
            obj.n = 1;
            obj.E = 0;
            obj.D = 0;
        end
        
        function update(obj, x1)
            x0 = obj.buff(obj.n);
            E0 = obj.E;
            E1 = E0 + (x1-x0)/obj.k;
            obj.D = obj.D + ((x1-E1)^2 - (x0-E0)^2 - 2*(E1-E0)*(E0*obj.k-x0) + (obj.k-1)*(E1^2-E0^2))/obj.k;
            obj.E = E1;
            obj.buff(obj.n) = x1;
            obj.n = mod(obj.n,obj.k) + 1;
        end
        
    end

end