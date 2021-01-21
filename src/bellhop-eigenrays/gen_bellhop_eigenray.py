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

# %% [markdown]
# # Generate BELLHOP files 
#
# For eigenray, arrival data related to the `modem-doodle` paper

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
        envs[key]['bathy'] = 2685
#         envs[key]['bathy'] = 2675


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

# %% [markdown]
# ## Write ENV files

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
              )

#         ss += ('\'{{run_mode}}\''+'\n'
#                +'3201'+'\n'
#                +'-80 80 /'+'\n'
#                +'0 2750 100'+'\n'
#               )
        ss += ('\'{{run_mode}}\''+'\n'
               +'7121'+'\n'
               +'-89 89 /'+'\n'
               +'0 2750 100'+'\n'
              )        
                
        
        with open('eig_runs/eig_case_%s.env'%(f'{ii:02}'),'w') as ff:
            ff.write(ss.replace('{{run_mode}}','EB'))
            
        with open('eig_runs/arr_case_%s.env'%(f'{ii:02}'),'w') as ff:
            ff.write(ss.replace('{{run_mode}}','AB'))
            
        print('Wrote case %s'%(f'{ii:02}'),end='\r')
        ii+=1
        
num_cases = ii-1
print('ENV files generated')

# %%
len(np.arange(-89,89.01,0.025))

# %% [markdown]
# # Read RAY, ARR files

# %%
from lib_pybellhop.read_arrivals import read_arrivals_asc 
from lib_pybellhop.read_ray import read_ray 


# %%
all_arrs = []

for arr in sorted(glob.glob('./eig_runs/*.arr')):
    all_arrs.append(read_arrivals_asc(arr))
    
print('ARR files loaded')

# %%
all_rays = []

for ray in sorted(glob.glob('./eig_runs/*.ray')):
    all_rays.append(read_ray(ray))
    
print('RAY files loaded')

# %%
# get times by case:
times_by_case = []
linear_cases = []
for yy,case in enumerate(eigentable):
    for tt in case['owtt_mean']:
        times_by_case.append(tt)
        linear_cases.append(case)
        linear_cases[-1]['tt'] = tt
        linear_cases[-1]['eb_idx'] = yy        

# %%
len(times_by_case)==num_cases

# %%
bad_cases = []
for case in range(num_cases):
#     print('Running',case)

    arr = np.squeeze(all_arrs[case][0]).item()
    
    ix = np.argmin(np.abs( np.abs(arr['delay']) -times_by_case[case]))
    ixt = np.min(np.abs( np.abs(arr['delay']) -times_by_case[case]))
    
    if ixt>.1:
        print('Running',case)
        print('Need new run for',case)
        print('From', linear_cases[case]['tx_node'],'to',linear_cases[case]['rx_node'])
        print('want : %.4f   have: %.4f'%(times_by_case[case],np.abs(arr['delay'])[ix]))
        print('Time difference',ixt)
        print()
        bad_cases.append(case)
        linear_cases[case]['arrival'] = 'None'
        linear_cases[case]['ray'] = 'None'
        
    else:
        alpha = arr['SrcDeclAngle'][ix]

        rays = all_rays[case]
        iy = np.argmin(np.abs( np.array([x['alpha0'] for x in rays]) -alpha))

        ray = rays[iy]
        arr = {key:arr[key][ix] if not key in ['A','delay'] else np.abs(arr[key][ix]) for key in arr if not key=='Narr'}
        
        linear_cases[case]['arrival'] = arr
        linear_cases[case]['ray'] = ray


# %%
from scipy.io import savemat

# %%
savemat('./eigentable_flat.mat',{'eigentable':linear_cases})

# %%
arr

# %%
