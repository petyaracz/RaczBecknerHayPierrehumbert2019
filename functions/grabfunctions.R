###########################################################################
# GCM functions
###########################################################################

# get similarity from whatever distance you choose to use
getSimilarity = function(feature.distance, var_s, var_p){#the def values in the paper
  pairwise.similarity = exp ( -feature.distance / var_s )^var_p 
  return(pairwise.similarity)
}

# set up GCM training thing as in paper

baselineGCMpaperSetup = function(lookup){
# first thing we need to do is restrict training set to moder verbs in celex.
  target.verbs = unique(lookup$target)

  baseline.gcm.paper = lookup %>% 
    filter(
      !training %in% target.verbs,
      moder.target == moder.training # we only keep comparisons to training verbs in the same moder class
    )

return(baseline.gcm.paper)
}

# fit GCM where regular class has ordinary regular verbs
baselineGCMreviewerSetup = function(lookup){

  target.verbs = unique(lookup$target)

  baseline.gcm.reviewer1 = lookup %>% 
    filter(
      !training %in% target.verbs, # no need for these
      moder.training == moder.target # we compare target verbs to real verbs in their category...
    )

  baseline.gcm.reviewer2 = lookup %>% 
    filter(
      is.na(moder.training) & category.training == 'regular'
    ) %>% 
    mutate(
      moder.training = moder.target # each "other" regular occurs with each target. all we need to do is flag it as belonging to the target's class.
    )

  baseline.gcm.reviewer = rbind(baseline.gcm.reviewer1, baseline.gcm.reviewer2)
  
return(baseline.gcm.reviewer)
}

# fit GCM on custom lookup table made by previous function
# for each verb class
#   for each target
#     sum over total
#     sum over regular
#     sum over irregular
#     get similarity to class

doGCM = function(restricted.set,gcm.id, var_s, var_p){
# this function expects a lookup table where each target is matched with all relevant training words.
# training words are regular or irregular.
  restricted.set = restricted.set %>% 
    mutate(
      f.pairwise.similarity = getSimilarity(feature.distance, var_s = var_s, var_p = var_p)
    )
  
  restricted.set = restricted.set %>% 
    group_by(target) %>% 
    mutate(
      f.total.similarity = sum(f.pairwise.similarity)
    )
  
  restricted.set = restricted.set %>% 
    group_by(
      target, 
      category.training
    ) %>% 
    mutate(
      f.summed.pairwise.similarity = sum(f.pairwise.similarity),
      # then we get gcm weight of category per target
      f.weight = f.summed.pairwise.similarity / f.total.similarity
    ) %>% 
    ungroup() # and how
  
  # restricted.set[restricted.set$target == 'JIm',] %>% select(-moder.target,-moder.training,category.training,-training.type) %>% View
  
  restricted.set = restricted.set %>% 
    select(target, f.weight, category.training) %>% 
    filter(category.training == 'regular') %>% 
    select(
      target,
      f.weight
    ) %>% 
    rename(
      disc = target,
      # baseline_gcm_wf_lookup_moder = f.weight
    ) %>% 
    distinct()


# naming trick    
colnames(restricted.set)[colnames(restricted.set) == 'f.weight'] = gcm.id

return(restricted.set)  
}

# tune S
tuneS = function(lookup, var_s = 0.3, var_p = 1){
  
  lookup$f.pairwise.similarity = NULL
  lookup$f.pairwise.similarity = getSimilarity(lookup$feature.distance, var_s = var_s, var_p = var_p)  
  
  baseline.gcm.reviewer = baselineGCMreviewerSetup(lookup)

  baseline.gcm.reviewer = doGCM(restricted.set = baseline.gcm.reviewer, gcm.id = 'whatever', var_s = var_s, var_p = var_p)

return(baseline.gcm.reviewer)
}

# ...get R

getR = function(baseline.gcm.reviewer, baseline.verbs){  
  
  baseline.verbs$whatever = NULL # in case I'm an idiot
  baseline.verbs = left_join(baseline.verbs, baseline.gcm.reviewer, by = 'disc')
  
  r.val = with(baseline.verbs, cor(reg.av, whatever))
  
return(r.val)
}

getC = function(baseline.gcm.reviewer, baseline){  

  baseline$whatever = NULL # in case I'm an idiot
  baseline = left_join(baseline, baseline.gcm.reviewer, by = 'disc')
  
  C.val = with(baseline, Hmisc::somers2(whatever, regular)['C'])

return(C.val)
}

# fit gcm on person
runGuyLookup = function(espdata, lookup, gcm.id, my.participant_id, var_s, var_p){
  ## the test side of things
  esp.test.verbs = espdata %>%
    filter(
      participant_id == my.participant_id,
      phase == 'test2'
      ) %>% 
    select(
      disc,
      moder
      )
  
  ## test-training pairs for celex training
    
  from.lexicon = baselineGCMreviewerSetup(lookup = lookup)
  from.lexicon = from.lexicon %>% 
    filter(target %in% esp.test.verbs$disc)
  
  ## test-training pairs for esp training
  esp.training.verbs = espdata %>%
    filter(
      participant_id == my.participant_id,
      phase == 'esp'
      ) %>% 
    mutate(category = ifelse(resp_bot_reg==T, 'regular', 'irregular')) %>%
    select(
      disc,
      moder,
      category
      ) %>% 
    rename(
      training = disc,
      category.training = category,
      moder.training = moder
    )
  
  from.esp = lookup %>% 
    filter(
      training.type == 'esp',
      target %in% esp.test.verbs$disc,
      training %in% esp.training.verbs$training
      )
  
  # nrow(from.esp) == 52*52 # n esp trials n test2 trials
  
  from.esp$category.training = NULL
  
  from.esp = left_join(from.esp, esp.training.verbs, by = c('training', 'moder.training'))
  
  # nrow(from.esp) == 52*52 # n esp trials n test2 trials
  
  ## and we combine them
  
  custom.lookup = rbind(from.lexicon, from.esp)
  
  participant.output = doGCM(restricted.set = custom.lookup, gcm.id = gcm.id, var_s = var_s, var_p = var_p)
  
  participant.output$participant_id = my.participant_id
  
  return(participant.output)
}

###########################################################################
# MGL functions
###########################################################################

## functions

# takes in read-in tsv, returns list of verbs with conf of regular form
getMGLRules <- function(output){
  
  output2 = output %>% 
    mutate(
      past.form = sub("»", "", form2),
      present.form = sub("»", "", form1),
      alternation = paste0(A,X8,B),
      environment = paste0(P,X15,Q)
    ) %>% 
    rename(
      related_forms = `related forms`
    )
  
  output2 = output2 %>% 
    select(
      present.form,
      past.form,
      alternation,
      Pres,
      Pfeat,
      environment,
      Qfeat,
      Qres,
      scope,
      hits,
      reliability,
      confidence,
      related_forms,
      exceptions
    )
  
  foc.dat = left_join(output2, verb_handles, by = 'present.form')
  
  
  foc.irreg.rules = subset(foc.dat, as.character(past.form) == as.character(irregular.form))
  foc.reg.rules = subset(foc.dat, as.character(past.form) == as.character(regular.form))
  foc.irreg.rules = subset(foc.irreg.rules, !duplicated(present.form))
  foc.reg.rules = subset(foc.reg.rules, !duplicated(present.form))
  
  foc.irreg.rules$rule_type = 'irregular'
  foc.reg.rules$rule_type = 'regular'
  
  regular.rules = foc.reg.rules %>% 
    select(
      present.form,
      reliability,
      confidence,
      category,
      base.print
    ) %>% 
    rename(
      reg.rel = reliability, 
      reg.conf = confidence
    )
  
  irregular.rules = foc.irreg.rules %>% 
    select(
      present.form,
      reliability,
      confidence,
      category,
      base.print
    ) %>% 
    rename(
      ir.rel = reliability, 
      ir.conf = confidence
    )
  
  rules = full_join(regular.rules,irregular.rules, by = c("present.form", "category", "base.print"))
  
  rules = rules %>% 
    mutate(
      ir.conf = ifelse(is.na(ir.conf), 0, ir.conf),
      indiv_mgl_conf = reg.conf / (reg.conf + ir.conf)
    ) %>% 
    select(present.form,indiv_mgl_conf)
  return(rules)
}

### example
# output = read_tsv('models/mgl/esp_mgl_by_hand_features_2/input_part1.sum')
# out = getMGLRules(output)

## getting data from everybody

### no features

getNoFeatures = function(participant_handles){
  
  participant_handles = participant_handles %>% 
    mutate(
      individual_mgl_edits_raw = map(participant, ~ read_tsv(
        paste0(
          'models/mgl/esp_mgl_no_features/input_part', ., '.sum'
        )  
      )
      )
    )
  
  # participant_handles$individual_mgl_edits_raw[[1]]
  
  participant_handles = participant_handles %>% 
    mutate(
      individual_mgl_edits = map(individual_mgl_edits_raw, ~ getMGLRules(.))
    )
  
  # this scoping is quite something
  
  # participant_handles$individual_mgl_edits[[1]]
  # participant 6030 == indiv 1 and test nonce verbs check out
  
  participant_handles = participant_handles %>% 
    select(
      participant_id,
      individual_mgl_edits
    ) %>% 
    unnest(cols = c(individual_mgl_edits)) %>% 
    rename(
      individual_mgl_edits = indiv_mgl_conf
    )
  
  return(participant_handles)
}

### with features

getWithFeatures = function(participant_handles){
  
  participant_handles = participant_handles %>% 
    mutate(
      individual_mgl_features_raw = map(participant, ~ read_tsv(
        paste0(
          'models/mgl/esp_mgl_by_hand_features_2/input_part', ., '.sum'
        )  
      )
      )
    )
  
  # participant_handles$individual_mgl_features_raw[[1]]
  
  participant_handles = participant_handles %>% 
    mutate(
      individual_mgl_features = map(individual_mgl_features_raw, ~ getMGLRules(.))
    )
  
  # this scoping is quite something
  
  # participant_handles$individual_mgl_features[[1]]
  # participant 6030 == indiv 1 and test nonce verbs check out
  
  participant_handles = participant_handles %>% 
    select(
      participant_id,
      individual_mgl_features
    ) %>% 
    unnest(cols = c(individual_mgl_features)) %>% 
    rename(
      individual_mgl_features = indiv_mgl_conf
    )
  
  return(participant_handles)
}