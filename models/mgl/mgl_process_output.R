library(tidyverse)
library(purrr)
setwd('~/Github/RaczBecknerHayPierrehumbert2019/')

## functions

source('~/Github/RaczBecknerHayPierrehumbert2019/functions/grabfunctions.R')

## data

test2 = read_csv('~/Github/RaczBecknerHayPierrehumbert2019/data/convergence_paper_esp_test2_predictions.txt')

espdata = read_csv('~/Github/RaczBecknerHayPierrehumbert2019/data/convergence_paper_esp_data.txt')
baseline = read_csv('~/Github/RaczBecknerHayPierrehumbert2019/data/convergence_paper_baseline_data.txt')

participant_handles = read_csv('~/Github/RaczBecknerHayPierrehumbert2019/data/participanthandles.txt')

verb_handles = read_csv("~/Github/RaczBecknerHayPierrehumbert2019/data/256verbs_print_forms.txt") %>% 
  select(
    base.form,
    category,
    base.print,
    regular.form,
    irregular.form
    ) %>% 
  rename(present.form = base.form) %>% 
  mutate(
    irregular.form = str_replace_all(irregular.form, "5","o"),
    regular.form = str_replace_all(regular.form, "Id","@d")
  )

############# run everything #############################

mgl_baseline_rules_raw = read_tsv('~/Github/RaczBecknerHayPierrehumbert2019/models/mgl/baseline_mgl/CELEXFull3.sum')
mgl_baseline_rules = getMGLRules(mgl_baseline_rules_raw)

write_tsv(mgl_baseline_rules, '~/Github/RaczBecknerHayPierrehumbert2019/models/mgl/baseline_mgl/baseline_rules_features.tsv')

participant_handles_edits = getNoFeatures(participant_handles)
participant_handles_features = getWithFeatures(participant_handles)

participant_handles_edits = participant_handles_edits %>% 
  rename(disc = present.form)

participant_handles_features = participant_handles_features %>% 
  rename(disc = present.form)

test2 = test2 %>% 
  select(
    -individual_mgl_edits,
    -individual_mgl_features
  ) %>% 
  left_join(
    participant_handles_features, by = c("disc", "participant_id")
  ) %>% 
  left_join(
    participant_handles_edits, by = c("disc", "participant_id")
  )

mgl_baseline_rules = mgl_baseline_rules %>% 
  rename(
    disc = present.form,
    baseline_mgl_features = indiv_mgl_conf
  )

test2 = test2 %>% 
  select(
    - baseline_mgl_edits
  ) %>% 
  left_join(mgl_baseline_rules, by = c("disc", "baseline_mgl_features"))

espdata = espdata %>% 
  select(
    - baseline_mgl_edits
  ) %>% 
  left_join(mgl_baseline_rules, by = c("disc", "baseline_mgl_features"))

baseline = baseline %>% 
  select(
    - baseline_mgl_edits
  ) %>% 
  left_join(mgl_baseline_rules, by = c("disc", "baseline_mgl_features"))

