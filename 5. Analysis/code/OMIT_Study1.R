#load the packages
library("vioplot")
library("ggstatsplot")
library("ggplot2")
library("sjPlot")
library("effects")
library("dplyr")
library("effectsize")
library("performance")
library("rstanarm")
library("bayestestR")
library("bayesplot")
library("BayesFactor")
library("glmmTMB") 
library("ordinal")
library("MASS")

#set the working directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(readr)
OMIT_study1 <- read_csv("OMIT_data_1.9.25.csv")


# Setting to use 4 cores for Bayesian models
options(mc.cores = 4)
options()$mc.cores
#------EDA-----------
dim(OMIT_study1)
str(OMIT_study1)
head(OMIT_study1)
tail(OMIT_study1)

#Prepare the data
OMIT_study1$Better_Friend_sad <- factor(OMIT_study1$Better_Friend_sad, labels = c("Fact", "Emotion"))
OMIT_study1$Better_Friend_sad
OMIT_study1$New_Friend_sad <- factor(OMIT_study1$New_Friend_sad, labels = c("Fact", "Emotion"))
OMIT_study1$New_Friend_sad
OMIT_study1$Better_Friend_happy <- factor(OMIT_study1$Better_Friend_happy, labels = c("Fact", "Emotion"))
OMIT_study1$Better_Friend_happy
OMIT_study1$New_Friend_happy <- factor(OMIT_study1$New_Friend_happy, labels = c("Fact","Emotion"))
OMIT_study1$New_Friend_happy
OMIT_study1$Ice_Cream_sad <- factor(OMIT_study1$Ice_Cream_sad, labels = c("Fact", "Emotion"))
OMIT_study1$Ice_Cream_sad
OMIT_study1$Ice_Cream_happy <- factor(OMIT_study1$Ice_Cream_happy, labels = c("Fact", "Emotion"))
OMIT_study1$Ice_Cream_happy
OMIT_study1$Candy_sad <- factor(OMIT_study1$Ice_Cream_sad, labels = c("Fact", "Emotion"))
OMIT_study1$Candy_happy <- factor(OMIT_study1$Candy_happy, labels = c("Fact", "Emotion"))
OMIT_study1$Candy_happy
OMIT_study1$Mom_sad <- factor(OMIT_study1$Mom_sad, labels = c("Fact", "Emotion"))
OMIT_study1$Mom_sad
OMIT_study1$Mom_happy <- factor(OMIT_study1$Mom_happy, labels = c("Fact", "Emotion"))
OMIT_study1$Mom_happy
OMIT_study1$FriendMom_sad <- factor(OMIT_study1$FriendMom_sad, labels = c("Fact", "Emotion"))
OMIT_study1$FriendMom_sad
OMIT_study1$FriendMom_happy <- factor(OMIT_study1$FriendMom_happy, labels = c("Fact", "Emotion"))
OMIT_study1$FriendMom_happy

#Bar plots by trial and condition. 
barplot(table(OMIT_study1$Better_Friend_sad), main = "Better Friend (Sad Condition)", xlab = "Information Type",col = c("lightblue", "lightgreen"))
barplot(table(OMIT_study1$New_Friend_sad), main = "New Friend (Sad Condition)", xlab = "Information Type",col = c("lightblue", "lightgreen"))
barplot(table(OMIT_study1$Better_Friend_happy), main = "Better Friend (Happy Condition)", xlab = "Information Type",col = c("purple", "pink"))
barplot(table(OMIT_study1$New_Friend_happy), main = "New Friend (Happy Condition)", xlab = "Information Type",col = c("purple", "pink"))
#ice cream and candy
barplot(table(OMIT_study1$Ice_Cream_sad), main = "Ice Cream (Sad Condition)", xlab = "Information Type",col = c("lightblue", "lightgreen"))
barplot(table(OMIT_study1$Ice_Cream_happy), main = "Ice Cream (Happy Condition)", xlab = "Information Type",col = c("purple", "pink"))
barplot(table(OMIT_study1$Candy_sad), main = "Candy (Sad Condition)", xlab = "Information Type",col = c("lightblue", "lightgreen"))
barplot(table(OMIT_study1$Candy_happy), main = "Candy (Happy Condition)", xlab = "Information Type", col = c("purple", "pink"))
#mom and friend mom
barplot(table(OMIT_study1$Mom_sad), main = "Mom (Sad Condition)", xlab = "Information Type", col = c("lightblue", "lightgreen"))
barplot(table(OMIT_study1$Mom_happy), main = "Mom (Happy Condition)", xlab = "Information Type", col = c("purple", "pink"))
barplot(table(OMIT_study1$FriendMom_sad), main = " Friend's Mom (Sad Condition)", xlab = "Information Type", col = c("lightblue", "lightgreen"))
barplot(table(OMIT_study1$FriendMom_happy), main = " Friend's Mom (Happy Condition)", xlab = "Information Type", col = c("purple", "pink"))

#circle measure warm up
vioplot(OMIT_study1$Mom_and_Child, OMIT_study1$Strangers, OMIT_study1$Friends,
        main = "Circle Warmup",
        names = c("Mom and Child", "Strangers", "Friends"),
        col = c("pink", "lightblue", "lightgreen"))

boxplot(OMIT_study1$Mom_and_Child, OMIT_study1$Strangers, OMIT_study1$Friends,
        main = "Circle Warmup",
        names = c("Mom and Child", "Strangers", "Friends"),
        col = c("pink", "lightblue", "lightgreen"))


boxplot(
  OMIT_study1$Mom_and_Child, OMIT_study1$Strangers, OMIT_study1$Friends,
  main = "Circle Warmup",
  names = c("Mom and Child", "Strangers", "Friends"),
  col = c("pink", "lightblue", "lightgreen")
)

# Calculate means for each group
means <- c(
  mean(OMIT_study1$Mom_and_Child, na.rm = TRUE),
  mean(OMIT_study1$Strangers, na.rm = TRUE),
  mean(OMIT_study1$Friends, na.rm = TRUE)
)

# Add mean points to the plot
points(1:3, means, col = "black", bg = "white", pch = 21, cex = 1.5)
# Customize color, size, and symbol

# better friend sad condition
vioplot(OMIT_study1$Circles_fact_s,OMIT_study1$Circles_emo_s,
        main = "Better Friend (Sad Condition)",
        names = c("Fact", "Emotion"),
        col = c("lightblue", "lightgreen"))
boxplot(OMIT_study1$Circles_fact_s,OMIT_study1$Circles_emo_s,
        main = "Better Friend (Sad Condition)",
        names = c("Fact", "Emotion"),
        col = c("lightblue", "lightgreen"))

# Create the boxplot
boxplot(
  OMIT_study1$Circles_fact_s, OMIT_study1$Circles_emo_s,
  main = "Better Friend (Sad Condition)",
  names = c("Fact", "Emotion"),
  col = c("lightblue", "lightgreen")
)

# Calculate the means for each group
means <- c(
  mean(OMIT_study1$Circles_fact_s, na.rm = TRUE),
  mean(OMIT_study1$Circles_emo_s, na.rm = TRUE)
)

# Add mean points with black border and white fill
points(
  1:2, means, 
  col = "black", bg = "white", 
  pch = 21, cex = 1.5
)


#better friend happy condition
vioplot(OMIT_study1$Circles_fact_h, OMIT_study1$Circles_emo_h,
        main = "Better Friend (Happy Condition)",
        names = c("Fact", "Emotion"),
        col = c("purple", "pink"))
boxplot(
  OMIT_study1$Circles_fact_h, OMIT_study1$Circles_emo_h,
        main = "Better Friend (Happy Condition)",
        names = c("Fact", "Emotion"),
        col = c("purple", "pink")
  )
means <- c(
  mean(OMIT_study1$Circles_fact_h, na.rm = TRUE),
  mean(OMIT_study1$Circles_emo_h, na.rm = TRUE)
)
points(
  1:2, means, 
  col = "black", bg = "white", 
  pch = 21, cex = 1.5
)

# models for circle measure
set.seed(123)
lmm_fact_sad <- stan_lmer(Circles_fact_s ~ AgeYears + (1 + AgeYears|ID), data = OMIT_study1) #Trial with fact
lmm_emo_sad <- stan_lmer(Circles_emo_s ~ AgeYears + (1 + AgeYears|ID), data = OMIT_study1) #Trial with emotion

#predictive check
set.seed(123)
performance::check_predictions(lmm_fact_sad)                           ## Okay, it's not that bad
performance::check_predictions(lmm_fact_sad, type = "density") 
plot(lmm_fact_sad, which = 2)

summary(lmm_emo_sad)
#effects plots
plot_model(lmm_emo_sad, type = "pred")
plot_model(lmm_fact_sad, type = "pred")
plot_model(lmm_emo_sad, type = "eff")
plot_model(lmm_fact_sad, type = "eff")
#glmm
##converting the dv into a factor
OMIT_study1$Circles_fact_s <-factor(OMIT_study1$Circles_fact_s)
OMIT_study1$Circles_emo_s <- factor(OMIT_study1$Circles_emo_s)
OMIT_study1$Circles_fact_h <- factor(OMIT_study1$Circles_fact_h)
OMIT_study1$Circles_emo_h <- factor(OMIT_study1$Circles_emo_h)

#visualization
spineplot(OMIT_study1$Circles_emo_s ~ OMIT_study1$AgeYears, main = "Emotion (Sad Condtion)", xlab = "Age", ylab = "Closeness Rating")
spineplot(OMIT_study1$Circles_fact_s ~ OMIT_study1$AgeYears, main = "Fact (Sad Condtion)", xlab = "Age", ylab = "Closeness Rating")
spineplot(OMIT_study1$Circles_fact_h ~ OMIT_study1$AgeYears, main = "Fact (Happy Condtion)", xlab = "Age", ylab = "Closeness Rating")
spineplot(OMIT_study1$Circles_emo_h ~ OMIT_study1$AgeYears, main = "Emotion (Happy Condtion)", xlab = "Age", ylab = "Closeness Rating")

glmm_fact_sad <-clm(Circles_fact_s ~ AgeYears, data = OMIT_study1)
glmm_emo_sad <-clm(Circles_emo_s ~ AgeYears, data = OMIT_study1)
glmm_fact_happy <-clm(Circles_fact_h ~ AgeYears, data = OMIT_study1)
glmm_emo_happy <-clm(Circles_emo_h ~ AgeYears, data = OMIT_study1)


#Effects plots
#emotion sad condition
plot(allEffects(glmm_emo_sad)[1], style = "stacked")
plot(allEffects(glmm_emo_sad, type = 'response'))
plot_model(glmm_emo_sad, type = "pred")
#fact sad condition
plot(allEffects(glmm_fact_sad)[1], style = "stacked")
plot(allEffects(glmm_fact_sad, type = 'response'))
plot_model(glmm_fact_sad, type = "pred")
#emotion happy condition
plot(allEffects(glmm_emo_happy)[1], style = "stacked")
plot(allEffects(glmm_emo_happy, type = 'response'))
plot_model(glmm_emo_happy, type = "pred")
#fact happy condition
plot(allEffects(glmm_fact_happy)[1], style = "stacked")
plot(allEffects(glmm_fact_happy, type = 'response'))
plot_model(glmm_fact_happy, type = "pred")

## Logistic regression models for forced choice measures
#Better friend trial
log_bf_sad <-glm(Better_Friend_sad ~ AgeYears, family = "binomial", data = OMIT_study1)
summary(log_bf_sad)
cdplot(Better_Friend_sad ~ AgeYears, data = OMIT_study1)
plot(allEffects(log_bf_sad))
#happy condition
log_bf_happy <-glm(Better_Friend_happy ~ AgeYears, family = "binomial", data = OMIT_study1)
summary(log_bf_happy)
cdplot(Better_Friend_happy ~ AgeYears, data = OMIT_study1)
plot(allEffects(log_bf_happy))
#New friend trial
#sad condition
log_nf_sad<-glm(New_Friend_sad ~ AgeYears, family = "binomial", data = OMIT_study1)
summary(log_nf_sad)
cdplot(New_Friend_sad ~ AgeYears, data = OMIT_study1)
plot(allEffects(log_nf_sad))
#happy condition
log_nf_happy<-glm(New_Friend_happy ~ AgeYears, family = "binomial", data = OMIT_study1)
summary(log_nf_happy)
cdplot(New_Friend_happy ~ AgeYears, data = OMIT_study1)
plot(allEffects(log_nf_happy))

#mom
#happy condition
log_mom_happy<-glm(Mom_happy ~ AgeYears, family = "binomial", data = OMIT_study1)
summary(log_mom_happy)
cdplot(Mom_happy ~ AgeYears, data = OMIT_study1)
plot(allEffects(log_mom_happy))
#sad condition
log_mom_sad<-glm(Mom_sad ~ AgeYears, family = "binomial", data = OMIT_study1)
summary(log_mom_sad)
cdplot(Mom_sad ~ AgeYears, data = OMIT_study1)
plot(allEffects(log_mom_sad))

#friends mom
#happy condition
log_friendmom_happy<-glm(FriendMom_happy ~ AgeYears, family = "binomial", data = OMIT_study1)
summary(log_friendmom_happy)
cdplot(FriendMom_happy ~ AgeYears, data = OMIT_study1)
plot(allEffects(log_friendmom_happy))
#sad condition
log_friendmom_sad<-glm(FriendMom_sad ~ AgeYears, family = "binomial", data = OMIT_study1)
summary(log_friendmom_sad)
cdplot(FriendMom_sad ~ AgeYears, data = OMIT_study1)
plot(allEffects(log_friendmom_sad))