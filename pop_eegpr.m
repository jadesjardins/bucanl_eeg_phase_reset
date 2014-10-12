% pop_eegpr() - collects inputs for eegpr which calculates phase reset on
%                pruned continuous EEG data.
%
% Usage:
%   >>  com= pop_eegpr(EEG, dattype, datind, varargin);
%
% Inputs:
%   EEG         - input EEG structure
%   dattype     - data type, 1= scalp signal, 2 = IC signal
%   datind      - index of signals to use [ind1,ind2]
%   evttype     - label of event type to use as boundary marker. If this
%   input is a cell array 
%   optstr      - string containing pop_eegpr key/val pairs for
%               varargin. See Options.with a length of 1 the specified even
%               is interpreted a marker of a cut in the data. If the length
%               of the cell array is 2 the phase reset calculations are
%               performed on the periods in the data that begin at
%               evttype{1} and end at evttype{2}.
%
% Options:

% Outputs:
%   com         - pop_eegpr command string
%
% See also:
%   eegpr

% Copyright (C) <2010>  <James Desjardins>
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function [EEG com] = pop_eegpr(EEG, dattype, datind, evttype)

%g = struct(varargin{:});

%if ~isempty(g)
%    optstr='';
%    try g.nfids;        catch, g.nfids      = 3;       end;
%    optstr=['''nfids'', ', num2str(g.nfids)];
%end

% the command output is a hidden output that does not have to
% be described in the header
com = ''; % this initialization ensure that the function will return something
          % if the user press the cancel button            
          % display help if not enough arguments
% ------------------------------------

if nargin < 1
	help pop_eegpr;
	return;
end;	

DataTypeCell={'EEG'};
if ~isempty(EEG.icaweights);
    DataTypeCell={'EEG','ICA'};
    for i=1:length(EEG.icaweights(:,1));EEG.ic(i).labels=sprintf('%s%s','comp',num2str(i));end
end

if isempty(EEG.chanlocs);
    disp('Labelling channels by number.');
    for i=1:EEG.nbchan;
        EEG.chanlocs(i).labels=num2str(i);
    end
end

%if some event types are stored numerically convert them to strings...
Num2StrEvCount=0;
for i=1:length(EEG.event);
    if isnumeric(EEG.event(i).type);
        Num2StrEvCount=Num2StrEvCount+1;
        EEG.event(i).type=num2str(EEG.event(i).type);
    end
end
if Num2StrEvCount>0;
    disp(sprintf('%s%s', num2str(Num2StrEvCount), 'numeric event types converted to string'));
end
    

% pop up window
% -------------
if nargin < 3

    if ~isempty(strmatch('boundary',{EEG.event.type},'exact'));
        eventlist=vararg2str('boundary');
    else
        eventlist = '';
    end
    results=inputgui( ...
    {[1] [1] [4 4 1] [4 4 1] [4 4 1] [1]}, ...
    {...
        ... %1
        {'Style', 'text', 'string', 'Enter phase reset parameters.', 'FontWeight', 'bold'}, ...
        ... %2
        {}, ...
        ... %3
        {'Style', 'text', 'string', 'Data type to use:'}, ...
        {'Style', 'popup', 'string', DataTypeCell, 'tag', 'DataTypePop'... 
                  'callback', ['switch get(findobj(gcbf, ''tag'', ''DataTypePop''), ''value'');' ...
                               '    case 1;' ...
                               '        set(findobj(gcbf, ''tag'', ''ChanLabelButton''), ''callback'',' ...
                               '            [''[ChanLabelIndex,ChanLabelStr,ChanLabelCell]=pop_chansel({EEG.chanlocs.labels});' ...
                               '             set(findobj(gcbf, ''''tag'''', ''''ChanIndexEdit''''), ''''string'''', vararg2str(ChanLabelIndex))'']);' ...
                               '        set(findobj(gcbf, ''tag'', ''ChanIndexEdit''), ''string'', vararg2str(1:EEG.nbchan));' ...
                               '    case 2;' ...
                               '        set(findobj(gcbf, ''tag'', ''ChanLabelButton''), ''callback'',' ...
                               '            [''for i=1:length(EEG.icaweights(:,1));IC(i).labels=sprintf(''''%s%s'''',''''comp'''',num2str(i));end;' ...
                               '            [ChanLabelIndex,ChanLabelStr,ChanLabelCell]=pop_chansel({IC.labels});' ...
                               '             set(findobj(gcbf, ''''tag'''', ''''ChanIndexEdit''''), ''''string'''', vararg2str(ChanLabelIndex))'']);' ...
                               '        set(findobj(gcbf, ''tag'', ''ChanIndexEdit''), ''string'', vararg2str(1:length(EEG.icaweights(:,1))));' ...
                               'end']}, ...
        {}, ...
        ... %4
        {'Style', 'text', 'string', 'Signals to use:'}, ...
        {'Style', 'edit', 'string', vararg2str(1:EEG.nbchan),'tag', 'ChanIndexEdit'}, ...
        {'Style', 'pushbutton', 'string', '...', 'tag', 'ChanLabelButton',... 
                  'callback', ['[ChanLabelIndex,ChanLabelStr,ChanLabelCell]=pop_chansel({EEG.chanlocs.labels});' ...
                  'set(findobj(gcbf, ''tag'', ''ChanIndexEdit''), ''string'', vararg2str(ChanLabelIndex))']}, ...
        ... %5
        {'Style', 'text', 'string', 'Event types identifying analysis borders:'}, ...
        {'Style', 'edit', 'string', eventlist, 'tag', 'EventTypeEdit'}, ...
        {'Style', 'pushbutton', 'string', '...', ... 
                  'callback', ['[EventTypeIndex,EventTypeStr,EventTypeCell]=pop_chansel(unique({EEG.event.type}));' ...
                  'set(findobj(gcbf, ''tag'', ''EventTypeEdit''), ''string'', vararg2str(EventTypeCell))']}, ...
        ... %6
        {}, ...
     }, ...
     'pophelp(''pop_eegpr'');', 'Select phase reset parameters -- pop_eegpr()' ...
     );
 
     if isempty(results);return;end
     
     dattype=results{1};
     datind=results{2};
     evttype=results{3};
end


% return command
% -------------------------
com=sprintf('EEG = pop_eegpr( %s, %d, %s, {%s});', inputname(1), dattype, vararg2str(datind), evttype)

% call command
% ------------
exec=sprintf('EEG = eegpr( %s, %d, %s, {%s});', inputname(1), dattype, vararg2str(datind), evttype);
eval(exec);
