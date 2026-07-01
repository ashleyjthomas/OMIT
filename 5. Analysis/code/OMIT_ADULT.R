ipak <- function (pkg) {
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg)) 
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}
packages <- c("afex", "vcd", "ggplot2", "likert", "lattice", "pbkrtest", "reshape2", "car", "plyr", "MASS", "lme4",
              "effects", "lmerTest", "multcomp", "lsmeans", "Hmisc", "tidyr", "ordinal","brms","jtools","DHARMa","rstanarm","plyr","BayesFactor",
              "magrittr","ggeffects","sjmisc","splines","dplyr","tidyverse","bayestestR", "sjPlot", "parameters")
ipak(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

OMIT_Adult<-read.csv("OMIT-ADULT.csv")

###EDA####
head(OMIT_Adult)
tail(OMIT_Adult)
dim(OMIT_Adult)

hist(OMIT_Adult$nf_happy)

#but first demographics
OMIT_Adult$Q1 <-factor(OMIT_Adult$Q1,labels = c("Woman", "Man"))
levels(OMIT_Adult$Q1)
table(OMIT_Adult$Q1)

OMIT_A_Age <- OMIT_Adult$Q2
summary(OMIT_A_Age)
sd(OMIT_A_Age)

#####################CIRCLE MEASURE##################

OMIT_A_Long_circles<-gather(OMIT_Adult, condition, answer,circles_orin,circles_avery,circles_cameron,circles_riley)
write.csv(OMIT_A_Long_circles,"OMIT_A_Long_circles.csv")

OMIT_A_Long_circles<-read.csv("OMIT_A_Long_circles.csv")

###Warmup###
OMIT_A_Long_warmup<-gather(OMIT_Adult, condition, answer,warmup_1,warmup_2,warmup_3)
write.csv(OMIT_A_Long_warmup,"OMIT_A_Long_warmup.csv")


boxplot(OMIT_Adult$warmup_1, OMIT_Adult$warmup_2, OMIT_Adult$warmup_3,
        main = "Circle Warmup",
        names = c("Mom and Child", "Strangers", "Friends"),
        col = c("pink", "lightblue", "lightgreen"))

#data visualization for warmup trials
resultsWarmup <- ggplot(data = dplyr::filter(OMIT_A_Long_warmup), aes(x = condition, y = answer)) +
  geom_boxplot(outlier.shape = NA, fill = c("lightblue1", "orange", "lightgreen")) +
  geom_point(alpha = .5)  +
  geom_line(aes(group = PROLIFIC_PID), alpha = .1, linetype = 1) +
  xlab("Trial") + ylab("Rating of Social Distance      ") +
  stat_summary(fun = mean, alpha = 1, geom = "point", 
               shape = 21, size = 3, colour = "black", fill = "white") +  
  labs(title = "Warmup") +
  scale_y_continuous(breaks = seq(1, 6, 1), limits = c(1, 7.5)) +
  theme(
    legend.position = "none",
    panel.background = element_rect(fill = "white"),
    axis.line = element_line(colour = "darkgrey", linewidth = .5),
    axis.title.y = element_text(margin = margin(0, 30, 0, 0), size = 14),   
    axis.title.x = element_text(size = 12),                                
    axis.text.x = element_text(size = 14),                                  
    axis.text.y = element_text(size = 14),                                  
    plot.title = element_text(size = 18, face = "bold")                     
  )
resultsWarmup


#Bayesian model
set.seed(123)
xfit1 <- brm (answer~condition_HS*condition_EF + (1|PROLIFIC_PID), data = OMIT_A_Long_circles, family='cumulative',save_pars = save_pars(all = TRUE), iter= 3000, warmup= 1000, thin= 1,chains=4)
xfit2 <- brm (answer~condition_HS+condition_EF + (1|PROLIFIC_PID), data = OMIT_A_Long_circles, family='cumulative',save_pars = save_pars(all = TRUE), iter= 3000, warmup= 1000, thin= 1,chains=4)

xfit1 <- brm (answer~condition_2 + (1|PROLIFIC_PID), data = OMIT_A_Long_sharing2, family='cumulative',save_pars = save_pars(all = TRUE), iter= 3000, warmup= 1000, thin= 1,chains=4)

bayes_factor(xfit1,xfit2)

plot(rope(xfit1,range=c(-0.1, 0.1)))

(rope(xfit1,range=c(-0.1, 0.1)))
summary(xfit1)
parameters(xfit1)

#sad condition
OMIT_A_circsad_long<- OMIT_Adult %>%
  pivot_longer(cols = c(circles_orin, circles_avery), 
               names_to = "condition", 
               values_to = "rating") %>%
  mutate(condition = case_when(
    condition == "circles_orin" ~ "Fact", 
    condition == "circles_avery" ~ "Emotion"
  ))


ggplot(OMIT_A_circsad_long, aes(x = condition, y = answer)) +
  geom_boxplot(aes(fill = condition), outlier.shape = NA) +  
  geom_jitter(aes(color = condition), width = 0.1, alpha = 0.7) +  
  geom_line(aes(group = PROLIFIC_PID), alpha = 0.4, linetype = 1, color = "black") +  
  stat_summary(fun = mean, geom = "point", shape = 21, size = 3, color = "black", fill = "white") + 
  labs(title = "Social Overlap (Sad Condition)", 
       x = "", y = "Rating of Social Distance") +
  scale_fill_manual(values = c("lightblue", "lightgreen")) +  
  scale_color_manual(values = c("black", "black")) +  
  theme_minimal() +  
  theme(
    legend.position = "none", 
    panel.background = element_rect(fill = "white"),
    axis.line = element_line(colour = "grey", size = 0.25),
    axis.title.x = element_text(size = 20),  
    axis.title.y = element_text(size = 20, margin = margin(0, 30, 0, 0)), 
    axis.text.x = element_text(size = 18),  
    axis.text.y = element_text(size = 18),  
    plot.title = element_text(size = 16, face = "bold")  
    
    
  #####NEW FRIEND#####
  
  OMIT_A_Long_NewFriend<-gather(OMIT_Adult, condition, answer,nf_sad,nf_happy)
  
  write.csv(OMIT_A_Long_NewFriend,"OMIT_A_Long_New_Friend.csv")
  
  OMIT_A_Long_NewFriend<-read.csv("OMIT_A_Long_New_Friend.csv")
  
  OMIT_Long_NewFriend$ID<-factor(OMIT_Long_NewFriend$ID)
  OMIT_Long_NewFriend$AgeYears<-factor(OMIT_Long_NewFriend$AgeYears)
  
  analysis<-glmer(answer~condition+AgeYears+(1|ID), family=binomial(link="logit"), data=OMIT_Long_NewFriend)
  
  analysis0<-glmer(answer~AgeYears+Sex+(1|ID), family=binomial(link="logit"), data=OMIT_Long_NewFriend)
  
  
  analysis02<-glmer(answer~condition+(1|PROLIFIC_PID), family=binomial(link="logit"), data=OMIT_A_Long_NewFriend)
  
  #Check to see if model adheres to assumptions using DHARMa
  simulationOutput <- simulateResiduals(fittedModel = xfit1)
  plot(simulationOutput)
  
  
  #summary of the data per condition
  cdata <- ddply(OMIT_A_Long_NewFriend, c("condition"), summarise,
                 N    = sum(!is.na(answer)),
                 mean = mean(answer, na.rm=TRUE),
                 sd   = sd(answer, na.rm=TRUE),
                 se   = sd / sqrt(N)
  )
  
  cdata  
  
  
pp_check(xfit1)
  
  #using a bayesian approach with the same model...
  
  #full model
  set.seed(123)
  xfit1 <- brm (answer~condition + (1|PROLIFIC_PID), data = OMIT_A_Long_NewFriend, family='bernoulli',save_all_pars = TRUE, iter= 3000, warmup= 1000, thin= 1,chains=4)
  xfit0 <- brm (answer~condition*AgeYears + (1|ID), data = OMIT_Long_NewFriend, family='bernoulli',save_all_pars = TRUE, iter= 3000, warmup= 1000, thin= 1,chains=4)
  
  
  plot(rope(xfit1))
  rope(xfit1)
  
  #model without condition
  xfit2 <- brm (answer~ AgeYears+ (1|ID), data = OMIT_Long_NewFriend, family='bernoulli',save_all_pars = TRUE, iter= 110000, warmup= 1000, thin= 4)
  
  #model without age
  xfit3<-brm (answer~condition + (1|ID), data = OMIT_Long_NewFriend, family='bernoulli',save_all_pars = TRUE, iter= 110000, warmup= 1000, thin= 4)
  
  #has the model converged? Check the Rhat, and should havehairy plots, Bulk ESS should be over 5,000
  summary(xfit1)
  
  #getting 95% credible intervals
  me<-(conditional_effects(xfit1,effects=NULL,prob=c(.025,.975)))
  me<-(conditional_effects(xfit0,effects=NULL,probs=c(.025,.975)))
  
  str(me)
  
  #plot 95% credible intervals
  x<-plot(me, plot = FALSE)[[1]] +
    scale_color_grey() +
    scale_fill_grey()
  
  x+ylim(0,1)+
    
    theme(panel.grid.major = element_line(colour="gray"), panel.grid.minor = element_blank(),
          panel.background = element_blank(), axis.line = element_blank(),panel.grid.major.x = element_blank())+xlab("")+ylab("")
  
  #Calculating Bayes Factors for effects
  bayes_factor(xfit1,xfit2)
  bayes_factor(xfit1,xfit3)
  bayes_factor(xfit1,xfit0)
  
  
  model_parameters(xfit1)
  rope(xfit1)
  plot(rope(xfit1))
  
  
  mcmc_areas(
    xfit1,
    regex_pars = "b_",
    prob = 0.89, 
    point_est = "median",
    area_method = "equal height"
  ) +
    geom_vline(xintercept = 0, color = "red", alpha = 0.6, lwd = .8, linetype = "dashed") +
    labs(
      title = "Effect of Condition on Answers"
    )
 
  

  ##Binomial test for new friend
  x <- sum(OMIT_Adult$nf_sad)
  binom.test(x = x, n = 47, p = 0.5)
  x <- sum(OMIT_Adult$nf_happy)
  binom.test(x = x, n = 47, p = 0.5)
  
  #Data visualization for new friend
  OMIT_Adult$nf_sad <- factor(OMIT_Adult$nf_sad, labels = c("Fact", "Emotion"))
  OMIT_Adult$nf_happy <- factor(OMIT_Adult$nf_happy, labels = c("Fact","Emotion"))
  
  
  table(OMIT_Adult$nf_sad)
  table(OMIT_Adult$nf_happy)
  
  newfriend <- matrix(c(24,22,
                        24,23),
                      ncol = 2, byrow = T)
  rownames(newfriend) <- c("Sad", "Happy")
  colnames(newfriend) <- c("Fact", "Emotion")
  newfriend.d <- as.data.frame(newfriend)
  newfriend.d$Trial <- c("Sad", "Happy")
  newfriend.dm <- melt(newfriend.d, id.vars = c('Trial'))
  names(newfriend.dm) <- c("Trial", "Target", "Freq")
  newfriend.dm$Trial <- as.factor(newfriend.dm$Trial)
  newfriend.dm$Trial <- relevel(newfriend.dm$Trial, "Sad")
  
  resultsNF <- ggplot(newfriend.dm, aes(Trial, Freq)) + #   
    geom_bar(aes(fill = Target), position = "fill", stat="identity", color = "grey25") +
    scale_fill_manual(values = c("lavenderblush", "orchid")) +
    theme(
      legend.position = "bottom", 
      panel.background = element_rect(fill = "white"),        
      plot.title = element_text(margin = margin(0,0,30,0), size = 16, face = "bold"),  # Increase title size and make bold
      axis.line = element_line(colour = "grey", size = .25),
      axis.title.x = element_text(size = 14),  # Increase x-axis title size
      axis.title.y = element_text(size = 22, margin = margin(0, 30, 0, 0)),  # Increase y-axis title size
      axis.text.x = element_text(size = 20),  # Increase x-axis labels size
      axis.text.y = element_text(size = 20),  # Increase y-axis labels size
      legend.text = element_text(size = 20),  # Increase legend label size
      legend.title = element_text(size = 14)  # Increase legend title size
    ) +  
    guides(fill = guide_legend(nrow = 2)) +
    geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
    xlab("") +
    ylab("Proportion of Judgments")
  
  resultsNF
  
plot(allEffects(xfit1, type = "pred"))
  
###################################BETTER FRIEND###############################
  

  
#full model

OMIT_A_Long_BetterFriend<-gather(OMIT_Adult, condition, answer,sad_bf,happy_bf)

write.csv(OMIT_A_Long_BetterFriend,"OMIT_A_Long_BetterFriend.csv")

OMIT_A_Long_BetterFriend<-read.csv("OMIT_A_Long_BetterFriend.csv")
set.seed(123)
xfit1 <- brm (answer~condition + (1|PROLIFIC_PID), data = OMIT_A_Long_BetterFriend, family='bernoulli',save_all_pars = TRUE, iter= 3000, warmup= 1000, thin= 1,chains=4)
summary(xfit1)
mcmc_areas(
  xfit1,
  regex_pars = "b_",
  prob = 0.89, 
  point_est = "median",
  area_method = "equal height"
) +
  geom_vline(xintercept = 0, color = "red", alpha = 0.6, lwd = .8, linetype = "dashed") +
  labs(
    title = "Effect of Condition on Answers"
  )

plot(rope(xfit1))
rope(xfit1)
summary(xfit1)
model_parameters(xfit1)

##Binomial test for new friend
x <- sum(OMIT_Adult$sad_bf)
binom.test(x = x, n = 47, p = 0.5)
x <- sum(OMIT_Adult$happy_bf)
binom.test(x = x, n = 47, p = 0.5)


#Data visualization for better friend
OMIT_Adult$sad_bf <- factor(OMIT_Adult$sad_bf, labels = c("Fact", "Emotion"))
OMIT_Adult$happy_bf <- factor(OMIT_Adult$happy_bf, labels = c("Fact","Emotion"))


table(OMIT_Adult$sad_bf)
table(OMIT_Adult$happy_bf)

betterfriend <- matrix(c(4,43,
                      9,38),
                    ncol = 2, byrow = T)
rownames(betterfriend) <- c("Sad", "Happy")
colnames(betterfriend) <- c("Fact", "Emotion")
betterfriend.d <- as.data.frame(betterfriend)
betterfriend.d$Trial <- c("Sad", "Happy")
betterfriend.dm <- melt(betterfriend.d, id.vars = c('Trial'))
names(betterfriend.dm) <- c("Trial", "Target", "Freq")
betterfriend.dm$Trial <- as.factor(betterfriend.dm$Trial)
betterfriend.dm$Trial <- relevel(betterfriend.dm$Trial, "Sad")

resultsBF <- ggplot(betterfriend.dm, aes(Trial, Freq)) + #   
  geom_bar(aes(fill = Target), position = "fill", stat="identity", color = "grey25") +
  scale_fill_manual(values = c("honeydew", "forestgreen")) +
  theme(
    legend.position = "bottom", 
    panel.background = element_rect(fill = "white"),        
    plot.title = element_text(margin = margin(0,0,30,0), size = 16, face = "bold"),  # Increase title size and make bold
    axis.line = element_line(colour = "grey", size = .25),
    axis.title.x = element_text(size = 14),  # Increase x-axis title size
    axis.title.y = element_text(size = 22, margin = margin(0, 30, 0, 0)),  # Increase y-axis title size
    axis.text.x = element_text(size = 20),  # Increase x-axis labels size
    axis.text.y = element_text(size = 20),  # Increase y-axis labels size
    legend.text = element_text(size = 20),  # Increase legend label size
    legend.title = element_text(size = 0)  # Increase legend title size
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsBF


########################################PARENT SHARING##################################################

OMIT_A_Long_mom<-gather(OMIT_Adult, condition, answer,mom_sad,mom_happy,friendmom_sad,friendmom_happy)

write.csv(OMIT_A_Long_mom,"OMIT_A_Long_mom.csv")
#in excel make two columns for item and emotion shared

OMIT_A_Long_mom<-read.csv("OMIT_A_Long_mom.csv")

#full model
set.seed(123)
xfit1 <- brm (answer~relationship*condition + (1|PROLIFIC_PID), data = OMIT_A_Long_mom, family='bernoulli',save_all_pars = TRUE, iter= 3000, warmup= 1000, thin= 1,chains=4)
xfit2 <- brm (answer~relationship*condition + (1|PROLIFIC_PID), data = OMIT_A_Long_mom, family='bernoulli',save_all_pars = TRUE, iter= 3000, warmup= 1000, thin= 1,chains=4)
model_parameters(xfit1)
summary(xfit1)
rope(xfit1)

mcmc_areas(
  xfit1,
  regex_pars = "b_",
  prob = 0.89, 
  point_est = "median",
  area_method = "equal height"
) +
  geom_vline(xintercept = 0, color = "red", alpha = 0.6, lwd = .8, linetype = "dashed") +
  labs(
    title = "Effect of Condition on Answers"
  )
rope(xfit1)

fixef(xfit1)

OMIT_A_Long_mom$condition <- relevel(OMIT_A_Long_mom$condition, ref = "happy")
OMIT_A_Long_mom$relationship <- relevel(OMIT_A_Long_mom$relationship, ref = "mom")

xfit1 <- brm(answer ~ relationship * condition + (1 | PROLIFIC_PID), data = OMIT_A_Long_mom, family = 'bernoulli')

OMIT_A_Long_mom$condition <- relevel(factor(OMIT_A_Long_mom$condition), ref = "happy")
OMIT_A_Long_mom$relationship <- relevel(factor(OMIT_A_Long_mom$relationship), ref = "friendmom")


#Data visualization for better friend
OMIT_Adult$sad_bf <- factor(OMIT_Adult$sad_bf, labels = c("Fact", "Emotion"))
OMIT_Adult$happy_bf <- factor(OMIT_Adult$happy_bf, labels = c("Fact","Emotion"))


table(OMIT_Adult$mom_sad)
table(OMIT_Adult$mom_happy)


mom <- matrix(c(10,37,
                        16 ,31),
                       ncol = 2, byrow = T)
rownames(mom) <- c("Sad", "Happy")
colnames(mom) <- c("Fact", "Emotion")
mom.d <- as.data.frame(mom)
mom.d$Trial <- c("Sad", "Happy")
mom.dm <- melt(mom.d, id.vars = c('Trial'))
names(mom.dm) <- c("Trial", "Target", "Freq")
mom.dm$Trial <- as.factor(mom.dm$Trial)
mom.dm$Trial <- relevel(mom.dm$Trial, "Sad")

resultsMOM <- ggplot(mom.dm, aes(Trial, Freq)) + #   
  geom_bar(aes(fill = Target), position = "fill", stat="identity", color = "grey25") +
  scale_fill_manual(values = c("lightyellow", "chocolate")) +
  theme(
    legend.position = "bottom", 
    panel.background = element_rect(fill = "white"),        
    plot.title = element_text(margin = margin(0,0,30,0), size = 16, face = "bold"),  # Increase title size and make bold
    axis.line = element_line(colour = "grey", size = .25),
    axis.title.x = element_text(size = 14),  # Increase x-axis title size
    axis.title.y = element_text(size = 22, margin = margin(0, 30, 0, 0)),  # Increase y-axis title size
    axis.text.x = element_text(size = 20),  # Increase x-axis labels size
    axis.text.y = element_text(size = 20),  # Increase y-axis labels size
    legend.text = element_text(size = 20),  # Increase legend label size
    legend.title = element_text(size = 0)  # Increase legend title size
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsMOM




table(OMIT_Adult$friendmom_sad)
table(OMIT_Adult$friendmom_happy)

fmom <- matrix(c(38,9,
                34 ,13),
              ncol = 2, byrow = T)
rownames(fmom) <- c("Sad", "Happy")
colnames(fmom) <- c("Fact", "Emotion")
fmom.d <- as.data.frame(fmom)
fmom.d$Trial <- c("Sad", "Happy")
fmom.dm <- melt(fmom.d, id.vars = c('Trial'))
names(fmom.dm) <- c("Trial", "Target", "Freq")
fmom.dm$Trial <- as.factor(fmom.dm$Trial)
fmom.dm$Trial <- relevel(fmom.dm$Trial, "Sad")

resultsFMOM <- ggplot(fmom.dm, aes(Trial, Freq)) + #   
  geom_bar(aes(fill = Target), position = "fill", stat="identity", color = "grey25") +
  scale_fill_manual(values = c("lightyellow", "chocolate")) +
  theme(
    legend.position = "bottom", 
    panel.background = element_rect(fill = "white"),        
    plot.title = element_text(margin = margin(0,0,30,0), size = 16, face = "bold"),  # Increase title size and make bold
    axis.line = element_line(colour = "grey", size = .25),
    axis.title.x = element_text(size = 14),  # Increase x-axis title size
    axis.title.y = element_text(size = 22, margin = margin(0, 30, 0, 0)),  # Increase y-axis title size
    axis.text.x = element_text(size = 20),  # Increase x-axis labels size
    axis.text.y = element_text(size = 20),  # Increase y-axis labels size
    legend.text = element_text(size = 20),  # Increase legend label size
    legend.title = element_text(size = 0)  # Increase legend title size
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsFMOM


##############################FOOD SHARING#######################
OMIT_A_Long_sharing<-gather(OMIT_Adult, condition, answer,sad_ice_cream,sad_candy, happy_ice_cream, happy_candy)

write.csv(OMIT_A_Long_sharing,"OMIT_A_Long_sharing.csv")
#in excel make two columns for item and emotion shared

OMIT_A_Long_sharing<-read.csv("OMIT_A_Long_sharing.csv")

set.seed(123)
xfit1 <- brm (answer~condition*item + (1|PROLIFIC_PID), data = OMIT_A_Long_sharing, family='bernoulli',save_all_pars = TRUE)
summary(xfit1)
model_parameters(xfit1)
rope(xfit1)

OMIT_Long_sharing2<-read.csv(file="OMIT_A_Long_sharing_adults.csv")

xfit2 <- brm (answer~condition_2 + (1|PROLIFIC_PID), data = OMIT_Long_sharing2, family='bernoulli',save_all_pars = TRUE)
summary(xfit2)
model_parameters(xfit2)
rope(xfit2)

model_parameters(OMIT_Long_sharing2$condition_2)
OMIT_A_Long_sharing$condition <- relevel(OMIT_A_Long_sharing$condition, ref = "happy")
OMIT_A_Long_sharing$item <- relevel(OMIT_A_Long_sharing$item, ref = "candy")

#ice cream#
table(OMIT_Adult$sad_ice_cream)
table(OMIT_Adult$happy_ice_cream)

icecream <- matrix(c(6,41,
                     10,37),
                   ncol = 2, byrow = T)
rownames(icecream) <- c("Sad", "Happy")
colnames(icecream) <- c("Fact", "Emotion")
icecream.d <- as.data.frame(icecream)
icecream.d$Trial <- c("Sad", "Happy")
icecream.dm <- melt(icecream.d, id.vars = c('Trial'))
names(icecream.dm) <- c("Trial", "Target", "Freq")
icecream.dm$Trial <- as.factor(icecream.dm$Trial)
icecream.dm$Trial <- relevel(icecream.dm$Trial, "Sad")

resultsICE <- ggplot(icecream.dm, aes(Trial, Freq)) + #   
  geom_bar(aes(fill = Target), position = "fill", stat="identity", color = "grey25") +
  scale_fill_manual(values = c("peachpuff", "maroon")) +
  theme(
    legend.position = "bottom", 
    panel.background = element_rect(fill = "white"),        
    plot.title = element_text(margin = margin(0,0,30,0), size = 16, face = "bold"),  
    axis.line = element_line(colour = "grey", size = .25),
    axis.title.x = element_text(size = 14),  
    axis.title.y = element_text(size = 22, margin = margin(0, 30, 0, 0)),  
    axis.text.x = element_text(size = 20),  
    axis.text.y = element_text(size = 20),  
    legend.text = element_text(size = 20),  
    legend.title = element_text(size = 0)  
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsICE

#candy
table(OMIT_Adult$sad_candy)
table(OMIT_Adult$happy_candy)

candy <- matrix(c(21,26,
                  27,20),
                ncol = 2, byrow = T)
rownames(candy) <- c("Sad", "Happy")
colnames(candy) <- c("Fact", "Emotion")
candy.d <- as.data.frame(candy)
candy.d$Trial <- c("Sad", "Happy")
candy.dm <- melt(candy.d, id.vars = c('Trial'))
names(candy.dm) <- c("Trial", "Target", "Freq")
candy.dm$Trial <- as.factor(candy.dm$Trial)
candy.dm$Trial <- relevel(candy.dm$Trial, "Sad")

resultsCANDY <- ggplot(candy.dm, aes(Trial, Freq)) + #   
  geom_bar(aes(fill = Target), position = "fill", stat="identity", color = "grey25") +
  scale_fill_manual(values = c("peachpuff", "maroon")) +
  theme(
    legend.position = "bottom", 
    panel.background = element_rect(fill = "white"),        
    plot.title = element_text(margin = margin(0,0,30,0), size = 16, face = "bold"),
    axis.line = element_line(colour = "grey", size = .25),
    axis.title.x = element_text(size = 14),  
    axis.title.y = element_text(size = 22, margin = margin(0, 30, 0, 0)),  
    axis.text.x = element_text(size = 20),  
    axis.text.y = element_text(size = 20),  
    legend.text = element_text(size = 20),  
    legend.title = element_text(size = 0)  
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsCANDY

model_2<-brms(answer~condition_2
              
              

##########################OMIT2#######################################################
OMIT2_Adult<-read.csv("OMIT2_ADULT.csv")

###EDA####
head(OMIT2_Adult)
tail(OMIT2_Adult)
dim(OMIT2_Adult)

#but first demographics
OMIT2_Adult$Gender <-factor(OMIT2_Adult$Gender,labels = c("Woman", "Man"))
levels(OMIT2_Adult$Gender)
table(OMIT2_Adult$Gender)

OMIT_A_Age <- OMIT_Adult$Q2
summary(OMIT_A_Age)
sd(OMIT_A_Age)


#######New Best Friend##########


##Binomial test for new best friend
x <- sum(OMIT2_Adult$nbf_sad)
binom.test(x = x, n = 49, p = 0.5)
x <- sum(OMIT2_Adult$nbf_happy)
binom.test(x = x, n = 49, p = 0.5)

#Data visualization for new friend
OMIT2_Adult$nbf_sad <- factor(OMIT2_Adult$nbf_sad, labels = c("Fact", "Emotion"))
OMIT2_Adult$nbf_happy <- factor(OMIT2_Adult$nbf_happy, labels = c("Fact","Emotion"))


table(OMIT2_Adult$nbf_sad)
table(OMIT2_Adult$nbf_happy)

newfriend <- matrix(c(41,8,
                      33,16),
                    ncol = 2, byrow = T)
rownames(newfriend) <- c("Sad", "Happy")
colnames(newfriend) <- c("Fact", "Emotion")
newfriend.d <- as.data.frame(newfriend)
newfriend.d$Trial <- c("Sad", "Happy")
newfriend.dm <- melt(newfriend.d, id.vars = c('Trial'))
names(newfriend.dm) <- c("Trial", "Target", "Freq")
newfriend.dm$Trial <- as.factor(newfriend.dm$Trial)
newfriend.dm$Trial <- relevel(newfriend.dm$Trial, "Sad")

resultsNF <- ggplot(newfriend.dm, aes(Trial, Freq)) + #   
  geom_bar(aes(fill = Target), position = "fill", stat="identity", color = "grey25") +
  scale_fill_manual(values = c("lavenderblush", "orchid")) +
  theme(
    legend.position = "bottom", 
    panel.background = element_rect(fill = "white"),        
    plot.title = element_text(margin = margin(0,0,30,0), size = 16, face = "bold"),  # Increase title size and make bold
    axis.line = element_line(colour = "grey", size = .25),
    axis.title.x = element_text(size = 14),  # Increase x-axis title size
    axis.title.y = element_text(size = 22, margin = margin(0, 30, 0, 0)),  # Increase y-axis title size
    axis.text.x = element_text(size = 20),  # Increase x-axis labels size
    axis.text.y = element_text(size = 20),  # Increase y-axis labels size
    legend.text = element_text(size = 20),  # Increase legend label size
    legend.title = element_text(size = 14)  # Increase legend title size
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsNF


#############Friend vs. Best Friend#######


##Binomial test for friend and best friend

# happy condition
x <- sum(OMIT2_Adult$Friend_happy)
binom.test(x = x, n = 49, p = 0.5)
x <- sum(OMIT2_Adult$BF_happy)
binom.test(x = x, n = 49, p = 0.5)

# sad condition
x <- sum(OMIT2_Adult$Friend_sad)
binom.test(x = x, n = 49, p = 0.5)
x <- sum(OMIT2_Adult$BF_sad)
binom.test(x = x, n = 49, p = 0.5)

#Data visualization for friend and best friend

# best friend 
OMIT2_Adult$BF_happy <- factor(OMIT2_Adult$BF_happy, labels = c("Fact", "Emotion"))
OMIT2_Adult$BF_sad <- factor(OMIT2_Adult$BF_sad, labels = c("Fact","Emotion"))

#friend
OMIT2_Adult$Friend_happy <- factor(OMIT2_Adult$Friend_happy, labels = c("Fact", "Emotion"))
OMIT2_Adult$Friend_sad <- factor(OMIT2_Adult$Friend_sad, labels = c("Fact","Emotion"))


table(OMIT2_Adult$BF_happy)
table(OMIT2_Adult$BF_sad)



bestfriend <- matrix(c(14,35,
                      33,16),
                    ncol = 2, byrow = T)
rownames(bestfriend) <- c("Sad", "Happy")
colnames(bestfriend) <- c("Fact", "Emotion")
bestfriend.d <- as.data.frame(bestfriend)
bestfriend.d$Trial <- c("Sad", "Happy")
bestfriend.dm <- melt(bestfriend.d, id.vars = c('Trial'))
names(bestfriend.dm) <- c("Trial", "Target", "Freq")
bestfriend.dm$Trial <- as.factor(bestfriend.dm$Trial)
bestfriend.dm$Trial <- relevel(bestfriend.dm$Trial, "Sad")

resultsBF <- ggplot(bestfriend.dm, aes(Trial, Freq)) + #   
  geom_bar(aes(fill = Target), position = "fill", stat="identity", color = "grey25") +
  scale_fill_manual(values = c("lavenderblush", "hotpink3")) +
  theme(
    legend.position = "bottom", 
    panel.background = element_rect(fill = "white"),        
    plot.title = element_text(margin = margin(0,0,30,0), size = 16, face = "bold"),  # Increase title size and make bold
    axis.line = element_line(colour = "grey", size = .25),
    axis.title.x = element_text(size = 14),  # Increase x-axis title size
    axis.title.y = element_text(size = 22, margin = margin(0, 30, 0, 0)),  # Increase y-axis title size
    axis.text.x = element_text(size = 20),  # Increase x-axis labels size
    axis.text.y = element_text(size = 20),  # Increase y-axis labels size
    legend.text = element_text(size = 20),  # Increase legend label size
    legend.title = element_text(size = 14)  # Increase legend title size
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsBF


# friend

table(OMIT2_Adult$Friend_sad)
table(OMIT2_Adult$Friend_happy)


friend <- matrix(c(21,28,
                       33,16),
                     ncol = 2, byrow = T)
rownames(friend) <- c("Sad", "Happy")
colnames(friend) <- c("Fact", "Emotion")
friend.d <- as.data.frame(friend)
friend.d$Trial <- c("Sad", "Happy")
friend.dm <- melt(friend.d, id.vars = c('Trial'))
names(friend.dm) <- c("Trial", "Target", "Freq")
friend.dm$Trial <- as.factor(friend.dm$Trial)
friend.dm$Trial <- relevel(friend.dm$Trial, "Sad")

resultsF <- ggplot(friend.dm, aes(Trial, Freq)) + #   
  geom_bar(aes(fill = Target), position = "fill", stat="identity", color = "grey25") +
  scale_fill_manual(values = c("lavenderblush", "hotpink2")) +
  theme(
    legend.position = "bottom", 
    panel.background = element_rect(fill = "white"),        
    plot.title = element_text(margin = margin(0,0,30,0), size = 16, face = "bold"),  # Increase title size and make bold
    axis.line = element_line(colour = "grey", size = .25),
    axis.title.x = element_text(size = 14),  # Increase x-axis title size
    axis.title.y = element_text(size = 22, margin = margin(0, 30, 0, 0)),  # Increase y-axis title size
    axis.text.x = element_text(size = 20),  # Increase x-axis labels size
    axis.text.y = element_text(size = 20),  # Increase y-axis labels size
    legend.text = element_text(size = 20),  # Increase legend label size
    legend.title = element_text(size = 14)  # Increase legend title size
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsF


#########Parent Sharing#####

OMIT2_Adult$mom_happy <- factor(OMIT2_Adult$mom_happy, labels = c("Fact", "Emotion"))
OMIT2_Adult$mom_sad <- factor(OMIT2_Adult$mom_sad, labels = c("Fact","Emotion"))


table(OMIT2_Adult$mom_sad)
table(OMIT2_Adult$mom_happy)


mom <- matrix(c(29,20,
                27 ,22),
              ncol = 2, byrow = T)
rownames(mom) <- c("Sad", "Happy")
colnames(mom) <- c("Fact", "Emotion")
mom.d <- as.data.frame(mom)
mom.d$Trial <- c("Sad", "Happy")
mom.dm <- melt(mom.d, id.vars = c('Trial'))
names(mom.dm) <- c("Trial", "Target", "Freq")
mom.dm$Trial <- as.factor(mom.dm$Trial)
mom.dm$Trial <- relevel(mom.dm$Trial, "Sad")

resultsMOM <- ggplot(mom.dm, aes(Trial, Freq)) + #   
  geom_bar(aes(fill = Target), position = "fill", stat="identity", color = "grey25") +
  scale_fill_manual(values = c("lightyellow", "salmon")) +
  theme(
    legend.position = "bottom", 
    panel.background = element_rect(fill = "white"),        
    plot.title = element_text(margin = margin(0,0,30,0), size = 16, face = "bold"),  # Increase title size and make bold
    axis.line = element_line(colour = "grey", size = .25),
    axis.title.x = element_text(size = 14),  # Increase x-axis title size
    axis.title.y = element_text(size = 22, margin = margin(0, 30, 0, 0)),  # Increase y-axis title size
    axis.text.x = element_text(size = 20),  # Increase x-axis labels size
    axis.text.y = element_text(size = 20),  # Increase y-axis labels size
    legend.text = element_text(size = 20),  # Increase legend label size
    legend.title = element_text(size = 0)  # Increase legend title size
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsMOM



OMIT2_Adult$friendmom_sad <- factor(OMIT2_Adult$friendmom_sad, labels = c("Fact", "Emotion"))
OMIT2_Adult$friendmom_happy <- factor(OMIT2_Adult$friendmom_happy, labels = c("Fact","Emotion"))


table(OMIT2_Adult$friendmom_sad)
table(OMIT2_Adult$friendmom_happy)

fmom <- matrix(c(35,14,
                 33 ,16),
               ncol = 2, byrow = T)
rownames(fmom) <- c("Sad", "Happy")
colnames(fmom) <- c("Fact", "Emotion")
fmom.d <- as.data.frame(fmom)
fmom.d$Trial <- c("Sad", "Happy")
fmom.dm <- melt(fmom.d, id.vars = c('Trial'))
names(fmom.dm) <- c("Trial", "Target", "Freq")
fmom.dm$Trial <- as.factor(fmom.dm$Trial)
fmom.dm$Trial <- relevel(fmom.dm$Trial, "Sad")

resultsFMOM <- ggplot(fmom.dm, aes(Trial, Freq)) + #   
  geom_bar(aes(fill = Target), position = "fill", stat="identity", color = "grey25") +
  scale_fill_manual(values = c("lightyellow", "salmon2")) +
  theme(
    legend.position = "bottom", 
    panel.background = element_rect(fill = "white"),        
    plot.title = element_text(margin = margin(0,0,30,0), size = 16, face = "bold"),  # Increase title size and make bold
    axis.line = element_line(colour = "grey", size = .25),
    axis.title.x = element_text(size = 14),  # Increase x-axis title size
    axis.title.y = element_text(size = 22, margin = margin(0, 30, 0, 0)),  # Increase y-axis title size
    axis.text.x = element_text(size = 20),  # Increase x-axis labels size
    axis.text.y = element_text(size = 20),  # Increase y-axis labels size
    legend.text = element_text(size = 20),  # Increase legend label size
    legend.title = element_text(size = 0)  # Increase legend title size
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsFMOM

