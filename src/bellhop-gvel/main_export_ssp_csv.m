%% main_export_ssp_csv.m

% exports 5 ssps as CSVs (depth,ssp)
% EOF ITP 2013 baseval + eof w/ artifact
% EOF ITP 2013 baseval + eof fix
% HYCOM

%% prep workspace
clear; clc;

Zq = 0:1:2680;
Zq = Zq.';

%% EOF ITP 2013 w/ ARTIFACT
OBJ_EOF = eb_read_eeof('../../data/eeof_itp_Mar2013.nc',true);
artifact_weights = [-10 -9.257 -1.023 3.312 -5.067 1.968 1.47].'; % manually written down weights from Toby's notes

Cq1 = interp1(OBJ_EOF.depth,OBJ_EOF.baseval,Zq,'spline');
writematrix([Zq Cq1],'ssp-artifact-baseval.csv');

Cq2 = interp1(OBJ_EOF.depth,OBJ_EOF.baseval + OBJ_EOF.eofs * artifact_weights,Zq,'spline');
writematrix([Zq Cq2],'ssp-artifact-eeof.csv');

%% EOF ITP 2013 w/o FIXED
OBJ_EOF = eb_read_eeof('../../data/eeof-itp-fix-2013.nc',true);
fixed_weights = [-6.112 15.368 -1.441 2.219 0.138 -0.322 -1.994].'; % manually chosen by Bradli, post ICEX20

Cq3 = interp1(OBJ_EOF.depth,OBJ_EOF.baseval,Zq,'spline');
writematrix([Zq Cq3],'ssp-fixed-baseval.csv');

Cq4 = interp1(OBJ_EOF.depth,OBJ_EOF.baseval + OBJ_EOF.eofs * fixed_weights,Zq,'spline');
writematrix([Zq Cq4],'ssp-fixed-eeof.csv');

%% HYCOM
load hycom-ssp-icex20.mat
Cq5 = interp1(hycomZ(1:end-1),hycomC(1:end-1),Zq,'spline');
writematrix([Zq Cq5],'ssp-hycom.csv');
