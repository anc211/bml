function [annot, spike] = bml_plexon2annot(cfg)

% BML_PLEXON2ANNOT loads spike events from plexon file
%
% Use as
%   annot = bml_plexon2annot(cfg)
%
% cfg.roi            - roi table with neuroomega sync information
% cfg.PlexonPath     - path to plexon file
% cfg.PlexonSrcPath  - path to preprocessed mat file for plexon
%                      inferred from cfg.PlexonPath if not given
%                      and cfg.FileMapping not provided
% cfg.FileMapping    - table with file mapping to vector analyzed by
%                      plexon. Loaded from cfg.PlexonSrcPath if not given
% cfg.label          - vector of channel names. Extracted from 'channels'
%                      cell array in cfg.PlexonSrcPath if not provided
% cfg.electrode      - table with variables channel and electrode. used to 
%                      rename the labels. 
%
% Returns
% annot - annotation table with time of spikes in global time coordinates
% spike - ft_datatype_spike structure as returned by ft_read_spike


sync          = bml_getopt(cfg,'roi');


FileMapping   = bml_getopt(cfg,'FileMapping');

label         = bml_getopt(cfg,'label',spike.label);

FM_VARS={'name','nSamples','Fs','raw1','raw2'};
SY_VARS={'starts','ends','t1','s1','t2','s2','name', 'nSamples'};

assert(~isempty(FileMapping),"FileMapping required");
assert(~isempty(sync),"sync requried");
assert(length(label)==length(spike.label),"Incorrect label");
assert(all(ismember(FM_VARS,FileMapping.Properties.VariableNames)),"Invalid FileMapping table");
assert(all(ismember(SY_VARS,sync.Properties.VariableNames)),"Invalid sync table");

annot=table();
for i=1:length(spike.label)
  if ~isempty(spike.timestamp{i})
    
    %creating sync table for the spike data
    assert(max(spike.timestamp{i}) <= max(FileMapping.raw2), "Invalid timestamp");
    
    fm = FileMapping(:,FM_VARS);
    sy = sync(ismember(sync.name,fm.name),SY_VARS);    
    syfm=join(sy,fm,'Keys','name');
    
    assert(all(syfm.nSamples_sy==syfm.nSamples_fm), "Inconsistent number of samples");

    syfm.s1=syfm.raw1;
    syfm.s2=syfm.raw2;
    syfm.nSamples = syfm.nSamples_sy;
    
    cfg1=[];
    cfg1.roi=syfm;
    cfg1.rowisfile=false;
    spike_sync=bml_sync_consolidate(cfg1);
    
    %creating table with spikes
    st = table(bml_idx2time(spike_sync,spike.timestamp{i})',spike.unit{i}');
    st.Properties.VariableNames = {'starts','unit'};
    st.channel(:)=label(i);
    st.spike_idx=(1:height(st))';
    
    annot=[annot;st];
  end  
end

annot.ends = annot.starts;
annot = bml_annot_table(annot);
