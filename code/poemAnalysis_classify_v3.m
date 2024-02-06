function [Dx] = poemAnalysis_classify_v3( T )
%
% This function takes the table variable "T" to generate ICHD-3 diagnoses.

% Migraine diagnosis

Dx = T(:,9); % start table with ResponseID

Dx.Migraine = zeros(height(Dx),1);
Dx.Migraine(T.migICHD_A==1 & T.migICHD_B==1 & T.migICHD_C>=2 & T.migICHD_D==1) = 1;

Dx.ProbableMigraine = zeros(height(Dx),1);
Dx.ProbableMigraine(T.migICHD_A==0 & T.migICHD_B==1 & T.migICHD_C>=2 & T.migICHD_D==1) = 1;
Dx.ProbableMigraine(T.migICHD_A==1 & T.migICHD_B==0 & T.migICHD_C>=2 & T.migICHD_D==1) = 1;
Dx.ProbableMigraine(T.migICHD_A==1 & T.migICHD_B==1 & T.migICHD_C<2 & T.migICHD_D==1) = 1;
Dx.ProbableMigraine(T.migICHD_A==1 & T.migICHD_B==1 & T.migICHD_C>=2 & T.migICHD_D==0) = 1;

Dx.Chronic = zeros(height(Dx),1);
Dx.Chronic(contains(string(T.MigFreq),'16 - 20 days')|contains(string(T.MigFreq),'More than 20 days')) = 1;

% Aura diagnosis
Dx.VisualAura = zeros(height(Dx),1);
Dx.VisualAura(T.visAuraICHD_A==1 & T.visAuraICHD_C>=3) = 1;
Dx.SensAura(T.sensAuraICHD_A==1 & T.sensAuraICHD_C>=3) = 1;
Dx.SpeechAura(T.speechAuraICHD_A==1 & T.speechAuraICHD_C>=3) = 1;
Dx.MultiAura = zeros(height(Dx),1);
Dx.MultiAura(Dx.VisualAura==1 & Dx.SensAura==1) = 1;
Dx.MultiAura(Dx.VisualAura==1 & Dx.SpeechAura==1) = 1;
Dx.MultiAura(Dx.SensAura==1 & Dx.SpeechAura==1) = 1;

% Make diagnostic categories
Dx.Dx = NaN*ones(height(Dx),1);
Dx.Dx(Dx.Migraine==1 & Dx.VisualAura==0 & Dx.SensAura==0 & Dx.SpeechAura==0) = 1; % migraine without aura
Dx.Dx(Dx.Migraine==1 & (Dx.VisualAura==1|Dx.SensAura==1|Dx.SpeechAura==1)) = 2; % migraine with aura
Dx.Dx(Dx.ProbableMigraine==1 & Dx.VisualAura==0 & Dx.SensAura==0 & Dx.SpeechAura==0) = 3; % probable migraine without aura
Dx.Dx(Dx.ProbableMigraine==1 & (Dx.VisualAura==1|Dx.SensAura==1|Dx.SpeechAura==1)) = 4; % probable migraine with aura
Dx.Dx(contains(string(T.unprovokedHA_yn),'Yes')==1 & Dx.Migraine==0 & Dx.ProbableMigraine==0) = 5; % non-migraine headache
Dx.Dx(contains(string(T.unprovokedHA_yn),'No')==1|contains(string(T.HA_yn),'No')==1) = 6; % no headache

Dx.Dx = categorical(Dx.Dx,1:6,{'migraine w/out aura','migraine w/aura','probable migraine w/out aura','probable migraine w/aura','non-migraine headache','no headache'});

Dx.Dx2 = mergecats(Dx.Dx,{'migraine w/out aura','migraine w/aura','probable migraine w/out aura','probable migraine w/aura'});
Dx.Dx2 = renamecats(Dx.Dx2,{'migraine w/out aura'},{'migraine'});

end % function



