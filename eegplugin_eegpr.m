% eegplugin_eegpr() - EEGLAB plugin for the calculation of phase reset in
%                       pruned continuous EEG data.
%
% Usage:
%   >> eegplugin_eegpr(fig, try_strings, catch_stringss);
%
% Inputs:
%   fig            - [integer]  EEGLAB figure
%   try_strings    - [struct] "try" strings for menu callbacks.
%   catch_strings  - [struct] "catch" strings for menu callbacks.
%
%
% Copyright (C) <2011> <William Marshal, James Desjardins> Waterloo/Brock University
%
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

% $Log: eegplugin_eegpr.m

function eegplugin_eegpr(fig,try_strings,catch_strings)


% Find "Tools" submenu.
toolsmenu=findobj(fig,'label','Tools');

% Create cmd for phase reset.
cmd='[EEG LASTCOM] = pop_eegpr( EEG );';
finalcmdpr=[try_strings.no_check cmd catch_strings.store_and_hist];

% add specific submenu to "Tools" menu.
uimenu(toolsmenu,'label','Calculate phase reset','callback',finalcmdpr);
