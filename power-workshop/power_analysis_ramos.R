library(tidyverse)
library(lme4)
library(lmerTest)
library(simr)
library(gghalves)
library(conflicted)
conflict_prefer("filter", "dplyr")
conflict_prefer("fixed", "simr")
conflict_prefer("lmer", "lmerTest")

ramos <- read_csv("data_ramos.csv", na = c("", "NA", ".")) %>% 
  mutate(totread = ifelse(totread == 0, NA, totread)) 

# means and sds by condition

ramos_summary <- ramos %>%
  group_by(congruency, task, IA_LABEL) %>%
  summarise(
    mean_totread = mean(totread, na.rm = TRUE),
    sd_totread = sd(totread, na.rm = TRUE),
    min_totread = min(totread, na.rm = TRUE),
    max_totread = max(totread, na.rm = TRUE),
    iqr_totread = IQR(totread, na.rm = TRUE),
    n = n()
  )

ramos %>%
  filter(IA_LABEL == "Target") %>%
  group_by(congruency, task) %>%
  summarise(
    mean_totread = mean(totread, na.rm = TRUE),
    sd_totread = sd(totread, na.rm = TRUE),
    min_totread = min(totread, na.rm = TRUE),
    max_totread = max(totread, na.rm = TRUE),
    iqr_totread = IQR(totread, na.rm = TRUE),
    n = n()
  )


# raincloud plots by congruency and task. facet by IA_LABEL. use gghalves package

ramos %>%
  filter(IA_LABEL != "Context") %>%
  ggplot(aes(x = congruency, y = totread, fill = congruency)) +
  gghalves::geom_half_boxplot(
    side = "l",
    outlier.color = "red",
    alpha = 0.5,
    width = 0.3,
    errorbar.draw = TRUE
  ) +
  gghalves::geom_half_violin(
    side = "r",
    alpha = 0.5,
    width = 0.3
  ) +
  geom_jitter(aes(color = congruency),
    position = position_jitterdodge(dodge.width = 0.3, jitter.width = 0.1),
    alpha = 0.2,
    size = 1
  ) +
  facet_grid(IA_LABEL ~ task) +
  labs(title = "Total Reading Time by Congruency and Task",
       x = "Congruency",
       y = "Total Reading Time (ms)") +
  theme_minimal()

# fit initial model

# sum contrasts for congruency and task
ramos <- ramos %>%
  mutate(
    congruency = factor(congruency, levels = c("incongruent", "congruent")),
    task = factor(task, levels = c("entertainment", "fact_check")),
    participant = factor(participant),
    item = factor(item)
  )

contrasts(ramos$congruency) <- c(-1,1)
contrasts(ramos$task) <- c(-1,1)

ramos_model <- lmer(totread ~ congruency * task + 
                       (1 | participant) + 
                       (1   | item),
                     data = ramos %>% filter(IA_LABEL == "Target")
                     )
summary(ramos_model)
# power analysis using simr


ramos_simr <- ramos_model %>%
  extend(
    along = "participant",
    n = 150
  ) 

fixef(ramos_simr)["congruency1"] <- -200

power_congruency <- powerSim(ramos_simr,
                               test = fixed("congruency1", "t"),
                               nsim = 100
                               )
print(power_congruency)
power_congruency_curve <- powerCurve(ramos_simr,
                                       test = fixed("congruency1", "t"),
                                       along = "participant",
                                       breaks = c(30, 50, 70, 90, 110, 130, 150),
                                       nsim = 100
                                       )
plot(power_congruency_curve)

fixef(ramos_simr)["congruency1"] <- -200
fixef(ramos_simr)["congruency1:task1"] <- 100

power_interaction <- powerSim(ramos_simr,
                                 test = fixed("congruency1:task1", "t"),
                                 nsim = 100
                                 )
print(power_interaction)
power_interaction_curve <- powerCurve(ramos_simr,
                                         test = fixed("congruency1:task1", "t"),
                                         along = "participant",
                                         breaks = c(30, 50, 70, 90, 110, 130, 150),
                                         nsim = 100
                                         )
plot(power_interaction_curve)

# power analysis for task main effect

fixef(ramos_simr)["task1"] <- 100
power_task <- powerSim(ramos_simr,
                            test = fixed("task1", "t"),
                            nsim = 100
                            )
print(power_task)
power_task_curve <- powerCurve(ramos_simr,
                                    test = fixed("task1", "t"),
                                    along = "participant",
                                    breaks = c(30, 50, 70, 90, 110, 130, 150),
                                    nsim = 200
                                    )
plot(power_task_curve)
