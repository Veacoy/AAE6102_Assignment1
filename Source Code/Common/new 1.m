function [pos,el, az, dop] = leastSquarePos(satpos,obs, Amp)
%Function calculates the Least Square Solution.
%
%[pos, el, az, dop] = leastSquarePos(satpos, obs, settings);
%
%   Inputs:
%       satpos      - Satellites positions (in ECEF system: [X; Y; Z;] -
%                   one column per satellite)
%       obs         - Observations - the pseudorange measurements to each
%                   satellite corrected by SV clock error
%                   (e.g. [20000000 21000000 .... .... .... .... ....]) 
%       Amp    - Amplitude vector of correlation output
%
%   Outputs:
%       pos         - receiver position and receiver clock error 
%                   (in ECEF system: [X, Y, Z, dt]) 
%       el          - Satellites elevation angles (degrees)
%       az          - Satellites azimuth angles (degrees)
%       dop         - Dilutions Of Precision ([GDOP PDOP HDOP VDOP TDOP])

%==========================================================================

%=== Initialization =======================================================
nmbOfIterations = 10;

dtr     = pi/180;
pos     = zeros(4, 1);   % center of earth
X       = satpos;
nmbOfSatellites = size(satpos, 2);

A       = zeros(nmbOfSatellites, 4);
omc     = zeros(nmbOfSatellites, 1);
az      = zeros(1, nmbOfSatellites);
el      = az;

%=== Iteratively find receiver position ===================================
for iter = 1:nmbOfIterations

    for i = 1:nmbOfSatellites
        if iter == 1
            %--- Initialize variables at the first iteration --------------
            Rot_X = X(:, i);
            %trop = 2;
        else
            %--- Update equations -----------------------------------------
           % rho2 = (X(1, i) - pos(1))^2 + (X(2, i) - pos(2))^2 + ...
            %       (X(3, i) - pos(3))^2;
            %traveltime = sqrt(rho2) / settings.c ;

            %--- Correct satellite position (do to earth rotation) --------
            % Convert SV position at signal transmitting time to position 
            % at signal receiving time. ECEF always changes with time as 
            % earth rotates.
            Rot_X = X(:, i);%e_r_corr(traveltime, X(:, i));
            
            %--- Find the elevation angel of the satellite ----------------
            [az(i), el(i), ~] = topocent(pos(1:3, :), Rot_X - pos(1:3, :));

        end % if iter == 1 ... ... else 

        %--- Apply the corrections ----------------------------------------
        omc(i) = obs(i)*c*T_chip/Amp(i); 

        %--- Construct the A matrix ---------------------------------------
        A(i, :) =  [ (-(Rot_X(1) - pos(1))) / norm(Rot_X - pos(1:3), 'fro') ...
                     (-(Rot_X(2) - pos(2))) / norm(Rot_X - pos(1:3), 'fro') ...
                     (-(Rot_X(3) - pos(3))) / norm(Rot_X - pos(1:3), 'fro') ...
                     1 ];
    end % for i = 1:nmbOfSatellites

    % These lines allow the code to exit gracefully in case of any errors
    if rank(A) ~= 4
        pos     = zeros(1, 4);
        dop     = inf(1, 5);
        fprintf('Cannot get a converged solotion! \n');
        return
    end

    %--- Find position update (in the least squares sense)-----------------
    x   = A \ omc;
    
    %--- Apply position update --------------------------------------------
    pos = pos + x;
    
end % for iter = 1:nmbOfIterations

%--- Fixing result -------------------------------------------------------
pos = pos';

%=== Calculate Dilution Of Precision ======================================
if nargout  == 4
    %--- Initialize output ------------------------------------------------
    dop     = zeros(1, 5);
    
    %--- Calculate DOP ----------------------------------------------------
    Q       = inv(A'*A);
    
    dop(1)  = sqrt(trace(Q));                       % GDOP    
    dop(2)  = sqrt(Q(1,1) + Q(2,2) + Q(3,3));       % PDOP
    dop(3)  = sqrt(Q(1,1) + Q(2,2));                % HDOP
    dop(4)  = sqrt(Q(3,3));                         % VDOP
    dop(5)  = sqrt(Q(4,4));                         % TDOP
end  % if nargout  == 4
