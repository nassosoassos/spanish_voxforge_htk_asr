ROOTDIR = /rmt/work/audio_asr/spanish
DATADIR = $(ROOTDIR)/data
FEATURESDIR = $(ROOTDIR)/features
LOCALFEATURESDIR = /local/nassos/audio_asr/spanish/features
LIBDIR = $(ROOTDIR)/library
LISTDIR = $(ROOTDIR)/lists
WAVLIST = $(LISTDIR)/wavs.list
TRAINSCP = $(LISTDIR)/train.scp
TRAINLOCALSCP = $(LISTDIR)/train_local.scp
TESTSCP = $(LISTDIR)/test.scp
TESTLOCALSCP = $(LISTDIR)/test_local.scp
CODINGSCP = $(LISTDIR)/wav2mfc.scp
SPEAKERLIST = $(LISTDIR)/speakers.list
HTKDICT = $(LIBDIR)/dictionary
COMPDICT = lib_files/missing_words_dict
HCOPYCONFIG = '-C common/config -C common/configwav -C common/config_voxforge'
HTKBINDIR = $(HTKBINDIR)
HCOPYBIN = $(HTKBINDIR)/HCopy.pl
HVITEBIN = $(HTKBINDIR)/HVite.pl
HHEDBIN = $(HTKBINDIR)/HHEd
HLEDBIN = $(HTKBINDIR)/HLEd
HCOMPVBIN = $(HTKBINDIR)/HCompV
HERESTBIN = $(HTKBINDIR)/HERest.pl
HLEDBIN = $(HTKBINDIR)/HLEd
LEXICON = $(LIBDIR)/voxforge_lexicon_spanish
PROMPTSFILE = $(LIBDIR)/master_prompts_train_16kHz-16bit
MLFFILE = $(LIBDIR)/train.mlf
MLFLOCALFILE = $(LIBDIR)/train_local.mlf
ALIGNMLF = $(LIBDIR)/aligned2.mlf
ALIGNLOCALMLF = $(LIBDIR)/aligned2_local.mlf
PMLFFILE = $(LIBDIR)/train_phones.mlf
MKPHONESLED = $(LIBDIR)/mkphones.led
CLEANPROMPTS = $(LIBDIR)/voxforge_prompts
PHONELIST = $(LIBDIR)/monophones
PHONELIST_SP = $(LIBDIR)/monophones_sp
TRIPHONELIST = $(MODELDIR)/triphones1
TIEDLIST = $(MODELDIR)/tiedlist
MODELDIR = $(ROOTDIR)/models
TRAINTEXT = $(LIBDIR)/lm.txt
LMFILE = $(LIBDIR)/lm.arpa
HTKDICT_NOSP = $(LIBDIR)/dict_no_sp 
WORDLIST = $(LIBDIR)/words.list

all: audio prompts dictionary scps hcopy hcompv mlf phonmlf phonelists monophones_local silsp train_mixup

audio: download untar

prompts: 
	mkdir -p $(LIBDIR); \
	wget --directory-prefix=$(LIBDIR) http://www.repository.voxforge1.org/downloads/es/Trunk/Prompts/Prompts.tgz; \
	tar xvf $(LIBDIR)/Prompts.tgz -C $(LIBDIR); \
	mv $(LIBDIR)/Prompts/* $(LIBDIR); \
	rm -rf $(LIBDIR)/Prompts*; \
	grep -v -e buhochileno_ES_01 $(PROMPTSFILE) > $(CLEANPROMPTS);
	cat $(DATADIR)/beavies-20120817-*/etc/PROMPTS >> $(CLEANPROMPTS);

dictionary:
	if [ ! -e $(LEXICON) ]; then \
		wget --directory-prefix=$(LIBDIR) http://www.dev.voxforge.org/projects/es/export/5768/Trunk/Ubanov/lexicon/voxforge_lexicon_spanish; \
	fi; \
	rm -f $(HTKDICT); \
	cp $(LEXICON) $(LEXICON).tmp
	cat $(COMPDICT) >> $(LEXICON).tmp;
	cat $(LEXICON).tmp | sed -e 's/$$/ sp/'  > $(HTKDICT);
	rm $(LEXICON).tmp
	echo silence [] sil >> $(HTKDICT);

download: 
	wget -r --no-parent --directory-prefix=$(ROOTDIR) --reject "index.html*" http://www.repository.voxforge1.org/downloads/es/Trunk/Audio/Main/16kHz_16bit/
	mv $(ROOTDIR)/www.repository.voxforge1.org/downloads/es/Trunk/Audio/Main/16kHz_16bit $(DATADIR)
	rm -rf $(ROOTDIR)/www.repository.voxforge1.org

untar: 
	for tfile in $(DATADIR)/*.tgz; do \
		tar xvf $${tfile} -C $(DATADIR);\
		rm $${tfile};\
	done;

hcopy: scps
	$(HCOPYBIN) $(HCOPYCONFIG) -S $(CODINGSCP); 

local_features: 
	pserimos_dir=`echo $(FEATURESDIR) | sed -e "s,rmt,cvsp1,"`; \
	bash scripts/transfer_data_locally.sh $(FEATURESDIR) /rmt/work $${pserimos_dir}

hcompv:
	hcompv_dir=$(MODELDIR)/hmm0;\
	mkdir -p $${hcompv_dir};\
	$(HCOMPVBIN) -A -T 1 -f 0.01 -m -S $(TRAINSCP) -M $${hcompv_dir} lib_files/proto > $${hcompv_dir}/hcompv_flat.log; \
	cp lib_files/macros $${hcompv_dir}; \
	cat $${hcompv_dir}/vFloors >> $${hcompv_dir}/macros; \
	perl scripts/CreateHMMDefs.pl $${hcompv_dir}/proto $(PHONELIST) > $${hcompv_dir}/hmmdefs;

scps: list paths
	rm -f $(CODINGSCP) $(TRAINSCP) $(TRAINLOCALSCP);
	for entry in `cat $(WAVLIST)`; do \
		wavfile=$(DATADIR)/$${entry}; \
		bname=`basename $${wavfile} .wav`;\
		mfcfile=$(FEATURESDIR)/`dirname $${entry} | sed 's,wav,mfc,g'`/$${bname}.mfc; \
		echo $${mfcfile} >> $(TRAINSCP); \
		echo $${wavfile} $${mfcfile} >> $(CODINGSCP);\
	done;
	# Test scp
	sort -R $(TRAINSCP) > temp.scp;
	cat temp.scp | head -n 500 > $(TESTSCP);
	cat temp.scp | tail -n +501 > $(TRAINSCP);
	sed -e "s,$(FEATURESDIR),$(LOCALFEATURESDIR)," $(TESTSCP) > $(TESTLOCALSCP); 
	sed -e "s,$(FEATURESDIR),$(LOCALFEATURESDIR)," $(TRAINSCP) > $(TRAINLOCALSCP); 

list:
	mkdir -p $(LISTDIR)
	ls $(DATADIR)/*/wav/*.wav | sed 's,$(DATADIR)/,,' | grep -v -e buhochileno_ES_01 > $(WAVLIST)
	ls $(DATADIR) > $(SPEAKERLIST)

paths: 
	mkdir -p $(FEATURESDIR);
	for entry in `cat $(SPEAKERLIST)`; do \
		mkdir -p $(FEATURESDIR)/$${entry}/mfc;\
	done

mlf:
	voxforge/prompts2mlf.py $(FEATURESDIR) < $(CLEANPROMPTS) > $(MLFFILE);
	voxforge/prompts2mlf.py $(LOCALFEATURESDIR) < $(CLEANPROMPTS) > $(MLFLOCALFILE);

phonmlf:
	echo EX > $(MKPHONESLED);
	echo IS sil sil >> $(MKPHONESLED);
	echo DE sp >> $(MKPHONESLED);
	HLEd -d $(HTKDICT) -i $(PMLFFILE) $(MKPHONESLED) $(MLFFILE);

phonelists:
	voxforge/phones_from_mlf.py < $(PMLFFILE) > $(PHONELIST); \
	cp $(PHONELIST) $(PHONELIST_SP); \
	echo sp >> $(PHONELIST_SP);

monophones:
	for iter in {1,2,3}; do \
		source_dir=$(MODELDIR)/hmm`expr $${iter} '-' 1`; \
		target_dir=$(MODELDIR)/hmm$${iter}; \
		mkdir -p $${target_dir}; \
		$(HERESTBIN) -m 3 -A -T 1 -s $${target_dir}/stats -C common/config -I $(PMLFFILE) -t 250.0 150.0 2000.0 -S $(TRAINLOCALSCP) -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} $(PHONELIST);\
	done;

monophones_local:
	for iter in {1,2,3}; do \
		source_dir=$(MODELDIR)/hmm`expr $${iter} '-' 1`; \
		target_dir=$(MODELDIR)/hmm$${iter}; \
		mkdir -p $${target_dir}; \
		$(HTKBINDIR)/HERest -m 3 -A -T 1 -s $${target_dir}/stats -C common/config -I $(PMLFFILE) -t 250.0 150.0 2000.0 -S $(TRAINSCP) -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} $(PHONELIST) > $${target_dir}/herest.log;\
	done;

silsp:
	source_dir=$(MODELDIR)/hmm3; \
	target_dir=$(MODELDIR)/hmm4; \
	mkdir -p $${target_dir}; \
	final_target_dir=$(MODELDIR)/hmm5; \
	mkdir -p $${final_target_dir}; \
	perl scripts/DuplicateSilence.pl $${source_dir}/hmmdefs > $${target_dir}/hmmdefs; \
	cp $${source_dir}/macros $${target_dir}/macros; \
	$(HHEDBIN) -A -T 1 -H $${target_dir}/macros -H $${target_dir}/hmmdefs -M $${final_target_dir} voxforge/sil.hed $(PHONELIST_SP) > $${final_target_dir}/hhed_flat_sil.log

alignmlf: 
	source_dir=$(MODELDIR)/hmm5; \
	rm -f $${source_dir}/hvite_align.log $${source_dir}/hled_sp_sil.log; \
	$(HVITEBIN) -A -T 1 -o SWT -b silence -C common/config -a -H $${source_dir}/macros -H $${source_dir}/hmmdefs -i $${source_dir}/aligned.mlf -m -t 250.0 -I $(MLFLOCALFILE) -S $(TRAINLOCALSCP) $(HTKDICT) $(PHONELIST_SP) > $${source_dir}/hvite_align.log; \
	$(HLEDBIN) -A -T 1 -i $(ALIGNMLF) voxforge/merge_sp_sil.led $${source_dir}/aligned.mlf > $${source_dir}/hled_sp_sil.log;\
	cp $(TRAINLOCALSCP) $${source_dir}/train_temp.scp;\
	perl scripts/RemovePrunedFiles.pl $(ALIGNMLF) $${source_dir}/train_temp.scp > $(TRAINLOCALSCP);\
	cat $(TRAINLOCALSCP) | sed -e "s,$(LOCALFEATURESDIR),$(FEATURESDIR)," > $(TRAINSCP);


monophones_aligned_local: alignmlf
	cat $(ALIGNMLF) | sed -e "s,$(LOCALFEATURESDIR),$(FEATURESDIR)," > $(ALIGNLOCALMLF);\
	align_mlf=$(ALIGNLOCALMLF); \
	for iter in {6,7,8,9}; do \
		source_dir=$(MODELDIR)/hmm`expr $${iter} '-' 1`; \
		target_dir=$(MODELDIR)/hmm$${iter}; \
		mkdir -p $${target_dir}; \
		$(HTKBINDIR)/HERest -m 3 -A -T 1 -s $${target_dir}/stats -C common/config -I $${align_mlf} -t 250.0 150.0 2000.0 -S $(TRAINSCP) -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} $(PHONELIST_SP)> $${target_dir}/herest.log;\
	done;

prep_tri: monophones_aligned_local
	source_dir=$(MODELDIR)/hmm9; \
	target_dir=$(MODELDIR)/hmm10; \
	rm -f -r $${target_dir}/hled_make_tri.log $${target_dir}/mktri.hed $${target_dir}/hhed_clone_mono.log $${target_dir};\
	mkdir -p $(MODELDIR)/hmm10; \
	$(HLEDBIN) -A -T 1 -n $(TRIPHONELIST) -i $(LIBDIR)/wintri.mlf voxforge/mktri_cross.led $(ALIGNMLF) > $${target_dir}/hled_make_tri.log; \
	perl scripts/MakeClonedMono.pl $(PHONELIST_SP) $(TRIPHONELIST) > $${target_dir}/mktri.hed; \
	$(HHEDBIN) -A -T 1 -B -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} $${target_dir}/mktri.hed $(PHONELIST_SP) > $${target_dir}/hhed_clone_mono.log;

train_tri: prep_tri
	rm -rf $(MODELDIR)/hmm11 $(MODELDIR)/hmm12 $(MODELDIR)/hmm11/herest.log $(MODELDIR)/hmm12/herest.log; 
	cat $(LIBDIR)/wintri.mlf | sed -e "s,$(LOCALFEATURESDIR),$(FEATURESDIR)," > $(LIBDIR)/wintri_local.mlf;
	for iter in {11,12}; do \
		source_dir=$(MODELDIR)/hmm`expr $${iter} '-' 1`; \
		target_dir=$(MODELDIR)/hmm$${iter}; \
		mkdir -p $${target_dir}; \
		$(HTKBINDIR)/HERest -B -m 3 -A -T 1 -s $${target_dir}/stats -C common/config -I $(LIBDIR)/wintri_local.mlf -t 250.0 150.0 2000.0 -S $(TRAINSCP) -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} $(TRIPHONELIST)> $${target_dir}/herest.log;\
	done;
	cp $(MODELDIR)/hmm12/stats $(MODELDIR)/stats;

prep_tied: train_tri
	rm -rf $(MODELDIR)/hmm13 $(MODELDIR)/hhed_cluster.log $(MODELDIR)/fulllist $(MODELDIR)/tree.hed; 
	mkdir $(MODELDIR)/hmm13;
	perl scripts/CreateFullList.pl $(PHONELIST) > $(MODELDIR)/fulllist;
	echo "RO 200 $(MODELDIR)/stats" > $(MODELDIR)/tree.hed; 
	echo "TR 0" >> $(MODELDIR)/tree.hed;
	cat voxforge/tree_ques.hed >> $(MODELDIR)/tree.hed;
	echo "TR 12" >> $(MODELDIR)/tree.hed;
	perl scripts/MakeClusteredTri.pl TB 750 $(PHONELIST_SP) >> $(MODELDIR)/tree.hed;
	echo "TR 1" >> $(MODELDIR)/tree.hed;
	echo "AU \"$(MODELDIR)/fulllist\"">> $(MODELDIR)/tree.hed;
	echo "CO \"$(MODELDIR)/tiedlist\"">> $(MODELDIR)/tree.hed;
	echo "ST \"$(MODELDIR)/trees\"">> $(MODELDIR)/tree.hed;
	$(HHEDBIN) -A -T 1 -H $(MODELDIR)/hmm12/macros -H $(MODELDIR)/hmm12/hmmdefs -M $(MODELDIR)/hmm13 $(MODELDIR)/tree.hed $(TRIPHONELIST) > $(MODELDIR)/hhed_cluster.log;

train_tied: prep_tied
	rm -rf $(MODELDIR)/hmm14 $(MODELDIR)/hmm15 $(MODELDIR)/hmm16 $(MODELDIR)/hmm17; 
	for iter in {14,15,16,17}; do \
		source_dir=$(MODELDIR)/hmm`expr $${iter} '-' 1`; \
		target_dir=$(MODELDIR)/hmm$${iter}; \
		mkdir -p $${target_dir}; \
		$(HTKBINDIR)/HERest -B -m 3 -A -T 1 -s $${target_dir}/stats -C common/config -I $(LIBDIR)/wintri_local.mlf -t 250.0 150.0 2000.0 -S $(TRAINSCP) -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} $(TIEDLIST)> $${target_dir}/herest.log;\
	done;

mixup1: train_tied
	for i in {18..22}; do rm -rf hmm$${i}; done;
	# Mixup sil 1->2
	source_dir=$(MODELDIR)/hmm17;\
	target_dir=$(MODELDIR)/hmm18;\
	mkdir -p $${target_dir};\
	$(HHEDBIN) -B -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} voxforge/mix1.hed $(TIEDLIST) > $${target_dir}/hhed_mix1.log;
	for iter in {19..22}; do \
		source_dir=$(MODELDIR)/hmm`expr $${iter} '-' 1`; \
		target_dir=$(MODELDIR)/hmm$${iter}; \
		mkdir -p $${target_dir}; \
		$(HTKBINDIR)/HERest -B -m 3 -A -T 1 -s $${target_dir}/stats -C common/config -I $(LIBDIR)/wintri_local.mlf -t 250.0 150.0 2000.0 -S $(TRAINSCP) -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} $(TIEDLIST)> $${target_dir}/herest.log;\
	done;

mixup2:
	for i in {23..27}; do rm -rf hmm$${i}; done;
	# Mixup sil 2->4, 1->2
	source_dir=$(MODELDIR)/hmm22;\
	target_dir=$(MODELDIR)/hmm23;\
	mkdir -p $${target_dir};\
	$(HHEDBIN) -B -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} voxforge/mix2.hed $(TIEDLIST) > $${target_dir}/hhed_mix1.log;
	for iter in {24..27}; do \
		source_dir=$(MODELDIR)/hmm`expr $${iter} '-' 1`; \
		target_dir=$(MODELDIR)/hmm$${iter}; \
		mkdir -p $${target_dir}; \
		$(HTKBINDIR)/HERest -B -m 3 -A -T 1 -s $${target_dir}/stats -C common/config -I $(LIBDIR)/wintri_local.mlf -t 250.0 150.0 2000.0 -S $(TRAINSCP) -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} $(TIEDLIST)> $${target_dir}/herest.log;\
	done;

mixup4:
	for i in {28..32}; do rm -rf hmm$${i}; done;
	# Mixup sil 4->8, 2->4
	source_dir=$(MODELDIR)/hmm27;\
	target_dir=$(MODELDIR)/hmm28;\
	mkdir -p $${target_dir};\
	$(HHEDBIN) -B -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} voxforge/mix4.hed $(TIEDLIST) > $${target_dir}/hhed_mix1.log;
	for iter in {29..32}; do \
		source_dir=$(MODELDIR)/hmm`expr $${iter} '-' 1`; \
		target_dir=$(MODELDIR)/hmm$${iter}; \
		mkdir -p $${target_dir}; \
		$(HTKBINDIR)/HERest -B -m 3 -A -T 1 -s $${target_dir}/stats -C common/config -I $(LIBDIR)/wintri_local.mlf -t 250.0 150.0 2000.0 -S $(TRAINSCP) -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} $(TIEDLIST)> $${target_dir}/herest.log;\
	done;

mixup6:
	for i in {33..37}; do rm -rf hmm$${i}; done;
	# Mixup sil 8->12, 4->6
	source_dir=$(MODELDIR)/hmm32;\
	target_dir=$(MODELDIR)/hmm33;\
	mkdir -p $${target_dir};\
	$(HHEDBIN) -B -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} voxforge/mix6.hed $(TIEDLIST) > $${target_dir}/hhed_mix1.log;
	for iter in {34..37}; do \
		source_dir=$(MODELDIR)/hmm`expr $${iter} '-' 1`; \
		target_dir=$(MODELDIR)/hmm$${iter}; \
		mkdir -p $${target_dir}; \
		$(HTKBINDIR)/HERest -B -m 3 -A -T 1 -s $${target_dir}/stats -C common/config -I $(LIBDIR)/wintri_local.mlf -t 250.0 150.0 2000.0 -S $(TRAINSCP) -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} $(TIEDLIST)> $${target_dir}/herest.log;\
	done;

mixup8:
	# Mixup sil 12->16, 6->8
	source_dir=$(MODELDIR)/hmm37;\
	target_dir=$(MODELDIR)/hmm38;\
	mkdir -p $${target_dir};\
	$(HHEDBIN) -B -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} voxforge/mix8.hed $(TIEDLIST) > $${target_dir}/hhed_mix1.log;
	for iter in {39..42}; do \
		source_dir=$(MODELDIR)/hmm`expr $${iter} '-' 1`; \
		target_dir=$(MODELDIR)/hmm$${iter}; \
		mkdir -p $${target_dir}; \
		$(HTKBINDIR)/HERest -B -m 3 -A -T 1 -s $${target_dir}/stats -C common/config -I $(LIBDIR)/wintri_local.mlf -t 250.0 150.0 2000.0 -S $(TRAINSCP) -H $${source_dir}/macros -H $${source_dir}/hmmdefs -M $${target_dir} $(TIEDLIST)> $${target_dir}/herest.log;\
	done;

train_mixup: mixup1 mixup2 mixup4 mixup6 mixup8

train_lm:
	scripts/mlf2text.py $(MLFFILE) < $(TRAINSCP) > $(TRAINTEXT)
	ngram-count -order 3 -wbdiscount -unk -map-unk !!UNK -write-vocab $(WORDLIST) -lm $(LMFILE) -text $(TRAINTEXT)

test:
	scripts/wordprons.py $(HTKDICT) < $(WORDLIST) | sed -e "s/sp$$//"  > $(HTKDICT_NOSP)
	echo "</s> [] sil" >> $(HTKDICT_NOSP);
	echo "<s> [] sil" >> $(HTKDICT_NOSP);
	echo  "FORCEXTEXP=T" > common/asr.cfg;
	echo "ALLOWXWRDEXP=T" >> common/asr.cfg;
	echo "NONUMESCAPES=T" >> common/asr.cfg;
	mkdir -p $(LIBDIR)/results;
	cp $(TESTSCP) temp.scp;
	rm $(TESTSCP);
	test_dir=$(FEATURESDIR)/test;\
	mkdir -p $${test_dir}; \
	echo "#!MLF!#" > $(LIBDIR)/test.mlf;\
	for i in `cat temp.scp`; do \
		s=`echo $${i} | sed -e "s,$(FEATURESDIR)/*,," | sed -e "s,/,-,g"`; \
		l=`echo $${s} | sed -e "s,\.mfc,\.lab,"`; \
		echo \"*/$${l}\" >> $(LIBDIR)/test.mlf; \
		scripts/mlf2lab.py $${i} < $(MLFFILE) >> $(LIBDIR)/test.mlf; \
		echo "." >> $(LIBDIR)/test.mlf; \
		cp $${i} $${test_dir}/$${s}; \
		echo $${test_dir}/$$s >> $(TESTSCP);\
	done;
	rm temp.scp;
	HDecode -C common/asr.cfg -l $(LIBDIR)/results -t 250.0 -z lat -o S -p -4.0 -s 15.0 -H $(MODELDIR)/hmm42/hmmdefs -i $(LIBDIR)/test_results.mlf -H $(MODELDIR)/hmm42/macros -S $(TESTSCP) -w $(LMFILE) $(HTKDICT_NOSP) $(TIEDLIST)
	HResults -n -A -T 1 -I $(LIBDIR)/test.mlf $(TIEDLIST) $(LIBDIR)/test_results.mlf > $(LIBDIR)/test_results.res

	
