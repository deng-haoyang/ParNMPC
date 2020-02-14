function setT(OCP,T)
    % assert
%     if isa(T,'numeric')
%         if T<0
%             error('T must be a positive number or parameter!');
%         end
%     else
%         if has(T,OCP.u) || has(T,OCP.x)
%             error('T cannot be an input or state!');
%         end
%     end

    OCP.T = T;
    OCP.deltaTau = OCP.T/OCP.N;
end