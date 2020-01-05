# Rácz, Beckner, Hay & Pierrehumbert 2019

Data and code for the paper "morphological convergence as on-line lexical analogy" 2019

## Contents

### Supplementary Information

The SI for the paper. The GCM and MGL sections are included in the paper as appendices.

### Data

- celex_verbs_with_categories_csv_fixed_moder -- Celex verbs with our categories
- convergence_paper_baseline_data -- Baseline data
- convergence_paper_esp_data -- Esp data (all)
- convergence_paper_esp_test2_predictions -- Esp data (post-test, w/ predictions)
- transcription_matcher -- differences between A&H and Celex transcription
- 256verbs_print_forms -- separate list of nonce verbs used in experiment

### Functions

- grabfunctions -- GCM written in R, with lookup table
- grabdata -- function to pull in data, used in other scripts

### Models

#### GCM

GCM with lookup table, in R. See gcm.Rmd

#### MGL

MGL rules for our data plus helper scripts. For MGL, visit Adam Albright's [page](http://www.mit.edu/~albright/mgl/). For a workflow summary, see MGL.md

#### Paper

Regression models reported in paper and in appendix. See convergence_paper_models.Rmd

## Data dictionary

### convergence_paper_baseline_data

Data from our baseline experiment. Column names:

- disc: disc transcription
- word: orthographic transcription
- subject: subject ID
- regular: is response regular (as opposed to irregular)
- yOB: year of birth of subject
- sex: sex of subject, self-identified (male/female/other or refuse to answer)
- vocab.av: subjects were given a vocabulary test based on (https://doi.org/10.1515/labphon.2010.018). this is the average score of the subject across the items
- baseline_gcm_features: Generalised Context Model (GCM) fit on celex, using segmental similarity, calculated across features (see appendix in paper)
- baseline_gcm_edits: GCM fit on celex, using simple edit distance
- baseline_mgl_features: Minimal Generalisation Learner (MGL) fit on celex, using minimal classes based on segmental features
- baseline_mgl_edits: MGL fit on celex, based on overlap and difference in segments

### convergence_paper_esp_data

This is the entire experiment: pre-test, esp test, post-test. Additional column names:

#### participant-level

- participant_id : subject
- gender : sex
- trial_index : participant progression through trials in test2
- overall_index : ~ through trials in entire experiment

#### word-level

- weak_past : weak past tense form of verb
- strong_past : strong ~
- category : verb category (see appendix)
- experiment-level
- reg_rate: rate of regularisation
- lex_typicality: lexical typicality
- list_block_order: which lists were used in which order for the participant
- response-level
- resp_pre_reg: regular response in pre-test by subject
- resp_esp_reg: regular response in esp test by subject
- resp_bot_reg: regular response in esp test by bot
- resp_post_reg: regular response in post-test by subject
- button1: button on left in trial
- button2: button on right in trial

### convergence_paper_esp_test2_predictions

Post-test data from our ESP experiment, along with model predictions. Additional column names:

#### word-level

- individual_gcm_features: GCM fit on Celex + bot responses in ESP phase, with features
- individual_gcm_edits: GCM fit on Celex + bot responses in ESP phase, without features
- individual_mgl_features: MGL fit on Celex + bot responses in ESP phase, with features
- individual_mgl_edits: MGL fit on Celex + bot responses in ESP phase, without features



