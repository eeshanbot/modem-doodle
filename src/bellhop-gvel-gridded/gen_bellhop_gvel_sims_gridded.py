# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:percent
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.10.2
#   kernelspec:
#     display_name: Python 3
#     language: python
#     name: python3
# ---

# %%
do_bellhop = False
save_files = False

# %% [markdown]
# # Generate BELLHOP files
#
# For eigenray, arrival data related to the `modem-doodle` paper

# %% code_folding=[]
# do imports
import numpy as np
import glob
import os

import subprocess
import time
import copy

from scipy.io import loadmat

# %% code_folding=[]
# load envs
pattern = '.csv'
envs = {x[2+4:-len(pattern)]:{'fname':x} for x in glob.glob('./ssp*.csv')}


# %%
for key in envs:
    with open(envs[key]['fname'],'r') as ff:
        envs[key]['ssp'] = np.genfromtxt(ff,delimiter=',')
        envs[key]['bathy'] = 2680


# %%
with open('./gveltable.csv','r') as ff:
    keys = ff.readline().replace('\n','').split(',')
    keys = ['tx_z','rx_z','rx_r','simGvel','tx_node','rx_node','owtt']
    lines = ff.read().split('\n')
    it_types = [float,float,float,float,str,str,float]

    gveltable = {}
        
    for key in keys:
        gveltable[key] = []
    
    for line in lines:
        line = line.split(',')
        if not len(line)==len(it_types):
            break
        
        for ii,it in enumerate(line):
            gveltable[keys[ii]].append(it_types[ii](it))
    
gveltable = {key:np.array(gveltable[key]) for key in gveltable}

# %% [markdown]
# ## Write ENV files

# %% code_folding=[]
# write ENV files for initial ARR mode
if do_bellhop:
    print('Begin cases')

    if not os.path.isdir('gvel_runs'):
        os.mkdir('gvel_runs')

    times_by_case = []
    linear_cases = []
    ss_by_case = []

    for env_key in envs:

        for ii in range(len(gveltable['rx_r'])):
            case = {key:gveltable[key][ii] for key in gveltable}

            rx_r = case['rx_r']
            tt = case['owtt']

            times_by_case.append(tt)
            linear_cases.append(copy.deepcopy(case))
            linear_cases[-1]['case_owtt'] = tt
            linear_cases[-1]['case_rx_r'] = rx_r
            linear_cases[-1]['eb_idx'] = ii+1

            bathy = envs[env_key]['bathy']

            ss = ('\' EOF GVel %s : %s to %s\''%(f'{ii:02}',case['tx_node'],case['rx_node'])+'\n'
                  +'10000.0'+'\n'
                  +'1'+'\n'
                  +'NVWT'+'\n'
                  +'0 0 %f'%(bathy)+'\n'
                 )

            for it in envs[env_key]['ssp']:
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
                   +'11'+'\n'
                   +'%f %f /'%(case['rx_z']-5*2,case['rx_z']+5*2)+'\n'
                   +'11'+'\n'
                   +'%f %f /'%((rx_r-5)/1000,(rx_r+5)/1000)+'\n'
                  )

            ss += ('\'%s\''+'\n'
                   +'%d'+'\n'
                   +'%.3f %.3f /'+'\n'
                   +'10 2750 %.1f'+'\n'
                  )

            ss_by_case.append(ss)

        #         with open('eig_runs/eig_case_%s.env'%(f'{ii:02}'),'w') as ff:
        #             ff.write(ss%('EB',3561,-89,89))
        #             ff.write(ss+ss_a.replace('{{run_mode}}','EB')%('EB',3561,-89,89))

            with open('gvel_runs/arr_case_'+env_key+'_%s.env'%(f'{ii:04}'),'w') as ff:
                # ff.write(ss%('AB',3201,-80,80,10))
                # ff.write(ss%('AB',7121,-89,89,10))
                ff.write(ss%('AB',3501,-60,60,10))

            print('Wrote case %s'%(f'{ii:04}'),end='\r')

        print('Wrote %d cases for %s'%(ii,env_key))

    num_cases = ii-1
    print('ENV files generated')

# %% code_folding=[]
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

    print('Calling clean_gvel_runs')
    print(os.system('ssh agx \'~/bin/clean_gvel_runs.sh\''))

    print('Sending ENV files')
    ans = subprocess.check_output(['rsync','-azP','./gvel_runs','agx:~/agxDATA/oviquezr/'])
    ans_log.append(ans.decode('utf-8'))

    print('Calling run_gvels')
    print(os.system('ssh agx \'~/bin/run_gvels.sh\''))

    time.sleep(1)

    print('Collecting ARR files')
    ans = subprocess.check_output(['rsync','-azP','--include=*.arr','--exclude=*',
                                   'agx:~/agxDATA/oviquezr/gvel_runs/','./gvel_runs/'])
    ans_log.append(ans.decode('utf-8'))
    print('Done!')


# %% [markdown]
# # Read RAY, ARR files

# %% code_folding=[]
# Use GVel calculation from ARR structure

def get_dt(ARR):

    bncSum = ARR['NumTopBnc']+ARR['NumBotBnc']

    response = {key:np.nan  for key in range(5)}
    for ii in response:
        if len(bncSum[bncSum==ii])>0:
            A = ARR['A'][bncSum==ii]
            delay = ARR['delay'][bncSum==ii]
            n_bnc = ii
            response[ii] = np.sum(np.abs(delay)*np.abs(A)**2)/np.sum(np.abs(A)**2)
            
    return response


# %%
from lib_pybellhop.read_arrivals import read_arrivals_asc
from lib_pybellhop.read_ray import read_ray


# %%
all_arrs = {key:[] for key in envs}

for arrfil in sorted(glob.glob('./gvel_runs/*.arr'),key=lambda s: (int(s[-8:-4]),s)):
    key = arrfil.split('arr_case_')[1][:-9]

    arr,pos,freq = read_arrivals_asc(arrfil)

    arr0 = arr[int((arr.shape[0]-1)/2),int((arr.shape[1]-1)/2),0]

    arr_concat = {key:[] for key in arr[0,0,0] if not key=='Narr'}
    for ii in range(arr.shape[0]):
        for jj in range(arr.shape[1]):
            for key2 in arr_concat:
                arr_concat[key2].extend(arr[ii,jj,0][key2])

    arr_concat = {key:np.array(arr_concat[key]) for key in arr_concat}

    dt = get_dt(arr_concat)
    dt0 = get_dt(arr0)

    all_arrs[key].append({'index':int(arrfil[-8:-4]),
                          'fname':arrfil,
                          #'arr':arr,
                          'pos':pos,
                          'freq':freq,
                          'owtt0':dt0,
                          'owtt':dt})
    print('%20s'%(key),int(arrfil[-8:-4]),' '*10,end='\r')
    
print('')
print('ARR files loaded')

# %%
from scipy.io import savemat

# %%
# all_arrs = {key:np.array(all_arrs[key]) for key in all_arrs}

# %%
# for key in all_arrs:
#     savemat('./gveltable_models_'+key+'.mat',{key:all_arrs[key]})    
if save_files:
    savemat('./gveltable_models.mat',{'all_arrs': all_arrs})

# %%
headers = ['index']+['owtt_%d_bounce'%(x) for x in range(5)]

for key in all_arrs:
    with open('./csv_arr/'+key+'-gridded.csv','w+') as ff:
        ff.write(','.join(headers)+'\n')
        for it in all_arrs[key]:
            ff.write('%d,'%(it['index']))
            ff.write(','.join([str(x) for x in it['owtt0'].values()]))
            ff.write('\n')
#             ff.write(','.join([str(it[hdr]) for hdr in headers])+'\n')
            
    with open('./csv_arr/'+key+'-center.csv','w+') as ff:
        ff.write(','.join(headers)+'\n')
        for it in all_arrs[key]:
            ff.write('%d,'%(it['index']))
            ff.write(','.join([str(x) for x in it['owtt0'].values()]))
            ff.write('\n')
#             ff.write(','.join([str(it[hdr]) for hdr in headers])+'\n')


# %% [markdown]
# # Sanity check : plot

# %%
from bokeh.plotting import figure, show
from bokeh.io import output_notebook
output_notebook()

from bokeh.palettes import Category10, Category20


# %%
from ipywidgets import interact


# %%
def make_plot(tx_z=20.,rx_z=30.,mode='gvel'):
    mask1 = gveltable['tx_z']==tx_z
    mask2 = gveltable['rx_z']==rx_z
    
    mask = mask1 * mask2
    
    pp = figure(plot_width=900, plot_height=400)
    
    mask_owtt = gveltable['owtt'][mask]< 10

    rr = np.array(gveltable['rx_r'][mask][mask_owtt])
    tt = np.array(gveltable['owtt'][mask][mask_owtt])
    
    if mode=='gvel':
        yy = rr/tt
    elif mode=='owtt':
        yy = tt
    
    pp.circle(rr,yy,
              color='gray',alpha=.1,
              legend_label='measured',
              name='measured'
             )

    
    if mode=='gvel':
        rr = np.array(gveltable['rx_r'][mask])
        yy = np.array(gveltable['simGvel'][mask])
        
        pp.cross(rr,yy,
                 color='gray',
                 alpha=1,
                 legend_label='simGvel',
                 name='simGvel'
                 )    
    
    for ii,key in enumerate(all_arrs):
        
        rr = np.array([x['pos']['r']['range'][0] for jj,x in enumerate(all_arrs[key]) if mask[jj]])
        tt = np.array([np.nanmin(list(x['owtt'].values())) for jj,x in enumerate(all_arrs[key]) if mask[jj]])

        if mode=='gvel':
            yy = rr/tt
        elif mode=='owtt':
            yy = tt
        
        pp.circle(rr,yy,
          color=Category10[10][ii],alpha=.1,
          legend_label=key,
          name=key
         )
                
    pp.legend.click_policy = 'hide'
    
    pp.add_layout(pp.legend[0],'right')
    
    pp.xaxis.axis_label = 'Range [m]'

    if mode=='gvel':
        pp.yaxis.axis_label = 'Grouo Velocity [m/s]'
    elif mode=='owtt':
        pp.yaxis.axis_label = 'One-Way Travel Time [s]'

    show(pp)


# %%
interact(make_plot,
         tx_z=np.unique(gveltable['tx_z']),
         rx_z=np.unique(gveltable['rx_z']),
         mode=['owtt','gvel'],
         continuous_update=False)
print()

# %%
