# code to process an MGL sum file

library(dplyr)
library(stringr)
library(knitr)


handles <- read.delim("256verbs_print_forms.txt", sep=",") %>% select(base.form,category,base.print,regular.form,irregular.form) %>% rename(present.form = base.form)
# get formatting right
handles$irregular.form <- sub("5","o",handles$irregular.form)
handles$regular.form <- sub("Id","@d",handles$regular.form)


getMGLRules <- function(output){
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

rules <- rules %>% mutate(ir.conf = ifelse(is.na(ir.conf), 0, ir.conf)) %>% mutate(indiv_mgl_conf = reg.conf / (reg.conf + ir.conf)) %>% select(present.form,indiv_mgl_conf)
return(rules)
}