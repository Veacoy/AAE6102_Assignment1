function vel = wlsVel(satpos,obs,settings,satvel,doppler,satClkdt)

%=== Initialization =======================================================
nmbOfIterations = 10;

dtr     = pi/180;
vel     = zeros(4, 1);   % center of earth
pos     = zeros(4, 1);   % center of earth
X       = satpos;
nmbOfSatellites = size(satpos, 2);

A       = zeros(nmbOfSatellites, 4);
omc     = zeros(nmbOfSatellites, 1);
weight = ones(nmbOfSatellites, 1);
az      = zeros(1, nmbOfSatellites);
el      = az;

%=== Iteratively find receiver position ===================================
for iter = 1:nmbOfIterations

    for i = 1:nmbOfSatellites
        if iter == 1
            %--- Initialize variables at the first iteration --------------
            Rot_X = X(:, i);
            trop = 2; 
        else
            %--- Update equations -----------------------------------------
            rho2 = (X(1, i) - pos(1))^2 + (X(2, i) - pos(2))^2 + ...
                   (X(3, i) - pos(3))^2;
            traveltime = sqrt(rho2) / settings.c ;

            %--- Correct satellite position (do to earth rotation) --------
            % Convert SV position at signal transmitting time to position 
            % at signal receiving time. ECEF always changes with time as 
            % earth rotates.
            Rot_X = e_r_corr(traveltime, X(:, i));
            
            %--- Find the elevation angel of the satellite ----------------
            [az(i), el(i), ~] = topocent(pos(1:3, :), Rot_X - pos(1:3, :));

            if (settings.useTropCorr == 1)
                %--- Calculate tropospheric correction --------------------
                trop = tropo(sin(el(i) * dtr), ...
                             0.0, 1013.0, 293.0, 50.0, 0.0, 0.0, 0.0);
            else
                % Do not calculate or apply the tropospheric corrections
                trop = 0;
            end
            weight(i)=sin(el(i))^2;
        end % if iter == 1 ... ... else 

        %--- Apply the corrections ----------------------------------------
        omc(i) = ( obs(i) - norm(Rot_X - pos(1:3), 'fro') - pos(4) - trop ); 

        %--- Construct the A matrix ---------------------------------------
        A(i, :) =  [ (-(Rot_X(1) - pos(1))) / norm(Rot_X - pos(1:3), 'fro') ...
                     (-(Rot_X(2) - pos(2))) / norm(Rot_X - pos(1:3), 'fro') ...
                     (-(Rot_X(3) - pos(3))) / norm(Rot_X - pos(1:3), 'fro') ...
                     1 ];

        
    end % for i = 1:nmbOfSatellites


    %--- Find position update (in the least squares sense)-----------------
    %x   = A \ omc;

    %--- Find position update (for the weighted least square)
    W=diag(weight);
    C=W'*W;
    x=(A'*C*A)\(A'*C*omc);

    %--- Apply position update --------------------------------------------
    pos = pos + x;

end % for iter = 1:nmbOfIterations



ddd = zeros(nmbOfSatellites,1);
for i = 1:nmbOfSatellites
    ddd(i) = -doppler(i)*3e8/1575.42e6 - satvel(:,i)'*(A(i,1:3))' + 3e8*satClkdt(i);
end

vel = (A'*C*A)\(A'*C*ddd);



end