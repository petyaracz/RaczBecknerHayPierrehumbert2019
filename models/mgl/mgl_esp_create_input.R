library(Hmisc)
# library(dplyr)
# library(stringr)
# library(knitr)
library(lme4)
library(RePsychLing)
library(tidyverse)
setwd('~/Github/RaczBecknerHayPierrehumbert2019/')

# MGL batch run doesn't pull in features. this has to be done by hand. 
# I don't want to run 222 participants by hand.
# Experiment regularisation rate, lexical typicality and list block order create the possible training + test data combinations for the individual MGL-s. 
# Individual participants will move round slightly more but this is a reasonable approximation (and still takes hours)
# I can pick the unique combinations of reg rate + lex typ + list_block_order and run one participant each.
# this doesn't cover all participants, since 

esp <- read_csv('data/convergence_paper_esp_data.txt') %>% filter(phase == 'test2')

participants <- esp %>% select(participant_id,reg_rate,lex_typicality,list_block_order) %>% unique %>% arrange(reg_rate,lex_typicality,list_block_order) %>% mutate(part_type = paste(reg_rate, lex_typicality, list_block_order, sep = ' ')) %>% select(participant_id,part_type)
participants <- participants[!duplicated(participants$part_type),]
handles <- read.csv("data/participanthandles.txt")
participants <- merge(participants,handles)

# now I paste the relevant participants' in files into inputlists_wf_minimal

# now I run the Minimal Generalisation Learner on each, 

# you have to quit the program EVERY TIME after you fit an individual file, otherwise it doesn't work.

# this works: turn mingenlearner off and on again every time, set lower and upper to 55 95 every time.

# I check every sum file to see if it specifies a set of segments for P environment. that is indicative of features being used. (length of fit is also indicative: with features it takes a noticable amount of time, w/o it fits almost instantly)
# close mgl. check sum output for features. open mgl. set 55 and 95. select next in. run. takes about 50 sec to fit.

# This takes a couple hours.

# I gather predictions.

# participants2 <- participants %>% filter(participant < 100)
# includedparticipants <- handles %>% filter(participant_id %in% participants2$participant_id)
includedparticipants <- handles %>% filter(participant_id %in% participants$participant_id)


getResPostTestMod <- function(dirname,includedparticipants){

handles <- read.delim("data/256verbs_print_forms.txt", sep=",") %>% select(base.form,category,base.print,regular.form,irregular.form) %>% rename(present.form = base.form)
# get formatting right
handles$irregular.form <- sub("5","o",handles$irregular.form)
handles$regular.form <- sub("Id","@d",handles$regular.form)
# includedparticipants <- read.delim("~/Work/NZILBB/convergence_esp/categorisation_models/albrighthayes2espwf/restwf/participanthandles.txt",sep=",")
includedparticipants <- unique(includedparticipants)


output.list <- as.list(NA)

# loops through participant numbers and creates a nice csv output for each and then writes it into a file. so we end up with lots of files. 

# you can use the code in the loop to process an individual output file
ii = 1
for (i in includedparticipants$participant){
output <- read.delim(paste(dirname, "/input_part",i,".sum",sep=""),sep="\t", header=F)

output2 <- output

output2$past.form <- sub("»", "", output2$V5)
output2$present.form <- sub("»", "", output2$V3)

output2$alternation <- paste(as.character(output2$V7),as.character(output2$V8),as.character(output2$V9), sep="")
output2$Pres <- output2$V12
output2$Pfeat <- output2$V13
output2$environment <- paste(as.character(output2$V14),as.character(output2$V15),as.character(output$V16), sep = ' ')
output2$Qfeat <- output2$V17
output2$Qres <- output2$V18
output2$scope <- output2$V19
output2$hits <- output2$V20
# output2$rule2 <- paste(as.character(output2$rule),as.character(output2$structural_description), sep= ' / ')
output2$reliability <- as.numeric(as.character(output2$V21))
output2$confidence <- as.numeric(as.character(output2$V22))
output2$related_forms <- output2$V23
output2$exceptions <- output2$V24

# output2$past.form <- output2$V5
# output2$present.form <- output2$V3
# It does the thing where it inserts an onset-rhyme boundary marker

output3 <- output2[,c("present.form","past.form","alternation","Pres","Pfeat","environment","Qfeat","Qres","scope","hits","reliability","confidence","related_forms","exceptions")]
output3 <- output3[-1,]

output3 <- output3[order(-output3$confidence),]

foc.dat <- merge(output3,handles)

foc.dat <- foc.dat[order(-foc.dat$confidence),]
foc.dat <- foc.dat[order(foc.dat$present.form),]

foc.irreg.rules <- subset(foc.dat, as.character(past.form) == as.character(irregular.form))
foc.reg.rules <- subset(foc.dat, as.character(past.form) == as.character(regular.form))
foc.irreg.rules <- subset(foc.irreg.rules, !duplicated(present.form))
foc.reg.rules <- subset(foc.reg.rules, !duplicated(present.form))

foc.irreg.rules$rule_type <- 'irregular'
foc.reg.rules$rule_type <- 'regular'

# handles[!(handles$base.print %in% foc.irreg.rules$base.print),]
# handles[!(handles$base.print %in% foc.reg.rules$base.print),]

regular.rules <- foc.reg.rules %>% select(present.form,reliability,confidence,category,base.print) %>% rename(reg.rel = reliability, reg.conf = confidence)
irregular.rules <- foc.irreg.rules %>% select(present.form,reliability,confidence,category,base.print) %>% rename(ir.rel = reliability, ir.conf = confidence)

rules <- merge(regular.rules,irregular.rules, all = T)

rules <- rules %>% mutate(ir.conf = ifelse(is.na(ir.conf), 0, ir.conf)) %>% mutate(indiv_mgl_conf_wf = reg.conf / (reg.conf + ir.conf)) %>% select(present.form,indiv_mgl_conf_wf)
rules$participant <- i
output.list[[ii]] <- rules
ii = ii + 1
print(i)
}

output.df <- do.call('rbind', output.list)
# 52*222 # checks out

output.df <- merge(output.df,includedparticipants) %>% select(-participant)

return(output.df)
}

# warnings are nothing to worry about
esp_mini_wf <- getResPostTestMod("esp_mgl_by_hand_features",includedparticipants)
esp_mini_wf <- esp_mini_wf %>% rename(disc = present.form, dec_esp_mgl_wf = indiv_mgl_conf_wf)

esp_mini_wf <- merge(esp_mini_wf, participants)
esp_mini_wf <- esp_mini_wf %>% select(-participant_id,-participant)

# I merge this with the esp master file:

esp <- read.csv('data/convergence_paper_esp_data.txt')
# esp_mini <- esp %>% mutate(part_type = paste(reg_rate, lex_typicality, list_block_order, sep = ' ')) %>% filter(part_type %in% participants2$part_type)
esp2 <- esp %>% mutate(part_type = paste(reg_rate, lex_typicality, list_block_order, sep = ' '))
# esp_mini <- merge(esp_mini,esp_mini_wf)
esp2 <- merge(esp2, esp_mini_wf)

###############################################################
# Do we lose information by not fitting the MGL on all participants?
###############################################################

# let's fit a simple model to see how predictions match with actual post-test behaviour.
# we do this for the entire data (fit1/fit2)
# we do this for the participants where the MGL was hand-fit (fit1b/fit2b)

test2 = read_csv('data/convergence_paper_esp_test2_predictions.txt')

test2b = test2[test2$participant_id %in% participants$participant_id,]

# a simple model of how predictions match post-test behaviour on the entire data

fit1 = glmer(resp_post_reg ~ 1 + 
    baseline_mgl_features + 
    baseline_gcm_features + 
    individual_mgl_features + 
    individual_gcm_features + 
    (1 | participant_id) + (1|word), 
  family = binomial, data = test2, control=glmerControl(optimizer="bobyqa")
  )
summary(fit1)

# a simple model of how predictions match post-test behaviour on the participants fit

fit1b = glmer(resp_post_reg ~ 1 + 
    baseline_mgl_features + 
    baseline_gcm_features + 
    individual_mgl_features + 
    individual_gcm_features + 
    (1 | participant_id) + (1|word), 
  family = binomial, data = test2b, control=glmerControl(optimizer="bobyqa")
  )
summary(fit1b)

# comparison models

fit2 = glmer(resp_post_reg ~ 1 + 
    baseline_mgl_features + 
    # baseline_gcm_features +
    # individual_mgl_features + 
    individual_gcm_features + 
    (1 | participant_id) + (1|word), 
  family = binomial, data = test2, control=glmerControl(optimizer="bobyqa")
  )
summary(fit2)

fit2b = glmer(resp_post_reg ~ 1 + 
    baseline_mgl_features + 
    # baseline_gcm_features + 
    # individual_mgl_features + 
    individual_gcm_features + 
    (1 | participant_id) + (1|word), 
  family = binomial, data = test2b, control=glmerControl(optimizer="bobyqa")
  )
summary(fit2b)

anova(fit1,fit2)
anova(fit1b,fit2b)

# even for the hand-picked participants, the individual MGL doesn't explain additional variation.