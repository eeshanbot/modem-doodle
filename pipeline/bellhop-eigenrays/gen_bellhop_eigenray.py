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
do_bellhop = True

# %% [markdown]
# # Generate BELLHOP files 
#
# For eigenray, arrival data related to the `modem-doodle` paper

# %% code_folding=[0]
# do imports 
import numpy as np
import glob
import os

import subprocess
import time
import copy

from scipy.io import loadmat

# %% code_folding=[0]
# load envs 
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

# %% code_folding=[0]
# load eigentable 
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

# %% code_folding=[0]
# write ENV files for initial ARR mode 
print('Begin cases')

if not os.path.isdir('eig_runs'):
    os.mkdir('eig_runs')

ii = 1
times_by_case = []
linear_cases = []
ss_by_case = []

for eb_idx,case in enumerate(eigentable):
    for jj in range(len(case['rx_r_mean'])):
        rx_r = case['rx_r_mean'][jj]
        tt = case['owtt_mean'][jj]

        times_by_case.append(tt)
        linear_cases.append(copy.deepcopy(case))
        linear_cases[-1]['case_owtt'] = tt
        linear_cases[-1]['case_rx_r'] = rx_r
        linear_cases[-1]['eb_idx'] = eb_idx+1
        
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

        ss += ('\'%s\''+'\n'
               +'%d'+'\n'
               +'%.3f %.3f /'+'\n'
               +'0 2750 %.1f'+'\n'
              )    
        
        ss_by_case.append(ss)
                        
#         with open('eig_runs/eig_case_%s.env'%(f'{ii:02}'),'w') as ff:
#             ff.write(ss%('EB',3561,-89,89))
#             ff.write(ss+ss_a.replace('{{run_mode}}','EB')%('EB',3561,-89,89))
            
        with open('eig_runs/arr_case_%s.env'%(f'{ii:02}'),'w') as ff:
            # ff.write(ss%('AB',3201,-80,80,10))
            # ff.write(ss%('AB',7121,-89,89,10))
            ff.write(ss%('AB',3561,-89,89,10))
            
        print('Wrote case %s'%(f'{ii:02}'),end='\r')
        ii+=1
        
num_cases = ii-1
print('ENV files generated')

# %% code_folding=[0]
# Send to server 
try:
    __IPYTHON__
    print('Running in IPython mode')
    is_ipy = True
except:
    print('Script mode')
    is_ipy = False
    
if is_ipy and do_bellhop:
    ans_log = []

    print('Calling clean_eig_runs')
    print(os.system('ssh agx \'~/bin/clean_eig_runs.sh\''))
    
    print('Sending ENV files')
    ans = subprocess.check_output(['rsync','-azP','./eig_runs','agx:~/agxDATA/oviquezr/'])
    ans_log.append(ans.decode('utf-8'))
    
    print('Calling run_arrs')
    print(os.system('ssh agx \'~/bin/run_arrs.sh\''))
    
    time.sleep(1)

    print('Collecting ARR files')
    ans = subprocess.check_output(['rsync','-azP','--include=*.arr','--exclude=*',
                                   'agx:~/agxDATA/oviquezr/eig_runs/','./eig_runs/'])
    ans_log.append(ans.decode('utf-8'))
    print('Done!')    

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

# %% code_folding=[0]
# check ARR files for first fit 
bad_cases = []

angles = []
for case in range(num_cases):
#     print('Running',case)

    arr = np.squeeze(all_arrs[case][0]).item()
    
    ix = np.argmin(np.abs( np.abs(arr['delay']) -times_by_case[case]))
    ixt = np.abs( np.abs(arr['delay'][ix]) -times_by_case[case])

    arr = {key:arr[key][ix] if not key in ['A','delay'] else np.abs(arr[key][ix]) for key in arr if not key=='Narr'}
    
    if ixt>.1:
        print('Running',case)
        print('Need new run for',case)
        print('From', linear_cases[case]['tx_node'],'to',linear_cases[case]['rx_node'])
        print('want : %.4f   have: %.4f'%(times_by_case[case],np.abs(arr['delay'])))
        print('Time difference',ixt)
        print('alpha',arr['SrcDeclAngle'])
        print()
        bad_cases.append(case)
        linear_cases[case]['arrival'] = 'None'
        linear_cases[case]['ray'] = 'None'
        
        angles.append(np.nan)
        
        
    else:
        linear_cases[case]['arrival'] = arr
        
        alpha = arr['SrcDeclAngle']        
        angles.append(alpha)
#         print('Running %2d'%(case),' & getting alpha : ',alpha,)
        
        case2 = case+1
        # with open('eig_runs/eig_zoom_%s.env'%(f'{case2:02}'),'w') as ff:
        with open('eig_runs/ray_case_%s.env'%(f'{case2:02}'),'w') as ff:
            ff.write(ss_by_case[case]%('RB',201,np.round(alpha-.1,2),np.round(alpha+.1,2),
                                       linear_cases[case]['case_rx_r']/1000+.2))

    


# %%
# len(np.arange(np.round(alpha-.2,2),np.round(alpha+.2,2)+1e-6,0.001))

# %% code_folding=[0]
# send to server 
if is_ipy and do_bellhop:

    # print('Calling clean_eig_runs')
    # print(os.system('ssh agx \'~/bin/clean_eig_runs.sh\''))
    
    print('Sending ENV files')
    ans = subprocess.check_output(['rsync','-azP','./eig_runs','agx:~/agxDATA/oviquezr/'])
    ans_log.append(ans.decode('utf-8'))
    
    print('Calling run_rays')
    print(os.system('ssh agx \'~/bin/run_rays.sh\''))
    
    time.sleep(1)

    print('Collecting RAY files')
    ans = subprocess.check_output(['rsync','-azP','--include=*.ray','--exclude=*',
                                   'agx:~/agxDATA/oviquezr/eig_runs/','./eig_runs/'])
    ans_log.append(ans.decode('utf-8'))
    print('Done!')

# %% code_folding=[0]
# load RAY files
all_rays = []
ray_files = sorted(glob.glob('./eig_runs/ray_case_*.ray'))

for case in range(1,num_cases+1):
    if './eig_runs/ray_case_%s.ray'%(f'{case:02}') in ray_files:
        all_rays.append(read_ray('./eig_runs/ray_case_%s.ray'%(f'{case:02}')))
    else:
        all_rays.append(None)
    
# for ray in :
#     all_rays[int(ray[-6:-4])-1]=read_ray(ray)
    
print('RAY files loaded')

# %% code_folding=[0]
# locate ray for plotting 
for case in range(num_cases):
#     if linear_cases[case]['arrival']!='None':
#     if case in all_rays: #if linear_cases[case]['arrival']!='None':
                
    alpha = arr['SrcDeclAngle']

    rays = all_rays[case]

    if not rays==None:        

        ix = np.argmin([np.min(np.sqrt((iray['r']-linear_cases[case]['case_rx_r'])**2
                                   +(iray['z']-linear_cases[case]['rx_z'])**2)) for iray in rays])

        ray = copy.deepcopy( rays[ix])

        ix = np.argmin(np.sqrt((ray['r']-linear_cases[case]['case_rx_r'])**2
                                   +(ray['z']-linear_cases[case]['rx_z'])**2))
        ray['r'] = ray['r'][:ix+1]
        ray['z'] = ray['z'][:ix+1]
        if not ray==None:
            linear_cases[case]['ray'] = ray

#     else:
#         print('Skipping case',case)

# %%
from scipy.io import savemat

# %%
savemat('./eigentable_flat.mat',{'eigentable':linear_cases})

# %% [markdown]
# # Sanity check : plot

# %%
from bokeh.plotting import figure, show
from bokeh.io import output_notebook
output_notebook()

# %%
from ipywidgets import interact


# %%
def make_plot(case=0):
    if case in all_rays:
        pp = figure(plot_width=900, plot_height=200)
        for ray in all_rays[case]:

            pp.line(x=ray['r'],y=ray['z'])

        pp.line(linear_cases[case]['ray']['r'],linear_cases[case]['ray']['z'],color='red')
        pp.circle(linear_cases[case]['case_rx_r'],linear_cases[case]['rx_z'],color='red')
        pp.y_range.flipped = True
        pp.title.text = 'Case number : %d'%(case)
        show(pp)


# %%
interact(make_plot,case=(0,num_cases-1),continuous_update=False)
print()

# %%
for case in range(num_cases):
    if not all_rays[case]==None:
        pp = figure(plot_width=900, plot_height=200)
        for ray in all_rays[case][::4]:

            pp.line(x=ray['r'],y=ray['z'],alpha=.2)

        pp.line(linear_cases[case]['ray']['r'],linear_cases[case]['ray']['z'],color='red')
        pp.circle(linear_cases[case]['case_rx_r'],linear_cases[case]['rx_z'],color='red')
        pp.y_range.flipped = True
        pp.title.text = 'Case number : %d   Theta : %.2f   EB : %d'%(
            case,linear_cases[case]['arrival']['SrcDeclAngle'],linear_cases[case]['eb_idx'])
        show(pp)

# %%

# %%
