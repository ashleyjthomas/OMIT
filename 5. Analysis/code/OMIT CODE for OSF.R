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
####Study 1

#If starting from scratch for Study 1: Do children think that people who disclose emotions are the better friend that people who disclose facts?
OMIT<-read.csv("OMIT_data_1.9.25.csv")

#but first demographics
OMIT$Sex <-factor(OMIT$Sex)
levels(OMIT$Sex)
table(OMIT$Sex)

OMITAge <- OMIT$AgeYears + OMIT$AgeMonths/12 + OMIT$AgeDays/(12*30)
summary(OMITAge)
sd(OMITAge)
OMIT_demo <-read.csv("OMIT_demo.csv")
OMIT_demo$Child.Race <-factor(OMIT_demo$Child.Race)
table(OMIT_demo$Child.Race)
levels(OMIT_demo$Child.Race)
barplot(table(OMIT_demo$Child.Race))
OMIT_demo$Education.1<-factor(OMIT_demo$Education.1)
OMIT_demo$Education.2<-factor(OMIT_demo$Education.2)
table(OMIT_demo$Education.1, OMIT_demo$Education.2)
table(OMIT_demo$Education.1)
table(OMIT_demo$Education.2)
#this is where you change the data to 'long' format. This is to analyze 'BetterFriend'

OMIT_Long_BetterFriend<-gather(OMIT, condition, answer, Better_Friend_sad, Better_Friend_happy)
#no need to make new columns for the two conditions

#this is where you change the data to 'long' format. This is to analyze the circle measure
OMIT_Long_circles<-gather(OMIT, condition, answer,Circles_emo_h,Circles_emo_s,Circles_fact_h,Circles_fact_s)
write.csv(OMIT_Long_circles,"OMIT_Long_circles.csv")


# Edit the CSV outside of R (select column, go to 'data', go to 'text to columns' then do 
#dilineated with an '_' rename the columns as condition_EF (for whether its emotion or fact) 
#and condition_HS (happy or sad) so that you have one column for whether its an emotion or a fact and one column for whether its happy or sad
OMIT_Long_circles<-read.csv("OMIT_Long_circles.csv")

##circle warmup
OMIT_Long_warmup<-gather(OMIT, condition, answer,Mom_and_Child,Strangers,Friends)
write.csv(OMIT_Long_warmup,"OMIT_Long_warmup.csv")

OMIT_Long_warmup<- read.csv("OMIT_Long_warmup.csv")

###warmup model
set.seed(123)
xfit0 <- brm (answer~condition + (1|ID), data = OMIT_Long_warmup, family='cumulative',save_pars = save_pars(all = TRUE), iter= 3000, warmup= 1000, thin= 1,chains=4)

summary(xfit0)

plot(rope(xfit0,range=c(-0.1, 0.1)))

(rope(xfit0,range=c(-0.1, 0.1)))

conditional_effects(xfit0, categorical = TRUE)
conditional_effects(xfit0, cumulative = TRUE)
model_parameters(xfit0)

mean(OMIT$Mom_and_Child)
mean(OMIT$Strangers)
mean(OMIT$Friends)


#data visualization for warmup trials
resultsWarmup <- ggplot(data = dplyr::filter(OMIT_Long_warmup), aes(x = condition, y = answer)) +
  geom_boxplot(outlier.shape = NA, fill = c("lightblue1", "orange", "lightgreen")) +
  geom_point(alpha = .5)  +
  geom_line(aes(group = ID), alpha = .1, linetype = 1) +
  xlab("Trial") + ylab("Rating of Social Distance      ") +
  stat_summary(fun = mean, alpha = 1, geom = "point", 
               shape = 21, size = 3, colour = "black", fill = "white") +  
  labs(title = "Warmup") +
  scale_y_continuous(breaks = seq(1, 6, 1), limits = c(1, 7.5)) +
  theme(
    legend.position = "none",
    panel.background = element_rect(fill = "white"),
    axis.line = element_line(colour = "darkgrey", size = .5),
    axis.title.y = element_text(margin = margin(0, 30, 0, 0), size = 14),   
    axis.title.x = element_text(size = 12),                                
    axis.text.x = element_text(size = 14),                                  
    axis.text.y = element_text(size = 14),                                  
    plot.title = element_text(size = 18, face = "bold")                     
  )
resultsWarmup
#####BEST FRIEND ANALYSIS FOR STUDY 1####
#Now we will analyze Best Friend to ask whether happy or sad made a difference. 

#1 is emotion 0 is fact

#glm to investigate the effects of condition on children's answers

analysis<-glmer(answer~condition+(1|ID), family=binomial(link="logit"), OMIT_Long_BetterFriend)

summary(analysis)
confint(analysis)
exp(fixef(analysis))

https://cran.r-project.org/web/packages/ggeffects/vignettes/introduction_randomeffects.html
pr <- ggpredict(analysis, "condition",type="fixed")
plot(pr)
pr


#Check to see if model adheres to assumptions using DHARMa
simulationOutput <- simulateResiduals(fittedModel = analysis)
plot(simulationOutput)

#summary of the data per condition
cdata <- ddply(OMIT_Long_BetterFriend, c("condition"), summarise,
               N    = sum(!is.na(answer)),
               mean = mean(answer, na.rm=TRUE),
               sd   = sd(answer, na.rm=TRUE),
               se   = sd / sqrt(N)
)

cdata              


#using a bayesian approach with the same model...

#brm (https://bayesat.github.io/lund2018/slides/andrey_anikin_slides.pdf) https://babieslearninglanguage.blogspot.com/2018/02/mixed-effects-models-is-it-time-to-go.html
priors <- c(
  set_prior("normal(0, 10)", class = "b"),          # Fixed effects
  set_prior("cauchy(0, 2)", class = "sd"))
#full model
set.seed(123)
xfit1 <- brm(
  formula = bf(answer ~ condition + (1 | ID), autocor = cor_ar(p = 1)),  
  data = OMIT_Long_BetterFriend,
  family = bernoulli(),                              
  prior = set_prior("normal(0, 10)", class = "b"),   
  save_pars = save_pars(all = TRUE),                 
  iter = 3000,                                       
  warmup = 1000,                                     
  chains = 4,                                        
  cores = parallel::detectCores()                    
)


plot(rope(xfit1))

#null model without condition
set.seed(123)
xfit2 <- brm (answer~ (1|ID), data = OMIT_Long_BetterFriend, family='bernoulli', save_pars = save_pars(all = TRUE), iter= 110000, warmup= 1000, thin= 4)

#model without age
#xfit3<-brm (answer~condition + (1|ID), data = OMIT_Long_BetterFriend, family='bernoulli',save_all_pars = TRUE, iter= 110000, warmup= 1000, thin= 4)

#has the model converged? Check the Rhat, and should havehairy plots, Bulk ESS should be over 5,000
summary(xfit1)

#getting 95% credible intervals
me<-(conditional_effects(xfit1,effects=NULL)

str(me)

#plot 95% credible intervals
data <- data.frame(
  x = rnorm(100),
  y = rnorm(100),
  group = factor(sample(1:2, 100, replace = TRUE))
)

x <- ggplot(data, aes(x = x, y = y, color = group, fill = group)) +
  geom_point() +          
  scale_color_grey() +    
  scale_fill_grey() +     
  theme_minimal()   
x

#effects plot
plot_model(xfit1)

x+ylim(0,1)+
  
  theme(panel.grid.major = element_line(colour="gray"), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_blank(),panel.grid.major.x = element_blank())+xlab("")+ylab("")

#Calculating Bayes Factors for effects of condition
bayes_factor(xfit1,xfit2)

#Rope Method with package to test for effects of condition
plot(rope(xfit1))
rope(xfit1)
pd1b <-p_direction(xfit1)
pd1b
median(xfit1)
summary(xfit1)
names(OMIT_Long_circles)
model_parameters(xfit1)

#Binomial test for better friend measure
x <- sum(OMIT$Better_Friend_sad)     #sad condition
binom.test(x = x, n = 57, p = 0.5)

x <- sum(OMIT$Better_Friend_happy)   #happy condition
binom.test(x = x, n = 57, p = 0.5)

#data visualization for better friend measure
OMIT$Better_Friend_sad <- factor(OMIT$Better_Friend_sad, labels = c("Fact", "Emotion"))
OMIT$Better_Friend_happy <- factor(OMIT$Better_Friend_happy, labels = c("Fact", "Emotion"))

table(OMIT$Better_Friend_sad)
table(OMIT$Better_Friend_happy)

betterfriend <- matrix(c(13,44,
                         29,28),
                       ncol = 2, byrow = T)
rownames(betterfriend) <- c("Sad", "Happy")
colnames(betterfriend) <- c("Fact", "Emotion")
betterfriend.d <- as.data.frame(betterfriend)
betterfriend.d$Trial <- c("Sad", "Happy")
betterfriend.dm <- melt(betterfriend.d, id.vars = c('Trial'))
names(betterfriend.dm) <- c("Trial", "Target", "Freq")
betterfriend.dm$Trial <- as.factor(betterfriend.dm$Trial)
betterfriend.dm$Trial <- relevel(betterfriend.dm$Trial, "Sad")

resultsBF <- ggplot(betterfriend.dm, aes(Trial, Freq)) + 
  geom_bar(aes(fill = Target), position = "fill", stat="identity", color = "grey25") +
  scale_fill_manual(values = c("honeydew", "darkcyan")) +
  theme(
    legend.position = "bottom", 
    panel.background = element_rect(fill = "white"),        
    plot.title = element_text(margin = margin(0,0,30,0), size = 16),
    axis.line = element_line(colour = "grey", size = .5),
    axis.title.x = element_text(size = 16),  
    axis.title.y = element_text(size = 16),  
    axis.text.x = element_text(size = 14),  
    axis.text.y = element_text(size = 14),  
    legend.text = element_text(size = 14),  
    legend.title = element_text(size = 14)  
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsBF

#####CIRCLE ANALYSIS FOR STUDY 1####

#Bayesian model
set.seed(123)
xfit1 <- brm (answer~condition_HS*condition_EF + (1|ID), data = OMIT_Long_circles, family='cumulative',save_pars = save_pars(all = TRUE), iter= 3000, warmup= 1000, thin= 1,chains=4)
xfit2 <- brm (answer~condition_HS+condition_EF + (1|ID), data = OMIT_Long_circles, family='cumulative',save_pars = save_pars(all = TRUE), iter= 3000, warmup= 1000, thin= 1,chains=4)

bayes_factor(xfit1,xfit2)

plot(rope(xfit1,range=c(-0.1, 0.1)))

(rope(xfit1,range=c(-0.1, 0.1)))

help("rope")

#data visualization for circles measure

#sad condition
OMIT_circsad_long <- OMIT %>%
  pivot_longer(cols = c(Circles_fact_s, Circles_emo_s), 
               names_to = "condition", 
               values_to = "rating") %>%
  mutate(condition = case_when(
    condition == "Circles_fact_s" ~ "Fact", 
    condition == "Circles_emo_s" ~ "Emotion"
  ))


ggplot(OMIT_circsad_long, aes(x = condition, y = rating)) +
  geom_boxplot(aes(fill = condition), outlier.shape = NA) +  
  geom_jitter(aes(color = condition), width = 0.1, alpha = 0.7) +  
  geom_line(aes(group = ID), alpha = 0.4, linetype = 1, color = "black") +  
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
  )

#happy condition
OMIT_circhappy_long <- OMIT %>%
  pivot_longer(cols = c(Circles_fact_h, Circles_emo_h), 
               names_to = "condition", 
               values_to = "rating") %>%
  mutate(condition = case_when(
    condition == "Circles_fact_h" ~ "Fact", 
    condition == "Circles_emo_h" ~ "Emotion"
  ))


ggplot(OMIT_circhappy_long, aes(x = condition, y = rating)) +
  geom_boxplot(aes(fill = condition), outlier.shape = NA) +  # Boxplot by condition
  geom_jitter(aes(color = condition), width = 0.1, alpha = 0.7) +  # Jittered points
  geom_line(aes(group = ID), alpha = 0.4, linetype = 1, color = "black") +  # Connect lines by ID
  stat_summary(fun = mean, geom = "point", shape = 21, size = 3, color = "black", fill = "white") +  # Mean points
  labs(title = "Social Overlap (Happy Condition)", 
       x = "", y = "Rating of Social Distance") +
  scale_fill_manual(values = c("purple", "pink")) +  # Fill colors for the boxplots
  scale_color_manual(values = c("black", "black")) +  # Color for jittered points
  theme_minimal() +  # Clean theme
  theme(
    legend.position = "none", 
    panel.background = element_rect(fill = "white"),
    axis.line = element_line(colour = "grey", size = 0.25),
    axis.title.x = element_text(size = 20),  # Increase x-axis title size
    axis.title.y = element_text(size = 20, margin = margin(0, 30, 0, 0)),  # Increase y-axis title size
    axis.text.x = element_text(size = 18),  # Increase x-axis labels size
    axis.text.y = element_text(size = 18),  # Increase y-axis labels size
    plot.title = element_text(size = 16, face = "bold")  # Increase plot title size
  )


#Model Diagnostics--is it a reasonable fit? (Are the density plots observed and predicted similar)
pp2 = brms::pp_check(xfit1)
pp2


####Food Sharing Emotions####
#If starting from scratch for Study 2: Do children think that children are more likely to disclose sad emotions versus facts than happy emotions versus facts to close others?
OMIT<-read.csv("OMIT_data_1.9.25.csv")

OMIT_Long_sharing<-gather(OMIT, condition, answer,Ice_Cream_sad,Candy_sad, Ice_Cream_happy, Candy_happy)

write.csv(OMIT_Long_sharing,"OMIT_Long_sharing.csv")
#in excel make two columns for item and emotion shared

OMIT_Long_sharing<-read.csv("OMIT_Long_sharing.csv")


OMIT_Long_sharing$ID<-factor(OMIT_Long_sharing$ID)
OMIT_Long_sharing$AgeYears<-factor(OMIT_Long_sharing$AgeYears)
OMIT_Long_sharing$item<-factor(OMIT_Long_sharing$item) # This is what type of item
OMIT_Long_sharing$emotion_shared<-factor(OMIT_Long_sharing$emotion) # This is what type of item


#1 is family 0 is nonfamily

#glm to investigate the effects of condition on children's answers

analysis<-glmer(answer~emotion_shared+AgeYears+(1|ID), family=binomial(link="logit"), data=OMIT_Long_sharing)

summary(analysis)
confint(analysis)
exp(fixef(analysis))

https://cran.r-project.org/web/packages/ggeffects/vignettes/introduction_randomeffects.html
pr <- ggpredict(analysis, "emotion_shared",type="fixed")
plot(pr)
pr
names(OMIT_Long_sharing)
analysis<-glmer(answer~item+AgeYears+Sex+(1|ID), family=binomial(link="logit"), data=OMIT_Long_sharing)

#model without including condition
analysis0<-glmer(answer~AgeYears+Sex+(1|ID), family=binomial(link="logit"), data=OMIT_Long_sharing)

#model without including age
analysis02<-glmer(answer~item+(1|ID), family=binomial(link="logit"), data=OMIT_Long_sharing)

summary(analysis)
exp(fixef(analysis))

#Does Condition have an effect?
anova(analysis,analysis0)

#Does Age have an effect?
anova(analysis,analysis02)


#Check to see if model adheres to assumptions using DHARMa
simulationOutput <- simulateResiduals(fittedModel = analysis)
plot(simulationOutput)


#summary of the data per condition
cdata <- ddply(OMIT_Long_sharing, c("item"), summarise,
               N    = sum(!is.na(answer)),
               mean = mean(answer, na.rm=TRUE),
               sd   = sd(answer, na.rm=TRUE),
               se   = sd / sqrt(N)
)

cdata              


#using a bayesian approach with the same model...

#brm (https://bayesat.github.io/lund2018/slides/andrey_anikin_slides.pdf) https://babieslearninglanguage.blogspot.com/2018/02/mixed-effects-models-is-it-time-to-go.html

#full model
set.seed(123)
xfit1 <- brm (answer~condition + AgeYears + (1|ID), data = OMIT_Long_sharing, family='bernoulli',save_pars = save_pars(all = TRUE), iter= 3000, warmup= 1000, thin= 1,chains=4)

plot(rope(xfit1))

#model without condition
xfit2 <- brm (answer~ AgeYears+ (1|ID), data = OMIT_Long_sharing, family='bernoulli',save_pars = save_pars(all = TRUE), iter= 110000, warmup= 1000, thin= 4)

#model without age
xfit3<-brm (answer~item + (1|ID), data = OMIT_Long_sharing, family='bernoulli',save_pars = save_pars(all = TRUE), iter= 110000, warmup= 1000, thin= 4)

#has the model converged? Check the Rhat, and should havehairy plots, Bulk ESS should be over 5,000
summary(xfit1)

#getting 95% credible intervals
me<-(conditional_effects(xfit1,effects=NULL,prob=c(.025,.975)))

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

#Rope Method with package
plot(rope(xfit1))

#Using Rope Method by hand
post_samples <- posterior_samples(xfit1) %>%
  select(!matches("^r"))

# extract posterior samples from model
post_samples <- posterior_samples(xfit1)

str(post_samples)

plot(density(post_samples$b_conditionNewBF))
plot(density(post_samples$b_Age7))

# estimate posterior probability of a parameter being within a ROPE interval
interval_test <- post_samples$b_conditionNewBF > -0.1 &post_samples$b_conditionNewBF < 0.1

cat("Probability that NewBF > -0.1 & < 0.1 =", mean(interval_test), "\n")

mean(interval_test)

model_parameters(xfit1)
rope(xfit1)
x<-plot(me, plot = FALSE)[[1]] +
  scale_color_grey() +
  scale_fill_grey()

x+ylim(0,1)+
  
  theme(panel.grid.major = element_line(colour="gray"), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_blank(),panel.grid.major.x = element_blank())+xlab("")+ylab("")


#Model Diagnostics--is it a reasonable fit? (Are the density plots observed and predicted similar)
pp2 = brms::pp_check(xfit1)
pp2

#using ROPE method
library(bayestestR)
xfit1R <- brms::brm (answer~condition + AgeYears + (1|ID), data = OMIT_Long_sharing, family='bernoulli',save_all_pars = TRUE, iter= 110000, warmup= 1000, thin= 4)
summary(xfit1R)
ROPE<-equivalence_test(
  xfit1R,
  range = c(-.1,.1),
  ci = 0.89,
  effects = c("condition"),
  component = c("conditional"),
  parameters = NULL,
  verbose = TRUE,
)




summary(me)

https://calogica.com/r/rstan/2020/07/05/season-pass-hierarchical-modelng-r-stan-brms.html
library(bayesplot)
https://cran.r-project.org/web/packages/bayesplot/vignettes/plotting-mcmc-draws.html

mcmc_trace(xfit1, regex_pars = c("b_"), facet_args = list(nrow = 2))

posterior2<-as.array(xfit1)
dim(posterior2)
dimnames(posterior2)

color_scheme_set("red")
mcmc_intervals(posterior2, pars = c("b_conditionfoodp","b_conditiontoyn","b_conditiontoyp"))

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

exp(fixef(xfit1))

#checking to see if an interaction or just age and condition is a better fit
xfit1 <- brm (answer~condition+AgeYears+ (1|ID), data = OMIT_Long_sharing, family='bernoulli',save_all_pars = TRUE)
xfit1_I <- brm (answer~condition*AgeYears+ (1|ID), data = OMIT_Long_sharing, family='bernoulli',save_all_pars = TRUE)
marginal_effects(xfit1_I)
xfit1_I

mcmc_areas(
  xfit1_I,
  regex_pars = "b_",
  prob = 0.89,
  prob_outer = 1,
  point_est = "median",
  area_method = "equal height"
) +
  geom_vline(xintercept = 0, color = "red", alpha = 0.6, lwd = .8, linetype = "dashed") +
  labs(
    title = "Effect of Condition",
    subtitle = "with interactions"
  )

bayes_factor(xfit1_I,xfit1)

model_parameters(xfit1_I)
summary(xfit1_I)
rope(xfit1_I)
xfit1_p1 <- brm (answer ~ condition + (1|ID),
                 data = OMIT_Long_sharing, 
                 family='bernoulli',save_all_pars = TRUE,prior(normal(0,1)))

pp_p1 = brms::pp_check(xfit1_p1)
pp_p1+theme_bw()
pp_p1 = brms::pp_check(xfit1_I)
pp_p1+theme_bw()
xfit2_p1 <- brm (answer ~  (1|ID), 
                 data = OMIT_Long_sharing, family='bernoulli',
                 save_all_pars = TRUE)

bayes_factor(xfit1_p1,xfit2_p1)


##binomial test for food sharing trials
#ice cream
x <- sum(OMIT$Ice_Cream_sad)
binom.test(x = x, n = 57, p = 0.5)
x <- sum(OMIT$Ice_Cream_happy)
binom.test(x = x, n = 57, p = 0.5)
#candy
x <- sum(OMIT$Candy_sad)
binom.test(x = x, n = 57, p = 0.5)
x <- sum(OMIT$Candy_happy)
binom.test(x = x, n = 57, p = 0.5)

#Data visualization for food sharing trials
OMIT$Ice_Cream_sad <- factor(OMIT$Ice_Cream_sad, labels = c("Fact", "Emotion"))
OMIT$Ice_Cream_happy <- factor(OMIT$Ice_Cream_happy, labels = c("Fact", "Emotion"))
OMIT$Candy_sad <- factor(OMIT$Candy_sad, labels = c("Fact", "Emotion"))
OMIT$Candy_happy <- factor(OMIT$Candy_happy, labels = c("Fact", "Emotion"))

#ice cream
table(OMIT$Ice_Cream_sad)
table(OMIT$Ice_Cream_happy)

icecream <- matrix(c(17,40,
                     29,28),
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
  scale_fill_manual(values = c("peachpuff", "lightcoral")) +
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
    legend.title = element_text(size = 16)  # Increase legend title size
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsICE

#candy
table(OMIT$Candy_sad)
table(OMIT$Candy_happy)

candy <- matrix(c(23,34,
                  27,30),
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
  scale_fill_manual(values = c("peachpuff", "lightcoral")) +
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
    legend.title = element_text(size = 16)  # Increase legend title size
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsCANDY


#####New Friend#######
OMIT<-read.csv("OMIT_data_1.9.25.csv")
OMIT_Long_NewFriend<-gather(OMIT, condition, answer,New_Friend_sad,New_Friend_happy)

write.csv(OMIT_Long_NewFriend,"OMIT_Long_New_Friend.csv")

OMIT_Long_NewFriend<-read.csv("OMIT_Long_New_Friend.csv")

OMIT_Long_NewFriend$ID<-factor(OMIT_Long_NewFriend$ID)
OMIT_Long_NewFriend$AgeYears<-factor(OMIT_Long_NewFriend$AgeYears)

analysis<-glmer(answer~condition+AgeYears+(1|ID), family=binomial(link="logit"), data=OMIT_Long_NewFriend)

analysis0<-glmer(answer~AgeYears+Sex+(1|ID), family=binomial(link="logit"), data=OMIT_Long_NewFriend)


analysis02<-glmer(answer~condition+(1|ID), family=binomial(link="logit"), data=OMIT_Long_NewFriend)

#Check to see if model adheres to assumptions using DHARMa
simulationOutput <- simulateResiduals(fittedModel = analysis)
plot(simulationOutput)


#summary of the data per condition
cdata <- ddply(OMIT_Long_NewFriend, c("condition"), summarise,
               N    = sum(!is.na(answer)),
               mean = mean(answer, na.rm=TRUE),
               sd   = sd(answer, na.rm=TRUE),
               se   = sd / sqrt(N)
)

cdata     

#using a bayesian approach with the same model...

#brm (https://bayesat.github.io/lund2018/slides/andrey_anikin_slides.pdf) https://babieslearninglanguage.blogspot.com/2018/02/mixed-effects-models-is-it-time-to-go.html

#full model
set.seed(123)
xfit1 <- brm (answer~condition + AgeYears + (1|ID), data = OMIT_Long_NewFriend, family='bernoulli',save_all_pars = TRUE, iter= 3000, warmup= 1000, thin= 1,chains=4)
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
x <- sum(OMIT$New_Friend_sad)
binom.test(x = x, n = 57, p = 0.5)
x <- sum(OMIT$New_Friend_happy)
binom.test(x = x, n = 57, p = 0.5)

#Data visualization for new friend
OMIT$New_Friend_sad <- factor(OMIT$New_Friend_sad, labels = c("Fact", "Emotion"))
OMIT$New_Friend_happy <- factor(OMIT$New_Friend_happy, labels = c("Fact","Emotion"))


table(OMIT_study1$New_Friend_sad)
table(OMIT_study1$New_Friend_happy)

newfriend <- matrix(c(29,28,
                      24,33),
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



####ParentSharing####
#If starting from scratch for Study 2: Do children think that children are more likely to disclose sad emotions versus facts than happy emotions versus facts to close others?
OMIT<-read.csv("OMIT_data_1.9.25.csv")

OMIT_Long_mom<-gather(OMIT, condition, answer,Mom_sad,Mom_happy,FriendMom_sad,FriendMom_happy)

write.csv(OMIT_Long_mom,"OMIT_Long_mom.csv")
#in excel make two columns for item and emotion shared

OMIT_Long_mom<-read.csv("OMIT_Long_mom.csv")


OMIT_Long_mom$ID<-factor(OMIT_Long_mom$ID)
OMIT_Long_mom$AgeYears<-factor(OMIT_Long_mom$AgeYears)
OMIT_Long_mom$relationship<-factor(OMIT_Long_mom$relationship) # This is what type of item
OMIT_Long_mom$emotion_shared<-factor(OMIT_Long_mom$emotion_shared) # This is what type of item


analysis<-glmer(answer~condition+AgeYears+(1|ID), family=binomial(link="logit"), data=OMIT_Long_mom)
summary(analysis)
confint(analysis)
exp(fixef(analysis))

pr <- ggpredict(analysis, "condition",type="fixed")
plot(pr)
pr
analysis0<-glmer(answer~AgeYears+Sex+(1|ID), family=binomial(link="logit"), data=OMIT_Long_mom)

analysis02<-glmer(answer~condition+(1|ID), family=binomial(link="logit"), data=OMIT_Long_mom)

#Does Condition have an effect?
anova(analysis,analysis0)

#Does Age have an effect?
anova(analysis,analysis02)


#1 is family 0 is nonfamily

#glm to investigate the effects of condition on children's answers

analysis<-glmer(answer~relationship*emotion_shared+AgeYears+(1|ID), family=binomial(link="logit"), data=OMIT_Long_mom)



summary(analysis)
confint(analysis)
exp(fixef(analysis))

https://cran.r-project.org/web/packages/ggeffects/vignettes/introduction_randomeffects.html
pr <- ggpredict(analysis, "relationship",type="fixed")
plot(pr)
pr

analysis<-glmer(answer~condition+AgeYears+Sex+(1|ID), family=binomial(link="logit"), data=OMIT_Long_mom)

#model without including condition
analysis0<-glmer(answer~AgeYears+Sex+(1|ID), family=binomial(link="logit"), data=OMIT_Long_mom)

#model without including age
analysis02<-glmer(answer~condition+(1|ID), family=binomial(link="logit"), data=OMIT_Long_mom)

summary(analysis)
exp(fixef(analysis))

#Does Condition have an effect?
anova(analysis,analysis0)

#Does Age have an effect?
anova(analysis,analysis02)


#Check to see if model adheres to assumptions using DHARMa
simulationOutput <- simulateResiduals(fittedModel = analysis)
plot(simulationOutput)


#summary of the data per condition
cdata <- ddply(OMIT_Long_mom, c("relationship"), summarise,
               N    = sum(!is.na(answer)),
               mean = mean(answer, na.rm=TRUE),
               sd   = sd(answer, na.rm=TRUE),
               se   = sd / sqrt(N)
)

cdata              


#using a bayesian approach with the same model...

#brm (https://bayesat.github.io/lund2018/slides/andrey_anikin_slides.pdf) https://babieslearninglanguage.blogspot.com/2018/02/mixed-effects-models-is-it-time-to-go.html

#full model
set.seed(123)
xfit1 <- brm (answer~relationship*emotion_shared + AgeYears + (1|ID), data = OMIT_Long_mom, family='bernoulli',save_all_pars = TRUE, iter= 3000, warmup= 1000, thin= 1,chains=4)

plot(rope(xfit1))
rope(xfit1)
model_parameters(xfit1)

#model without condition
xfit2 <- brm (answer~ AgeYears+ (1|ID), data = OMIT_Long_mom, family='bernoulli',save_all_pars = TRUE, iter= 110000, warmup= 1000, thin= 4)

#model without age
xfit3<-brm (answer~condition + (1|ID), data = OMIT_Long_mom, family='bernoulli',save_all_pars = TRUE, iter= 110000, warmup= 1000, thin= 4)

#has the model converged? Check the Rhat, and should havehairy plots, Bulk ESS should be over 5,000
summary(xfit1)

#getting 95% credible intervals
me<-(conditional_effects(xfit1,effects=NULL,probs=c(.025,.975)))

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

#Rope Method with package
plot(rope(xfit1))

#Using Rope Method by hand
post_samples <- posterior_samples(xfit1) %>%
  select(!matches("^r"))

# extract posterior samples from model
post_samples <- posterior_samples(xfit1)

str(post_samples)

plot(density(post_samples$b_conditionNewBF))
plot(density(post_samples$b_Age7))

# estimate posterior probability of a parameter being within a ROPE interval
interval_test <- post_samples$b_conditionNewBF > -0.1 &post_samples$b_conditionNewBF < 0.1

cat("Probability that NewBF > -0.1 & < 0.1 =", mean(interval_test), "\n")

mean(interval_test)



x<-plot(me, plot = FALSE)[[1]] +
  scale_color_grey() +
  scale_fill_grey()

x+ylim(0,1)+
  
  theme(panel.grid.major = element_line(colour="gray"), panel.grid.minor = element_blank(),
        panel.background = element_blank(), axis.line = element_blank(),panel.grid.major.x = element_blank())+xlab("")+ylab("")


#Model Diagnostics--is it a reasonable fit? (Are the density plots observed and predicted similar)
pp2 = brms::pp_check(xfit1)
pp2

#using ROPE method
library(bayestestR)
xfit1R <- brms::brm (answer~condition + AgeYears + (1|ID), data = OMIT_Long_mom, family='bernoulli',save_all_pars = TRUE, iter= 110000, warmup= 1000, thin= 4)
summary(xfit1R)
ROPE<-equivalence_test(
  xfit1R,
  range = c(-.1,.1),
  ci = 0.89,
  effects = c("condition"),
  component = c("conditional"),
  parameters = NULL,
  verbose = TRUE,
)




summary(me)

https://calogica.com/r/rstan/2020/07/05/season-pass-hierarchical-modelng-r-stan-brms.html
library(bayesplot)
https://cran.r-project.org/web/packages/bayesplot/vignettes/plotting-mcmc-draws.html

mcmc_trace(xfit1, regex_pars = c("b_"), facet_args = list(nrow = 2))

posterior2<-as.array(xfit1)
dim(posterior2)
dimnames(posterior2)

color_scheme_set("red")
mcmc_intervals(posterior2, pars = c("b_conditionfoodp","b_conditiontoyn","b_conditiontoyp"))

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

exp(fixef(xfit1))

#checking to see if an interaction or just age and condition is a better fit
xfit1 <- brm (answer~condition+AgeYears+ (1|ID), data = OMIT_Long_mom, family='bernoulli',save_all_pars = TRUE)
xfit1_I <- brm (answer~condition*AgeYears+ (1|ID), data = OMIT_Long_mom, family='bernoulli',save_all_pars = TRUE)
marginal_effects(xfit1_I)
xfit1_I

mcmc_areas(
  xfit1_I,
  regex_pars = "b_",
  prob = 0.89,
  prob_outer = 1,
  point_est = "median",
  area_method = "equal height"
) +
  geom_vline(xintercept = 0, color = "red", alpha = 0.6, lwd = .8, linetype = "dashed") +
  labs(
    title = "Effect of Condition",
    subtitle = "with interactions"
  )

bayes_factor(xfit1_I,xfit1)

plot_model(xfit1_I, type = "eff", terms = "condition") 
xfit1_p1 <- brm (answer ~ condition + (1|ID),
                 data = OMIT_Long_mom, 
                 family='bernoulli',save_all_pars = TRUE,prior(normal(0,1)))

pp_p1 = brms::pp_check(xfit2_p1)
pp_p1+theme_bw()

xfit2_p1 <- brm (answer ~  (1|ID), 
                 data = OMIT_Pilot_Long, family='bernoulli',
                 save_all_pars = TRUE)

bayes_factor(xfit1_p1,xfit2_p1)

conditional_effects(xfit1_I, effects = "condition", prob = 0)

get_prior(answer ~  (1|ID), 
          data = OMIT_Long, family='bernoulli')

#Custom Plot of model Predictions
xfit3<-brm (answer~condition+ (1|ID), data = OMIT_Long, family='bernoulli',save_all_pars = TRUE)
newdata=data.frame(condition=levels(OMIT_Long$condition))
fit=fitted(
  xfit3,
  newdata=newdata,
  re_formula = NA,
  summary=TRUE)*100

colnames(fit) = c('fit', 'se', 'lwr', 'upr')
OMIT_Long_plot = cbind(newdata, fit)

fit


model_parameters(xfit1)
rope(xfit1)

#Binomial test for mom trials
#mom
x <- sum(OMIT$Mom_sad)
binom.test(x = x, n = 57, p = 0.5)

x <- sum(OMIT$Mom_happy)
binom.test(x = x, n = 57, p = 0.5)

#Friend's mom
x <- sum(OMIT$FriendMom_sad)
binom.test(x = x, n = 57, p = 0.5)

x <- sum(OMIT$FriendMom_happy)
binom.test(x = x, n = 57, p = 0.5)

#Data visualization for mom trials

OMIT$Mom_sad <- factor(OMIT$Mom_sad, labels = c("Fact", "Emotion"))
OMIT$Mom_happy <- factor(OMIT$Mom_happy, labels = c("Fact", "Emotion"))
OMIT$FriendMom_sad <- factor(OMIT$FriendMom_sad, labels = c("Fact", "Emotion"))
OMIT$FriendMom_happy <- factor(OMIT$FriendMom_happy, labels = c("Fact", "Emotion"))

#mom
table(OMIT$Mom_sad)
table(OMIT$Mom_happy)

mom <- matrix(c(14,43,
                26,31),
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
  scale_fill_manual(values = c("lightyellow", "sandybrown")) +
  theme(
    legend.position = "bottom", 
    panel.background = element_rect(fill = "white"),        
    plot.title = element_text(margin = margin(0,0,30,0), size = 16, face = "bold"),  # Increase title size and make bold
    axis.line = element_line(colour = "grey", size = .25),
    axis.title.x = element_text(size = 14),  # Increase x-axis title size
    axis.title.y = element_text(size = 22, margin = margin(0, 30, 0, 0)),  # Increase y-axis title size
    axis.text.x = element_text(size = 20),  # Increase x-axis labels size
    axis.text.y = element_text(size = 20),  # Increase y-axis labels size
    legend.text = element_text(size = 18),  # Increase legend label size
    legend.title = element_text(size = 18)  # Increase legend title size
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsMOM


#friend mom
table(OMIT_study1$FriendMom_sad)
table(OMIT_study1$FriendMom_happy)

friendmom <- matrix(c(35,22,
                      29,28),
                    ncol = 2, byrow = T)
rownames(friendmom) <- c("Sad", "Happy")
colnames(friendmom) <- c("Fact", "Emotion")
friendmom.d <- as.data.frame(friendmom)
friendmom.d$Trial <- c("Sad", "Happy")
friendmom.dm <- melt(friendmom.d, id.vars = c('Trial'))
names(friendmom.dm) <- c("Trial", "Target", "Freq")
friendmom.dm$Trial <- as.factor(friendmom.dm$Trial)
friendmom.dm$Trial <- relevel(friendmom.dm$Trial, "Sad")

resultsFRIENDMOM <- ggplot(friendmom.dm, aes(Trial, Freq)) + #   
  geom_bar(aes(fill = Target), position = "fill", stat="identity", color = "grey25") +
  scale_fill_manual(values = c("lightyellow", "sandybrown")) +
  theme(
    legend.position = "bottom", 
    panel.background = element_rect(fill = "white"),        
    plot.title = element_text(margin = margin(0,0,30,0), size = 16, face = "bold"),  # Increase title size and make bold
    axis.line = element_line(colour = "grey", size = .25),
    axis.title.x = element_text(size = 14),  # Increase x-axis title size
    axis.title.y = element_text(size = 22, margin = margin(0, 30, 0, 0)),  # Increase y-axis title size
    axis.text.x = element_text(size = 20),  # Increase x-axis labels size
    axis.text.y = element_text(size = 20),  # Increase y-axis labels size
    legend.text = element_text(size = 18),  # Increase legend label size
    legend.title = element_text(size = 18)  # Increase legend title size
  ) +  
  guides(fill = guide_legend(nrow = 2)) +
  geom_hline(yintercept = 0.5, linetype = 2, alpha = 0.5) +
  xlab("") +
  ylab("Proportion of Judgments")

resultsFRIENDMOM





