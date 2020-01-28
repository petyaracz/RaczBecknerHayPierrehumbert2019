######################################################################
# training set
######################################################################

celex = read_csv('~/Github/RaczBecknerHayPierrehumbert2019/data/celex_verbs_with_categories_csv_fixed_moder.txt')

celex = celex %>% 
  select(
    present.o,
    present,
    moder,
    regular
  ) %>% 
  rename(
    word = present.o,
    disc.old = present
  ) %>%
  mutate(
    category = case_when(
      regular == 'Y' ~ 'regular',
      regular == 'N' ~ 'irregular'
    )
  )  %>% 
  filter(!is.na(category))

# fixing transcription

transcription.matcher = read_csv('~/Github/RaczBecknerHayPierrehumbert2019/data/transcription_matcher.txt')

celex = left_join(celex, transcription.matcher)

# celex[celex$disc == 'riN',]

######################################################################
# test set
######################################################################

baseline = read_csv('~/Github/RaczBecknerHayPierrehumbert2019/data/convergence_paper_baseline_data.txt')

# esp data
espdata = read_csv('~/Github/RaczBecknerHayPierrehumbert2019/data/convergence_paper_esp_data.txt')

# esp only post-test with gcm weights
test2 = read_csv('~/Github/RaczBecknerHayPierrehumbert2019/data/convergence_paper_esp_test2_predictions.txt')

