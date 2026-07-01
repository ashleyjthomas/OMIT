# Pre-registration — Wave B/C (manuscript Studies 2, 4B, and 3B)

*Note on numbering: the internal study labels below (2.1, 2.2, 2.3) correspond to
manuscript **Study 2** (2.1: friend vs. best friend), **Study 4B** (2.2: mother →
child), and **Study 3B** (2.3: deepening an existing friendship).*

**Start Date**
February 2025

## Research Question

Think of a time when your best friend failed to tell you something important that happened in their life. How did it make you feel? Perhaps a little surprised or hurt. Adults seem to have expectations around sharing information in close relationships, but do children share these intuitions? If they do, these expectations might play an important role in their understanding of their social world. Previous research on children's information sharing suggests that children as young as six years old are sensitive to the type of information shared (such as a secret or fact) and the relationship with whom the information is being shared (Anagnostaki et al., 2013; Liberman and Shaw, 2018). We are primarily interested in children's expectations around sharing emotional information in close relationships, as it can be sensitive. This project has already found that (1) children infer that individuals who share negative emotional states are close, (2) children expect emotionally sensitive information to be shared in close relationships and (3) children do not think others will share negative emotional states to create relationships. These findings suggest that children make rich inferences about sharing emotional information in close relationships and that there may be more to investigate. Thus, we propose to conduct three more studies to further probe children's reasoning.

In the first study, we aim to explore whether children expect others to share sad emotions with best friends as opposed to friends. In our previous studies we compared parents and friend's parents, so this is a way to investigate whether this intuition generalizes to non-familial close and more distant relations.

The second study explores whether children expect information sharing to occur equally within asymmetrical relationships. In our previous studies, we found that children expect a child to share sad emotions with their mother (but not their friend's mother), but we are curious about whether children expect a mother to share sensitive emotions with her child.

The third study aims to investigate children's intuitions about whether children think that sharing emotions is a good way to become best friends with someone who is already a friend. In our previous study, children did not think that sharing sad emotions was a way to make a new friend. Hence, making a somewhat close relationship even closer.

## Methods and Design

This is a within-subjects design and will be conducted fully online via Zoom. Data for all three parts will be collected during the same study session.

For study 2.1, we will tell children a story where the protagonist learns an animal fact in school and is also feeling happy in the happy condition, or sad in the sad condition. The protagonist will encounter a friend who wants to know how their day was at school. We will then ask the children if the protagonist will share the fact or their emotional state. Then the protagonist will encounter their best friend who wants to know how the protagonist's day was at school. We will then ask children if the protagonist would share the fact or their emotional state. The order of happy and sad conditions as well as whether they run into their best friend or friend will be counterbalanced.

In the story for study 2.2, the protagonist's mother learns a fact at work and is feeling sad, and the protagonist asks their mom how her day was. We will then ask the children if they think the protagonist's mother will share the fact or her emotional state. Likewise, a friend's mom will learn a fact and feel sad at work, and the protagonist will ask her how her day was. We will also have a condition where the protagonist's mother and the friend's mother feels happy and learns a fact at work. The order of these four conditions will be counterbalanced.

For study 2.3, The protagonist will encounter a different friend with the goal of becoming closer friends with that character. We will then ask children if they think the protagonist will share their emotional state (sad or happy) or the fact they learned in school.

## Participants

Children aged 6 years and 0 days to 9 years and 364 days of age. We chose this age range because it is consistent with past literature that suggests that children at this point in development have adequate theory-of-mind reasoning and social perspective-taking skills to navigate these tasks (e.g. Liberman and Shaw, 2018; Woo et. al., 2024).

## Sample Size

We plan to test 56 children. This sample size is consistent with prior research that has found similar effects (e.g. Woo et. al, 2024).

## Hypotheses

In the first study, we hypothesize that children will think that the child will share sad emotions, but not happy emotions or facts with a best friend more than a friend.

In the second study, we predict that children will think that a mother will not share sad emotions with her child and will share happy emotions and facts. We expect children to be at chance for all conditions with the friend's mom.

In the third experiment, we predict that children will think that sharing sad emotions can be a way to become closer friends with someone. We predict that sharing happy emotions and facts will be at chance.

## Primary and Secondary DVs

**Study 2.1**
Closeness is measured by which type of information (emotion or fact) would be shared by the protagonist with the protagonist's friend and best friend.

**Study 2.2**
Closeness is measured by which type of information (emotion or fact) would be shared by the protagonist's mother and friend's mother to the protagonist.

**Study 2.3**
Closeness is measured by which type of information (emotion or fact) should be shared with a presumed close social partner (the protagonist's best friend) and a presumed social partner that is less close (the protagonist's friend).

## Primary Analyses

For all three experiments we will use a one-sided Bayesian binomial test, in the direction of our hypotheses to measure how often children choose sharing the emotion over sharing the fact.

We will also run a Bayesian probit generalized linear mixed-effects model with default priors to analyze if there is an effect by condition. The DV will be whether children choose the emotion over the fact and we will include participant ID as a random effect. We will also add age into the model to see if there are any age effects.

    answer ~ condition * age + (trial + 1 | ID)

## Inference Criteria

In all analyses, we will assess whether the value 0 falls within the 95% credible interval. The absence of 0 in the 95% credible interval will be interpreted as supporting evidence for the presence of effects, whereas the presence of 0 in the 95% credible interval will be interpreted as supporting evidence for the null.

## Counterbalancing

Across experiments, we will counterbalance the order of conditions we will present to the participants.

Study 2.1, we will counterbalance the order in which the friend and best friend are presented, and the order in which we ask the children to choose the emotion or fact. We will also counterbalance which character is the "friend" and which character is the "best friend."

Study 2.2, we will counterbalance the order in which the protagonist's mother and friend's mother are presented and the order in which we will ask children to choose the emotion or fact.

Study 2.3, we will counterbalance the order in which we ask children to choose the emotion or fact.

## Exclusion Criteria

We will exclude data if there is constant familial interference, procedural error, or equipment failure where the participant is unable to hear all of the vignettes.

**Familial Interference:**
We require that caregivers avoid intervening or guiding their children's behavior. Caregiver interference includes caregivers doing something that might bias their child's responses (e.g., speaking to their children about the events, telling their children the answers, etc.).

Because we are testing children over Zoom and they are in their family homes, we have less control over the testing environment. If siblings or others in the home environment consistently distract or interfere in a way that might bias a child's responses (as in the examples of caregiver interference above), we will have reason to exclude the participant on the basis of familial interference.

**Procedural Error:**
This includes deviation from the standard procedure of the study such that the participants do not see all vignettes, trials, etc.

**Equipment Failure:**
This can occur when there is a lack of adequate internet access to complete the study or if the device the participant or experimenter is using malfunctions to the point where the study cannot be completed.
