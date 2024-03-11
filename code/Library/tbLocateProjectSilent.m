function path = tbLocateProjectSilent(projectName)
% Return the path silently

prefs = tbParsePrefs([]);
prefs.verbose = false;
path = tbLocateProject(projectName,prefs);

end