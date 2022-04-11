#################################
# X. Startup
#################################

packages <- c("data.table",
             "readxl",
             "excel.link",
             "dplyr",
             "here")

#install.packages(packages)


invisible(lapply(packages, library, character.only = TRUE))


#################################
# E. Excel
#################################

### E.1 Defining Directory ###

master_dir <- paste0(here::here(),"/")

player_data_file <- "2022-student-research-case-study-player-data.xlsx"
input_file <- "01_SOA_Model_Input_v0.1.xlsm"


### E.2 Extracting Excel Data ###
# sg = shooting, pg = passing, df = defense, gk = goalkeeping

## E.2.1 League Data ##
player.sg_league <- data.table(readxl::read_excel(paste0(master_dir,player_data_file), range = "'League Shooting!B12:AA5566",na="", guess_max=Inf))
player.pg_league <- data.table(readxl::read_excel(paste0(master_dir,player_data_file), range = "'League Passing!B12:AF5566",na="", guess_max=Inf))
player.df_league <- data.table(readxl::read_excel(paste0(master_dir,player_data_file), range = "'League Defense!B12:AG5566",na="", guess_max=Inf))
player.gk_league <- data.table(readxl::read_excel(paste0(master_dir,player_data_file), range = "'League Goalkeeping!B12:AB425",na="", guess_max=Inf))

## E.2.2 Tournament Data
player.sg_tournament <- data.table(readxl::read_excel(paste0(master_dir,player_data_file), range = "'Tournament Shooting!B12:Z2027",na="", guess_max=Inf))
player.pg_tournament <- data.table(readxl::read_excel(paste0(master_dir,player_data_file), range = "'Tournament Passing!B12:AE500",na="", guess_max=Inf))
player.df_tournament <- data.table(readxl::read_excel(paste0(master_dir,player_data_file), range = "'Tournament Defense!B12:AF500",na="", guess_max=Inf))
player.gk_tournament <- data.table(readxl::read_excel(paste0(master_dir,player_data_file), range = "'Tournament Goalkeeping!B12:AA141",na="", guess_max=Inf))


#################################
# 0. Data Cleaning 
#################################

### 0.1 Sub-setting Tournament Data by Year ###

## 0.1.1 League Data 2021
player.sg_league_2021 <- player.sg_league[player.sg_league$Year == 2021]
player.pg_league_2021 <- player.pg_league[player.pg_league$Year == 2021]
player.df_league_2021 <- player.df_league[player.df_league$Year == 2021]
player.gk_league_2021 <- player.gk_league[player.gk_league$Year == 2021]

## 0.1.2 Tournament Data 2021
player.sg_tournament_2021 <- player.sg_tournament[player.sg_tournament$Year == 2021]
player.pg_tournament_2021 <- player.pg_tournament[player.pg_tournament$Year == 2021]
player.df_tournament_2021 <- player.df_tournament[player.df_tournament$Year == 2021]
player.gk_tournament_2021 <- player.gk_tournament[player.gk_tournament$Year == 2021]

#################################
# 1. Data Configuration
#################################

### Input Key Parameters of Simulation

# Finding span of Simulation in Input Excel
end_row <- data.table(readxl::read_excel(paste0(master_dir,input_file), range = "'Input!C3:C4",na=""))
input_xl_NA <- data.table(readxl::read_excel(paste0(master_dir,input_file), range = paste0("'Input!B6:I",end_row),na=""))
input_xl <- input_xl_NA[rowSums(is.na(input_xl_NA)) != ncol(input_xl_NA), ]

# Defining Number of Simulations
param.number_of_scenario <- length(t(input_xl[,1])) 


# Defining Report Type
report_info <- data.table(readxl::read_excel(paste0(master_dir,input_file), range = "'Input!K6:L11",na="", col_names = FALSE))
league_info <- data.table(readxl::read_excel(paste0(master_dir,input_file), range = "'Input!N39:O45",na="", col_names = TRUE))
 

if(report_info[1,2] == "Project"){
  player_info <- data.table(na.omit(readxl::read_excel(paste0(master_dir,input_file), range = "'Input!K15:L42",na="", col_names = TRUE)))
  
  rnt_sg <- data.table(readxl::read_excel(paste0(master_dir,input_file), range = "'RNT - Adjusted!B4:AA26",na="", col_names = TRUE))
  rnt_pg <- data.table(readxl::read_excel(paste0(master_dir,input_file), range = "'RNT - Adjusted!B34:AF56",na="", col_names = TRUE))
  rnt_df <- data.table(readxl::read_excel(paste0(master_dir,input_file), range = "'RNT - Adjusted!B64:AG86",na="", col_names = TRUE))
  rnt_gk <- data.table(readxl::read_excel(paste0(master_dir,input_file), range = "'RNT - Adjusted!B94:AC96",na="", col_names = TRUE))
  
  rnt_sg <- rnt_sg %>% mutate(Nation = "Rarita") %>% select(unlist(names(player.sg_tournament_2021)))
  player.sg_tournament_2021 <- rbind(rnt_sg,player.sg_tournament_2021)
  
  rnt_pg <- rnt_pg %>% mutate(Nation = "Rarita") %>% select(unlist(names(player.pg_tournament_2021)))
  player.pg_tournament_2021 <- rbind(rnt_pg,player.pg_tournament_2021)
  
  rnt_df <- rnt_df %>% mutate(Nation = "Rarita") %>% select(unlist(names(player.df_tournament_2021)))
  player.df_tournament_2021 <- rbind(rnt_df,player.df_tournament_2021)
  
  rnt_gk <- rnt_gk %>% mutate(Nation = "Rarita") %>% select(unlist(names(player.gk_tournament_2021)))
  player.gk_tournament_2021 <- rbind(rnt_gk,player.gk_tournament_2021)
  
  
  years_future <- as.numeric(report_info[2,2]) - 2021
  
  if(years_future >= 1){
    age_info <- data.table(readxl::read_excel(paste0(master_dir,input_file), range = "'Input!N13:O37",na="", col_names = TRUE))
    
    exc_col <- c("Player", "Nation", "Pos", "Age", "Born")
    
    for(j in 1: years_future){
      
    # Shooting
    player.sg_tournament_raw <- player.sg_tournament_2021 %>%
                                  inner_join(age_info, by = c("Age"))
    
    player.age_vec <- unlist(c(player.sg_tournament_raw[, "Factor"]))
    player.age_factor_1 <- data.table(matrix(player.age_vec, length(player.age_vec), 12))
    player.age_factor_2 <- data.table(matrix(player.age_vec, length(player.age_vec), 6))
    
    player.sg_tournament_fut <- player.sg_tournament_raw %>% select(-c("Factor"))
    player.sg_tournament_fut[,6:17] <- player.sg_tournament_fut[,6:17] * player.age_factor_1
    player.sg_tournament_fut[, 20:25] <- player.sg_tournament_fut[,20:25] * player.age_factor_2
    
    player.sg_tournament_fut <- player.sg_tournament_fut %>% 
                                  mutate(Age = Age + 1, Year = Year + 1)
    player.sg_tournament_2021 <- player.sg_tournament_fut
    
    # Passing
    player.pg_tournament_fut <- player.pg_tournament_2021 %>%
                                     inner_join(age_info, by = c("Age"))
    player.pg_tournament_fut[,6:28] <- player.pg_tournament_fut[,6:28] * data.table(matrix(player.age_vec, length(player.age_vec), 23))
    
    player.pg_tournament_2021 <- player.pg_tournament_fut %>% 
      mutate(Age = Age + 1, Year = Year + 1)
    
    # Defense
    player.df_tournament_fut <- player.df_tournament_2021 %>%
                                  inner_join(age_info, by = c("Age"))
    
    player.age_vec_df <- unlist(c(player.df_tournament_fut[, "Factor"]))
    player.df_tournament_fut[,6:29] <- player.df_tournament_fut[,6:29] * data.table(matrix(player.age_vec_df, length(player.age_vec_df), 24))
    player.df_tournament_fut <- player.df_tournament_fut %>% select(-c("Factor"))
    
    player.df_tournament_2021 <- player.df_tournament_fut %>% 
      mutate(Age = Age + 1, Year = Year + 1)
    
    # GK
    player.gk_tournament_fut <- player.gk_tournament_2021 %>%
      inner_join(age_info, by = c("Age"))
    
    player.age_vec_gk <- unlist(c(player.gk_tournament_fut[, "Factor"]))
    player.gk_tournament_fut[,6:24] <- player.gk_tournament_fut[,6:24] * data.table(matrix(player.age_vec_gk, length(player.age_vec_gk), 19))
    player.gk_tournament_fut <- player.gk_tournament_fut %>% select(-c("Factor"))
    
    player.gk_tournament_2021 <- player.gk_tournament_fut %>% 
      mutate(Age = Age + 1, Year = Year + 1)
    

    }
  }
}


# Setting up Output Table
results_output <- data.table(matrix(0, nrow = param.number_of_scenario, ncol = 3))
pos_output <- data.table(matrix(0, nrow = param.number_of_scenario, ncol = 2))


### Start Loop
for (i in 1:param.number_of_scenario){

home <- as.character(input_xl[i, "Home"])
away <- as.character(input_xl[i, "Away"])
param.number_of_sim <- as.numeric(input_xl[i, "Sim.Num"])
param.seed <- as.numeric(input_xl[i, "Seed"])


home.sg_raw <- player.sg_tournament_2021[player.sg_tournament_2021$Nation == home]
home.sg_sorted <- home.sg_raw[home.sg_raw$`90s` >= 0.5] 

home.pg_raw <- player.pg_tournament_2021[player.pg_tournament_2021$Nation == home]
home.pg_sorted <- home.pg_raw[home.pg_raw$`90s` >= 0.5] 

home.df_raw <- player.df_tournament_2021[player.df_tournament_2021$Nation == home]
home.df_sorted <- home.df_raw[home.df_raw$`90s` >= 0.5] 

home.gk_raw <- player.gk_tournament_2021[player.gk_tournament_2021$Nation == home]
home.gk_sorted <- home.gk_raw[home.gk_raw$`Playing Time 90s` >= 0.5] 

##Then Away


away.sg_raw <- player.sg_tournament_2021[player.sg_tournament_2021$Nation == away]
away.sg_sorted <- away.sg_raw[away.sg_raw$`90s` >= 0.5] 

away.pg_raw <- player.pg_tournament_2021[player.pg_tournament_2021$Nation == away]
away.pg_sorted <- away.pg_raw[away.pg_raw$`90s` >= 0.5] 

away.df_raw <- player.df_tournament_2021[player.df_tournament_2021$Nation == away]
away.df_sorted <- away.df_raw[away.df_raw$`90s` >= 0.5] 

away.gk_raw <- player.gk_tournament_2021[player.gk_tournament_2021$Nation == away]
away.gk_sorted <- away.gk_raw[away.gk_raw$`Playing Time 90s` >= 0.5] 



#################################
# 2. Data Manipulation
#################################

#---------------------------------#

### 2.1 Tournament Data 2021 - Shooting ###

#---------------------------------#

## 2.1.1 Home - Who is Shooting?

home.sg_sh.90 <- home.sg_sorted[,"Standard Sh/90"] # Cannot have negative number for this figure
home.sg_sh.90[home.sg_sh.90 < 0] <- 0

home.sg_sh.90_sum <- sum(home.sg_sh.90, na.rm = TRUE)
home.sg_percentage <- home.sg_sh.90 / home.sg_sh.90_sum

## 2.1.2 Home - Shot on Target?

home.sg_sot.90 <-  pmax(home.sg_sorted[,"Standard SoT/90"],0) # Cannot have negative number for this figure
home.sg_sot.90[is.na(home.sg_sot.90)] <- colMeans(home.sg_sot.90, na.rm = TRUE)
home.sg_sot.percentage <- home.sg_sot.90 / home.sg_sh.90
home.sg_sot.percentage[home.sg_sot.percentage$`Standard SoT/90` > 1] <- 0

## 2.1.4 Home - Collate

home.sg_stat <- cbind(home.sg_sorted[,c("Player", "Nation")],
                      home.sg_percentage,
                      home.sg_sot.percentage)

setnames(home.sg_stat, c("Player", "Nation", "Shoot %", "SoT %"))

#---------------------------------#
## 2.1.1a Away - Who is Shooting?

away.sg_sh.90 <- away.sg_sorted[,"Standard Sh/90"] # Cannot have negative number for this figure
away.sg_sh.90[away.sg_sh.90 < 0] <- 0

away.sg_sh.90_sum <- sum(away.sg_sh.90, na.rm = TRUE)
away.sg_percentage <- away.sg_sh.90 / away.sg_sh.90_sum




## 2.1.2a Away - Shot on Target?

away.sg_sot.90 <-  pmax(away.sg_sorted[,"Standard SoT/90"],0) # Cannot have negative number for this figure
away.sg_sot.90[is.na(away.sg_sot.90)] <- colMeans(away.sg_sot.90, na.rm = TRUE)
away.sg_sot.percentage <- away.sg_sot.90 / away.sg_sh.90
away.sg_sot.percentage[away.sg_sot.percentage$`Standard SoT/90` > 1] <- 0


## 2.1.4a Away - Collate

away.sg_stat <- cbind(away.sg_sorted[,c("Player", "Nation")],
                      away.sg_percentage,
                      away.sg_sot.percentage)

setnames(away.sg_stat, c("Player", "Nation", "Shoot %", "SoT %"))


#---------------------------------#

### 2.2 Tournament Data 2021 - Passing ###

#---------------------------------#
## 2.2.1 Home - Team Pass Attempted

home.pg_90_vec <- home.pg_sorted %>% select(`90s`) %>%  mutate(`90s` = replace(`90s`, `90s` <= 1, 1))

home.pg_pass_90 <- data.table(cbind(home.pg_sorted[, "Short Att"] / home.pg_90_vec,
                                    home.pg_sorted[, "Medium Att"]/ home.pg_90_vec,
                                    home.pg_sorted[, "Long Att"]/ home.pg_90_vec))

setnames(home.pg_pass_90, c("Short Pass/90", "Medium Pass/90", "Long Pass/90"))


# 2.2.2 Home - Check Average Pass % from player
home.pg_total_pass_90 <- colSums(home.pg_pass_90)
home.pg_pass_percent <-  cbind(home.pg_pass_90[, "Short Pass/90"] / as.numeric(home.pg_total_pass_90["Short Pass/90"]),
                               home.pg_pass_90[, "Medium Pass/90"] / as.numeric(home.pg_total_pass_90["Medium Pass/90"]),
                               home.pg_pass_90[, "Long Pass/90"] / as.numeric(home.pg_total_pass_90["Long Pass/90"]))

setnames(home.pg_pass_percent, c("Player Short Pass Weight%", "Player Medium Pass Weight%", "Player Long Pass Weight%"))


# 2.2.3 Home - Calculate Pass Accuracy of Team (Weighted by % pass made by each player)


home.pg_stat_success <- data.table(cbind(sum(home.pg_sorted[, "Short Cmp%"] * home.pg_pass_percent[, "Player Short Pass Weight%"], na.rm = TRUE) / 100,
                                         sum(home.pg_sorted[, "Medium Cmp%"] * home.pg_pass_percent[, "Player Medium Pass Weight%"], na.rm = TRUE) / 100,
                                         sum(home.pg_sorted[, "Long Cmp%"] * home.pg_pass_percent[, "Player Long Pass Weight%"], na.rm = TRUE) / 100))

home.pg_stat_pass_percentage <- data.table(sum(home.pg_pass_90[, "Short Pass/90"]) /sum(home.pg_pass_90),
                                           sum(home.pg_pass_90[, "Medium Pass/90"]) /sum(home.pg_pass_90),
                                           sum(home.pg_pass_90[, "Long Pass/90"]) / sum(home.pg_pass_90))

setnames(home.pg_stat_success, c("Team Short Success%", "Team Medium Success%", "Team Long Success%"))
setnames(home.pg_stat_pass_percentage, c("Short Pass%", "Medium Pass%", "Long Pass%"))



#---------------------------------#
#---------------------------------#
## 2.2.1a away - Team Pass Attempted

away.pg_90_vec <- away.pg_sorted %>% select(`90s`) %>%  mutate(`90s` = replace(`90s`, `90s` <= 1, 1))

away.pg_pass_90 <- data.table(cbind(away.pg_sorted[, "Short Att"] / away.pg_90_vec,
                                    away.pg_sorted[, "Medium Att"]/ away.pg_90_vec,
                                    away.pg_sorted[, "Long Att"]/ away.pg_90_vec))

setnames(away.pg_pass_90, c("Short Pass/90", "Medium Pass/90", "Long Pass/90"))


# 2.2.2a away - Check Average Pass % from player
away.pg_total_pass_90 <- colSums(away.pg_pass_90)
away.pg_pass_percent <-  cbind(away.pg_pass_90[, "Short Pass/90"] / as.numeric(away.pg_total_pass_90["Short Pass/90"]),
                               away.pg_pass_90[, "Medium Pass/90"] / as.numeric(away.pg_total_pass_90["Medium Pass/90"]),
                               away.pg_pass_90[, "Long Pass/90"] / as.numeric(away.pg_total_pass_90["Long Pass/90"]))

setnames(away.pg_pass_percent, c("Player Short Pass Weight%", "Player Medium Pass Weight%", "Player Long Pass Weight%"))


# 2.2.3a away - Calculate Pass Accuracy of Team (Weighted by % pass made by each player)


away.pg_stat_success <- data.table(cbind(sum(away.pg_sorted[, "Short Cmp%"] * away.pg_pass_percent[, "Player Short Pass Weight%"], na.rm = TRUE) / 100,
                                         sum(away.pg_sorted[, "Medium Cmp%"] * away.pg_pass_percent[, "Player Medium Pass Weight%"], na.rm = TRUE) / 100,
                                         sum(away.pg_sorted[, "Long Cmp%"] * away.pg_pass_percent[, "Player Long Pass Weight%"], na.rm = TRUE) / 100))

away.pg_stat_pass_percentage <- data.table(sum(away.pg_pass_90[, "Short Pass/90"]) /sum(away.pg_pass_90),
                                           sum(away.pg_pass_90[, "Medium Pass/90"]) /sum(away.pg_pass_90),
                                           sum(away.pg_pass_90[, "Long Pass/90"]) / sum(away.pg_pass_90))

setnames(away.pg_stat_success, c("Team Short Success%", "Team Medium Success%", "Team Long Success%"))
setnames(away.pg_stat_pass_percentage, c("Short Pass%", "Medium Pass%", "Long Pass%"))



#---------------------------------#

### 2.3 Tournament Data 2021 - Defense ###

#---------------------------------#

## 2.3.1T Tournament - Team Defense

# Tournament - Tackle, Pressure and Blocks Sucess %

tournament.df_team_attempted_0 <- colSums(player.df_tournament_2021[, c("Tackles Tkl", "Pressures Press")])
tournament.df_team_attempted <- data.table(cbind(t(tournament.df_team_attempted_0), sum(player.df_tournament_2021[,c("Blocks Blocks", "Blocks Sh", "Blocks ShSv", "Blocks Pass")])))

tournament.df_team_success <- colSums(player.df_tournament_2021[, c("Tackles TklW", "Pressures Succ", "Int")])
tournament.df_stat_success <- data.table(tournament.df_team_success / tournament.df_team_attempted)

setnames(tournament.df_stat_success, c("Tackle %", "Pressure %", "Interception %"))

#---------------------------------#

## 2.3.1 Home - Team Defense

# Home - Tackle, Pressure and Blocks Sucess %

home.df_team_attempted_0 <- colSums(home.df_sorted[, c("Tackles Tkl", "Pressures Press")])
home.df_team_attempted <- data.table(cbind(t(home.df_team_attempted_0), sum(home.df_sorted[,c("Blocks Blocks", "Blocks Sh", "Blocks ShSv", "Blocks Pass")])))

home.df_team_attempted_total <- sum(home.df_team_attempted)
home.df_stat_defend_percentage <- data.table(home.df_team_attempted / home.df_team_attempted_total)
setnames(home.df_stat_defend_percentage, c("Tackle%", "Pressure%", "Block%"))

home.df_team_success <- colSums(home.df_sorted[, c("Tackles TklW", "Pressures Succ", "Int")])
home.df_stat_success <- data.table(home.df_team_success / home.df_team_attempted)
setnames(home.df_stat_success, c("Tackle Success%", "Pressure Success%", "Interception Sucess%"))


#---------------------------------#

## 2.3.1a Away - Team Defense

# Away - Tackle, Pressure and Blocks Sucess %

away.df_team_attempted_0 <- colSums(away.df_sorted[, c("Tackles Tkl", "Pressures Press")])
away.df_team_attempted <- data.table(cbind(t(away.df_team_attempted_0), sum(away.df_sorted[,c("Blocks Blocks", "Blocks Sh", "Blocks ShSv", "Blocks Pass")])))

away.df_team_attempted_total <- sum(away.df_team_attempted)
away.df_stat_defend_percentage <- data.table(away.df_team_attempted / away.df_team_attempted_total)
setnames(away.df_stat_defend_percentage, c("Tackle%", "Pressure%", "Block%"))

away.df_team_success <- colSums(away.df_sorted[, c("Tackles TklW", "Pressures Succ", "Int")])
away.df_stat_success <- data.table(away.df_team_success / away.df_team_attempted)
setnames(away.df_stat_success, c("Tackle Success%", "Pressure Success%", "Interception Sucess%"))


#---------------------------------#

### 2.4 Tournament Data 2021 - GoalKeeping ###

#---------------------------------#

## 2.4.1 Home - Which Goal Keeper

home.gk_stat <- home.gk_sorted[, c("Player", "Nation")]
home.gk_team_playtime <- sum(home.gk_sorted$`Playing Time 90s`)
home.gk_stat[,"Play %" := home.gk_sorted[,"Playing Time 90s"] / home.gk_team_playtime]

## 2.4.2 Home - Save or not

home.gk_stat[,"Save %" := home.gk_sorted[,"Performance Save%"] / 100]


#---------------------------------#

## 2.4.3 Away - Which Goal Keeper

away.gk_stat <- away.gk_sorted[, c("Player", "Nation")]
away.gk_team_playtime <- sum(away.gk_sorted$`Playing Time 90s`)
away.gk_stat[,"Play %" := away.gk_sorted[,"Playing Time 90s"] / away.gk_team_playtime]

## 2.4.4 Away - Save or not

away.gk_stat[,"Save %" := away.gk_sorted[,"Performance Save%"] / 100]


#################################
# 3. Simulation
#################################

### 3.1 Posession ###

## 3.1.1 Defining type of pass type and success rate

home.sim.pg_likelihood <- home.pg_stat_pass_percentage * home.pg_stat_success
away.sim.pg_likelihood <- away.pg_stat_pass_percentage * away.pg_stat_success


## 3.1.2 Defining type of defense type and success rate

home.sim.df_likelihood <- home.df_stat_defend_percentage * (1 - home.df_stat_success) / (1 - tournament.df_stat_success)
away.sim.df_likelihood <- away.df_stat_defend_percentage * (1 - away.df_stat_success) / (1 - tournament.df_stat_success)

## 3.1.3 Finding simulation threshold

home.sim.poss_threshold <- sum(home.sim.pg_likelihood) * sum(away.sim.df_likelihood)
away.sim.poss_threshold <- sum(away.sim.pg_likelihood) * sum(home.sim.df_likelihood)

## 3.1.4 Simulating Possession - TODO HT
home.param.number_of_pass <- round(sum(home.pg_sorted[, "Total Att"] / home.pg_sorted[, "90s"])) # 11 players at any one time given no red card

away.param.number_of_pass <- round(sum(away.pg_sorted[, "Total Att"] / away.pg_sorted[, "90s"])) # 11 players at any one time given no red card



set.seed(param.seed)
home.sim.poss <- data.table(matrix(runif(home.param.number_of_pass * param.number_of_sim), nrow = home.param.number_of_pass, ncol = param.number_of_sim))
home.sim.poss_results <- colSums(home.sim.poss <= home.sim.poss_threshold )

set.seed(param.seed)
away.sim.poss <- data.table(matrix(runif(away.param.number_of_pass * param.number_of_sim), nrow = away.param.number_of_pass, ncol = param.number_of_sim))
away.sim.poss_results <- colSums(away.sim.poss <= away.sim.poss_threshold )

## 3.1.5 Calculating Possession

total.sim.poss <- home.sim.poss_results + away.sim.poss_results
results.home_poss <- home.sim.poss_results / total.sim.poss
output.home_poss <- cbind(t(summary(results.home_poss)), Variance = var(results.home_poss))

average.possession <- cbind(Home = mean(results.home_poss), Away = 1 - mean(results.home_poss))


### 3.2 Shots - Home ###
#---------------------------------#

## 3.2.1 Goals for the Home Team

# 3.2.1.1 Defining Shot parameters
# 
# shots_total <- cbind(Home = sum(home.sg_raw[, "Standard Sh"]), Away = sum(away.sg_raw[, "Standard Sh"]))
# 
# shots_home <- round(as.numeric(shots_total[,"Home"]) * average.possession[,"Home"] / average.possession[,"Away"])
# 
# # shots_home<- 40
# shots_away <- round(as.numeric(shots_total[,"Away"]) * average.possession[,"Away"] / average.possession[,"Home"])

shots_home_average <- sum(home.sg_raw[, "90s"] * home.sg_raw[, "Standard Sh"]) / sum(home.sg_raw[, "90s"]) * 11
shots_away_average <- sum(away.sg_raw[, "90s"] * away.sg_raw[, "Standard Sh"]) / sum(away.sg_raw[, "90s"]) * 11

shots_home <- round(shots_home_average * average.possession[,"Home"] / average.possession[,"Away"])

shots_away <- round(shots_away_average * average.possession[,"Away"] / average.possession[,"Home"])



# 3.2.1.2 Shooting Player and Corresponding Success Rate
set.seed(param.seed)
home.sim.shot_choose_rand <- runif(shots_home * param.number_of_sim) #Set of RN used to choose players (shooting and goalkeeping)
home.shoot_percent_cml <- cumsum(home.sg_stat$`Shoot %`)
home.sim.shot_shooting_player <- findInterval(home.sim.shot_choose_rand, home.shoot_percent_cml) + 1

# 3.2.1.3 Is the goal a SoT?
home.sim.shot_sot_percentage <- home.sg_stat[home.sim.shot_shooting_player, "SoT %"]
home.sim.shot_deciding_rand <- runif(shots_home * param.number_of_sim) #Set of RN used to decide whether the shot is blocked or a SoT

home.sim.shot_sot_percentage[home.sim.shot_sot_percentage >= home.sim.shot_deciding_rand] <- NA
home.sim.shot_sot_percentage[home.sim.shot_sot_percentage < home.sim.shot_deciding_rand] <- 0
home.sim.shot_sot_percentage[is.na(home.sim.shot_sot_percentage)] <- 1

home.sim.shot_sot_percentage <- home.sim.shot_sot_percentage[, lapply(.SD, as.numeric)]

#---------------------------------#

## 3.2.2 Defending against the Home Team

# 3.2.2.1 Who will defend - Away ? 
away.sim.gk_choose_rand <- runif(shots_away * param.number_of_sim)
away.gk_percent_cml <- cumsum(away.gk_stat$`Play %`)
away.gk_defending_player <- findInterval(away.sim.gk_choose_rand, away.gk_percent_cml) + 1

# 3.2.2.2 Defend Success Rate
away.sim.gk_save_percentage <- away.gk_stat[away.gk_defending_player, "Save %"]
away.sim.gk_save_percentage <- away.sim.gk_save_percentage[, lapply(.SD, as.numeric)]

away.sim.shot_deciding_rand <- runif(shots_home * param.number_of_sim) #Set of RN used to decide whether the shot is blocked or a SoT

away.sim.gk_save_percentage[is.na(away.sim.gk_save_percentage)] <- quantile(player.gk_tournament_2021$`Performance Save%`, 0.25, na.rm = TRUE) /100
away.sim.gk_save_percentage[away.sim.gk_save_percentage >= away.sim.shot_deciding_rand] <- 10
away.sim.gk_save_percentage[away.sim.gk_save_percentage < away.sim.shot_deciding_rand] <- 0
away.sim.gk_save_percentage[away.sim.gk_save_percentage == 10] <- 1


away.sim.gk_save_percentage <- away.sim.gk_save_percentage[, lapply(.SD, as.numeric)]

away.sim.gk_save <- away.sim.gk_save_percentage %>%
  mutate(ID_goal = seq(from = 1, to = nrow(away.sim.gk_save_percentage)), by = 1)


#---------------------------------#

## 3.2.3 Goal or not? - Home Team
home.sim.sot_90_tmp <- home.sim.shot_sot_percentage %>% 
                      mutate(ID = seq(from = 1, to = length(t(home.sim.shot_sot_percentage)), by = 1)) 

home.sim.sot_90 <- home.sim.sot_90_tmp %>%
                   filter(`SoT %` == 1) %>%
                   mutate(ID_goal = seq(from = 1, to = sum(home.sim.shot_sot_percentage), by = 1))


home.goal <- home.sim.sot_90_tmp %>%
                left_join(home.sim.sot_90, by = c("ID")) %>%
                left_join(away.sim.gk_save, by = c("ID_goal")) %>%
                replace(is.na(.), 0) %>% 
                mutate(goal = `SoT %.x` - `Save %`) %>%
                select(goal)
  
  
#---------------------------------#
#---------------------------------#


### 3.2a Shots - Away ###
#---------------------------------#

## 3.2.1a Goals for the Away Team

# 3.2.1.2a Shooting Player and Corresponding Success Rate
set.seed(param.seed)
away.sim.shot_choose_rand <- runif(shots_away * param.number_of_sim) #Set of RN used to choose players (shooting and goalkeeping)
away.shoot_percent_cml <- cumsum(away.sg_stat$`Shoot %`)
away.sim.shot_shooting_player <- findInterval(away.sim.shot_choose_rand, away.shoot_percent_cml) + 1

# 3.2.1.3a Is the goal a SoT?
away.sim.shot_sot_percentage <- away.sg_stat[away.sim.shot_shooting_player, "SoT %"]
away.sim.shot_deciding_rand <- runif(shots_away * param.number_of_sim) #Set of RN used to decide whether the shot is blocked or a SoT

away.sim.shot_sot_percentage[away.sim.shot_sot_percentage >= away.sim.shot_deciding_rand] <- NA
away.sim.shot_sot_percentage[away.sim.shot_sot_percentage < away.sim.shot_deciding_rand] <- 0
away.sim.shot_sot_percentage[is.na(away.sim.shot_sot_percentage)] <- 1

away.sim.shot_sot_percentage <- away.sim.shot_sot_percentage[, lapply(.SD, as.numeric)]


#---------------------------------#

## 3.2.2 Defending against the Away Team

# 3.2.2.1 Who will defend - Home ? 
home.sim.gk_choose_rand <- runif(shots_home * param.number_of_sim)
home.gk_percent_cml <- cumsum(home.gk_stat$`Play %`)
home.gk_defending_player <- findInterval(home.sim.gk_choose_rand, home.gk_percent_cml) + 1


# 3.2.2.2 Defend Success Rate
home.sim.gk_save_percentage <- home.gk_stat[home.gk_defending_player, "Save %"]
home.sim.gk_save_percentage <- home.sim.gk_save_percentage[, lapply(.SD, as.numeric)]

home.sim.shot_deciding_rand <- runif(shots_away * param.number_of_sim) #Set of RN used to decide whether the shot is blocked or a SoT

home.sim.gk_save_percentage[is.na(home.sim.gk_save_percentage)] <- quantile(player.gk_tournament_2021$`Performance Save%`, 0.25, na.rm = TRUE) /100
home.sim.gk_save_percentage[home.sim.gk_save_percentage >= home.sim.shot_deciding_rand] <- 10
home.sim.gk_save_percentage[home.sim.gk_save_percentage < home.sim.shot_deciding_rand] <- 0
home.sim.gk_save_percentage[home.sim.gk_save_percentage == 10] <- 1


home.sim.gk_save_percentage <- home.sim.gk_save_percentage[, lapply(.SD, as.numeric)]

home.sim.gk_save <- home.sim.gk_save_percentage %>%
  mutate(ID_goal = seq(from = 1, to = nrow(home.sim.gk_save_percentage)), by = 1)


#---------------------------------#

## 3.2.3 Goal or not? - Away Team

away.sim.sot_90_tmp <- away.sim.shot_sot_percentage %>% 
                          mutate(ID = seq(from = 1, to = length(t(away.sim.shot_sot_percentage)), by = 1)) 

away.sim.sot_90 <- away.sim.sot_90_tmp %>%
                      filter(`SoT %` == 1) %>%
                      mutate(ID_goal = seq(from = 1, to = sum(away.sim.shot_sot_percentage), by = 1))


away.goal <- away.sim.sot_90_tmp %>%
                  left_join(away.sim.sot_90, by = c("ID")) %>%
                  left_join(home.sim.gk_save, by = c("ID_goal")) %>%
                  replace(is.na(.), 0) %>% 
                  mutate(goal = `SoT %.x` - `Save %`) %>%
                  select(goal)






## 3.2.4 Consolidating
home.goal <- home.goal[, lapply(.SD, as.numeric)]
away.goal <- away.goal[, lapply(.SD, as.numeric)]

home.goal_csl <- data.table(matrix(c(unlist(home.goal[,1])), nrow = shots_home, ncol = param.number_of_sim))
away.goal_csl <- data.table(matrix(c(unlist(away.goal[,1])), nrow = shots_away, ncol = param.number_of_sim))

result <- data.table(cbind(colSums(home.goal_csl), colSums(away.goal_csl)))
setnames(result, c("Home", "Away"))

results_csl <- result$Home - result$Away
result_score_csl <- data.table(cbind(length(results_csl[results_csl>0]), length(results_csl[results_csl<0]), length(results_csl[results_csl == 0])))
setnames(result_score_csl, c("Home", "Away", "Draw"))

sum(home.goal)
sum(away.goal)
result_score_csl

#################################
# 4. Output
#################################

results_output[eval(i),] <- result_score_csl
pos_output[eval(i),] <- data.table(average.possession)

print(paste0(i, " out of ", param.number_of_scenario))

}

xls = xl.get.excel()

xl.write(results_output, xls[["Activesheet"]]$Cells(4, 4),row.names = FALSE,col.names = FALSE)
xl.write(pos_output, xls[["Activesheet"]]$Cells(4, 7),row.names = FALSE,col.names = FALSE)
