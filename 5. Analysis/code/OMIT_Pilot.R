library("vioplot")
library("ggstatsplot")
library("car")
library("XICOR")
library("naniar")
library("polycor")
library(dplyr)
library(ggplot2)
# import the dataset
 library(readr)
 OMITpilot <- read_csv("OMITpilot.csv")

#EDA
dim(OMITpilot)
head(OMITpilot)
tail(OMITpilot)
str(OMITpilot)
class(OMITpilot)

OMITpilot <- OMITpilot %>% select(-"Why")
OMITpilot <- OMITpilot %>% select(-"POSITIVE")
OMITpilot <- OMITpilot %>% select(-"ID")

#histograms of each trial
OMIT_neg_tell <- c(OMITpilot$NegClassmate_T, OMITpilot$NegBF_T, OMITpilot$NegStranger_T)
hist(OMIT_neg_tell,
     xlab = "n = 11",
     main = "Moral Eval of Disclosing")
OMIT_neg_not_tell <- c(OMITpilot$NegClassmate_NT, OMITpilot$NegBF_NT, OMITpilot$NegStranger_NT)
hist(OMIT_neg_not_tell,
     xlab = "n = 11",
     main = "Moral Eval of Omitting")
OMIT_neg_percy <- c(OMITpilot$NegClassmate_Percy, OMITpilot$NegBF_Percy, OMITpilot$NegStranger_Percy)
hist(OMIT_neg_percy, 
     xlab = "n = 11",
     main = "Emotion of Protagonist")
OMIT_neg_other <- c(OMITpilot$NegClassmate_Avery, OMITpilot$NegBF_Orin, OMITpilot$NegStranger_Kendall)
hist(OMIT_neg_other,
     xlab = "n = 11",
     main = "Emotion of Social Partner")

mean(classmate_not_tell)
mean(best_friend_not_tell)
mean(stranger_not_tell)



# omitting negative information
classmate_not_tell <- OMITpilot$NegClassmate_NT
best_friend_not_tell <- OMITpilot$NegBF_NT
stranger_not_tell <- OMITpilot$NegStranger_NT

stranger_not_tell


boxplot(classmate_not_tell, best_friend_not_tell, stranger_not_tell)

#violin plot for moral evaluation of omitting bad grade

vioplot(classmate_not_tell, 
        best_friend_not_tell, 
        stranger_not_tell, 
        names = c("Classmate", "Best Friend", "Stranger"), 
        main = "Moral Eval of Omitting the Bad Grade", 
        col = c("lightblue", "orange", "lightgreen"))



#disclosing facts about foxes
classmate_tell <- OMITpilot$NegClassmate_T
best_friend_tell <- OMITpilot$NegBF_T
stranger_tell <- OMITpilot$NegStranger_T

vioplot(classmate_tell, 
        best_friend_tell, 
        stranger_tell, 
        names = c("Classmate", "Best Friend", "Stranger"), 
        main = "Moral Eval of Telling the Fact", 
        col = c("lightblue", "orange", "lightgreen"))


classmate_percy <- OMITpilot$NegClassmate_Percy
best_friend_percy <-OMITpilot$NegBF_Percy
stranger_percy <- OMITpilot$NegStranger_Percy

vioplot(classmate_percy, 
        best_friend_percy, 
        stranger_percy, 
        names = c("Classmate", "Best Friend", "Stranger"), 
        main = "Emotion Attribution of Protagonist Omitting Bad Grade", 
        col = c("lightblue", "orange", "lightgreen"))

classmate_other <- OMITpilot$NegClassmate_Avery
bestfriend_other <- OMITpilot$NegBF_Orin
stranger_other <- OMITpilot$NegStranger_Kendall

vioplot(classmate_other, 
        bestfriend_other, 
        stranger_other, 
        names = c("Classmate", "Best Friend", "Stranger"), 
        main = "Emotion Attribution of Socal Partner from Omitting Bad Grade", 
        col = c("lightblue", "orange", "lightgreen"))


#positive condition

OMIT_pos_tell <- c(OMITpilot$PosClassmate_T, OMITpilot$PosBF_T, OMITpilot$PosStranger_T)
hist(OMIT_neg_tell,
     xlab = "n = 10",
     main = "Moral Eval of Disclosing")
OMIT_pos_not_tell <- c(OMITpilot$PosClassmate_NT, OMITpilot$PosBF_NT, OMITpilot$PosStranger_NT)
hist(OMIT_neg_not_tell,
     xlab = "n = 10",
     main = "Moral Eval of Omitting")
OMIT_pos_percy <- c(OMITpilot$PosClassmate_Percy, OMITpilot$PosBF_Percy, OMITpilot$PosStranger_Percy)
hist(OMIT_neg_percy, 
     xlab = "n = 10",
     main = "Emotion of Protagonist")
OMIT_pos_other <- c(OMITpilot$PosClassmate_Avery, OMITpilot$PosBF_Orin, OMITpilot$PosStranger_Finley)
hist(OMIT_neg_other,
     xlab = "n = 10",
     main = "Emotion of Social Partner")




pos_classmate_not_tell <- OMITpilot$PosClassmate_NT
pos_best_friend_not_tell <- OMITpilot$PosBF_NT
pos_stranger_not_tell <- OMITpilot$PosStranger_NT

vioplot(pos_classmate_not_tell, 
        pos_best_friend_not_tell, 
        pos_stranger_not_tell, 
        names = c("Classmate", "Best Friend", "Stranger"), 
        main = "Moral Eval of Omitting", 
        col = c("lightblue", "orange", "lightgreen"))

boxplot(pos_classmate_not_tell, 
        pos_best_friend_not_tell, 
        pos_stranger_not_tell, 
        names = c("Classmate", "Best Friend", "Stranger"), 
        main = "Moral Eval of Omitting", 
        col = c("lightblue", "orange", "lightgreen"))

pos_classmate_tell <- OMITpilot$PosClassmate_T
pos_best_friend_tell <- OMITpilot$PosBF_T
pos_stranger_tell <- OMITpilot$PosStranger_T

vioplot(pos_classmate_tell, 
        pos_best_friend_tell, 
        pos_stranger_tell, 
        names = c("Classmate", "Best Friend", "Stranger"), 
        main = "Moral Eval of Disclosing", 
        col = c("lightblue", "orange", "lightgreen"))



pos_classmate_percy <- OMITpilot$PosClassmate_Percy
pos_best_friend_percy <-OMITpilot$PosBF_Percy
pos_stranger_percy <- OMITpilot$PosStranger_Percy

vioplot(pos_classmate_percy, 
        pos_best_friend_percy, 
        pos_stranger_percy, 
        names = c("Classmate", "Best Friend", "Stranger"), 
        main = "Emotion Attribution of Protagonist Omitting", 
        col = c("lightblue", "orange", "lightgreen"))




pos_classmate_other <- OMITpilot$PosClassmate_Avery
pos_bestfriend_other <- OMITpilot$PosBF_Orin
pos_stranger_other <- OMITpilot$PosStranger_Finley

vioplot(pos_classmate_other, 
        pos_bestfriend_other, 
        pos_stranger_other, 
        names = c("Classmate", "Best Friend", "Stranger"), 
        main = "Emotion Attribution of Socal Partner from Omitting", 
        col = c("lightblue", "orange", "lightgreen"))

boxplot(pos_classmate_other, 
        pos_bestfriend_other, 
        pos_stranger_other, 
        names = c("Classmate", "Best Friend", "Stranger"), 
        main = "Emotion Attribution of Socal Partner from Omitting", 
        col = c("lightblue", "orange", "lightgreen"))