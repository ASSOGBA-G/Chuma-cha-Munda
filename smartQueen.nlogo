;;author: Gildas Assogba
;;this is a computerized version of the serious game QUEEN
;;aiming at simulaing biomass fluxes at household and
;;village scale
;;2025
__includes ["biomtransfer.nls" "message.nls" "exportresults.nls" "explo_core.nls" "market_explo.nls" "market_play.nls"
  "biomtransfer_explo.nls" "cropSy.nls" "cropSy_hubnet.nls" "common.nls" "smart.nls" "smart_transfer.nls" "smart_market.nls"]

extensions [csv gini.jar]
globals [
  player1pos
  player2pos
  player3pos
  player4pos
  player1type
  player2type
  player3type
  player4type
  season;;type of season: 0=bad, 1=good, 2=very good
  saison;; explanation of season, see set up
  month
  mois
  crop-inputs;;inputs in the cropping system
  crop-inputs1;;inputs in the cropping system. player 1
  crop-inputs2
  crop-inputs3
  crop-inputs4
  t-crop-inputs;;temporary inputs in the cropping system. used for update
  t-crop-inputs1;;inputs in the cropping system. player 1
  t-crop-inputs2
  t-crop-inputs3
  t-crop-inputs4
  crop-head;;head of matrix
  ngseason;;ngseason: grain units per season
  nrseason;; nrseason: residue units
  cultivplot;; cultivated plots
  bushplot;;bush
  farmers;;farms
  farmi;;list of farms
  government;; government and private sector agent
  graine
  resid
  accessresid;;access to residue y/n
  mn;;event: manure creation on bushplot, happen once
  cc;;animal creation for farm, happen once
  livfeed?;;automatic livestock feeding with residue harvested
  maxc maxr maxd maxp maxrc;;number of farm owing a certain type of animal
  canharvest;
  exchg;if one biomass exchange already occured, used in biomexchange
  warn;display warnings related to livestock
      ;feedfam;; control family feeding (grain)
  year
  forage;livestock feeding by farmer
  day;used in reproduce and nextmonth
  idplayer; list of players
  playerlist; association of pseudo and player
  oldlist;;keep record of list of players, see create player
  oldpseudo;;keep record of old pseudo of players, see create player
  nj; index for players list
  headoutput;;head of data to be exported in separated file
  headmarket
  headflux
  output;;data to be exported in separated file
  flux;;fluxes between players
  messages;;list of messages
  buysell;;list of selling and buying
  harvstop?;;to stop the game if prop of resid to be harvest aren't normal
  sim;;simulation unique ID
  nsim
  biodiversity;;calculated based on land use, see common.nls
  gov_microfinance;; money avaible for microfinance from government. updated each year. see nextmonth procedure
  gov_loanterm;; define every round by government agent. see govmanagement in common.nls
  gov_shrubrest;; money to restore shrubland. deducted from gov_microfiance
  gov_forestrest;;money to restore forest. deducted from gov_microfinance
  micro_rate;; interest rate per laonterm (see turtles-own)
  gov_employment;;off farm opportunities. updated in govmanagement in common.nls
  equity;; gini index
]

breed [joueurs joueur]
directed-link-breed [biom_owner a-biom_owner]
directed-link-breed [biom_transfer a-biom_transfer]

patches-own [
  posit;;determine the position of the plot. e.g. plot 1
  residue;;crop residue
  grain;;grain produced on agricultural plots
  grass;; grass on bush plots only
  cultiv;; is the patch cultivated or not?y/n
  ferti;;fertilized plot
  manu;;manure applied to plot
  pailles;;mulch
  harvested;;is plot harvested? y/n
  mulch;;amount of residue on field when starting a new year
  animhere;;total of animal on a cultivated patch, used in getmanure and livsim
  manuregain
  crop1;;crops grown 1=maize, 2=pigeonpea, 3=groundnut, 4=soybean
  crop2
  crop1_irr
  crop2_irr
  intercropping;;intercropping plots yes/no
  solecropping;; monoculture plots yes/no
  intercroptype;; type of intercropping: strip / intra-hill
  intertrack;; track intercrop for bonus
  soletrack;; track monoculture for penalties
  manuretrack;;track manure/residue application for bonuses.
  manuretrack?
  soletrack?
  intertrack?
  tempgrow;;to be used in computation of production, see compute-play
  tmpvar;;to stored temporary variables
  labreq;;labor requirement of growing options on a plot
  page;;age of the plot. used in land use, common.nls
  samefield;; to identify same fields in land selling and buying and keep the spatial patter coherent. see market_play.nls
  pestattack
  sow?
]

joueurs-own [
  pseudo; name the player use entering the game
  idplay;
  residue_harvest
  irr_residue_harvest
  send_biomass
  send_to
  send_how_much
  buy_what
  who_buy
  amount_buy
  sell_what
  who_sell
  amount_sell
  biom_weight
  message_text
  message_who
  open_field?
  list_of_player
  household_members
  livestock;type of livestock to be fed
  feed;type of biomass to feed livestock with
  amount_feed;amount of fodder/conc
  diet;;for animal transfer (fed and hungry)
  plot1_crop;crop(s) assigned to each plot
  plot2_crop
  plot3_crop
  plot4_crop
  plot5_crop
  plot6_crop
  plot7_crop
  plot1_fertilizer;;fertilizer to be applied to a plot
  plot2_fertilizer
  plot3_fertilizer
  plot4_fertilizer
  plot5_fertilizer
  plot6_fertilizer
  plot7_fertilizer
  plot1_manure;;manure to be applied as organic input to a plot
  plot2_manure
  plot3_manure
  plot4_manure
  plot5_manure
  plot6_manure
  plot7_manure
  plot1_residue;;crop residues to be applied as organic input to a plot
  plot2_residue
  plot3_residue
  plot4_residue
  plot5_residue
  plot6_residue
  plot7_residue
  apply_n_fertilizer;; determine total amount of fertilizer to be applied to fields
  apply_n_manure;; determine total amount of fertilizer to be applied to fields
]

turtles-own [
  pos
  nature
  typo
  nplot
  playerpos
  player
  farm
  family_size
  ncow
  ndonkey
  nsrum
  npoultry
  nfertilizer
  ncart
  ntricycle
  ngrain
  nresidue;residue harvested
  nresiduep;residue on plots
  nconc
  nmanure
  onfarm_inc
  offfarm_inc
  fertilized
  canmove; distinguish moving agent from fictive ones
  energy;;of livestock
  neat;;number of times a residue agent is grazed
  open;;residue available for grazing
  foreignaccess;; other farm can access residue?
  grazed;;animal already ate?
  state;of livestock skinny medium fat
  repro;if an animal already reproduce during one year, y/n
  food_unsecure;; number of person food unsecure in the HH
  feedfam
  hunger;increase if an animal did not eat in a step, see reproduce
  nf;see livupdate, for fertilizer
  mulch?;;used to determined if a residue can be turned into mulch
  recolt;;
  alharv;;amount of residue harvested in a year
  crops_grown;;list of crops grown. code: 1=sorghum, 2=cowpea, 3=mungbean, 4=sesame. on position 1 to 4 resp.
  manure_crops;;amount of manure app to crops. list of 4. see above for crop position
  fertilizer_crops;;amount of fertilizer app to crops. list of 4. see above for crop position
  mulch_crops;;amount of mulch app to crops. list of 4. see above for crop position
  intcrp-tradi-prop;;proportion of tradi intercropping in the system
  intcrp-strip-prop;;proportion of strip intercropping in the system
  falsetwin?;;true/false. true if crop 1 different from crop2
  falsetwin-color;;color of second crop in intercropping
  twin;;1 or 2 to differentiate grain and residues
  age;;used for grains;;cannot be conserved more than 2 years
  prodHereNow;;to check if grains and biomass were produced the current year on a given farm
  labour;; total labor available in the household. 1 person = 1 field (3 plots). additional labor can be purchased for one season/round.
  off_farm_labour;; part of the household working off-farm.
  hired_labour
  labour_received
  labour_sent
  tractor_owner
  tractor_borrowed
  nwaterpump
  pestdamage
  mystrategy
  allstrategy
  activestrategy
  newstrategy
  newstrategy?
  strategyscore
  strategyposition
  commonvote_field
  commonvote_shrub
  commonvote_forest
  activevote_field
  activevote_forest
  activevote_shrub
  moneyborrowed
  loantime;;number of rounds since the player borrowed money from government (microfinance, no interest).
  loanterm;;number of round after which the player has to repay
  myrate;;interest rate for each farmer
  microfinance;; money avaible for microfinance from government. updated each year. see nextmonth procedure
  shrubrest;; money to restore shrubland. deducted from gov_microfiance
  forestrest;;money to restore forest. deducted from gov_microfiance
  rate;; interest rate per laonterm (see turtles-own)
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;HUBNET;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to startup
  hubnet-reset
  set-up
  listen-clients
end

to listen-clients
  while [ hubnet-message-waiting? ] [
    hubnet-fetch-message
    ifelse hubnet-enter-message? [
      create-new-player
      ask joueurs [update]
    ] [
      ifelse hubnet-exit-message? and count joueurs with [substring pseudo 0 5 = "Smart"] = 0 [
        remove-player
        set oldlist [idplay] of joueurs
      ] [
        if hubnet-exit-message? = false [
          ask joueurs with [ pseudo = hubnet-message-source ] [
            execute-command hubnet-message-tag
          ]
        ]
      ]
    ]
  ]
end

to create-new-player
  set idplayer (list "player 1" "player 2" "player 3" "player 4")

  ifelse (length hubnet-clients-list) <= 4 [
    create-joueurs 1 [
      set pseudo hubnet-message-source
      ifelse member? "player 4" oldlist[][set idplay "player 4"]
      ifelse member? "player 3" oldlist[][set idplay "player 3"]
      ifelse member? "player 2" oldlist[][set idplay "player 2"]
      ifelse member? "player 1" oldlist[][set idplay "player 1"]
      ;set idplay item nj idplayer
      set hidden? true
      set plot1_crop "maize"
      set plot2_crop "maize"
      set plot3_crop "maize"
      set plot4_crop "maize"
      set plot5_crop "maize"
      set plot6_crop "maize"
      set plot7_crop "maize"

      set plot1_fertilizer 0
      set plot2_fertilizer 0
      set plot3_fertilizer 0
      set plot4_fertilizer 0
      set plot5_fertilizer 0
      set plot6_fertilizer 0
      set plot7_fertilizer 0

      set plot1_manure 0
      set plot2_manure 0
      set plot3_manure 0
      set plot4_manure 0
      set plot5_manure 0
      set plot6_manure 0
      set plot7_manure 0

      set plot1_residue 0
      set plot2_residue 0
      set plot3_residue 0
      set plot4_residue 0
      set plot5_residue 0
      set plot6_residue 0
      set plot7_residue 0

      set residue_harvest 0
      set send_biomass "residue"
      set send_to "player 1"
      set send_how_much 0
      set buy_what "manure"
      set who_buy "player 1"
      set amount_buy 0
      set sell_what "manure"
      set who_sell "player 1"
      set amount_sell 0
      set biom_weight "skinny"
      set open_field? true
      set message_who "player 1"
      set amount_feed 0
      set feed "residue"
      set livestock "cattle"
      set diet "fed"
      move-to patch-at 0 0
      ;set playerlist fput item nj idplayer playerlist
      ;set playerlist fput pseudo playerlist
    ]
    set nj nj + 1
    set oldlist sort [idplay] of joueurs; set oldpseudo hubnet-clients-list
  ]
  [user-message "Maximum number of player reached"]
end

to remove-player
  ask joueurs with [pseudo = hubnet-message-source][die]
end

to go
  listen-clients
  ask joueurs [
    livupdate idplay
    update
  ]
end

to update
  let stck 0 let stck2 0 let rskc 0 let rsks 0 let rskd 0
  let cfed 0 let srfed 0 let dfed 0 let residharvcap 0
  let idplays idplay
  ;hubnet-send pseudo "nplot" item 0[nplot] of farmers with [player = idplays]
  hubnet-send pseudo "cattle" item 0[ncow] of farmers with [player = idplays]
  hubnet-send pseudo "srum" item 0[nsrum] of farmers with [player = idplays]
  hubnet-send pseudo "donkey" item 0[ndonkey] of farmers with [player = idplays]
  ;hubnet-send pseudo "poultry" item 0[npoultry] of farmers with [player = idplays]
  ;hubnet-send pseudo "nplot" item 0 [nplot] of farmers with [player = idplays]
  hubnet-send pseudo "fertilizer" item 0[nfertilizer] of farmers with [player = idplays]
  ;hubnet-send pseudo "tricycle" item 0[ntricycle] of farmers with [player = idplays]
  ;hubnet-send pseudo "cart" item 0[ncart] of farmers with [player = idplays]
  hubnet-send pseudo "grain" item 0[ngrain] of farmers with [player = idplays]
  hubnet-send pseudo "household_members" item 0[family_size] of farmers with [player = idplays]
  ;hubnet-send pseudo "residue harv" item 0[nresidue] of farmers with [player = idplays]
  ask farmers with [player = idplays][
    set stck count out-link-neighbors with [typo = "residue" and hidden? = true and shape = "star"]
    set stck2 count out-link-neighbors with [typo = "residue" and hidden? = false and shape = "star" and mulch? != true]
    set rskc count out-link-neighbors with [shape = "cow" and canmove = "yes" and hunger < 0]
    set rsks count out-link-neighbors with [shape = "sheep" and canmove = "yes" and hunger < 0]
    set rskd count out-link-neighbors with [shape = "wolf" and canmove = "yes" and hunger < 0]
    set cfed count out-link-neighbors with [shape = "cow" and canmove != 0 and grazed = "yes"]
    set srfed count out-link-neighbors with [shape = "sheep" and canmove != 0 and grazed = "yes"]
    set dfed count out-link-neighbors with [shape = "wolf" and canmove != 0 and grazed = "yes"]
    set residharvcap labour;;(floor (family_size / 2)) + ncow + ndonkey
  ]
  hubnet-send pseudo "stock residue" stck
  ;hubnet-send pseudo "residue on field" stck2
  ;hubnet-send pseudo "residue harvest capacity" residharvcap
  hubnet-send pseudo "labour" item 0[labour] of farmers with [player = idplays]
  hubnet-send pseudo "manure" item 0[nmanure] of farmers with [player = idplays]
  ;hubnet-send pseudo "conc" item 0[nconc] of farmers with [player = idplays]
  hubnet-send pseudo "manure" item 0[nmanure] of farmers with [player = idplays]
  ;hubnet-send pseudo "off farm" item 0[offfarm_inc] of farmers with [player = idplays]
  hubnet-send pseudo "total income" item 0[onfarm_inc + offfarm_inc] of farmers with [player = idplays]
  hubnet-send pseudo "risky cow" rskc hubnet-send pseudo "risky srum" rsks hubnet-send pseudo "risky donkey" rskd
  hubnet-send pseudo "cattle_fed" cfed hubnet-send pseudo "srum_fed" srfed hubnet-send pseudo "donkey_fed" dfed
  hubnet-send pseudo "food unsecure" item 0[food_unsecure] of farmers with [player = idplays]
  hubnet-send pseudo "pseudo_" pseudo
  hubnet-send pseudo "name" idplay
  hubnet-send pseudo "month" month
  hubnet-send pseudo "year" year
  ifelse month != "December" [hubnet-send pseudo "season" saison][hubnet-send pseudo "season" ""]
  if length hubnet-clients-list = length oldlist [
    let mylist []
    ask joueurs with [idplay = "player 1"][set mylist fput pseudo mylist]
    ask joueurs with [idplay = "player 2"][set mylist lput pseudo mylist]
    ask joueurs with [idplay = "player 3"][set mylist lput pseudo mylist]
    ask joueurs with [idplay = "player 4"][set mylist lput pseudo mylist]
    hubnet-send pseudo "list_of_player" (map [[a b] -> (word a "=" b " ||")] oldlist mylist)]
  ;if idplay = "player 1" [set presid1 100 - residue_harvest]
  ;if idplay = "player 2" [set presid2 100 - residue_harvest]
  ;if idplay = "player 3" [set presid3 100 - residue_harvest]
  ;if idplay = "player 4" [set presid4 100 - residue_harvest]
end

to execute-command [command ]
  if command = "transfer_biomass" [biomtransfer]
  if command = "Market" [market-play]
  if command = "feed family" [feedfamily idplay livupdate idplay]
  if command = "feed livestock" [directfeed-play idplay livestock]
  if command = "harvest residue" [harvest]
  if command = "send message" [message]
  if command = "apply resources" [investfarm-play]
  if member? command ["transfer_biomass" "Market" "feed family" "send message"
    "feed livestock" "harvest residue" "apply resources"] = false [
    receive-message
  ]
end


to set-up
  ;clear-drawing clear-patches
  clear-all-plots clear-patches
  ask turtles with [breed != joueurs][die]
  set nj 0
  set cc 0
  set idplayer (list "player 1" "player 2" "player 3" "player 4")
  set oldlist []
  set season "";;one-of (list "Good" "Bad");;(list "Good" "Bad" "Bad" "Good" "Good");;fixed as played
  set mois (list "December" "May" "June")
  set farmers turtles with [shape = "person farmer"]
  set harvstop? false
  set month item 0 mois
  set canharvest 0
  set year 1 set day 0
  reset-ticks
  set headoutput (list "sim" "year" "month" "p1type" "p2type" "p3type" "p4type" "p1cattle" "p2cattle" "p3cattle" "p4cattle" "vcattle"
    "p1srum" "p2srum" "p3srum" "p4srum" "vsrum" "p1donkey" "p2donkey" "p3donkey" "p4donkey" "vdonkey" "p1famsize" "p2famsize"
    "p3famsize" "p4famsize" "vfamsize" "p1cart" "p2cart" "p3cart" "p4cart" "p1trcycl" "p2trcycl" "p3trcycl" "p4trcycl"
    "p1fert" "p2fert" "p3fert" "p4fert" "vfert" "p1man" "p2man" "p3man" "p4man" "vman"
    "p1grain" "p2grain" "p3grain" "p4grain" "vgrain"
    "p1residHarv" "p2residHarv" "p3residHarv" "p4residHarv" "vresidHarv"
    "p1residstck" "p2residstck" "p3residstck" "p4residstck" "vresidstck"
    "p1residsoil" "p2residsoil" "p3residsoil" "p4residsoil" "vresidsoil"
    "p1residsoilp" "p2residsoilp" "p3residsoilp" "p4residsoilp"
    "p1openfield" "p2openfield" "p3openfield" "p4openfield"
    "p1conc" "p2conc" "p3conc" "p4conc" "p1fdunsec" "p2fdunsec" "p3fdunsec" "p4fdunsec" "vfdunsec"
    "p1onfinc" "p2onfinc" "p3onfinc" "p4onfinc"
    "p1offinc" "p2offinc" "p3offinc" "p4offinc" "vinc")
  set headmarket (list "sim" "year" "month" "transaction" "player" "what" "amount")
  set headflux (list "sim" "year" "month" "sender" "receiver" "what" "amount")
  set crop-head (list "sim" "year" "month" "pcrop1" "pcrop2" "pcrop3" "pcrop4" "pintcrp-tradi" "pintcrp-strip" "manureapp" "fertapp" "mulchapp"
    "pman-crop1" "pman-crop2" "pman-crop3" "pman-crop4" "pfert-crop1" "pfert-crop2" "pfert-crop3" "pfert-crop4"
    "grainT" "grainH" "grain1" "grain2" "grain3" "grain4" "residharvT" "residharvH" "residharv1" "residharv2" "residharv3" "residharv4"
    "pcrop1-p1" "pcrop2-p1" "pcrop3-p1" "pcrop4-p1" "pintcrp-tradi-p1" "pintcrp-strip-p1" "manureapp-p1" "fertapp-p1" "mulchapp-p1"
    "pman-crop1-p1" "pman-crop2-p1" "pman-crop3-p1" "pman-crop4-p1" "pfert-crop1-p1" "pfert-crop2-p1" "pfert-crop3-p1" "pfert-crop4-p1"
    "grainT-p1" "grainH-p1" "grain1-p1" "grain2-p1" "grain3-p1" "grain4-p1" "residharvT-p1" "residharvH-p1" "residharv1-p1" "residharv2-p1" "residharv3-p1" "residharv4-p1"
    "pcrop1-p2" "pcrop2-p2" "pcrop3-p2" "pcrop4-p2" "pintcrp-tradi-p2" "pintcrp-strip-p2" "manureapp-p2" "fertapp-p2" "mulchapp-p2"
    "pman-crop1-p2" "pman-crop2-p2" "pman-crop3-p2" "pman-crop4-p2" "pfert-crop1-p2" "pfert-crop2-p2" "pfert-crop3-p2" "pfert-crop4-p2"
    "grainT-p2" "grainH-p2" "grain1-p2" "grain2-p2" "grain3-p2" "grain4-p2" "residharvT-p2" "residharvH-p2" "residharv1-p2" "residharv2-p2" "residharv3-p2" "residharv4-p2"
    "pcrop1-p3" "pcrop2-p3" "pcrop3-p3" "pcrop4-p3" "pintcrp-tradi-p3" "pintcrp-strip-p3" "manureapp-p3" "fertapp-p3" "mulchapp-p3"
    "pman-crop1-p3" "pman-crop2-p3" "pman-crop3-p3" "pman-crop4-p3" "pfert-crop1-p3" "pfert-crop2-p3" "pfert-crop3-p3" "pfert-crop4-p3"
    "grainT-p3" "grainH-p3" "grain1-p3" "grain2-p3" "grain3-p3" "grain4-p3" "residharvT-p3" "residharvH-p3" "residharv1-p3" "residharv2-p3" "residharv3-p3" "residharv4-p3"
    "pcrop1-p4" "pcrop2-p4" "pcrop3-p4" "pcrop4-p4" "pintcrp-tradi-p4" "pintcrp-strip-p4" "manureapp-p4" "fertapp-p4" "mulchapp-p4"
    "pman-crop1-p4" "pman-crop2-p4" "pman-crop3-p4" "pman-crop4-p4" "pfert-crop1-p4" "pfert-crop2-p4" "pfert-crop3-p4" "pfert-crop4-p4"
    "grainT-p4" "grainH-p4" "grain1-p4" "grain2-p4" "grain3-p4" "grain4-p4" "residharvT-p4" "residharvH-p4" "residharv1-p4" "residharv2-p4" "residharv3-p4" "residharv4-p4")
  set sim random 100000000000000
  set nsim 0
  set flux []
  set output []
  set messages []
  set buysell []
  set crop-inputs []
  set crop-inputs1 []
  set crop-inputs2 []
  set crop-inputs3 []
  set crop-inputs4 []
  if count joueurs = 0 [set playerlist []]
  ask patches [
    set animhere []
    set intertrack []
    set soletrack []
    set manuretrack []
  ]

  ;;player position and type
  set player1pos 1
  set player2pos 2
  set player3pos 3
  set player4pos 4

  set player1type "SOC"
  set player2type "MOD"
  set player3type "SOL"
  set player4type "LCL"

  ;;biodiversity
  calcBiodiversity

  ;;microfinance
  set gov_microfinance 10;;arbitrary fixed at the start
  set micro_rate one-of (range 0 0.31 0.1);;0-30% interest rate

  ;;remove inactive players: useful while using local server
  if any? joueurs [
    ask joueurs [
      if not member? pseudo hubnet-clients-list [die]
    ]
  ]
end

to nextmonth
  set warn 0
  ;;export

  ;;set flux []
  set messages []
  ;;set buysell []

  tick
  if ticks < 3 [set month item ticks mois]

  ;;update sowing of patches
  ask patches with [cultiv = "yes"][
   set sow? false
  ]

  ;;reproduction at year 3, 6, 9 etc.
  if (ticks mod 3) = 0 [
    set year year + 1
    set month item 0 mois reset-ticks
    ;;user-message "New season! Time to sow"
    set warn 0
    ;;ask joueurs [hubnet-send pseudo "warning" ""]

    ;;animals not fed die
    ask turtles with [(shape = "cow" or shape = "donkey" or shape = "sheep" or shape  = "bird") and hunger < 0][
      die
    ]

    ;;events happening every 3 years
    if year mod 3 = 0 [

      ;;update farmers' resources
      ask farmers [
        let ply player

        ;;;1 cow = 1 newborn
        if count out-link-neighbors with [shape = "cow" and canmove ="yes"] >= 1[
          let nwbrn floor (count out-link-neighbors with [shape = "cow" and canmove ="yes"] / 1)
          ask one-of out-link-neighbors with [shape = "cow" and canmove ="yes"][
            hatch nwbrn
          ]
          ;ask joueurs with [idplay = ply][
          ;  hubnet-send pseudo "warning" "You have newborn in your herd"
          ;]
        ]

        ;;;1 srum = 1 newborn
        if count out-link-neighbors with [shape = "sheep" and canmove ="yes"] >= 1[
          let nwbrn floor (count out-link-neighbors with [shape = "sheep" and canmove ="yes"] / 1)
          ask one-of out-link-neighbors with [shape = "sheep" and canmove ="yes"][
            hatch nwbrn
          ]
          ;ask joueurs with [idplay = ply][
          ;  hubnet-send pseudo "warning" "You have newborn in your herd"
          ;]
        ]

        ;;;1 donkey = 1 newborn
        if count out-link-neighbors with [shape = "wolf" and canmove ="yes"] >= 1[
          let nwbrn floor (count out-link-neighbors with [shape = "wolf" and canmove ="yes"] / 1)
          ask one-of out-link-neighbors with [shape = "wolf" and canmove ="yes"][
            hatch nwbrn
          ]
          ;ask joueurs with [idplay = ply][
          ;  hubnet-send pseudo "warning" "You have newborn in your herd"
          ;]
        ]

        ;;1 poultry = 1 newborn
        ;;there is one ficitive chicken on the board, just for representation
        if count out-link-neighbors with [shape = "bird" and energy != 99] > 1 [
          ;ask joueurs with [idplay = ply][
          ;  hubnet-send pseudo "warning" "You have newborn in your herd"
          ;]
          let np count out-link-neighbors with [shape = "bird" and energy != 99];;does not account for the fictive chicken
          ask n-of np out-link-neighbors with [shape = "bird" and energy != 99][hatch 1]
        ]

      ]

    ]
    liens "1" liens "2" liens "3" liens "4"

    ;; residue left on field not grazed are turned into mulch
    ask turtles with [shape = "star" and hidden? != true][set mulch? true]

    ;;grains and crop residues age. cannot last more than 5 years/rounds
    ask turtles with [member? shape ["cylinder" "star"] and [pcolor] of patch-here != white][
     set age age + 1
      if age > 5 [die]
    ]


    ;;farmers evaluate their strategy. autoplay mode only
    if auto-play? [
      evaluate-strategy "player 1"
      evaluate-strategy "player 2"
      evaluate-strategy "player 3"
      evaluate-strategy "player 4"
      evaluate-strategy "government"
    ]



    ;;household off farm income and update of government finance

    let off_cash one-of (range 3 7 1);;each off far labour = 3-6 units of cash per year/round.
    set gov_microfinance gov_microfinance + (sum [off_cash * off_farm_labour] of farmers) / 2;; half of total off farm revenue goes to government. added value
    ask government [
     set microfinance gov_microfinance
    ]

    ;;yearly manure production
    ask farmers [
      let xy farm let ply player
      set nmanure floor (count out-link-neighbors with [shape = "cow" and canmove = "yes"] * 1 / 2) +;;1cow=1manure/year. 1 cow = 2.1 DM manure/day = 422 kg DM/year (incl. Loss = 45% (rufino et al 2007))
      floor (count out-link-neighbors with [shape = "sheep" and canmove = "yes"] / 5) +;; 1 sheep = 42 kg DM/year. 1 sheep = 20 sheep in real life
      floor (count out-link-neighbors with [shape = "wolf" and canmove = "yes"] / 4) + ;; 1 donkey = 211 kg DM /year. 1 bag of NPK = 11.5 kg N. %N manure = 1.5% (Sileshi et al 2017)
      floor (count out-link-neighbors with [shape = "bird" and canmove = "yes"] / 10)   ;; 1 chicken = 20 real life chicken = 20*20 kg DM manure/year = 400 kg DM/year = 220 kg DM/year incl 45% loss in storage

      ask patches with [plabel = ""][set plabel "99"]
      hatch nmanure [
        set shape "triangle"
        set color 36
        set typo "manure"
        ifelse any? patches with [(substring plabel 0 1) = xy and cultiv = "yes"][
          move-to one-of patches with [(substring plabel 0 1) = xy and cultiv = "yes"]
        ][
          move-to one-of patches with [pcolor = 26]
        ]
        set heading random 361
        set size .75
      ]
      ask patches with [plabel = "99"][set plabel ""]

      ;;1 additional poultry each round
      ;;there is one ficitive chicken on the board, just for representation
      ;if count out-link-neighbors with [shape = "bird" and energy != 99] > 1 [
      ;  ;ask joueurs with [idplay = ply][
      ;  ;  hubnet-send pseudo "warning" "You have newborn in your herd"
      ;  ;]
      ;  let np count out-link-neighbors with [shape = "bird" and energy != 99];;does not account for the fictive chicken
      ;  ask n-of np out-link-neighbors with [shape = "bird" and energy != 99][hatch 1]
      ;]

      ;;farm care, off-farm income, labour and food security update, removing hired labour
      set hired_labour 0
      set labour_received 0
      set labour_sent 0
      set labour family_size + 5 * ncow + 3 * ndonkey + ntricycle * 10

      ;;if no more field than off farm revenue only, assumed they all work off farm
      ifelse nplot = 0 [
        set offfarm_inc offfarm_inc + family_size * off_cash
      ][
        set offfarm_inc offfarm_inc + off_farm_labour * off_cash
      ]

      let farmcare family_size + ncow + ndonkey + ntricycle + nwaterpump
      ;set onfarm_inc onfarm_inc - farmcare
      set off_farm_labour 0
      set labour labour - food_unsecure
       if labour < 0 [set labour 0];;in case hired labor was transfred/exchanges with other farms
      set food_unsecure 0
    ]

    ;;update land use
    land-use

    ;;bushsim update
    ask turtles with [shape = "box"][die]
    ask turtles with [shape = "cow" and canmove = "no"][set canmove "yes" set hidden? false];;back from transhumance
    ask turtles with [canmove = "yes" and shape != "bird"][
      ifelse any? patches with [pcolor = 64][
        move-to one-of patches with [pcolor = 64]
      ][
        move-to one-of patches with [pcolor = 26]
      ]
    ]
    ;ask turtles with [shape = "cow" or shape = "sheep" or shape = "wolf" and canmove = "yes"][set energy 4]
    initbush
    ;;season
    set canharvest 0
    ask farmers [set feedfam 0]
    ;set season 1;one-of (range 0 3 1)
    ;if season = 0 [set saison "Good :)"]
    ;if season = 1 [set saison "Good :)"]
    ;if season = 2 [set saison "Good :)"]
    ;;manure from other farm
    ask patches with [pcolor = rgb 0 255 0][set animhere []]

    ;;initialization of reproduction and hunger
    ask turtles with [shape = "cow" or shape = "donkey" or shape = "sheep" or (shape = "bird" and energy != 99)][
      set repro "no"
      set grazed ""
      set hunger 0
      set energy 0
    ]
    ;set livfeed? false
    ask turtles with [typo = "residue" and shape = "star" and hidden? = true and recolt = 1][
      set recolt 0
    ]

    ;;calcuate biodiveristy index
    calcBiodiversity

    ;;subsisdies. random distrubution if less subsidies than farmers
    subsidy

    ;;update microfinance money available from government
    ask farmers with [moneyborrowed > 0][
      set loantime loantime + 1
      let repay 0

      if loantime >= loanterm [
        ifelse (offfarm_inc + onfarm_inc) >= moneyborrowed * (1 + myrate) [
          set repay moneyborrowed * (1 + myrate)
          set moneyborrowed 0
          set loantime 0
          set loanterm 0
          set onfarm_inc onfarm_inc - moneyborrowed * (1 + myrate)
          if onfarm_inc < 0 [
           set offfarm_inc onfarm_inc + offfarm_inc
           set onfarm_inc 0
          ]
        ][
          set repay offfarm_inc + onfarm_inc
          set moneyborrowed moneyborrowed - offfarm_inc - onfarm_inc
          set offfarm_inc 0
          set onfarm_inc 0
        ]
      ]
      set gov_microfinance gov_microfinance + repay
    ]

    ask government [
     set microfinance gov_microfinance
    ]

  ]

  if month != "May" [
    ask turtles with [typo = "residue" and shape = "star" and hidden? = false] [set open "yes"]
  ]

  ;;remove pest from patches
  if month = "June"[
    ask turtles with [shape = "bug"][die]
  ]

  ;;update livestock age
  ask turtles with [member? shape ["cow" "wolf" "sheep"] and [pcolor] of patch-here != white][
   set age age + 1
   if age > 10 [
     die
    ]
  ]

  ask turtles with [shape = "bird" and energy != 99][
    set age age + 1
    if age > 5 [
      die
    ]
  ]

  ;;livestock management
  let players1 (list "player 1" "player 2" "player 3" "player 4")
  let animals shuffle (list "cow" "sheep" "wolf")
  let gle shuffle (list "1" "2" "3" "4");;shuffle is important for animal movement in grazeresidue (whose animal move first)
  let kk 0
  foreach players1 [
    let jj 0
    foreach animals[
      livsim item kk players1 item jj animals
      set jj jj + 1
    ]
    liens item kk gle
    livupdate item kk players1
    set kk kk + 1
  ]
  set kk 0
  ;set players1 (list feedconc_p1 feedconc_p2 feedconc_p3 feedconc_p4)
  ;foreach players1 [concfeed item kk players1 set kk kk + 1]

  ;;unused manure and fertilizer from last year (obtained after harvest) are transfered to fields
  if month = "December"[
    ask turtles with [(typo = "manure" or typo = "fertilizer") and
      [pcolor] of patch-here = 0 and hidden? = true][
      let myfarm farm
      move-to one-of patches with [(pcolor = rgb 0 255 0 or pcolor = yellow) and
        plabel = myfarm]
      set hidden? false
    ]
  ]

  ;;export data
  export-data

  ;if month = "May" [user-message "You can now harvest :)"]
  set day day + 1
end


to environment
  ;;ressources
  ask patches with [pxcor = min-pxcor and (pycor != 0 and pycor > min-pycor)][
    set pcolor white
  ]
  ask patches with [pycor = 0 and (pxcor != 0 and pxcor < max-pxcor)][
    set pcolor white
  ]

  ask patches with [pycor = min-pycor and (pxcor != 0 and pxcor < max-pxcor)][
    set pcolor white
  ]

  ask patches with [pxcor = max-pxcor and (pycor != 0 and pycor > min-pycor)][
    set pcolor white
  ]

  ask patches with [pcolor = white] [
    ask neighbors4[
      if pxcor != 0 and pycor > min-pycor and pxcor < max-pxcor [set pcolor white]
    ]
  ]

  ;;bordure
  ask patch 1 0 [set pcolor gray]
  ask patch 0 -1 [set pcolor gray]
  ask patch 1 -1 [set pcolor gray]
  ask patch 0 -11 [set pcolor gray]
  ask patch 1 -12 [set pcolor gray]
  ask patch 11 -12 [set pcolor gray]
  ask patch 12 -11 [set pcolor gray]
  ask patch 11 -11 [set pcolor gray]
  ask patch 12 -1 [set pcolor gray]
  ask patch 11 0 [set pcolor gray]
  ask patch 11 -1 [set pcolor gray]
  ask patch 1 -11 [set pcolor gray]
  ask patch 0 -12 [set pcolor gray]
  ask patch 0 0 [set pcolor gray]
  ask patch 12 -12 [set pcolor gray]
  ask patch 12 0 [set pcolor gray]

  ;;landscape
  ;;fields
  ask  patch 2 -6
  [set pcolor rgb 0 255 0
    set plabel "1"
    ask neighbors with [pcolor = black][
      set pcolor rgb 0 255 0
      set plabel "1"
    ]
  ]
  ask patch 2 -4 [
    set pcolor rgb 0 255 0
    set plabel "1"
  ]
  ask patch 2 -3[
    set pcolor rgb 0 255 0
    set plabel "1"
  ]
  ask patch 2 -2[
    set pcolor rgb 0 255 0
    set plabel "1"
  ]

  ;;player 2
  ask patch 6 -10
  [set pcolor rgb 0 255 0
    set plabel "2"
    ask neighbors with [pcolor = black][
      set pcolor rgb 0 255 0
      set plabel "2"
    ]
  ]
  ask patch 4 -10 [
    set pcolor rgb 0 255 0
    set plabel "2"
  ]
  ask patch 3 -10 [
    set pcolor rgb 0 255 0
    set plabel "2"
    ask neighbors with [pcolor = black][
      set pcolor rgb 0 255 0
      set plabel "2"
    ]
  ]

  ;;player 3
  ask patch 9 -6
  [set pcolor rgb 0 255 0
    set plabel "3"
    ask neighbors with [pcolor = black][
      set pcolor rgb 0 255 0
      set plabel "3"
    ]
  ]
  ask patch 8 -5 [
    set pcolor black
    set plabel ""
  ]
  ask patch 9 -5 [
    set pcolor black
    set plabel ""
  ]
  ask patch 10 -5 [
    set pcolor black
    set plabel ""
  ]

  ;;player 4
  ask patch 5 -2
  [set pcolor rgb 0 255 0
    set plabel "4"
    ask neighbors with [pcolor = black][
      set pcolor rgb 0 255 0
      set plabel "4"
    ]
  ]

  ask patches with [pcolor = rgb 0 255 0][set plabel-color black]

  ;;market
    ask patch 9 -5 [
    set pcolor 124
  ]
  ask patch 10 -5 [
    set pcolor 124
  ]

  ;;forest
  ask patch 5 -6 [
    set pcolor 54;;rgb 0 50 0
    ask neighbors [set pcolor 54];;rgb 0 50 0
  ]

  ;;bush
  ask patches with [pxcor <= 7 and pycor = -4 and pcolor = black][
    set pcolor 64;;rgb 0 150 0
  ]
  ask patch 8 -5 [
    set pcolor 64;;rgb 0 150 0
  ]
  ask patch 7 -5 [
    set pcolor 64;;rgb 0 150 0
  ]
  ask patches with [pxcor = 7 and pycor > -9 and pycor <= -5] [
    set pcolor 64;;rgb 0 150 0
  ]
  ask patches with [pxcor >= 2 and pxcor <= 6 and pycor = -8] [
    set pcolor 64;;rgb 0 150 0
  ]

  ask patch 7 -2 [set pcolor 64];;rgb 0 150 0]
  ask patch 7 -3 [set pcolor 64];;rgb 0 150 0]

  ;;water
  ;ask patches with [pxcor >= 2 and pxcor <= 3 and pycor = -9] [
  ;  set pcolor blue
  ;]
  let sf random-float -100000
  ask patches with [pxcor = 3 and pycor <= -2 and pycor >= -3] [
    set pcolor blue
    set samefield sf
  ]
  ask patch 3 -4 [
    set pcolor blue
    set samefield sf
  ]

  ;;settlements
  ask patch 9 -3 [
    set pcolor 26
    ask neighbors with [pcolor = black] [set pcolor 26]
  ]
  ask patch 9 -9 [
    set pcolor 26
    ask neighbors with [pcolor = black] [set pcolor 26]
  ]
  ask patch 8 -4 [set pcolor 26];;rgb 200 100 0
  ask patch 8 -5 [set pcolor 26]

  ;;position 1
  farmres1 1 (range -2 -11 -1) (list "person farmer" "tile stones" "cow" "wolf" "sheep" "bird" "drop" "car" "truck")
  (list 15 37 85 5 135 116 95 85 44) (list "famer" "land" "cattle" "donkey" "srum" "poultry" "fertilizer" "cart" "tricycle") 1

  farmres1 0 (range -3 -10 -1) (list "checker piece 2" "tile water" "lightning" "triangle" "coin tails" "coin tails" "dot")
  (list 25 45 75 35 55 95 125) (list "grain" "residue" "conc" "manure" "onfarm inc" "off-farm inc" "seed") 1

  ;;position 2
  farmres2 -11 (range 2 11 1) (list "person farmer" "tile stones" "cow" "wolf" "sheep" "bird" "drop" "car" "truck")
  (list 15 37 85 5 135 116 95 85 44)(list "famer" "land" "cattle" "donkey" "srum" "poultry" "fertilizer" "cart" "tricycle") 2

  farmres2 -12 (range 3 10 1) (list "checker piece 2" "tile water" "lightning" "triangle" "coin tails" "coin tails" "dot")
  (list 25 45 75 35 55 95 125) (list "grain" "residue" "conc" "manure" "onfarm inc" "off-farm inc" "seed") 2

  ;;position 3
  farmres1 11 (range -2 -11 -1) (list "person farmer" "tile stones" "cow" "wolf" "sheep" "bird" "drop" "car" "truck")
  (list 15 37 85 5 135 116 95 85 44) (list "famer" "land" "cattle" "donkey" "srum" "poultry" "fertilizer" "cart" "tricycle") 3

  farmres1 12 (range -3 -10 -1) (list "checker piece 2" "tile water" "lightning" "triangle" "coin tails" "coin tails" "dot")
  (list 25 45 75 35 55 95 125) (list "grain" "residue" "conc" "manure" "onfarm inc" "off-farm inc" "seed") 3

  ;;position 4
  farmres2 -1 (range 10 1 -1) (list "person farmer" "tile stones" "cow" "wolf" "sheep" "bird" "drop" "car" "truck")
  (list 15 37 85 5 135 116 95 85 44) (list "famer" "land" "cattle" "donkey" "srum" "poultry" "fertilizer" "cart" "tricycle") 4

  farmres2 0 (range 9 2 -1) (list "checker piece 2" "tile water" "lightning" "triangle" "coin tails" "coin tails" "dot")
  (list 25 45 75 35 55 95 125) (list "grain" "residue" "conc" "manure" "onfarm inc" "off-farm inc" "seed") 4

  playerplace

  set farmi (list "1" "2" "3" "4")
  let playi (list player1type player2type player3type player4type)
  let ii 0
  foreach farmi [
    resdistrib item ii playi item ii farmi
    liens item ii farmi
    set ii ii + 1
  ]

  initbush;;create bush biomass
          ;fix heading of resources on white patches
  ask turtles with [typo = "manure" or typo = "fertilizer"
    or typo = "cattle" or typo = "srum"][
    set heading 0
  ]

  let players (list "player 1" "player 2" "player 3" "player 4")
  let animals (list "cow" "sheep" "wolf" "bird")
  let gle (list "1" "2" "3" "4")
  let kk 0
  foreach players [
    let jj 0
    foreach animals[
      livsim item kk players item jj animals
      set jj jj + 1
    ]
    ;liens item kk gle
    ask farmers with [player = item kk players][
      ask patches with [plabel = ""][set plabel "99"]
      let poss pos
      let nb nconc
      let nfert nfertilizer
      let nman nmanure
      let nca ncart
      let ntr ntricycle
      ;set uncultivated patches to yellow
      let agri patches with [(read-from-string plabel) = poss and pcolor != white]
      ask n-of (nplot * 3) agri [set cultiv "yes"]
      ask agri with [cultiv != "yes"][set pcolor yellow]

      ask out-link-neighbors with [shape = "lightning"] [
        hatch nb
      ]
      ask out-link-neighbors with [shape = "car"] [
        hatch nca
      ]
      ask out-link-neighbors with [shape = "truck"] [
        hatch ntr
      ]


      ask out-link-neighbors with [shape = "drop"][
        hatch nfert [
          set typo "fertilizer"
          set shape "drop"
          set color 96
          set size .75
          set heading one-of (range 0 360 90)
          move-to one-of patches with [(read-from-string plabel) = poss and pcolor = rgb 0 255 0]
          if any? patches with [(read-from-string plabel) = poss and
            count turtles-here with [shape = "drop"] < 2 and pcolor = rgb 0 255 0]
          [move-to one-of patches with [(read-from-string plabel) = poss and
            count turtles-here with [shape = "drop"] < 2 and pcolor = rgb 0 255 0]]

          if any? patches with [(read-from-string plabel) = poss and
            count turtles-here with [shape = "drop"] = 0 and pcolor = rgb 0 255 0]
          [move-to one-of patches with [(read-from-string plabel) = poss and
            count turtles-here with [shape = "drop"] = 0 and pcolor = rgb 0 255 0]]
        ]
      ]
      ask out-link-neighbors with [shape = "triangle"][
        hatch nman [
          set typo "manure"
          set shape "triangle"
          set color 36
          set size .75
          set heading one-of (range 0 360 90)
          move-to one-of patches with [(read-from-string plabel) = poss and pcolor = rgb 0 255 0]
          if any? patches with [(read-from-string plabel) = poss and
            count turtles-here with [shape = "triangle"] < 2 and pcolor = rgb 0 255 0]
          [move-to one-of patches with [(read-from-string plabel) = poss and
            count turtles-here with [shape = "triangle"] < 2 and pcolor = rgb 0 255 0]]

          if any? patches with [(read-from-string plabel) = poss and
            count turtles-here with [shape = "triangle"] = 0 and pcolor = rgb 0 255 0]
          [move-to one-of patches with [(read-from-string plabel) = poss and
            count turtles-here with [shape = "triangle"] = 0 and pcolor = rgb 0 255 0]]
        ]
      ]
      ask patches with [plabel = "99"][set plabel ""]
    ]

    liens item kk gle
    livupdate item kk players
    set kk kk + 1
  ]

  ;;number each plot/field
  ;;player 1
  set sf random-float -1000000
  ask patches with [pxcor = 2 and pycor >= -4 and pycor < -1] [
    set plabel (word plabel "-" 1)
    set posit 1
    set samefield sf
  ]
  let sf2 random-float -1000000
  ask patches with [pxcor <= 3 and pycor = -5 and pcolor != white] [
    set plabel (word plabel "-" 2)
    set posit 2
    set samefield sf2
  ]

  set sf random-float -1000000
  ask patch 3 -7[
    set plabel (word plabel "-" 3)
    set posit 3
    set samefield sf
    ask neighbors with [pcolor = rgb 0 255 0][
      set plabel (word plabel "-" 3)
      set posit 3
      set samefield sf
    ]
  ]

  ask patch 3 -6 [
    set plabel (word (substring plabel 0 1) "-" 2)
    set posit 2
    set samefield sf2
  ]

  ;;player 2
  set sf random-float -1000000
  ask patches with [pxcor <= 4 and pycor = -9 and pcolor != white] [
    set plabel (word plabel "-" 1)
    set posit 1
    set samefield sf
  ]
  set sf random-float -1000000
  ask patches with [pxcor <= 4 and pycor = -10 and pcolor != white] [
    set plabel (word plabel "-" 3)
    set posit 3
    set samefield sf
  ]
  set sf random-float -1000000
  ask patches with [pxcor <= 7 and pxcor >= 5 and pycor = -9 and pcolor != white] [
    set plabel (word plabel "-" 2)
    set posit 2
    set samefield sf
  ]
  set sf random-float -1000000
  ask patches with [pxcor <= 7 and pxcor >= 5 and pycor = -10 and pcolor != white] [
    set plabel (word plabel "-" 4)
    set posit 4
    set samefield sf
  ]

  ;;player 3
  set sf random-float -1000000
  ask patches with [pxcor <= 10 and pxcor >= 8 and pycor = -7 and pcolor != white] [
    set plabel (word plabel "-" 1)
    set posit 1
    set samefield sf
  ]
  set sf random-float -1000000
  ask patches with [pxcor <= 10 and pxcor >= 8 and pycor = -6 and pcolor != white] [
    set plabel (word plabel "-" 2)
    set posit 2
    set samefield sf
  ]

  ;;player 4
  set sf random-float -1000000
  ask patches with [pxcor <= 6 and pxcor >= 4 and pycor = -2 and pcolor != white] [
    set plabel (word plabel "-" 2)
    set posit 2
    set samefield sf
  ]
  set sf random-float -1000000
  ask patches with [pxcor <= 6 and pxcor >= 4 and pycor = -3 and pcolor != white] [
    set plabel (word plabel "-" 1)
    set posit 1
    set samefield sf
  ]

  ;;aesthetics, forest grow trees
  ask patches with [pcolor = 54][
    sprout 1 [
      set shape "tree"
      set size .5
      set color rgb 0 220 0
    ]
  ]
  ;;define unique id for block of 3 patches potentially being a field later
  set sf random-float -1000000
  ask patches with [pcolor = 54 and pycor = -5 ][
    set samefield sf
  ]
  set sf random-float -1000000
  ask patches with [pcolor = 54 and pycor = -6 ][
    set samefield sf
  ]
  set sf random-float -1000000
  ask patches with [pcolor = 54 and pycor = -7 ][
    set samefield sf
  ]
  set sf random-float -1000000
  ask patches with [pcolor = 64 and pycor = -8 and pxcor <= 4][
    set samefield sf
  ]
  set sf random-float -1000000
  ask patches with [pcolor = 64 and pycor = -8 and pxcor > 4  and pxcor <= 7][
    set samefield sf
  ]
  set sf random-float -1000000
  ask patches with [pcolor = 64 and pxcor = 7 and member? pycor [-7 -6 -5]][
    set samefield sf
  ]
  set sf random-float -1000000
  ask patches with [pcolor = 64 and pxcor = 7 and member? pycor [-4 -3 -2]][
    set samefield sf
  ]
  set sf random-float -1000000
  ask patches with [pcolor = 64 and pycor = -4 and member? pxcor [4 5 6]][
    set samefield sf
  ]
  ;;labour and fictive chicken
  ask farmers [
    set labour labour + (ncow * 5 + ndonkey * 3 + ntricycle * 10)
    ask one-of out-link-neighbors with [shape = "bird"][
      set energy 99
    ]
  ]

  ;;government agent
  crt 1 [
    set shape "flag"
    set hidden? true
    set player "government"
    move-to one-of patches with [pcolor = 26]
    set allstrategy []
    set strategyscore []
    set commonvote_field []
    set commonvote_shrub []
    set commonvote_forest []
  ]
  set government turtles with [shape = "flag"]

  ;;subsidy
  subsidy

  ;;old code for labelling fields
  ;ask farmers [
  ;  let posi pos
  ;  let i 1
  ;  let myplot patches with [cultiv = "yes" and (read-from-string (substring plabel 0 1)) = posi]
  ;  foreach (range 0 nplot) [
  ;    ask one-of myplot with [posit = 0][
  ;      set posit i
  ;      set plabel (word plabel "-" i)
  ;    ]
  ;    set i i + 1
  ;  ]
  ;]

  ;set kk 0

  ;foreach players [
  ;ask farmers with [player = item kk players][
  ;  ask out-link-neighbors with [shape = "drop" and color = 97][
  ;   die
  ;  ]
  ;]

  ; set kk kk + 1]

end

to farmres1 [p i j col typ ps]
  ;;function to dispose resources
  ;; vertical disposition
  let n 0
  foreach i [
    create-turtles 1 [
      let l item n i
      move-to patch p l
      set shape item n j
      set color item n col
      set pos ps
      set typo item n typ
    ]
    set n n + 1
  ]
end
to farmres2 [p i j col typ ps]
  ;;function to dispose resources
  ;; horizontal disposition
  let n 0
  foreach i [
    create-turtles 1 [
      let l item n i
      move-to patch l p
      set shape item n j
      set color item n col
      set pos ps
      set typo item n typ
    ]
    set n n + 1
  ]

end

to playerplace
  set farmers turtles with [shape = "person farmer"]
  ask farmers with [pos = player1pos] [set player "player 1"]
  ask turtles with [pos = player1pos] [set farm "1"]

  ask farmers with [pos = player2pos] [set player "player 2"]
  ask turtles with [pos = player2pos] [set farm "2"]

  ask farmers with [pos = player3pos] [set player "player 3"]
  ask turtles with [pos = player3pos] [set farm "3"]

  ask farmers with [pos = player4pos] [set player "player 4"]
  ask turtles with [pos = player4pos] [set farm "4"]

  ask turtles [set label farm set label-color red]

  ask farmers [
    set allstrategy []
    set strategyscore []
    set commonvote_field []
    set commonvote_shrub []
    set commonvote_forest []
  ]
  ;;avoid more than one player per position
  let playpos (list player1pos player2pos player3pos player4pos)
  if sum playpos != 10 [
    user-message "More than one player in a position. Please check players position, reset and start again"
    stop
  ]
end

to resdistrib [typology ferme]
  ;; Subsistence-oriented crop farm
  if typology = "SOC" [

    ask turtles with [shape = "person farmer" and farm = ferme][
      set family_size 4
      set nplot 3
      set ncow 0;one-of (range 0 2 1)
      set nsrum 3;one-of (range 2 4 1)
      set npoultry 2;one-of (range 1 6 1)
      set nfertilizer 0; one-of (range 0 1 1)
      set ncart 0;one-of (range 0 2 1)
      set ndonkey 0;one-of (range 0 2 1)
                   ;if ncart > 0 [set ndonkey 1]
      set ntricycle 0
      set ngrain 0
      set nresidue 0
      set nconc 0;one-of (range 0 4 1)
      set nmanure (floor (ncow * 3 / 2)) + (floor (nsrum / 4)) + (floor (ndonkey / 2))
      set onfarm_inc 1
      set offfarm_inc 0
      set labour 5
      set off_farm_labour 0
    ]

  ]

  ;; Subsistence-oriented livestock farm
  if typology = "SOL" [

    ask turtles with [shape = "person farmer" and farm = ferme][
      set family_size 4
      set nplot 2
      set ncow 0;one-of (range 0 2 1)
      set nsrum 4;one-of (range 4 6 1)
      set npoultry 2;one-of (range 1 6 1)
      set nfertilizer 0;one-of (range 0 3 1)
      set ncart 0;one-of (range 0 2 1)
      set ndonkey 0;one-of (range 0 2 1)
                   ;if ncart > 0 [set ndonkey 1]
      set ntricycle 0
      set ngrain 0
      set nresidue 0
      set nconc 0;one-of (range 0 4 1)
      set nmanure (floor (ncow * 3 / 2)) + (floor (nsrum / 4)) + (floor (ndonkey / 2))
      set onfarm_inc 1
      set offfarm_inc 0
      set labour 4
      set off_farm_labour 0
    ]

  ]

  ;; Market-oriented diversified farm
  if typology = "MOD" [

    ask turtles with [shape = "person farmer" and farm = ferme][
      set family_size 5
      set nplot 4
      set ncow 0;one-of (range 1 3 1)
      set ndonkey 0;one-of (range 1 2 1)
      set nsrum 3;one-of (range 2 4 1)
      set npoultry 2;one-of (range 1 6 1)
      set nfertilizer 0;one-of (range 0 4 1)
      set ncart 0;1
      set ntricycle 0;one-of (range 0 2 1)
      set ngrain 2
      set nresidue 0
      set nconc 0;one-of (range 0 6 1)
      set nmanure (floor (ncow * 3 / 2)) + (floor (nsrum / 4)) + (floor (ndonkey / 2))
      set onfarm_inc 2
      set offfarm_inc 0
      set labour 6
      set off_farm_labour 0
    ]

  ]

  ;; Land-constrained livestock farm
  if typology = "LCL" [

    ask turtles with [shape = "person farmer" and farm = ferme][
      set family_size 5
      set nplot 2
      set ncow 0;one-of (range 5 7 1)
      set ndonkey 0;one-of (range 0 3 1)
      set nsrum 2;one-of (range 2 5 1)
      set npoultry 2;one-of (range 1 6 1)
      set nfertilizer 0;one-of (range 0 2 1)
      set ncart 0;one-of (range 0 2 1)
      ifelse ncart > 0 [set ndonkey one-of (range 1 3 1)][set ndonkey 0]
      set ntricycle 0
      set ngrain 0
      set nresidue 0
      set nconc 0;one-of (range 7 21 1)
      set nmanure (floor (ncow * 3 / 2)) + (floor (nsrum / 4)) + (floor (ndonkey / 2))
      set onfarm_inc 1
      set offfarm_inc 0
      set labour 4
      set off_farm_labour 0
    ]

  ]

end

to sow
  set saison item (year - 1) season
  let fin ""
  ifelse month = "December" [
    ;set farmers turtles with [shape = "person farmer"]
    ask patches with [pcolor = rgb 0 255 0 and cultiv = "yes"][
      let pl plabel
      set mulch count turtles-here with [shape = "star" and mulch? = true and farm = pl]
    ]
    ask turtles with [mulch? = true][set open "no" set hidden? true];;residue become mulch if not eaten for an entire season
    ask turtles with [typo = "fertilizer" and color = 96 and [pcolor]of patch-here != 0][die]
    ask turtles with [typo = "fertilizer" and color = 97 and [pcolor]of patch-here != 0][die]
    ask turtles with [typo = "manure" and color = 36 and [pcolor]of patch-here != 0][die]

    ask turtles-on patches with [pcolor = rgb 0 255 0 or pcolor = yellow][
      if typo != "fertilizer" and typo !="manure" and shape != "cow" and shape != "wolf" and shape != "sheep" and hidden? = false [
        die]
    ]
    set farmi [farm] of farmers
    let n 0
    let m 0

    foreach farmi [
      ask turtles with [farm = item n farmi and shape = "person farmer"][
        ;show nplot
        let nseed nplot
        let nfert nfertilizer - count out-link-neighbors with [typo = "fertilizer" and [pcolor] of patch-here = 0]
        let nman nmanure - count out-link-neighbors with [typo = "manure" and [pcolor] of patch-here = 0]
        let posi pos
        ask patches with [plabel = ""][set plabel "99"]
        set fin patches with [cultiv = "yes" and (read-from-string (substring plabel 0 1)) = posi];;cultivate the same plot each year
        ask patch-here[
          ;;seed
          sprout nseed [
            set typo "seed2"
            set farm item n farmi
            set label farm
            set shape "dot"
            set color 125
            move-to one-of fin with [count turtles-here with [typo ="seed2"] = 0]
          ]
          ;;old fertilizer/manure
          ask turtles with [[pcolor] of patch-here = rgb 0 255 0 and
            (typo = "fertilizer" or typo = "manure") and hidden? = true
            and farm = item n farmi][
            set hidden? false
            set farm item n farmi
            move-to one-of fin with [count turtles-here with [typo ="seed2"] > 0]
          ]


          sprout nman [
            set typo "manure"
            set shape "triangle"
            set farm item n farmi
            set color 35
            set size .5
            move-to one-of fin with [count turtles-here >= 1]
            if count turtles-here with [typo = "manure"] > 2 [
              if any? patches with [(read-from-string (substring plabel 0 1)) = posi and pcolor != white
                and count turtles-here with [typo = "manure"] < 2 and count turtles-here with [typo = "seed2"] > 0][
                let destination patches with [(read-from-string (substring plabel 0 1)) = posi and pcolor != white
                  and count turtles-here with [typo = "manure"] < 2 and count turtles-here with [typo = "seed2"] > 0]
                move-to one-of destination;; try to put max of 2 manure per plot as beyond yield do not increase
              ]
            ]
          ]

          sprout nfert [
            set typo "fertilizer"
            set shape "drop"
            set color 95
            set farm item n farmi
            set size .5
            move-to one-of fin with [count turtles-here >= 1]
            if count turtles-here with [typo = "fertilizer"] > 2 [
              if any? patches with [(read-from-string (substring plabel 0 1)) = posi and pcolor != white
                and count turtles-here with [typo = "fertilizer"] < 2 and count turtles-here with [typo = "seed2"] > 0][
                let destination patches with [(read-from-string (substring plabel 0 1)) = posi and pcolor != white
                  and count turtles-here with [typo = "fertilizer"] < 2 and count turtles-here with [typo = "seed2"] > 0]
                move-to one-of destination;; try to put max of 2 fertilizer per plot as beyond yield do not increase
              ]
            ]
          ]

        ]

      ]
      ;show farmi
      ;show xseed
      ;ask turtles with [farm = item n farmi and shape = "person farmer"][
      ; set nfertilizer 0 set nmanure 0
      ;]
      set n n + 1
    ]

    ;;conserve unused manure and fertilizer
    ask patches with [pcolor = rgb 0 255 0][
      if count turtles-here with [typo = "fertilizer" and hidden? = false] > 2 [
        let rfert (count turtles-here with [typo = "fertilizer" and hidden? = false] - 2)
        ask n-of rfert turtles-here with [typo = "fertilizer" and hidden? = false][
          set color 95 set hidden? true set size .5
          ;show rfert
        ]
      ]
    ]

    ask patches with [pcolor = rgb 0 255 0 and
      count turtles-here with [typo = "manure" and hidden? = false] > 2][
      ;if count turtles-here with [typo = "manure" and hidden? = false] > 2
      let rfert ((count turtles-here with [typo = "manure" and hidden? = false]) - 2) ;show rfert
      ask n-of rfert turtles-here with [typo = "manure" and hidden? = false][
        set color 35 set hidden? true set size .5
      ]
    ]

    ask turtles-on patches with [pcolor = rgb 0 255 0][set label ""]
    ask patches with [plabel = "99"][set plabel ""]
    let seeds turtles with [typo = "seed2"]
    ;ask farmers [set nmanure 0 set nfertilizer 0 set ngrain 0]
    liens "1" liens "2" liens "3" liens "4"
  ]
  [user-message "You cannot sow, wait for December"]

end

to grow [taille]
  let g ""; variable to check the period is suitable for growing crops
  if member? month ["December" "May"] [set g "ok"]
  if g = "ok" [
    ;;set saison item (year - 1) season
    ;;set saison one-of (list "Good" "Bad");;only visible (rainy season) to players after they have sown and applied nutrients

    ;;adjust saison variable or irrigated season
    if month = "May" [
     set saison "Good";;water is not a problem in irrgated season
    ]

    ask patches with [pcolor = rgb 0 255 0][
      let lab plabel
      let myinput turtles-on patches with [plabel = lab]
      set ferti count myinput with [typo = "fertilizer"]
      set manu count myinput with [typo = "manure"]
      if plabel != "" [
        set cultiv "yes"
      ]
      let pl plabel
      set mulch count myinput with [shape = "star" and mulch? = true and farm = pl]
      set pailles mulch
    ]

    ;;apply crops, manure/residue and fertilizer. useful when runing without players on hubnet. e.g. exploration or debug
    ;if (length hubnet-clients-list) <= 4 [
    ;  ask joueurs [choose-crops-explo]
    ;]

    cropstats-sow-play;sowing: crops and inputs applied stats

    produce;;calculate harvest and display it

    pest;;eventual pest and disease damage

    cropstats-harvest-play;;harvest stats

    ask turtles with [(typo = "seed2" or typo = "fertilizer" or typo = "manure") and
      hidden? = false] [
      if [pcolor] of patch-here != white [
        die
      ]
    ]
    ;;update the variable prodHereNow
    ask turtles with [typo = "grain" and shape = "cylinder"][
      set prodHereNow ""
    ]

    ask turtles with [typo = "residue" and shape = "star"][
      set prodHereNow ""
    ]
    ;;update resources
    livupdate "player 1"
    livupdate "player 2"
    livupdate "player 3"
    livupdate "player 4"

    update-explo "player 1"
    update-explo "player 2"
    update-explo "player 3"
    update-explo "player 4"
    ;;unused manure, residue and fertilizer are lost
    ;;ask turtles with [(typo = "manure" or typo = "fertilizer" or typo = "residue") and [pcolor] of patch-here != white][die]

    ;;harvest crop residue and grains in irrigated season
    ask joueurs [
      harvest-irr
    ]

  ]

  bush
end

to produce
  ;set farmers turtles with [shape = "person farmer"]
  set farmi [farm] of farmers
  let n 0

  ;;basic prod according ot season
  ;if season = 0 [set ngseason 1 set nrseason 10]
  ifelse saison = "Good" [set ngseason 2 set nrseason 2][set ngseason 1 set nrseason 1]
  ;if season = 2 [set ngseason 3 set nrseason 12]
  if member? month ["December" "May"] [
    ask patches with [plabel = ""][set plabel "99"]

    if auto-play? = false [
      ask joueurs with [substring pseudo 0 5 = "Smart"][investfarm-play]
    ]
    compute-play "grain"
    compute-play "residue"

    ;;move residues around for better visibility
    ;ask turtles with [typo = "residue" and prodHereNow = "yes" and farm = posi][
    ;  move-to one-of cultivplot
    ;  set hidden? false
    ;  set mulch? false
    ;]

    liens "1" liens "2" liens "3" liens "4";;link created biomass to owner

    ;;removing used mulch
    ask farmers [
      ask out-link-neighbors with [shape = "star" and mulch? = true][die]
    ]

    ;;farms with no active member farming or with no hired labour do not produce

    ask farmers [
      let active_member labour - 5 * ncow - 3 * ndonkey - 10 * ntricycle

      if active_member = 0 [
        ask out-link-neighbors with [shape = "cylinder" or shape = "star"][die]
      ]

    ]

    ;;plots not cultivated as result of labor shrotage do not produce [in exploration only, see smart.nls]

    let outbiomass turtles-on patches with [pcolor = rgb 0 255 0 and crop1 = 0 and crop2 = 0]
    set outbiomass outbiomass with [shape = "cylinder" or shape = "star"]
    ask outbiomass [die]

    ;ask turtles with [typo = "residue" and shape = "star" and hidden? = false] [set open "yes"]
    ask patches with [plabel = "99"][set plabel ""]

    ask patches with [cultiv = "yes"][
      set manuretrack? ""
      set soletrack? ""
      set intertrack? ""
    ]

    ;ask turtles with [shape = "flower"][die]
    ;update residue harvested before new harvest
    ask farmers [set alharv 0]

  ]


end

to harvest
  let idplays idplay
  let rharv residue_harvest
  ;;presid is the amount of residue harvested, see interface
  let farmii item 0 [farm] of farmers with [player = idplays]
  if month = "May" [
    liens farmii
    ;;residue harvested and left on field
    ask farmers with [player = idplays][
      let tresid count out-link-neighbors with [typo = "residue" and shape = "star" and hidden? = false and recolt != 1];actual amount of residue produced/on field
      let harcapa 1000000;;labour ;;(floor (family_size / 2)) + ncow + ndonkey;harvest capacity, 2 members = 1 resid, 1 cow/donkey = 1 unit of resid
      ;;set rharv one-of (range 0 (harcapa + 1) 1)

      if player = "player 1" [set presid1 rharv]
      if player = "player 2" [set presid2 rharv]
      if player = "player 3" [set presid3 rharv]
      if player = "player 4" [set presid4 rharv]
      ;;possibility to harvest multiple times until the harvest capacity is reached
      if alharv < harcapa [
        if tresid > harcapa [set tresid harcapa]
        if rharv > tresid [set rharv tresid]
        ifelse (count out-link-neighbors with [typo = "residue" and shape = "star" and hidden? = true and recolt = 1]) > 0 [
         ; set rharv harcapa - count out-link-neighbors with [typo = "residue" and
         ;   shape = "star" and hidden? = true and recolt = 1]
          set alharv alharv + rharv
        ][
         set alharv alharv + rharv
        ]
        ;;harvest residue according to the max capacity (labor) and the amount of residue produced
        if rharv <= tresid[
          ask n-of rharv out-link-neighbors with [typo = "residue" and shape = "star" and hidden? = false and recolt != 1] [
            set hidden? true set mulch? 0 set recolt 1
        ]]
      ]

      ask out-link-neighbors with [typo = "grain" and shape = "cylinder"][set hidden? true]

      ask out-link-neighbors with [typo = "residue" and shape = "star" and hidden? = false] [
        set mulch? false;;these residue can be turned into mulch if not grazed before new season
      ]

      ;;update grain and residue info in farms
      set graine count out-link-neighbors with [typo = "grain" and shape = "cylinder"]
      set resid count out-link-neighbors with [typo = "residue" and hidden? = true]
      set ngrain graine ;- 1; remove the ficitve one white plot
      set nresidue resid ;- 1; remove the ficitve one white plot
      set nresiduep count out-link-neighbors with [typo = "residue" and hidden? = false and shape = "star"];;residue on field

      ;;other farms access residue left on field
      if player = "player 1" [set accessresid open_field1?]
      if player = "player 2" [set accessresid open_field2?]
      if player = "player 3" [set accessresid open_field3?]
      if player = "player 4" [set accessresid open_field4?]
      if any? joueurs with [idplay = idplays][
        set accessresid item 0 [open_field?] of joueurs with [idplay = idplays]];;player has priority on game master
      ask out-link-neighbors with [typo = "residue" and shape = "star" and hidden? = false][
        if accessresid = true [set foreignaccess "yes"]
      ]
    ]
    ask turtles with [typo = "residue" and shape = "star" and hidden? = false] [set open "yes"]
    ask joueurs with [idplay = idplays][
      hubnet-send pseudo "residue_harvest" 0
    ]
  ]
  ;[user-message "You cannot harvest, it is only possible in May"]
  ;if month = "May" and canharvest <= 4 [user-message "Feed your family with the grain harvested before next step"]
end

to harvest-irr
  let idplays idplay
  let rharv irr_residue_harvest
  ;let rharv item 0 [residue_harvest] of joueurs with [idplay = id];;residue requested to be harvested through hubnet
  ;;presid is the amount of residue harvested, see interface
  let farmii item 0 [farm] of farmers with [player = idplays]
  liens farmii
  ;;residue harvested and left on field
  ask farmers with [player = idplays][
    let tresid count out-link-neighbors with [typo = "residue" and shape = "star" and hidden? = false and recolt != 1 and [plabel-color] of patch-here = blue];actual amount of residue produced/on field
    let harcapa 1000000;;labour

    if rharv > tresid [set rharv tresid]
    ;if rharv > labour [set rharv labour]

    ask n-of rharv out-link-neighbors with [typo = "residue" and shape = "star" and hidden? = false and recolt != 1 and [plabel-color] of patch-here = blue] [
      set hidden? true
      set mulch? 0
      set recolt 1
    ]

      ask out-link-neighbors with [typo = "grain" and shape = "cylinder"][set hidden? true]

      ;;update grain and residue info in farms
      set graine count out-link-neighbors with [typo = "grain" and shape = "cylinder"]
      set resid count out-link-neighbors with [typo = "residue" and hidden? = true]
      set ngrain graine ;- 1; remove the ficitve one white plot
      set nresidue resid ;- 1; remove the ficitve one white plot
      set nresiduep count out-link-neighbors with [typo = "residue" and hidden? = false and shape = "star"];;residue on field

      ;;other farms access residue left on field
      if player = "player 1" [set accessresid open_field1?]
      if player = "player 2" [set accessresid open_field2?]
      if player = "player 3" [set accessresid open_field3?]
      if player = "player 4" [set accessresid open_field4?]
      if any? joueurs with [idplay = idplays][
        set accessresid item 0 [open_field?] of joueurs with [idplay = idplays]];;player has priority on game master
      ask out-link-neighbors with [typo = "residue" and shape = "star" and hidden? = false][
        if accessresid = true [set foreignaccess "yes"]
      ]
    ]
    ask turtles with [typo = "residue" and shape = "star" and hidden? = false] [set open "yes"]

end

to initbush
  set bushplot patches with [member? pcolor [54 64]];;rgb 0 150 0]
  let nbush count bushplot
  set saison one-of (list "Good" "Bad")
  let bushprod 0
  ifelse saison = "Good" [set bushprod 2][set bushprod 1]
  ;set nbush nbush * bushprod

  ask bushplot [
    sprout bushprod [
      set shape "box"
      set size .25
      set color 135
      ;;move-to one-of bushplot; with [count turtles-here with [shape = "box"] < ]
    ]
  ]
end

to bush
  ifelse (month = "August" or month = "September" or month = "October")[
    ask bushplot [
      sprout 1 [
        set shape "box"
        set size .25
        set color 135
      ]
    ]
  ]
  [
    ask turtles with[shape = "box"][die]
  ]

end

to livsim [gamer animal]
  let farmlab item 0 [label] of farmers with [player =  gamer]
  let coul 0
  let nanim 0
  let sz 0;size of animals
  set maxc count farmers with [ncow > 0]
  set maxr count farmers with [nsrum > 0]
  set maxd count farmers with [ndonkey > 0]
  set maxp count farmers with [npoultry > 0]
  set maxrc maxc + maxr + maxd + maxp
  ifelse animal = "cow" [
    set coul cyan
    set maxc count farmers with [ncow > 0]
  ] [
    set coul white
    set maxc count farmers with [nsrum > 0]
  ]
  if animal = "wolf" [set coul gray]
  if animal = "bird" [set coul 116]
  ;;create cows

  if (month = "December" and year = 1) [
    set cc cc + 1
    ask farmers with [player = gamer][
      if animal ="cow" [set nanim ncow set sz 1.25]
      if animal = "sheep"[set nanim nsrum set sz .75]
      if animal = "wolf"[set nanim ndonkey set sz 1.1]
      if animal = "bird"[set nanim npoultry set sz 1]
      ifelse animal != "bird" [
        ask out-link-neighbors with [shape = animal and canmove = 0][
          hatch nanim [
            set color coul
            set size sz
            set energy 0
            set state "skinny"
            set repro "no"
            set canmove "yes"
            if random 101 > 50 [lt 1]
            ;;(rgb 0 150 0)]
          ]
        ]
      ][
        ask out-link-neighbors with [shape = animal][
          hatch nanim [
            set color coul
            set size sz
            set energy 0
            set state "skinny"
            set repro "no"
          ]
        ]
      ]
    ]
  ]

  liens farmlab

  ;;livestock movements on bushplot
  let cow turtles with [shape = animal and canmove = "yes" and farm = farmlab]
  ask cow with [canmove = "yes" and grazed != "yes"][
    if any? bushplot with-min [count turtles-here with [shape != "box"]][
      move-to one-of bushplot with-min [count turtles-here with [shape != "box"]]
    ]
  ]

  ;ask cow with [grazed != "yes"][
  ;  if (count turtles-here with [shape = animal and canmove = "yes"]) >
  ;  (count turtles-here  with[shape = "box"])[
  ;    if any? bushplot with [count turtles-here with [shape = animal and canmove = "yes"] <
  ;      count turtles-here with [shape = "box"]] [
  ;      move-to patch-here
  ;    ]
  ;  ]
  ;]
  ;ask cow with [grazed != "yes"] [
  ;  ifelse any? turtles-here with[shape = "box"][][
  ;    if any? turtles with[shape = "box"] [
  ;      move-to one-of bushplot with [count turtles with [shape = "box"] > 0]
  ;    ]
  ;  ]
  ;
  ;]
  ;;eating grass
  let kil 0
  let kild 0
  let feedanim 2;;default for small ruminants.
  if animal = "cow" [set feedanim 4]
  if animal = "wolf" [set feedanim 3]
  ask cow with [grazed != "yes"][
    if any? turtles-here with[shape = "box"] [
      let feedhere count turtles-here with[shape = "box"]
      if feedhere > feedanim [set feedhere feedanim]

        ask n-of feedhere turtles-here with[shape = "box" ][die]
        set energy energy + feedhere
        set grazed "yes"
        set hunger 0
      ;set energy energy + 1
      ;set grazed "yes"
    ]
  ]

  ;;animal in transhumance are supposed to be fed correctly
  ask farmers with [player = gamer][
    ask out-link-neighbors with [shape = "cow" and canmove = "no"][
      set grazed "yes"
      set hunger 0
    ]
  ]

  ;directfeed gamer
  foreignresidue gamer
  if month != "December" and count turtles with [shape = "cylinder" and hidden? = false] = 0 [
    repeat 1 [;;can move 1 times on fields in the game to get residue to eat
      grazeresidue gamer animal
    ]
  ]
  ;concfeed gamer
  ;reproduce gamer animal;; already in nextmonth
  ;getmanure gamer
  liens farmlab

  if month = "December" [ask cow with [grazed = "yes"] [set grazed ""]]
end

to grazeresidue [gamer animal]
  let farmlab item 0 [label] of farmers with [player =  gamer]
  let farmpos item 0 [pos] of farmers with [player =  gamer]
  let cow turtles with [shape = animal and canmove = "yes" and farm = farmlab]
  ;;2 grazing movements max per hungry animal. so grazeresidue will be repeated twice in livsim
  ask cow with [grazed != "yes"][

    if any? patches with [pcolor = rgb 0 255 0 and
      count turtles-here with [shape = "star"and open = "yes" and (farm = farmlab or foreignaccess = "yes") and mulch? != true] >= 1 and
      count turtles-here with [shape = "star"and open = "yes" and (farm = farmlab or foreignaccess = "yes") and mulch? != true] >=
      (count turtles-here with [(shape = "cow" or shape = "sheep" or shape = "wolf") and grazed != "yes"]) * 2][
      move-to one-of patches with [pcolor = rgb 0 255 0 and
        count turtles-here with [shape = "star"and open = "yes" and (farm = farmlab or foreignaccess = "yes") and mulch? != true] >= 1 and
        count turtles-here with [shape = "star"and open = "yes" and (farm = farmlab or foreignaccess = "yes") and mulch? != true] >=
        (count turtles-here with [(shape = "cow" or shape = "sheep" or shape = "wolf") and grazed != "yes"]) * 2];max 2 animal on a residue
    ]
  ]

  ;;eating residue
  ask cow with [grazed != "yes"][
    ifelse animal = "cow" [
      if any? turtles-here with[shape = "star" and (farm = farmlab or foreignaccess = "yes") and hidden? = false and mulch? != true] [
        let plab ""
        ifelse plabel != ""[
          set plab item 0[plabel] of patch-here
        ][
          if [samefield] of patch-here != 0[
            set plab [samefield] of patch-here
          ]
        ]
        let field patches with [plabel = plab]
        let feedhere turtles-on field
        let en count feedhere with[shape = "star" and (farm = farmlab or foreignaccess = "yes") and hidden? = false and mulch? != true ]
        if en > 10 * 3 [set en 10 * 3]
        ask n-of en feedhere with[shape = "star" and (farm = farmlab or foreignaccess = "yes") and hidden? = false and mulch? != true] [
          die
        ]
        set energy energy + en
        if energy >= 10 * 3 [set grazed "yes"]
        set hunger energy - 10 * 3
      ]
    ]
    [
      if any? turtles-here with[shape = "star" and (farm = farmlab or foreignaccess = "yes") and hidden? = false and mulch? != true] [
        let plab ""
        ifelse plabel != ""[
          set plab item 0[plabel] of patch-here
        ][
          if [samefield] of patch-here != 0[
            set plab [samefield] of patch-here
          ]
        ]
        let field patches with [plabel = plab or samefield = plab]
        let feedhere turtles-on field
        let en count feedhere with[shape = "star" and (farm = farmlab or foreignaccess = "yes") and hidden? = false and mulch? != true ]
        if animal = "wolf" and en > 8 * 3 [set en 8 * 3]
        if animal = "sheep" and en > 6 * 3 [set en 6 * 3]
        ask n-of en feedhere with[shape = "star" and (farm = farmlab or foreignaccess = "yes") and hidden? = false and mulch? != true ] [
          die
        ]
        set energy energy + en
        if animal = "wolf" and energy >= 8 * 3 [
          set hunger energy - 8 * 3
          set grazed "yes"
        ]
        if animal = "sheep" and energy >= 6 * 3 [
          set hunger energy - 6 * 3
          set grazed "yes"
        ]
      ]
    ]
  ]

end

to livupdate [gamer]

  ask farmers with [player = gamer][
    let ms 0
    let ferme farm
    ifelse ticks >= 1 [set ms 0][set ms 0]
    set ncow count out-link-neighbors with[shape = "cow"  and [pcolor] of patch-here != white]
    set nsrum count out-link-neighbors with[shape = "sheep" and canmove = "yes" and [pcolor] of patch-here != white]
    set ndonkey count out-link-neighbors with[shape = "wolf" and canmove = "yes" and [pcolor] of patch-here != white]
    set npoultry count out-link-neighbors with[shape = "bird"] - 1; remove the ficitve one
    set ngrain count out-link-neighbors with[shape = "cylinder" and [pcolor] of patch-here != white]
    set nconc count out-link-neighbors with[typo = "conc"] - ms; remove the ficitve one
                                                               ;ifelse ticks > 1 [set nfertilizer count out-link-neighbors with[typo = "fertilizer"] - 1]; remove the ficitve one
                                                               ;[ifelse nf < 1 [set nfertilizer nfertilizer + count out-link-neighbors with[typo = "fertilizer"] - 1 set nf nf + 1]
                                                               ;  [set nfertilizer count out-link-neighbors with[typo = "fertilizer"] - 1]
                                                               ;]
    set nfertilizer count out-link-neighbors with[typo = "fertilizer" and [pcolor] of patch-here != white] - ms
    set ncart count out-link-neighbors with[shape = "car"] - ms
    set ntricycle count out-link-neighbors with[shape = "truck" and [pcolor] of patch-here = 26] ;+ count turtles with [shape = "truck" and tractor_owner = ferme and farm != ferme ] - ms
    set nwaterpump count out-link-neighbors with[shape = "wheel" and [pcolor] of patch-here = 26]

    set nmanure count out-link-neighbors with[typo = "manure" and [pcolor] of patch-here != white] - ms
    set nresidue count out-link-neighbors with [shape = "star" and (hidden? = true or mulch? = true) and [pcolor] of patch-here != white]

    ;;update fields that can be irrigated
    ;;1 water pump can irrigate 2 fields
    let myplot patches with [cultiv = "yes" and (substring plabel 0 1) = ferme]

    set nplot (count myplot) / 3;;adjust the number of fields owned

    ifelse nwaterpump > 0 [
      ;;check if any field adjacent to water source
      if any? myplot with [count neighbors4 with [pcolor = 105] > 0][
        ;let targ 0
        let targ myplot with [count neighbors4 with [pcolor = 105] > 0]
        let targlab [plabel] of targ
        let targplot myplot with [member? plabel targlab]
        ;ifelse nwaterpump > 2 * (count targplot) / 3[
        ;  set targ count myplot with [count neighbors with [pcolor = 105] > 0]
        ;][
        ;  set targ nwaterpump
        ;]

        ;;all fields which can be irrigated turn their label blue
        ask targplot [
          let lab plabel
          let sf samefield
          if lab != "" [
            ;show (list lab targplot with [plabel = lab and samefield = sf and plabel-color != blue])
            ask targplot with [plabel = lab and samefield = sf and plabel-color != blue][
              set plabel-color blue;;fields that can be irrigated
            ]
          ]
        ]
        ;;adjust to make 2 fields per water pump
        if 2 * nwaterpump < (count targplot) / 3 [
          let norm ((count targplot) / 3) - 2 * nwaterpump

          repeat norm [
            ask one-of myplot with [plabel-color = blue][
              let lab plabel
              let sf samefield
              if lab != "" [
                ask myplot with [plabel = lab and samefield = sf][
                  set plabel-color black;;fields that can be irrigated
                ]
              ]
            ]
          ]

        ]

      ]
    ][
      ask myplot [set plabel-color black]
    ]
  ]

  ;;biodiversity
  calcBiodiversity
end

to directfeed
  let psd pseudo
  let idplays idplay
  let fodder feed
  let animal livestock
  let foragecowdon 0;actual number of animal to be fed
  let nanim amount_feed;number of animal to be fed
  let shp "" let form "star" let vis true let fict 0; vis=visibility ; fict = fictive agent (for conc)
  let fac 0; 8 for cow 6 for donkey 4 for small ruminants. x3 in the virtual game
  let eff 1; 2 for conc 1 for residue

  if animal = "cattle" [set fac (1 / (10 * 3))]
  if animal = "donkey" [set fac (1 / (8 * 3))]
  if animal = "small ruminant" [set fac (1 / (6 * 3))]

  if fodder = "concentrate" [set eff 2 set form "lightning" set vis false set fict 1]

  let farmlab item 0 [farm] of farmers with [player = idplays]
  ask farmers with [player = idplays][
    set forage count out-link-neighbors with [shape = form and hidden? = vis and mulch? != true] - fict
    set forage forage * fac * eff
    if animal = "cattle"[
      set foragecowdon count out-link-neighbors with [shape = "cow" and canmove = "yes" and grazed != "yes"]
      set shp "cow"
    ]
    if animal = "donkey"[
      set foragecowdon count out-link-neighbors with [shape = "wolf" and canmove = "yes" and grazed != "yes"]
      set shp "wolf"
    ]
    if animal = "small ruminant"[
      set foragecowdon count out-link-neighbors with [shape = "sheep" and canmove = "yes" and grazed != "yes"]
      set shp "sheep"
    ]
    ;;8 residue feed one cow, 6 for donkey for one season
    ;;4 residue feed 1 small ruminants for one season
    if nanim < foragecowdon [set foragecowdon nanim]

    ifelse forage >= foragecowdon [
      ask n-of foragecowdon out-link-neighbors with [shape = shp and canmove = "yes" and grazed != "yes"][
        set grazed "yes"
        set hunger 0
      ]

      ask n-of ceiling (foragecowdon / (fac * eff)) out-link-neighbors with [shape = form and hidden? = vis and mulch? != true][
        die
      ]
      ask joueurs with [idplay = idplays][
        hubnet-send pseudo "amount_feed" 0
        set amount_feed 0
      ]
    ]
    [
      ask joueurs with [idplay = idplays][
        hubnet-send pseudo "warning" "You do not own enough biomass"
        hubnet-send pseudo "amount_feed" 0
        set amount_feed 0
      ]
    ]

  ]
  ;set livfeed? true
end

to directfeed-play [id animals]
  let psd item 0[pseudo] of joueurs with [idplay = id]
  let idplays id
  let fodder item 0[feed] of joueurs with [idplay = id]
  let animal animals
  let foragecowdon 0;actual number of animal to be fed
  let shp ""
  let form "star"
  let vis true
  let fict 0; vis=visibility ; fict = fictive agent (for conc)
  let nanim 0
  let enreq 6;;energy required by animals.default 6 for small ruminants
  let enreq-anim 0
  let forme "sheep"

  ask farmers with [player = idplays][
    set nanim count out-link-neighbors with [shape = form and hidden? = vis and mulch? != true] - fict;;amount_feed;number of animal to be fed
  ]
  let fac 0.5; factor conversion for feed. 8 residues for cow 6 for donkey 4 for small ruminants in physical game. so time 3 here.
  let eff 1; 2 for conc 1 for residue

  if animal = "cattle" [set fac (1 / (10 * 3)) set enreq-anim (10 * 3) set forme "cow"]
  if animal = "donkey" [set fac (1 / (8 * 3)) set enreq-anim (8 * 3) set forme "wolf"]
  if fodder = "concentrate" [set eff 2 set form "lightning" set vis false set fict 1]

  let farmlab item 0 [farm] of farmers with [player = idplays]
  ask farmers with [player = idplays][
    set forage count out-link-neighbors with [shape = form and hidden? = vis and mulch? != true] - fict
    set forage forage * fac * eff
    if animal = "cattle"[
      set foragecowdon count out-link-neighbors with [shape = "cow" and canmove = "yes" and grazed != "yes"]
      set enreq sum [10 * 3 - energy] of out-link-neighbors with [shape = "cow" and canmove = "yes" and grazed != "yes"]
      set shp "cow"
    ]
    if animal = "donkey"[
      set foragecowdon count out-link-neighbors with [shape = "wolf" and canmove = "yes" and grazed != "yes"]
      set enreq sum [8 * 3 - energy] of out-link-neighbors with [shape = "cow" and canmove = "yes" and grazed != "yes"]
      set shp "wolf"
    ]
    if animal = "small ruminant"[
      set foragecowdon count out-link-neighbors with [shape = "sheep" and canmove = "yes" and grazed != "yes"]
      set enreq sum [6 * 3 - energy] of out-link-neighbors with [shape = "cow" and canmove = "yes" and grazed != "yes"]
      set shp "sheep"
    ]
    ;;1 residue feed one cow/donkey for one season
    ;;1 residue feed 1 small ruminants for one season
    ;if nanim < foragecowdon [set foragecowdon nanim]
    if foragecowdon > 0 [
      while [forage > 0 and count out-link-neighbors with [shape = forme and canmove = "yes" and grazed != "yes"] > 0] [
        ask one-of out-link-neighbors with [shape = forme and canmove = "yes" and grazed != "yes"][
          let nreq enreq-anim - energy
          ifelse forage > nreq [
            set energy enreq-anim
            set grazed "yes"
            set hunger 0
            set forage forage - nreq
          ][
            set energy energy + forage
            set hunger energy - enreq-anim
            if energy >= enreq-anim [
              set grazed "yes"
              set hunger 0
            ]
            set forage 0
          ]
        ]


      ]
    ]

    ;;chicken
    let ngr ngrain
    let nhp count out-link-neighbors with [shape = "bird" and energy != 99 and grazed != "yes"]
    if ngr > nhp [set ngr nhp]
    ask n-of ngr out-link-neighbors with [shape = "bird" and energy != 99 and grazed != "yes"][
      set energy 1
      set grazed "yes"
    ]

    ask out-link-neighbors with [shape = "bird" and energy != 99] [
     set hunger energy - 1
    ]
  ]
  ;set livfeed? true
end

to emergencyfeed [gamer animal]
  let fac 0
  let frg forage
  if animal = "sheep" [set fac 2]
  ask farmers with [player = gamer][
    let riskyc count out-link-neighbors with [shape = animal and canmove = "yes" and hunger > 0]
    if riskyc > 0 [ifelse (forage * fac) > riskyc [
      ask n-of riskyc out-link-neighbors with [shape = animal and canmove = "yes" and hunger > 0][
        set energy energy + 1
        set hunger 0
        set grazed "yes"
        set forage forage - floor riskyc / fac
      ]]
      [ask n-of (forage * fac) out-link-neighbors with [shape = animal and canmove = "yes" and hunger > 0][
        set energy energy + 1
        set hunger 0
        set grazed "yes"
        set forage 0
      ]]
      ; ask n-of (ceiling frg - forage) out-link-neighbors with [shape = "star" and hidden? = true][
      ;  die
      ; ]
  ]]
end


to foreignresidue [gamer]
  ;;other farms access residue left on field
  if gamer = "player 1" [set accessresid open_field1?]
  if gamer = "player 2" [set accessresid open_field2?]
  if gamer = "player 3" [set accessresid open_field3?]
  if gamer = "player 4" [set accessresid open_field4?]
  if any? joueurs with [idplay = gamer][
    set accessresid item 0 [open_field?] of joueurs with [idplay = gamer]];;player has priority on game master
  ask farmers with [player = gamer][
    ask out-link-neighbors with [typo = "residue" and shape = "star"][
      if accessresid = true [
        set foreignaccess "yes"
      ]
    ]
  ]
end

to liens [ferme]
  ask farmers with [farm = ferme] [
    create-biom_owner-to other turtles with [farm = ferme][
      set color red hide-link
    ]
    ask out-link-neighbors [
      set label farm
      set label-color red
    ]
  ]

  ;;special case of tricycle rented
    ask farmers with [farm = ferme] [
    create-biom_owner-to other turtles with [tractor_owner = ferme][
      set color red hide-link
    ]
  ]
end

to farmlink
  ask farmers [
    create-biom_transfer-to other farmers[
      set color blue hide-link
    ]
  ]

end


to feedfamily [gamer]
  ;;1 unit of grain = 1 persons per year
  let nfeed 0
  let ration (1 / 3) * (item 0 [ngrain] of farmers with [player = gamer]); * 2
  ifelse (item 0 [feedfam] of farmers with [player = gamer]) = 0 [
    set nfeed item 0 [family_size] of farmers with [player = gamer]]
  [set nfeed item 0 [food_unsecure] of farmers with [player = gamer]]

  let foodreq ration - nfeed
  ask farmers with [player = gamer][
    ask out-link-neighbors with [shape = "cylinder"][set hidden? true]
    ifelse foodreq < 0 [
      set food_unsecure ceiling abs foodreq
      set ngrain 0
      ask out-link-neighbors with [shape = "cylinder"][die]
    ]
    [
      set food_unsecure 0
      set ngrain floor (ngrain - 3 * nfeed)
      ask n-of (ceiling 3 * nfeed) out-link-neighbors with [shape = "cylinder"][die]
    ]
    set feedfam 1
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
456
10
864
419
-1
-1
30.8
1
10
1
1
1
0
0
0
1
0
12
-12
0
1
1
1
ticks
30.0

BUTTON
64
35
131
68
set-up
set-up\nenvironment
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
311
217
398
262
Month
month
17
1
11

TEXTBOX
923
10
1019
30
Player 1 stats
16
0.0
1

MONITOR
867
35
924
80
cattle
item 0 [ncow] of turtles with [player = \"player 1\" and shape = \"person farmer\"]
17
1
11

MONITOR
925
35
989
80
small rum
item 0 [nsrum] of turtles with [player = \"player 1\" and shape = \"person farmer\"]
17
1
11

MONITOR
990
35
1047
80
poultry
item 0 [npoultry] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1049
35
1099
80
donkey
item 0 [ndonkey] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1152
35
1202
80
fertilizer
item 0 [nfertilizer] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1204
35
1254
80
cart
item 0 [ncart] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1100
35
1150
80
tricycle
item 0 [ntricycle] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1257
35
1307
80
grain
item 0 [ngrain] of turtles with [\nplayer = \"player 1\" and\nshape = \"person farmer\"]
17
1
11

MONITOR
867
84
938
129
residue harv
item 0 [nresidue] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1111
85
1168
130
conc
item 0 [nconc] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1171
85
1228
130
manure
item 0 [nmanure] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1283
84
1333
129
on farm
item 0 [onfarm_inc] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1231
84
1282
129
off farm
item 0 [offfarm_inc] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

BUTTON
534
428
812
461
Next step
if ticks = 0 [plot-pen-down]\nif member? month [\"December\" \"May\"][grow [0]];;[sow grow [0]]\n;grow [0]\nfeedfamily-explo \"player 1\"\nfeedfamily-explo \"player 2\"\nfeedfamily-explo \"player 3\"\nfeedfamily-explo \"player 4\"\n;set buy_how_much 0\n;set sell_how_much 0\n;set biomass_sent_amount 0\n;set biomass_in_amount 0\nnextmonth
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
30
598
122
631
presid1
presid1
0
100
310.0
1
1
NIL
HORIZONTAL

SLIDER
129
598
222
631
presid2
presid2
0
100
483.0
1
1
NIL
HORIZONTAL

SLIDER
29
707
121
740
presid3
presid3
0
100
146.0
1
1
NIL
HORIZONTAL

SLIDER
129
707
221
740
presid4
presid4
0
100
53.0
1
1
NIL
HORIZONTAL

TEXTBOX
9
557
241
576
Proportion of residue left on field
14
0.0
1

TEXTBOX
56
579
110
597
Player 1
12
0.0
1

TEXTBOX
152
578
198
596
Player 2
12
0.0
1

TEXTBOX
56
687
103
705
Player 3
12
0.0
1

TEXTBOX
149
687
193
705
Player 4
12
0.0
1

MONITOR
1019
85
1106
130
residue on field
count turtles\nwith [farm = \"1\" and\n hidden? = false and shape = \"star\" and mulch? != true]
17
1
11

MONITOR
238
267
326
312
Season
saison
17
1
11

MONITOR
940
84
1014
129
stock residue
count turtles\nwith [farm = \"1\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]
17
1
11

TEXTBOX
925
131
1024
151
Player 2 stats
16
0.0
1

MONITOR
867
154
917
199
cattle
item 0 [ncow] of turtles with [player = \"player 2\" and shape = \"person farmer\"]
17
1
11

MONITOR
919
153
974
198
small rum
item 0 [nsrum] of turtles with [player = \"player 2\" and shape = \"person farmer\"]
17
1
11

MONITOR
976
153
1026
198
poultry
item 0 [npoultry] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1028
153
1078
198
donkey
item 0 [ndonkey] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1080
153
1130
198
tricycle
item 0 [ntricycle] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1132
153
1190
198
fertilizer
item 0 [nfertilizer] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1194
153
1246
198
cart
item 0 [ncart] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1250
152
1307
197
grain
item 0 [ngrain] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
868
201
942
246
residue harv
item 0 [nresidue] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
944
201
1020
246
stock residue
count turtles\nwith [farm = \"2\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]
17
1
11

MONITOR
1021
202
1109
247
residue on field
count turtles\nwith [farm = \"2\" and\n hidden? = false and shape = \"star\" and mulch? != true]
17
1
11

MONITOR
1110
202
1160
247
conc
item 0 [nconc] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1163
202
1213
247
manure
item 0 [nmanure] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1215
202
1265
247
off farm
item 0 [offfarm_inc] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1269
201
1319
246
on farm
item 0 [onfarm_inc] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

TEXTBOX
931
252
1033
272
Player 3 stats
16
0.0
1

MONITOR
868
277
918
322
cattle
item 0 [ncow] of turtles with [player = \"player 3\" and shape = \"person farmer\"]
17
1
11

MONITOR
920
277
976
322
small rum
item 0 [nsrum] of turtles with [player = \"player 3\" and shape = \"person farmer\"]
17
1
11

MONITOR
979
277
1036
322
poultry
item 0 [npoultry] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1039
277
1089
322
donkey
item 0 [ndonkey] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1091
277
1141
322
tricycle
item 0 [ntricycle] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1143
277
1193
322
fertilizer
item 0 [nfertilizer] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1196
277
1246
322
cart
item 0 [ncart] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1249
277
1299
322
grain
item 0 [ngrain] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
868
324
939
369
residue harv
item 0 [nresidue] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
941
324
1017
369
stock residue
count turtles\nwith [farm = \"3\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]
17
1
11

MONITOR
1019
324
1103
369
residue on field
count turtles\nwith [farm = \"3\" and\n hidden? = false and shape = \"star\" and mulch? != true]
17
1
11

MONITOR
1106
324
1156
369
conc
item 0 [nconc] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1159
324
1209
369
manure
item 0 [nmanure] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1212
325
1262
370
off farm
item 0 [offfarm_inc] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1264
324
1314
369
on farm
item 0 [onfarm_inc] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

TEXTBOX
933
376
1032
396
Player 4 stats
16
0.0
1

MONITOR
870
397
920
442
cattle
item 0 [ncow] of turtles with [player = \"player 4\" and shape = \"person farmer\"]
17
1
11

MONITOR
923
397
979
442
small rum
item 0 [nsrum] of turtles with [player = \"player 4\" and shape = \"person farmer\"]
17
1
11

MONITOR
982
397
1032
442
poultry
item 0 [npoultry] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1036
396
1086
441
donkey
item 0 [ndonkey] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1090
395
1140
440
tricycle
item 0 [ntricycle] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1143
395
1193
440
fertilizer
item 0 [nfertilizer] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1196
395
1246
440
cart
item 0 [ncart] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1248
395
1298
440
grain
item 0 [ngrain] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
870
445
942
490
residue harv
item 0 [nresidue] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
944
445
1020
490
stock residue
count turtles\nwith [farm = \"4\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]
17
1
11

MONITOR
1021
445
1109
490
residue on field
count turtles\nwith [farm = \"4\" and\n hidden? = false and shape = \"star\" and mulch? != true]
17
1
11

MONITOR
1112
445
1162
490
conc
item 0 [nconc] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1166
445
1216
490
manure
item 0 [nmanure] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1219
445
1269
490
off farm
item 0 [offfarm_inc] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1272
446
1322
491
on farm
item 0 [onfarm_inc] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

TEXTBOX
205
26
462
52
Management of common resources
16
0.0
1

MONITOR
334
268
396
313
Warning
warn
17
1
11

MONITOR
986
524
1036
569
Player 1
item 0 [food_unsecure] of farmers with [player = \"player 1\"]
17
1
11

MONITOR
1044
524
1094
569
Player 2
item 0 [food_unsecure] of farmers with [player = \"player 2\"]
17
1
11

MONITOR
1101
523
1151
568
Player 3
item 0 [food_unsecure] of farmers with [player = \"player 3\"]
17
1
11

MONITOR
1156
523
1206
568
Player 4
item 0 [food_unsecure] of farmers with [player = \"player 4\"]
17
1
11

TEXTBOX
1040
497
1153
516
Food unsecure
14
0.0
1

MONITOR
248
218
305
263
Year
year
17
1
11

MONITOR
1322
154
1387
199
risky cow
count turtles with [farm = \"2\" and\nhunger > 0 and shape = \"cow\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1322
36
1387
81
risky cow
count turtles with [farm = \"1\" and\nhunger > 0 and shape = \"cow\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1389
35
1459
80
risky srum
count turtles with [farm = \"1\" and\nhunger > 0 and shape = \"sheep\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1358
84
1441
129
risky donkey
count turtles with [farm = \"1\" and\nhunger > 0 and shape = \"wolf\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1388
153
1458
198
risky srum
count turtles with [farm = \"2\" and\nhunger > 0 and shape = \"sheep\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1344
202
1426
247
risky donkey
count turtles with [farm = \"2\" and\nhunger > 0 and shape = \"wolf\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1322
278
1387
323
risky cow
count turtles with [farm = \"3\" and\nhunger > 0 and shape = \"cow\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1386
278
1454
323
risky srum
count turtles with [farm = \"3\" and\nhunger > 0 and shape = \"sheep\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1352
326
1432
371
risky donkey
count turtles with [farm = \"3\" and\nhunger > 0 and shape = \"wolf\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1320
399
1385
444
risky cow
count turtles with [farm = \"4\" and\nhunger > 0 and shape = \"cow\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1387
398
1454
443
risky srum
count turtles with [farm = \"4\" and\nhunger > 0 and shape = \"sheep\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1354
447
1433
492
risky donkey
count turtles with [farm = \"4\" and\nhunger > 0 and shape = \"wolf\" and \n[pcolor] of patch-here != white\n]
17
1
11

BUTTON
20
287
83
320
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1486
37
1719
210
residue left on field
ticks
amount of residue
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player 1" 1.0 0 -13791810 true "" "plot count turtles\nwith [farm = \"1\" and\n hidden? = false and shape = \"star\"]"
"player 2" 1.0 0 -1184463 true "" "plot count turtles\nwith [farm = \"2\" and\n hidden? = false and shape = \"star\"]"
"player 3" 1.0 0 -12087248 true "" "plot count turtles\nwith [farm = \"3\" and\n hidden? = false and shape = \"star\"]"
"player 4" 1.0 0 -955883 true "" "plot count turtles\nwith [farm = \"4\" and\n hidden? = false and shape = \"star\"]"

PLOT
1719
36
1952
211
residue stocked
ticks
amount of residue
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player 1" 1.0 0 -13791810 true "" "plot count turtles\nwith [farm = \"1\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]"
"player 2" 1.0 0 -1184463 true "" "plot count turtles\nwith [farm = \"2\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]"
"player 3" 1.0 0 -14439633 true "" "plot count turtles\nwith [farm = \"3\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]"
"player 4" 1.0 0 -955883 true "" "plot count turtles\nwith [farm = \"4\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]"

PLOT
1487
213
1722
390
cattle
ticks
Number of animals
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player 1" 1.0 2 -13791810 true "" "if ticks > 0 [\nplot item 0 [ncow] of turtles\nwith [farm = \"1\" and shape = \"person farmer\"]\n]"
"player 2" 1.0 2 -1184463 true "" "if ticks > 0 [\nplot item 0 [ncow] of turtles\nwith [farm = \"2\" and shape = \"person farmer\"]\n]"
"player 3" 1.0 2 -14439633 true "" "if ticks > 0 [\nplot item 0 [ncow] of turtles\nwith [farm = \"3\" and shape = \"person farmer\"]\n]"
"player 4" 1.0 2 -955883 true "" "if ticks > 0 [\nplot item 0 [ncow] of turtles\nwith [farm = \"4\" and shape = \"person farmer\"]\n]"

PLOT
1724
213
1953
389
small ruminants
ticks
Number of animals
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player 1" 1.0 2 -13791810 true "" "if ticks > 0 [\nplot item 0 [nsrum] of turtles\nwith [farm = \"1\" and shape = \"person farmer\"]\n]"
"player 2" 1.0 2 -1184463 true "" "if ticks > 0 [\nplot item 0 [nsrum] of turtles\nwith [farm = \"2\" and shape = \"person farmer\"]\n]"
"player 3" 1.0 2 -13840069 true "" "if ticks > 0 [\nplot item 0 [nsrum] of turtles\nwith [farm = \"3\" and shape = \"person farmer\"]\n]"
"player 4" 1.0 2 -955883 true "" "if ticks > 0 [\nplot item 0 [nsrum] of turtles\nwith [farm = \"4\" and shape = \"person farmer\"]\n]"

PLOT
1486
393
1723
543
total income
ticks
Income
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player 1" 1.0 2 -13791810 true "" "if ticks > 0 [\nplot item 0[onfarm_inc + offfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 1\"\n]\n]"
"player 2" 1.0 2 -1184463 true "" "if ticks > 0 [\nplot item 0[onfarm_inc + offfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 2\"\n]\n]"
"player 3" 1.0 2 -13840069 true "" "if ticks > 0 [\nplot item 0[onfarm_inc + offfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 3\"\n]\n]"
"player 4" 1.0 2 -955883 true "" "if ticks > 0 [\nplot item 0[onfarm_inc + offfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 4\"\n]\n]"

PLOT
1712
545
1950
700
grain
ticks
amount of grain
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player 1" 1.0 2 -13791810 true "" "if ticks > 0 [\nplot item 0[ngrain] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 1\"\n]\n]"
"player 2" 1.0 2 -1184463 true "" "if ticks > 0 [\nplot item 0[ngrain] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 2\"\n]\n]"
"player 3" 1.0 2 -13840069 true "" "if ticks > 0 [\nplot item 0[ngrain] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 3\"\n]\n]"
"player 4" 1.0 2 -955883 true "" "if ticks > 0 [\nplot item 0[ngrain] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 4\"\n]\n]"

SWITCH
7
634
124
667
open_field1?
open_field1?
0
1
-1000

SWITCH
129
634
247
667
open_field2?
open_field2?
0
1
-1000

SWITCH
7
744
122
777
open_field3?
open_field3?
0
1
-1000

SWITCH
132
746
247
779
open_field4?
open_field4?
0
1
-1000

BUTTON
18
119
98
152
autoplay
;;create robot player in autoplay mode\nif auto-play?[\n create-robots \n]\n\n;;loop\nrepeat runs * 3 [\n\nsmartplay\n\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
122
120
191
180
runs
20000.0
1
0
Number

PLOT
1499
551
1699
701
Total grain stock
NIL
NIL
0.0
5.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" "if ticks > 0 [\n\nplot sum [ngrain] of farmers\n\n]"

BUTTON
45
392
124
425
NIL
create-robots
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
345
60
439
120
land_price
4.0
1
0
Number

SWITCH
218
53
331
86
open_shrub?
open_shrub?
0
1
-1000

SWITCH
217
91
331
124
open_forest?
open_forest?
1
1
-1000

MONITOR
1253
524
1330
569
NIL
biodiversity
17
1
11

SWITCH
13
159
115
192
auto-play?
auto-play?
0
1
-1000

PLOT
1958
38
2228
212
strategy score (max)
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player 1" 1.0 0 -13791810 true "" "if ticks > 0 [\nplot item 0[item 0 strategyscore] of farmers with [farm = \"1\"]\n]"
"player 2" 1.0 0 -1184463 true "" "if ticks > 0 [\nplot item 0[item 0 strategyscore] of farmers with [farm = \"2\"]\n]"
"player 3" 1.0 0 -13840069 true "" "if ticks > 0 [\nplot item 0[item 0 strategyscore] of farmers with [farm = \"3\"]\n]"
"player 4" 1.0 0 -955883 true "" "if ticks > 0 [\nplot item 0[item 0 strategyscore] of farmers with [farm = \"4\"]\n]"
"government" 1.0 0 -7858858 true "" "if ticks > 0 [\nplot item 0[item 0 strategyscore] of government\n]"

PLOT
1962
218
2162
368
crop value
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -955883 true "" "if ticks > 0 [\nlet val1 count turtles with [typo = \"grain\" and pcolor != magenta and [pcolor] of patch-here != white and hunger = 0]\nlet val2 count turtles with [typo = \"grain\" and pcolor = magenta and [pcolor] of patch-here != white and hunger = 0]\nlet val3 count turtles with [typo = \"residue\" and [pcolor] of patch-here != white and hunger = 0]\nplot val1 * (1 / 3) + val2 * (2 / 3) + val3 * (.5 / 3)\n]"

PLOT
2168
218
2368
368
livestock value
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -2064490 true "" "if ticks > 0 [\nplot sum [ncow * 10 + ndonkey * 5 + nsrum * 3 + npoultry * 1] of farmers\n]"

PLOT
1972
377
2172
527
labour
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -7500403 true "" "if ticks > 0 [\nplot sum [labour] of farmers\n]"

PLOT
2189
376
2389
526
income
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -7171555 true "" "if ticks > 0 [\nplot sum [onfarm_inc + offfarm_inc] of farmers\n]"

PLOT
1972
534
2172
684
biodiversity
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -13840069 true "" "plot biodiversity"

SWITCH
216
126
346
159
open_fieldsold?
open_fieldsold?
1
1
-1000

BUTTON
91
287
164
321
play-with-AI
smart-player
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
63
258
116
277
Hubnet
16
0.0
1

TEXTBOX
65
91
146
110
Exploration
16
0.0
1

TEXTBOX
35
13
189
33
Set-up environment
16
0.0
1

TEXTBOX
50
362
158
391
Only useful in test phase of hubnet
11
0.0
1

TEXTBOX
291
190
341
209
Global
16
0.0
1

PLOT
2185
539
2385
689
food unsecure
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -14462382 true "" "if ticks > 0 [\nplot sum [food_unsecure] of farmers\n]"

PLOT
1738
394
1938
544
donkeys
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"player 1" 1.0 2 -13791810 true "" "if ticks > 0 [\nplot item 0 [ndonkey] of turtles\nwith [farm = \"1\" and shape = \"person farmer\"]\n]"
"player 2" 1.0 2 -1184463 true "" "if ticks > 0 [\nplot item 0 [ndonkey] of turtles\nwith [farm = \"2\" and shape = \"person farmer\"]\n]"
"player 3" 1.0 2 -10899396 true "" "if ticks > 0 [\nplot item 0 [ndonkey] of turtles\nwith [farm = \"3\" and shape = \"person farmer\"]\n]"
"player 4" 1.0 2 -955883 true "" "if ticks > 0 [\nplot item 0 [ndonkey] of turtles\nwith [farm = \"4\" and shape = \"person farmer\"]\n]"

PLOT
2402
377
2602
527
off farm income
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -3425830 true "" "if ticks > 0 [\nplot sum [offfarm_inc] of farmers\n]"

PLOT
2397
539
2597
689
total money borrowed
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -2674135 true "" "if ticks > 0 [\nplot sum [moneyborrowed] of farmers\n]"

PLOT
1552
707
1752
857
microfinance available
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -14439633 true "" "if ticks > 0 [\nplot gov_microfinance\n]"

PLOT
1764
706
1964
853
rate microfinance
NIL
NIL
0.0
10.0
0.0
0.5
true
false
"" ""
PENS
"default" 1.0 2 -14439633 true "" "if ticks > 0 [\nplot micro_rate\n]"

PLOT
2190
699
2390
849
forest restoration budget
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -10649926 true "" "if ticks > 0 [\nplot gov_forestrest\n]"

PLOT
2397
698
2597
848
shrubland restoration budget
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -817084 true "" "if ticks > 0 [\nplot gov_shrubrest\n]"

PLOT
1975
699
2175
853
land price
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -10603201 true "" "if ticks > 0 [\nplot land_price\n]"

PLOT
1341
708
1541
858
off farm employment
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -11881837 true "" "if ticks > 0 [\nplot item 0 [gov_employment] of government\n]"

PLOT
1128
708
1328
858
shannon index crops
NIL
NIL
0.0
10.0
0.0
4.0
true
false
"" ""
PENS
"default" 1.0 2 -2674135 true "" "if ticks > 0 [\n\nlet cps sentence [crop1] of patches with [cultiv = \"yes\" and pcolor = rgb 0 255 0][crop2] of patches with [cultiv = \"yes\" and pcolor = rgb 0 255 0]\nlet shannon 0; in case there is no crop grown\n\n\nif length cps > 0 [\n\nlet cp1 filter [i -> i = 1] cps\nlet cp2 filter [i -> i = 2] cps\n\nlet cp3 filter [i -> i = 3] cps\nlet cp4 filter [i -> i = 4] cps\n\n\nlet sp1 (length cp1 / length cps)\n\nlet sp2 (length cp2 / length cps)\n\nlet sp3 (length cp3 / length cps)\n\nlet sp4 (length cp4 / length cps)\n\n\n\nset shannon 0\n\n\nif sp1 > 0 [\nset shannon shannon + sp1 * (ln sp1)\n]\n\n\nif sp2 > 0 [\n set shannon shannon + sp2 * (ln sp2)\n]\n\n\nif sp3 > 0 [\n set shannon shannon + sp3 * (ln sp3)\n]\n\n\nif sp4 > 0 [\n set shannon shannon + sp4 * (ln sp4)\n]\n\n\nset shannon -1 * shannon\n\n]\n\n\nplot shannon\n\n\n]"

PLOT
917
709
1117
859
gini
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 2 -11221820 true "" "if ticks > 0 [\nset equity gini.jar:gini [onfarm_inc + offfarm_inc]of farmers\nplot equity\n]"

BUTTON
38
464
136
497
export data
;;force to export\nset nsim (runs * 3) - 1\nexport-data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
29
441
179
459
premature export data
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

acorn
false
0
Polygon -7500403 true true 146 297 120 285 105 270 75 225 60 180 60 150 75 105 225 105 240 150 240 180 225 225 195 270 180 285 155 297
Polygon -6459832 true false 121 15 136 58 94 53 68 65 46 90 46 105 75 115 234 117 256 105 256 90 239 68 209 57 157 59 136 8
Circle -16777216 false false 223 95 18
Circle -16777216 false false 219 77 18
Circle -16777216 false false 205 88 18
Line -16777216 false 214 68 223 71
Line -16777216 false 223 72 225 78
Line -16777216 false 212 88 207 82
Line -16777216 false 206 82 195 82
Line -16777216 false 197 114 201 107
Line -16777216 false 201 106 193 97
Line -16777216 false 198 66 189 60
Line -16777216 false 176 87 180 80
Line -16777216 false 157 105 161 98
Line -16777216 false 158 65 150 56
Line -16777216 false 180 79 172 70
Line -16777216 false 193 73 197 66
Line -16777216 false 237 82 252 84
Line -16777216 false 249 86 253 97
Line -16777216 false 240 104 252 96

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bird
false
0
Polygon -7500403 true true 135 165 90 270 120 300 180 300 210 270 165 165
Rectangle -7500403 true true 120 105 180 237
Polygon -7500403 true true 135 105 120 75 105 45 121 6 167 8 207 25 257 46 180 75 165 105
Circle -16777216 true false 128 21 42
Polygon -7500403 true true 163 116 194 92 212 86 230 86 250 90 265 98 279 111 290 126 296 143 298 158 298 166 296 183 286 204 272 219 259 227 235 240 241 223 250 207 251 192 245 180 232 168 216 162 200 162 186 166 175 173 171 180
Polygon -7500403 true true 137 116 106 92 88 86 70 86 50 90 35 98 21 111 10 126 4 143 2 158 2 166 4 183 14 204 28 219 41 227 65 240 59 223 50 207 49 192 55 180 68 168 84 162 100 162 114 166 125 173 129 180

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

checker piece 2
false
0
Circle -7500403 true true 60 60 180
Circle -16777216 false false 60 60 180
Circle -7500403 true true 75 45 180
Circle -16777216 false false 83 36 180
Circle -7500403 true true 105 15 180
Circle -16777216 false false 105 15 180

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

coin tails
false
0
Circle -7500403 true true 15 15 270
Circle -16777216 false false 20 17 260
Line -16777216 false 130 92 171 92
Line -16777216 false 123 79 177 79
Rectangle -7500403 true true 57 101 242 133
Rectangle -16777216 false false 45 180 255 195
Rectangle -16777216 false false 75 120 225 135
Polygon -16777216 false false 81 226 70 241 86 248 93 235 89 232 108 243 97 256 118 247 118 265 123 248 142 247 129 253 130 271 145 269 131 259 162 245 153 262 168 268 197 259 177 255 187 245 174 243 193 235 209 251 193 234 225 244 208 227 240 240 222 218
Rectangle -7500403 true true 91 210 222 226
Polygon -16777216 false false 65 70 91 50 136 35 181 35 226 65 246 86 241 65 196 50 166 35 121 50 91 50 61 95 54 80 61 65
Polygon -16777216 false false 90 135 60 135 60 180 90 180 90 135 120 135 120 180 150 180 150 135 180 135 180 180 210 180 210 135 240 135 240 180 210 180 210 135

cow
true
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

drop
true
0
Circle -7500403 true true 73 133 152
Polygon -7500403 true true 219 181 205 152 185 120 174 95 163 64 156 37 149 7 147 166
Polygon -7500403 true true 79 182 95 152 115 120 126 95 137 64 144 37 150 6 154 165

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

lightning
false
0
Polygon -7500403 true true 120 135 90 195 135 195 105 300 225 165 180 165 210 105 165 105 195 0 75 135

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

molecule oxygen
true
0
Circle -7500403 true true 120 75 150
Circle -16777216 false false 120 75 150
Circle -7500403 true true 30 75 150
Circle -16777216 false false 30 75 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
true
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
true
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tile stones
false
0
Polygon -7500403 true true 0 240 45 195 75 180 90 165 90 135 45 120 0 135
Polygon -7500403 true true 300 240 285 210 270 180 270 150 300 135 300 225
Polygon -7500403 true true 225 300 240 270 270 255 285 255 300 285 300 300
Polygon -7500403 true true 0 285 30 300 0 300
Polygon -7500403 true true 225 0 210 15 210 30 255 60 285 45 300 30 300 0
Polygon -7500403 true true 0 30 30 0 0 0
Polygon -7500403 true true 15 30 75 0 180 0 195 30 225 60 210 90 135 60 45 60
Polygon -7500403 true true 0 105 30 105 75 120 105 105 90 75 45 75 0 60
Polygon -7500403 true true 300 60 240 75 255 105 285 120 300 105
Polygon -7500403 true true 120 75 120 105 105 135 105 165 165 150 240 150 255 135 240 105 210 105 180 90 150 75
Polygon -7500403 true true 75 300 135 285 195 300
Polygon -7500403 true true 30 285 75 285 120 270 150 270 150 210 90 195 60 210 15 255
Polygon -7500403 true true 180 285 240 255 255 225 255 195 240 165 195 165 150 165 135 195 165 210 165 255

tile water
false
0
Rectangle -7500403 true true -1 0 299 300
Polygon -1 true false 105 259 180 290 212 299 168 271 103 255 32 221 1 216 35 234
Polygon -1 true false 300 161 248 127 195 107 245 141 300 167
Polygon -1 true false 0 157 45 181 79 194 45 166 0 151
Polygon -1 true false 179 42 105 12 60 0 120 30 180 45 254 77 299 93 254 63
Polygon -1 true false 99 91 50 71 0 57 51 81 165 135
Polygon -1 true false 194 224 258 254 295 261 211 221 144 199

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
true
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
281
35
684
431
0
0
0
1
1
1
1
1
0
1
1
1
0
12
-12
0

CHOOSER
46
304
138
349
send_biomass
send_biomass
\"manure\" \"fertilizer\" \"grain\" \"residue\" \"cattle\" \"small ruminant\" \"donkey\" \"money\" \"labour\" \"tractor\" \"rent tractor to\" \"water pump\"
0

INPUTBOX
146
350
243
410
send_how_much
0.0
1
0
Number

CHOOSER
147
304
242
349
send_to
send_to
\"player 1\" \"player 2\" \"player 3\" \"player 4\" \"off farm activities\"
0

BUTTON
102
412
196
445
transfer_biomass
NIL
NIL
1
T
OBSERVER
NIL
NIL

TEXTBOX
66
33
242
59
Amount of residue to be harvested
11
0.0
1

TEXTBOX
99
289
243
307
Resources exchange
11
0.0
1

CHOOSER
33
502
138
547
buy_what
buy_what
\"manure\" \"fertilizer\" \"grain\" \"residue\" \"cattle\" \"small ruminant\" \"donkey\" \"labour\" \"tractor\" \"water pump\" \"field\" \"shrubland-field\" \"forest-field\" \"transhumance\"
0

INPUTBOX
159
503
233
563
amount_buy
0.0
1
0
Number

CHOOSER
31
573
123
618
sell_what
sell_what
\"manure\" \"fertilizer\" \"grain\" \"residue\" \"cattle\" \"small ruminant\" \"donkey\" \"labour\" \"tractor\" \"water pump\" \"field\"
0

INPUTBOX
160
574
233
634
amount_sell
0.0
1
0
Number

BUTTON
101
639
171
672
Market
NIL
NIL
1
T
OBSERVER
NIL
NIL

TEXTBOX
141
480
175
498
Market
11
0.0
1

MONITOR
1235
340
1289
389
cattle
NIL
0
1

MONITOR
1294
341
1352
390
srum
NIL
0
1

MONITOR
1029
389
1091
438
donkey
NIL
0
1

MONITOR
1029
339
1090
388
fertilizer
NIL
0
1

MONITOR
1170
340
1229
389
grain
NIL
0
1

MONITOR
1093
388
1179
437
stock residue
NIL
0
1

MONITOR
1096
339
1167
388
manure
NIL
0
1

MONITOR
1182
390
1259
439
total income
NIL
0
1

MONITOR
701
360
765
409
risky cow
NIL
0
1

MONITOR
773
360
842
409
risky srum
NIL
0
1

MONITOR
849
342
929
391
risky donkey
NIL
0
1

MONITOR
874
275
951
324
food unsecure
NIL
3
1

BUTTON
957
275
1040
308
feed family
NIL
NIL
1
T
OBSERVER
NIL
NIL

TEXTBOX
1030
314
1140
334
Resources
16
0.0
1

MONITOR
334
622
774
671
warning
NIL
0
1

TEXTBOX
453
453
564
471
Secret message
16
0.0
1

INPUTBOX
404
481
628
616
message text
NIL
1
1
String

BUTTON
634
558
720
591
send message
NIL
NIL
1
T
OBSERVER
NIL
NIL

CHOOSER
631
486
723
531
message who
message who
\"player 1\" \"player 2\" \"player 3\" \"player 4\"
0

MONITOR
832
567
948
616
pseudo_
NIL
0
1

MONITOR
968
567
1114
616
name
NIL
0
1

TEXTBOX
949
546
964
564
ID
11
0.0
1

MONITOR
922
483
1005
532
month
NIL
0
1

MONITOR
838
484
895
533
year
NIL
0
1

TEXTBOX
936
457
966
475
Time
11
0.0
1

TEXTBOX
29
29
50
253
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+
11
25.0
1

TEXTBOX
30
257
287
275
*+++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
267
29
286
253
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n
11
25.0
1

TEXTBOX
30
22
281
50
*+++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
25
284
40
438
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+
11
25.0
1

TEXTBOX
25
278
282
296
*++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
24
443
278
461
*++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
273
288
288
442
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n
11
25.0
1

TEXTBOX
4
477
19
701
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n
11
25.0
1

TEXTBOX
4
671
315
689
*+++++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
4
466
335
484
*+++++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
276
476
291
700
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+
11
25.0
1

TEXTBOX
321
449
336
673
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n
11
25.0
1

TEXTBOX
324
677
808
695
*++++++++++++++++++++++++++++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
324
444
802
462
*++++++++++++++++++++++++++++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
776
454
791
678
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n
11
25.0
1

TEXTBOX
1687
39
1702
375
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+
11
25.0
1

TEXTBOX
810
457
825
681
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+
11
25.0
1

TEXTBOX
817
682
1350
710
*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
814
446
1352
474
*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
1334
456
1349
680
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+
11
25.0
1

MONITOR
1020
483
1119
532
season
NIL
0
1

MONITOR
826
623
1326
672
list_of_player
NIL
3
1

MONITOR
751
275
868
324
household_members
NIL
3
1

CHOOSER
56
163
148
208
livestock
livestock
\"cattle\" \"donkey\" \"small ruminant\"
0

CHOOSER
56
210
148
255
feed
feed
\"residue\"
0

INPUTBOX
154
161
231
221
amount_feed
0.0
1
0
Number

BUTTON
155
223
230
256
feed livestock
NIL
NIL
1
T
OBSERVER
NIL
NIL

INPUTBOX
39
48
131
108
residue_harvest
0.0
1
0
Number

BUTTON
40
110
127
143
harvest residue
NIL
NIL
1
T
OBSERVER
NIL
NIL

TEXTBOX
120
143
190
161
Feed livestock
11
0.0
1

MONITOR
936
340
1006
389
cattle_fed
NIL
3
1

MONITOR
856
393
921
442
srum_fed
NIL
3
1

MONITOR
929
392
1008
441
donkey_fed
NIL
3
1

CHOOSER
46
351
138
396
diet
diet
\"fed\" \"hungry\"
0

BUTTON
987
12
1106
45
apply resources
NIL
NIL
1
T
OBSERVER
NIL
NIL

MONITOR
698
276
748
325
labour
NIL
3
1

CHOOSER
697
52
789
97
plot1_crop
plot1_crop
\"maize\" \"pigeonpea\" \"groundnut\" \"soybean\" \"maize+pigeonpea\" \"maize+groundnut\" \"maize+soybean\" \"pigeonpea+groundnut\" \"pigeonpea+soybean\" \"groundnut+soybean\"
0

CHOOSER
794
53
886
98
plot2_crop
plot2_crop
\"maize\" \"pigeonpea\" \"groundnut\" \"soybean\" \"maize+pigeonpea\" \"maize+groundnut\" \"maize+soybean\" \"pigeonpea+groundnut\" \"pigeonpea+soybean\" \"groundnut+soybean\"
0

CHOOSER
892
53
984
98
plot3_crop
plot3_crop
\"maize\" \"pigeonpea\" \"groundnut\" \"soybean\" \"maize+pigeonpea\" \"maize+groundnut\" \"maize+soybean\" \"pigeonpea+groundnut\" \"pigeonpea+soybean\" \"groundnut+soybean\"
0

CHOOSER
990
52
1082
97
plot4_crop
plot4_crop
\"maize\" \"pigeonpea\" \"groundnut\" \"soybean\" \"maize+pigeonpea\" \"maize+groundnut\" \"maize+soybean\" \"pigeonpea+groundnut\" \"pigeonpea+soybean\" \"groundnut+soybean\"
0

CHOOSER
697
99
789
144
plot1_fertilizer
plot1_fertilizer
0 1 2 3 4
0

CHOOSER
795
100
887
145
plot2_fertilizer
plot2_fertilizer
0 1 2 3 4
0

CHOOSER
893
99
985
144
plot3_fertilizer
plot3_fertilizer
0 1 2 3 4
0

CHOOSER
991
100
1083
145
plot4_fertilizer
plot4_fertilizer
0 1 2 3 4
0

CHOOSER
698
148
790
193
plot1_manure
plot1_manure
0 1 2 3 4
0

CHOOSER
795
148
887
193
plot2_manure
plot2_manure
0 1 2 3 4
0

CHOOSER
893
148
985
193
plot3_manure
plot3_manure
0 1 2 3 4
0

CHOOSER
992
149
1084
194
plot4_manure
plot4_manure
0 1 2 3 4
0

TEXTBOX
699
25
886
47
Cropping system settings
16
0.0
1

BUTTON
1175
481
1279
514
play_with_AI
NIL
NIL
1
T
OBSERVER
NIL
NIL

TEXTBOX
1170
522
1320
550
Only possible if there is less than four players
11
0.0
1

CHOOSER
698
199
790
244
plot1_residue
plot1_residue
0 1 2 3 4
0

CHOOSER
797
198
889
243
plot2_residue
plot2_residue
0 1 2 3 4
0

CHOOSER
895
199
987
244
plot3_residue
plot3_residue
0 1 2 3 4
0

CHOOSER
993
198
1085
243
plot4_residue
plot4_residue
0 1 2 3 4
0

TEXTBOX
702
256
787
276
Household
16
0.0
1

TEXTBOX
285
10
384
30
Game board
16
0.0
1

TEXTBOX
704
333
778
353
Livestock
16
0.0
1

CHOOSER
1084
51
1176
96
plot5_crop
plot5_crop
\"maize\" \"pigeonpea\" \"groundnut\" \"soybean\" \"maize+pigeonpea\" \"maize+groundnut\" \"maize+soybean\" \"pigeonpea+groundnut\" \"pigeonpea+soybean\" \"groundnut+soybean\"
0

CHOOSER
1178
51
1270
96
plot6_crop
plot6_crop
\"maize\" \"pigeonpea\" \"groundnut\" \"soybean\" \"maize+pigeonpea\" \"maize+groundnut\" \"maize+soybean\" \"pigeonpea+groundnut\" \"pigeonpea+soybean\" \"groundnut+soybean\"
0

CHOOSER
1272
51
1364
96
plot7_crop
plot7_crop
\"maize\" \"pigeonpea\" \"groundnut\" \"soybean\" \"maize+pigeonpea\" \"maize+groundnut\" \"maize+soybean\" \"pigeonpea+groundnut\" \"pigeonpea+soybean\" \"groundnut+soybean\"
0

CHOOSER
1086
100
1178
145
plot5_fertilizer
plot5_fertilizer
0 1 2 3 4
0

CHOOSER
1087
148
1179
193
plot5_manure
plot5_manure
0 1 2 3 4
0

CHOOSER
1088
197
1180
242
plot5_residue
plot5_residue
0 1 2 3 4
0

CHOOSER
1181
99
1273
144
plot6_fertilizer
plot6_fertilizer
0 1 2 3 4
0

CHOOSER
1183
149
1275
194
plot6_manure
plot6_manure
0 1 2 3 4
0

CHOOSER
1184
196
1276
241
plot6_residue
plot6_residue
0 1 2 3 4
0

CHOOSER
1275
99
1367
144
plot7_fertilizer
plot7_fertilizer
0 1 2 3 4
0

CHOOSER
1276
149
1368
194
plot7_manure
plot7_manure
0 1 2 3 4
0

CHOOSER
1278
196
1370
241
plot7_residue
plot7_residue
0 1 2 3 4
0

INPUTBOX
141
46
253
106
irr_residue_harvest
0.0
1
0
Number

@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
