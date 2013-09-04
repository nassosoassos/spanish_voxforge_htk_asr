#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  build_back_lm.pl
#
#        USAGE:  ./build_back_lm.pl  
#
#  DESCRIPTION:  Build the background language model for the couple therapy data.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Nassos Katsamanis (NK), nkatsam@sipi.usc.edu
#      COMPANY:  University of Southern California
#      VERSION:  1.0
#      CREATED:  08/17/2010 02:21:19 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use File::Spec::Functions;
use SailTools::SailComponent;

my $root_dir = "/home/work/MoS";
my $text_source = catfile($root_dir, "library", "mos_all_plist_source_text_clean.txt");
my $back_lm = catfile($root_dir, "library", "background.lm");
my $frequent_back_words_list = catfile($root_dir, "library", "back_words_sorted.list");
my $final_word_list = catfile($root_dir, "library", "mos_unique_clean_words_back.list");
my $word_list = catfile($root_dir, "library", "mos_unique_clean_words.list");
my $mos_lm = catfile($root_dir, "library", "mos_all_trigrams_clean.lm");
my $out_lm = catfile($root_dir, "library", "mos_all_trigrams_clean_back.lm");

my $N_words = 100;
# First find a list of the N_words most frequent word
open(FWL, "$frequent_back_words_list") or die("Cannot open list of most frequent words");
my @freq_words = <FWL>;
chomp(@freq_words);
close(FWL);
my @sel_freq_words = @freq_words[0..($N_words-1)];

my %lm_cfg = (
        order => 3,
        kndiscount3 => '',
        kndiscount2 => '',
        kndiscount1 => '',
        lm => $mos_lm,
        "write-vocab" => $word_list,
        text => $text_source,
);

my $options = SailTools::SailComponent::sprint_otosense_config(\%lm_cfg);
my $cmd = "ngram-count $options";
print $cmd."\n";
system($cmd);

if ($N_words>0) {
  # Add the background lm words in the word list
  open(FWL,">$final_word_list") or die("Cannot open $final_word_list for writing.");
  open(WL,"$word_list") or die("Cannot open $word_list for reading.");
  my @lm_words = <WL>;
  chomp(@lm_words);
  my %word_map;
  for my $w (@lm_words,@sel_freq_words) {
      $word_map{$w}++;
  }
  my @uniq = sort keys(%word_map);
  print FWL join("\n",@uniq);
  close(WL);
  close(FWL);
}
else {
    $final_word_list = $word_list;
}

# Mixing with background model
my %mix_lm_cfg = (
        order => $lm_cfg{order},
        lambda => 0.05,
        "limit-vocab" => '',
        vocab => $final_word_list,
        "mix-lm" => $mos_lm,
        lm => $back_lm,
        "write-lm" => $out_lm,
);

$options = SailTools::SailComponent::sprint_otosense_config(\%mix_lm_cfg);
$cmd = "ngram $options";
print $cmd."\n";
system($cmd);
