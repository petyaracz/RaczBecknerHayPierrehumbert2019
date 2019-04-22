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
