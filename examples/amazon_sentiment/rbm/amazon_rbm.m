function amazon_rbm()
%% Train RBM on unlabelled data
global mod_name;
conf.hidNum    = 5000;  % Number of hidden units
conf.eNum      = 100;   % Number of epoch
conf.bNum      = 0;    % Batch number, 0 means it will be decided by the number of training samples
conf.sNum      = 100;  % Number of samples in one batch
conf.gNum      = 1;    % Number of Gibbs sampling
conf.params(1) = 0.1;  % Learning rate (starting)
conf.params(2) = conf.params(1); % This is unused
conf.params(3) = 0; % Momentum
conf.params(4) = 0; % Weight decay

dat_file = strcat('unlabelled_',domain,'_data.mat');
conf.row_dat = 1; % one data point is one row   

% Sparsity
SPARSITY = 'RELU';
ld = 0.1;
p  = 0.0001;
if strcmp(SPARSITY,'RELU'), conf.h_unit  = 'relu'; ld = 0; p=0; end
conf.sparsity  = SPARSITY;% EMIN,KLMIN
conf.cumsparse = 1;       % Only for KLMIN, using the expectation of previous batches or not (see the code)
conf.sparse_w  = 1;       % Only for EMIN, apply sparsity to w or not(for Lee's approach)
conf.lambda    = ld;      % Sparsity penalty
conf.p         = p;       % Sparsity constraint

%% Training RBMs
conf.trn_dat_file = dat_file;
MOD_DIR = './MOD/RBM/'; 
lm = '/'; % linux
 MOD_DIR = strcat(MOD_DIR,SPARSITY,lm);
if ~exist(MOD_DIR,'dir'), mkdir(MOD_DIR); end
mod_name = strcat(MOD_DIR,'rbm_h'...
    ,num2str(conf.hidNum),'_lr',num2str(conf.params(1)),'_mm',num2str(conf.params(3)),...
    '_cst',num2str(conf.params(4)),'_ld',num2str(ld),'_p',num2str(p),'.mat');

if ~exist(mod_name,'file')
tic
model = gen_rbm_train(conf);
save(mod_name,'model');
toc
else
end

if isfield(conf,'h_unit'), h_unit = conf.h_unit; end
if isfield(conf,'v_unit'), v_unit = conf.v_unit; end
units

% Classification using linear SVM 
trn_dat_file = strcat(TGT_DIR,domain,'_trn_dat.mat');
trn_lab_file = strcat(TGT_DIR,domain,'_trn_lab.mat');

tst_dat_file = strcat(TGT_DIR,domain,'_tst_dat.mat');
tst_lab_file = strcat(TGT_DIR,domain,'_tst_lab.mat');
%% load data
trn_dat = get_data_from_file(trn_dat_file);
trn_lab = get_data_from_file(trn_lab_file)';
tst_dat = get_data_from_file(tst_dat_file);
tst_lab = get_data_from_file(tst_lab_file)';

trn_acc =0;vld_acc=0;vld_acc_=0;vld_av_prec=0;vld_av_recall=0;vld_av_f1=0;tst_acc=0;tst_acc_=0;tst_av_prec=0;tst_av_recall=0;tst_av_f1=0;
           
trn_fts = vis2hid(bsxfun(@plus,trn_dat*model.W,model.hidB'));             
tst_fts = vis2hid(bsxfun(@plus,tst_dat*model.W,model.hidB'));
             
clear trn_dat tst_dat;   
css     = 0.001;
pss      = 0.0001;
ess      = 0.00001;
slinearmod = train(trn_lab, sparse(trn_fts),[' -q -c ' num2str(css) ' -p ' num2str(pss) ' -e ' num2str(ess)]);
[~, acc, ~] = predict(tst_lab, sparse(tst_fts), slinearmod, ' -q ');
tst_acc = acc(1);
disp(tst_acc);
clear trn_fts tst_fts model;

end

