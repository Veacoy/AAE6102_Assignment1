function dopplers = calculateDopplers(trackResults,currMeasSample,channelList,settings)

dopplers = zeros(1,length(channelList));
for channelNr = 1:length(channelList)
    for index = 1: length(trackResults(channelNr).absoluteSample)
        if(trackResults(channelNr).absoluteSample(index) > currMeasSample )
            break
        end 
    end
    index = index - 1;

    dopplers(channelNr) = trackResults(channelNr).carrFreq(index) - settings.IF;
end
end