# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:percent
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.9.1
#   kernelspec:
#     display_name: Python 3
#     language: python
#     name: python3
# ---

# %%
import numpy as np
import glob
import os

from scipy.io import loadmat

# %%
pattern = '_generated_env.pb.cfg'
envs = {x[2:-len(pattern)]:{'fname':x} for x in glob.glob('./*_generated_env.pb.cfg')}

for key in envs:
    
    with open(envs[key]['fname'],'r') as ff:
        lines = ff.read().replace('\n\n','\n').split('\n')
        
        n_ssp = np.sum(np.array([ii.startswith('sample') for ii in lines]))
        ssp_mat = np.zeros([n_ssp,2])
        ii = 0
        for line in lines:
            if line.startswith('sample'):
                data_line = line.split(' ')
                if data_line[2]=='depth:' and data_line[4]=='cp:':
                    ssp_mat[ii,0] = data_line[3]
                    ssp_mat[ii,1] = data_line[5].split('}')[0]
                    ii+=1
                    
        envs[key]['ssp'] = ssp_mat
        envs[key]['bathy'] = 2675
        

# %%
eof_status = {0:'baseval',
              1:'eof',
             }

# %%
eigentable = np.squeeze(loadmat('./eigentable.mat')['eigentable'])
eigentable = [{key: x[0][0][y] for y,key in 
               enumerate(list(eigentable[0].dtype.fields.keys()))} for x in eigentable]

v_keys = ['rx_r_mean','rx_r_std','owtt_mean','owtt_std','owtt_num']

eigentable = [{key:x[key][0][0] if x[key].shape==(1,1) else x[key] for key in x} for x in eigentable]
eigentable = [{key:x[key][0] if x[key].shape==(1,) else x[key] for key in x} for x in eigentable]

for case in eigentable:
    for key in v_keys:
        if type(case[key])==np.ndarray:
            case[key] = np.squeeze([case[key]])
        else:
            case[key] = np.array([case[key]])
            
    case['env'] = eof_status[case['eof_status']]

# %%
envs.keys()

# %%
# [x['eof_status'] for x in eigentable]

# %%
print('Begin cases')
ii = 1

if not os.path.isdir('eig_runs'):
    os.mkdir('eig_runs')

for case in eigentable:
    for rx_r in case['rx_r_mean']:
        bathy = envs[case['env']]['bathy']
        
        ss = ('\' EOF Eig %s : %s to %s\''%(f'{ii:02}',case['tx_node'],case['rx_node'])+'\n'
              +'10000.0'+'\n'
              +'1'+'\n'
              +'NVWT'+'\n'
              +'0 0 %f'%(bathy)+'\n'
             )
        for it in envs[case['env']]['ssp']:
            if it[0]<= bathy:
                ss += '%f %f /'%(it[0],it[1]) + '\n'
                it_prev = it
            else:
                it_new = ((it[1]-it_prev[1])/(it[0]-it_prev[0]))*(bathy-it_prev[0])+it_prev[1]
                ss += '%f %f /'%(bathy,it_new) + '\n'
                break
                
        ss += ('\'A\' 0.0' + '\n'
               +'%f 1510.0 0.0 1.0 2.0 /'%(bathy) + '\n'
               +'1'+'\n'
               +'%f /'%(case['tx_z'])+'\n'
               +'1'+'\n'
               +'%f /'%(case['rx_z'])+'\n'
               +'1'+'\n'
               +'%f /'%(rx_r/1000)+'\n'

               +'\'EB\''+'\n'
               +'3201'+'\n'
               +'-80 80 /'+'\n'
               +'0 2750 10'+'\n'
              )
                
        
        with open('eig_runs/case_%s.env'%(f'{ii:02}'),'w') as ff:
            ff.write(ss)
        ii+=1

# %%
