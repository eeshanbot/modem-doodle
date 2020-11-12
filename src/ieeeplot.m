%% plot w/ coeffs

load bradli_ctd_eofnum.mat

figure(1); clf;

filename = '~/.dropboxmit/icex_2020_mat/eeof_itp_Mar2013.nc';
num_eofs = double(ncread(filename,'num_eofs'));
pdf_val = double(ncread(filename,'pdf_val'));
pdf_freq = double(ncread(filename,'pdf_freq'));
weights = double(ncread(filename,'weights'));
baseval = double(ncread(filename,'baseval'));


listlist = NaN(8,7);
for cc = [1 2 4:9]
    listlist(cc,ctd_eofnum{cc}) = ctd_weight{cc};
end



%% figure
figure(1)
for ne = 1:num_eofs
    subplot(4,2,ne);
    plot(pdf_val(ne,:),pdf_freq(ne,:)/max(pdf_freq(ne,:)))
    grid on
    xval = max(abs(pdf_val(ne,:)));
    xlim([-xval xval])
    
    [~,ind_max] = max(pdf_freq(ne,:));

    
    hold on
    plot([pdf_val(ne,ind_max) pdf_val(ne,ind_max)],[0 1],'r--')
    
    
    Fq = interp1(pdf_val(ne,:),pdf_freq(ne,:)/max(pdf_freq(ne,:)),listlist(:,ne));
    Fq(isnan(Fq)) = 0;
    
    plot(listlist(:,ne),Fq,'*')
    
    hold off
    
    default_weights(ne) = pdf_val(ne,ind_max);
    
    str = sprintf('eeof %d',ne);
    title(str);
    
    axis tight
end