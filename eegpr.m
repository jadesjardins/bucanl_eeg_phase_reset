function EEG=eegpr(EEG,dattype,datind,evttype,varargin)
% Data is a [Channels x Samples] matrix containing the recording
% seg is a [2 x Num Segments] matrix of values. The vector seg(1,:)
% indicates the starting point of each segment and seg(2,:) the end point
% Ch1 and Ch2 are the channels to be compared

% The output consists of a cout of the number of phase resets, as well as
% the start and end times as well as the segment it is in

%handle optional inputs...
g=struct(varargin{:});

try g.lockthresh;       catch, g.lockthresh      = 0.1;           end; 
try g.fqcenter;         catch, g.fqcenter        = 11;            end;
try g.wintype;          catch, g.wintype         = 'hamming';     end;
try g.k;                catch, g.k               = 1.5;           end;
try g.filttype;         catch, g.filttype        = 'butter';      end;


%create seg vector from "evttype" eventlatencies...
if length(evttype)==1;
    boundevtinds=strmatch(evttype,{EEG.event.type},'exact');
    nboundevts=length(boundevtinds);
    for i=1:nboundevts+1;
        if i==1;
            seg(1,i)=1;
            seg(2,i)=EEG.event(boundevtinds(i)).latency-1;
            if seg(2,i) < 0; seg(2,i)=1;end; 
        elseif i==nboundevts+1;
            seg(1,i)=EEG.event(boundevtinds(i-1)).latency+1;
            seg(2,i)=EEG.pnts;
        else
            seg(1,i)=EEG.event(boundevtinds(i-1)).latency-1;
            if seg(1,i) < 0; seg(1,i)=1;end; 
            seg(2,i)=EEG.event(boundevtinds(i)).latency-1;
        end
    end
end

if length(evttype)==2;
    strt_boundevtinds=strmatch(evttype{1},{EEG.event.type},'exact');
    stop_boundevtinds=strmatch(evttype{2},{EEG.event.type},'exact');
    nboundevts=length(strt_boundevtinds);
    for i=1:nboundevts;
        seg(1,i)=EEG.event(strt_boundevtinds(i)).latency-1;
        seg(2,i)=EEG.event(stop_boundevtinds(i)).latency-1;
    end
end
                
% The number of segments in the data
NumSeg = size(seg,2);

%Initialize the output 
shift=zeros(1,3);
lock=zeros(1,3);
count=0;

% the threshold which defines periods of phase locking
% value changes depending on situation and needs more attention
%c=0.1; %now g.lockthresh

% centre of frequency band of interest
%w=11; %now g.fqcenter

% filter parameters...
%k=1.5; now g.k ... I do not know how to name this parameter...


datind=str2num(datind);

for segi=1:size(seg,2)

    % Only calculate resets on segments that are at least one second long,
    % avoid truncation effects
      if seg(2,segi)-seg(1,segi) > EEG.srate
        
        %X1 - Channel1, X2 - Channel2
        if dattype==1;
            X1=EEG.data(datind(1),round(seg(1,segi)):round(seg(2,segi)));
            X2=EEG.data(datind(2),round(seg(1,segi)):round(seg(2,segi)));
        else
            X1=EEG.icaact(datind(1),round(seg(1,segi)):round(seg(2,segi)));
            X2=EEG.icaact(datind(2),round(seg(1,segi)):round(seg(2,segi)));
        end        
        %X1=Data(Ch1,seg(1,ind):seg(2,ind));
        %X2=Data(Ch2,seg(1,ind):seg(2,ind));
        
        % Sampling rate
        T=EEG.srate;
        
        % index of sample
        t=1:length(X1);

        % windowing function
        eval(['window_var = ', g.wintype, '(length(X1));']);
        %window=ones(length(X1),1);

        %Y - windowed sine and cosine components of X1, with frequency w shifted towards 0
        %Z - windowed sine and cosine components of X2, with frequency w
        %shifted towards 0
        
        Y1=window_var'.*X1.*sin(2*pi*g.fqcenter/T*t);
        Y2=window_var'.*X1.*cos(2*pi*g.fqcenter/T*t);
        Z1=window_var'.*X2.*sin(2*pi*g.fqcenter/T*t);
        Z2=window_var'.*X2.*cos(2*pi*g.fqcenter/T*t);
        break
        % [b,a] are vectors which define a lowpass butter filter, 6th order
        % The second parameter is a percentage of the nyqvist frequency it defines
        % the cutoff point
        % Filter k Hz, x*(T/2)=k, x=2*k/T
%        k=1.5;
%        [b,a]=butter(4,2*k/T,'low');

        eval(['[b,a]=',g.filttype,'(4,2*k/T,''low'');']);
        
        % F is lowpass filter on Y to remove frequencies away from w
        % G is lowpass filter on Z to remove frequencies away from w
        F1=filtfilt(b,a,double(Y1));
        F2=filtfilt(b,a,double(Y2));
        G1=filtfilt(b,a,double(Z1));
        G2=filtfilt(b,a,double(Z2));

        % The power in the remaining signal is that from the band (w-k,
        % w+k) from the original signals
        
        % Calculate magnitude (M1) and Phase (P1) of X1
        M1=2*sqrt(F1.^2+F2.^2);
        P=atan(F2./F1);
        LP=length(P);
        for i=1:LP-1
            if P(i)-P(i+1) > pi/2
                P((i+1):LP)=P((i+1):LP)+pi;
            end
            if P(i)-P(i+1) < -pi/2
                P((i+1):LP)=P((i+1):LP)-pi;
            end
        end
        P1=P;
        
        % Calculate magnitude (M2) and Phase (P2) of X2
        M2=2*sqrt(G1.^2+G2.^2);
        P=atan(G1./G2);
        LP=length(P);
        for i=1:(LP-1)
            if P(i)-P(i+1) > pi/2
                P((i+1):LP)=P((i+1):LP)+pi;
            end
            if P(i)-P(i+1) < -pi/2
                P((i+1):LP)=P((i+1):LP)-pi;
            end
        end
        P2=P;
        
        % Phase difference
        d=P1-P2;

        % Numerical estimate of first derivative d1
        N=length(d);
        d1=zeros(1,N-2);
        for i=2:(N-1)
            d1(i-1)=(d(i+1)-d(i-1))/2;
        end
        
        % Absolute value of first derivative
        d11=abs(d1);

        % t0 is the start of the first reset (beginning with a phase lock)
        t0=length(d1);
        for i=1:length(d1)
            if d11(i) < g.lockthresh
                t0=i;
                break
            end
        end
        
        % count1 count the transition from phase lock to phase shift
        % t1 marks the time of the transition
        
        % count2 counts the transitions from phase shift to phase lock
        % t2 mark the time of the transition
        
        count1=0;
        count2=0;
        for i=t0:length(d1)-1
            if d11(i) <g.lockthresh&& d11(i+1) > g.lockthresh
                count1=count1+1;
                t1(count1)=i;
            end
            if d11(i) > g.lockthresh && d11(i+1) < g.lockthresh
                count2=count2+1;
                t2(count2)=i;
            end
        end


        % count and record the complete phase resets
        for i=1:count1-1
            count=count+1;
            shift(count,1)=i;
            shift(count,2)=t1(i);
            shift(count,3)=t2(i);
            lock(count,1)=i;
            lock(count,2)=t2(i);
            lock(count,3)=t1(i+1);
        end

        
        % Some plots shows for each segment, pauses until keypress 
        % used to help determine what g.lockthreshshould be
        %{
        figure
        subplot(2,1,1)
        hold on
        plot(t,X1,'b')
        plot(t,X2,'r')
        title('Two Signals')
        subplot(2,1,2)
        hold on
        plot(t,P1,'b')
        plot(t,P2,'r')
        title('Two Phase plots')
        
        figure
        subplot(2,1,1)
        plot(t,d)
        title('Phase Difference')
        subplot(2,1,2)
        plot(t(2:N-1),d11)
        hold on
        plot(t(2:N-1),c*ones(1,N-2), '--r')
        title('Absolute first derivative')
        pause();
        %}
      end
end
EEG.prout.count=count;
EEG.prout.shift=shift;
EEG.prout.lock=lock;

