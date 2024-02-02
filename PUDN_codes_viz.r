# Première version de codage (01 fév 2024)


# Importation ---------------------------------------------------------------


library(readr)
library(labelled)
library(questionr)
library(stringr)
library(tidyverse)

# Import des données dans R à partir de l'API HAL
url <- "https://api.archives-ouvertes.fr/search/hal/?q=alzheimer&rows=7000&wt=csv&indent=true&fl=docid,publicationDateY_i,docType_s,language_s,domain_s,primaryDomain_s,openAccess_bool,submitType_s,journalTitle_s,journalPublisher_s,authFullName_s,title_s,subTitle_s,citationRef_s,doiId_s,issue_s,journalIssn_s,volume_s,source_s,licence_s,files_s,journalTitleAbbr_s,title_st,submitType_s,type_s,page_s,publicationDate_s,keyword_s,en_keyword_s,fr_keyword_s,abstract_s,en_abstract_s,fr_abstract_s&sort=publicationDateY_i%20desc"

options(timeout=600) # pour forcer le temps limite de chargement (si faible connexion internet)
download.file(url, destfile = "AlzheimerHAL.csv")

url <- "https://api.archives-ouvertes.fr/search/hal/?q=alzheimer&rows=7000&wt=bibtex&indent=true&fl=docid,publicationDateY_i,docType_s,language_s,domain_s,primaryDomain_s,openAccess_bool,submitType_s,journalTitle_s,journalPublisher_s,authFullName_s,title_s,subTitle_s,citationRef_s,doiId_s,issue_s,journalIssn_s,volume_s,source_s,licence_s,files_s,journalTitleAbbr_s,title_st,submitType_s,type_s,page_s,publicationDate_s,keyword_s,en_keyword_s,fr_keyword_s,abstract_s,en_abstract_s,fr_abstract_s&sort=publicationDateY_i%20desc"

options(timeout=600) # pour forcer le temps limite de chargement (si faible connexion internet)
download.file(url, destfile = "AlzheimerHAL.bib")

# Le fichier csv est ensuite importé dans la session R sous forme de tableau de données (le fichier bibtext sera utilisé ultérieurement).
dataset_alzheimer <- read.csv("AlzheimerHAL.csv")

# Etiquetage des variables et de leurs modalités
# Les variables portent les mêmes noms que les champs sélectionnés dans le lien d'export dans l'API :
# noms des variables du dataframe
names(dataset_alzheimer)

# On ajoute des étiquettes aux noms de variables (avec le package labelled), pour les documenter et limiter les risques de mésinterprétation.
# Etiquettes de variables
var_label(dataset_alzheimer) <- list(
  docid = "Identifiant HAL du dépôt",
  publicationDateY_i = "Date de publication : année",
  docType_s = "Type de document",
  language_s = "Langue du document (code ISO 639-1 (alpha-2))",
  domain_s = "Codes domaines du document",
  primaryDomain_s = "Domaine primaire",
  openAccess_bool = "publication en open access",
  submitType_s = "Type de dépôt",
  journalTitle_s = "Revue : Titre",
  journalPublisher_s = "Revue : Editeur",
  authFullName_s = "Auteur : Nom complet ",
  title_s = "Titres",
  subTitle_s = "Sous-titre",
  citationRef_s = "Citation abrégée",
  doiId_s = "Identifiant DOI",
  issue_s = "Numéro de revue",
  journalIssn_s = "Revue : ISSN",
  volume_s= "Volume",
  source_s= "Source",
  licence_s= "Droit d'auteur associé au document",
  files_s= "URL des fichiers",
  journalTitleAbbr_s= "Revue : Titre abrégé",
  title_st= "Titres (sans les mots vides)",
  type_s= "Type",
  page_s= "Pagination",
  publicationDate_s= "Date de publication",
  keyword_s = "Mots-clés",
  en_keyword_s = "Mots-clés en anglais",
  fr_keyword_s = "Mots-clés en français",
  abstract_s = "Résumé",
  en_abstract_s = "Résumé en anglais",
  fr_abstract_s = "Résumé en français"
)

# De même pour rendre les modalités plus explicites, par exemple, le type et la langue du document :
# Etiquettes de modalités type de document
val_labels(dataset_alzheimer$docType_s) <- c(
  "Article dans une revue" = "ART",
  "Article de blog scientifique" = "BLOG",
  "Communication dans un congrès" = "COMM",
  "Chapitre d'ouvrage" = "COUV",
  "N°spécial de revue/special issue" = "ISSUE",
  "Cours" = "LECTURE",
  "Autre publication scientifique" = "OTHER",
  "Ouvrages" = "OUV",
  "Brevet" = "PATENT",
  "Poster de conférence" = "POSTER",
  "Rapport" = "REPORT",
  "Thèse" = "THESE",
  "Vidéo" = "VIDEO"
)

freq(dataset_alzheimer$docType_s, sort = "dec", valid = FALSE, total = TRUE) %>% knitr::kable(caption = "Types de documents présents dans le corpus")

# Langue
val_labels(dataset_alzheimer$language_s) <- c(
  "Allemand" = "de",
  "Anglais" = "en",
  "Espagnol" = "es",
  "Français" = "fr",
  "Portugais" = "pt",
  "Ukrainien" = "uk"
)

freq(dataset_alzheimer$language_s, sort = "dec", valid = FALSE, total = TRUE) %>% 
  knitr::kable(caption = "Langue du document")

# Les codes domaines sont particulièrement détaillés:
freq(dataset_alzheimer$primaryDomain_s, sort = "dec", valid = FALSE, total = TRUE) %>% 
  head(20) %>% 
  knitr::kable(caption = "Domaines primaires détaillés (les 20 plus fréquents)")

# On créé une variable `domaine_gpe`pour les regrouper.
# extraire les débuts de chaînes de caractères dans une nouvelle variable
# termes recherchés : commence par (^) chim ou (|) commence par,....
mots <- "^chim|^info|^math|^phys|^scco|^sde|^sdu|^sdv|^shs|^spi|^stat"

# domaine_gpe prend les modalités extraites de primaryDomains
dataset_alzheimer$domaine_gpe <- str_extract(dataset_alzheimer$primaryDomain_s, pattern = mots)

# ajoute des étiquettes aux modalités de domaine_gpe
val_labels(dataset_alzheimer$domaine_gpe) <- c(
  "Chimie" = "chim",
  "Informatique [cs]" = "info",
  "Mathématiques [math]" = "math",
  "Physique [physics]" = "phys",
  "Économie et finance quantitative [q-fin]" = "qfin",
  "Sciences cognitives" = "scco",
  "Sciences de l'environnement" = "sde",
  "Planète et Univers [physics]" = "sdu",
  "Sciences du Vivant [q-bio]" = "sdv",
  "Sciences de l'Homme et Société" = "shs",
  "Sciences de l'ingénieur [physics]" = "spi",
  "Statistiques [stat]" = "stat"
)

# tableau de fréquence
freq(dataset_alzheimer$domaine_gpe, sort = "dec", valid = FALSE) %>% 
  knitr::kable(caption = "Domaines primaires regroupés")

### TODO On crée aussi une variable domaine_shs, pour identifier les articles dont au moins un des domaines est shs.
dataset_alzheimer$language_gpe <- as.character(dataset_alzheimer$language_s)

dataset_alzheimer$language_gpe[dataset_alzheimer$language_s != "en" & dataset_alzheimer$language_s != "fr"] <- "autre"

val_labels(dataset_alzheimer$language_gpe) <- c(
  "Anglais" = "en",
  "Français" = "fr",
  "Autres" = "autre"
)

freq(dataset_alzheimer$language_gpe) %>% 
  knitr::kable(caption = "Langues du corpus")

## Sauvegarde des données et de leurs étiquettes
# On sauvegarde les données et leur configuration dans le fichier "AlzheimerHAL.Rda" qui sera utilisé pour faire les analyses.
save(dataset_alzheimer, file = "AlzheimerHAL.Rda")



# Nettoyage ---------------------------------------------------------------


# Nettoyage des données :

# Étape 1 : Préparation du dataset général
# Dans cette étape, nous procéderons à la préparation du dataset général pour 
#faire des visualisations sur les tendances générales

# Étape 2 : Création d'un sub-dataset spécialisé pour les revues
# Dans cette étape, nous créerons un sub-dataset spécifique qui se concentre exclusivement sur les 
# publications de type "revues". Cela permettra une analyse plus approfondie et ciblée sur ce 
# sous-ensemble de données, facilitant ainsi l'extraction d'informations spécifiques liées aux revues.




# Étape 1
# Préparation du dataset général : 

# Création d'un sous-ensemble de données "dataset_shs_alzheimer"

# Utilisation de l'opérateur de pipe (%>%) pour chaîner des opérations avec dplyr
dataset_shs_alzheimer <- dataset_alzheimer %>%
  
  # Filtrage des lignes basé sur des conditions spécifiques
  filter(
    # Utilisation de str_detect pour rechercher le motif "shs" ou "ssh" dans la colonne domain_s
    # ou la colonne primaryDomain_s, avec la conversion en minuscules pour rendre la recherche insensible à la casse
    str_detect(tolower(domain_s), "shs|ssh") |
      str_detect(tolower(primaryDomain_s), "shs|ssh")
  )


# Étape 2 :

# Création d'un dataset pour analyser les données liées aux revues :

# Affichage des données liées aux types de documents 
unique_doctype <- unique(dataset_alzheimer$docType_s)
print(unique_doctype)

# Vu que nous souhaitons nous concentrer sur les revues SHS, nous allons donc créer un nouveau dataset 
# qui prend seulement les données liées aux revues : ART(Article dans une revue) et ISSUE (N°spécial de revue/special issue)

# Filtrer le jeu de données pour inclure uniquement les lignes où docType_s est "ISSUE" ou "ART"
# et où la colonne journalTitle_s contient les mots "Revue", "revue", "review" ou "Review" 
# car il se peut que quelques revues ne soient pas indiquées comme étant des revues dans le type du document (undefined)

# Convertir publicationDateY_i en type numérique (nous allons supprimer les données de 2024 car nous souhaitons arrêter avant le 1er janvier 2024)
dataset_alzheimer$publicationDateY_i <- as.numeric(trimws(dataset_alzheimer$publicationDateY_i))

# Filtrer le jeu de données pour inclure uniquement les lignes où docType_s est "ISSUE" ou "ART"
# et où la colonne journalTitle_s contient les mots "Revue", "revue", "review" ou "Review"
# et où publicationDateY_i n'est pas égal à 2024
revues_shs_alzheimer <- dataset_alzheimer %>%
  filter(
    docType_s %in% c("ISSUE", "ART") &
      str_detect(tolower(journalTitle_s), "revue|review") &
      publicationDateY_i != 2024
  )

# Nous allons encore nettoyer notre jeu de données, en nous concentrant plutôt sur les revues SHS. 
# Filtrer le jeu de données pour inclure uniquement les lignes où docType_s est "ISSUE" ou "ART"
# et où domain_s et primaryDomain_s contiennent le mot "shs"
revues_shs_alzheimer <- revues_shs_alzheimer %>%
  filter(
    str_detect(tolower(domain_s), "shs|ssh") &
      str_detect(tolower(primaryDomain_s), "shs|ssh") &
      publicationDateY_i != 2024
  )

# Nous avons donc 47 publications de revues.

# Nettoyage des données liées à la langue :
# Nous allons tout d'abord créer une nouvelle colonne de vérification de langue
# Nous allons sélectionner les mots les plus utilisés dans les titres francophones et anglophones 
# pour filtrer et extraire la langue des publications
revues_shs_alzheimer <- revues_shs_alzheimer %>%
  mutate(language_title = ifelse(
    grepl("\\b(?:an|and|as|by|for|in|is|of|on|the|to|with)\\b", title_s, ignore.case = TRUE),
    "en",
    ifelse(
      grepl("\\b(?:le|la|et|a-t-il|a-t-elle)\\b", title_s, ignore.case = TRUE),
      "fr",
      NA
    )
  ))

# Nous allons comparer ces données à celles déjà saisies sur HAL (donc language_s)
# Filtrer les lignes où language_title n'est pas égal à language_s
lignes_langue_différente <- revues_shs_alzheimer %>%
  filter(language_title != language_s)

# Afficher les lignes
print(lignes_langue_différente)

# Maintenant que nous avons les lignes qui ne correspondent pas, nous allons vérifier manuellement 

# Nettoyer les données liées à la langue à partir de l'identifiant docid
revues_shs_alzheimer <- revues_shs_alzheimer %>%
  mutate(language_s = case_when(
    docid %in% c(3158921, 1584518, 1240621, 1806639) ~ "fr",
    TRUE ~ language_s
  ))

view(revues_shs_alzheimer)



# Viz 1 - Auteurs actifs ----------------------------------------------------------------

#1. Analyse des auteurs les plus actifs dans les revues SHS : Identification des auteurs avec le plus grand nombre de publications sur Alzheimer.
library(tidyverse)
library(questionr)
library(skimr)
library(igraph)

view(revues_shs_alzheimer)

revues_shs_auteur <- revues_shs_alzheimer %>% select(1:14,26)
skim(revues_shs_auteur)
view(revues_shs_auteur)

# distinguer les auteurs de chaque publication
revues_shs_auteur$AutList <- strsplit(revues_shs_auteur$authFullName_s, ",")


# index : combien d auteurs par publications?
revues_shs_auteur$nbAut <- NA

for(i in 1:length(revues_shs_auteur$AutList)){
  
  revues_shs_auteur$nbAut[[i]] <- length(revues_shs_auteur$AutList[[i]])
}

# format long : une ligne par collection

revues_shs_auteur <- revues_shs_auteur[rep(1:nrow(revues_shs_auteur), revues_shs_auteur$nbAut),]


# une collection par ligne par ordre de citation


revues_shs_auteur$ordre <- NA

revues_shs_auteur$ordre[1] <- 1

for(i in 2:length(revues_shs_auteur$ordre)){
  
  # si l'id hal est identique a la ligne precedente, ajouter 1 
  if(revues_shs_auteur$docid[i]==revues_shs_auteur$docid[i-1]){
    revues_shs_auteur$ordre[i] <- revues_shs_auteur$ordre[i-1]+1
  } else (revues_shs_auteur$ordre[i] <- 1)
  
}

# auteurs

revues_shs_auteur$Auteur <- NA

for(i in 1:length(revues_shs_auteur$ordre)){
  
  revues_shs_auteur$Auteur[i] <- revues_shs_auteur$AutList[[i]][revues_shs_auteur$ordre[i]]
  
}

view(revues_shs_auteur)

############################### auteurs actifs

aut_actif <- table(revues_shs_auteur$Auteur)
aut_actif_df <- data.frame(aut = names(aut_actif), frequentation = as.numeric(aut_actif))
top_aut <- aut_actif_df[order(aut_actif_df$frequentation, decreasing = TRUE), ]

top_13 <- head(top_aut, 13)
view(top_13)

ggplot(top_13, aes(x = reorder(aut, -frequentation), y = frequentation)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  labs(title = "Top 15 Authors by Frequency",
       x = "Author",
       y = "Frequency") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))



# Viz 2 - Réseau de collaboration -----------------------------------------


# 2. Analyse du réseau de collaborations des auteurs des revues SHS: Construction d'un réseau de collaborations entre auteurs, identification des groupes fréquemment actifs.
############# collaboration (igraph)

aut_collab <- revues_shs_auteur %>% select(docid,Auteur) %>%
  filter(Auteur %in% c("Christelle Hureau", "Didier Le Gall", "Francis Eustache","Gaël Chételat","Béatrice Desgranges", "Bruno Vincent","Christophe Jarry","François Osiurak","Josselin Baumard","Mathieu Lesourd","Mohamad El Haj","Peter Faller","Thierry Dantoine"))

aut_collab_graph <- graph_from_data_frame(aut_collab, directed = FALSE)

# Plot 1
plot(aut_collab_graph, main = "Collab d'auteurs",vertex.label.cex=0.7, vertex.label.color="black")

bipartite.mapping(aut_collab_graph)$res
V(aut_collab_graph)$type <- bipartite_mapping(aut_collab_graph)$type

# Plot 2
gg <- graph.data.frame(aut_collab,directed=FALSE)
plot(gg, vertex.color = "orange", edge.label=aut_collab$value, vertex.size=2, edge.color="orange", 
     vertex.label.font=1, edge.label.font =1, edge.label.cex = 1, 
     vertex.label.cex = 0.68,vertex.label.color="black")




# Viz 3 - Nuage de mots (titres) ------------------------------------------

  
  
# 3. Nuage de mots des titres des revues SHS : Création d'un nuage de mots basé sur les titres des publications pour visualiser les termes les plus fréquents.
# il y a quelques groupes plus actifs, mais le nombre de fois qu'ils ont travaillé ensemble est petit (2 fois)

library(wordcloud)
library(tm)
library(SnowballC)
library(RColorBrewer)

nuage <- data.frame(revues_shs_alzheimer)
nuage_corpus <- Corpus(VectorSource(revues_shs_alzheimer$title_s))


nuage_corpus_clean<-tm_map(nuage_corpus,tolower)
nuage_corpus_clean<-tm_map(nuage_corpus_clean,removeNumbers)
nuage_corpus_clean<-tm_map(nuage_corpus_clean,removeWords,stopwords("english"))
nuage_corpus_clean<-tm_map(nuage_corpus_clean,removeWords,stopwords("fr"))
nuage_corpus_clean<-tm_map(nuage_corpus_clean,removeWords,"alzheimer")
nuage_corpus_clean<-tm_map(nuage_corpus_clean,removePunctuation)
nuage_corpus_clean<-tm_map(nuage_corpus_clean,stripWhitespace)

wordcloud(nuage_corpus_clean,max.words = 100, min.freq =1, colors = brewer.pal(8, "Dark2"), rot.per=0.35)



# Viz 4 - Tendances de pubs -------------------------------------------------------


# Visualisations :

# 1. Analyse des tendances de publication au fil des années : Identification des tendances globales et par type de publication

# Chargement des bibliothèques nécessaires :
library(ggplot2)
library(dplyr)
library(viridis)

# Analyse des données :
# Nous allons tout d'abord calculer le nombre de publications pour chaque année et type de document
# Nous allons créer un tableau ou un data frame de résumé

tendances_publication <- dataset_shs_alzheimer %>%
  group_by(publicationDateY_i, docType_s) %>%
  summarise(count = n())
view(tendances_publication)


# Visualisation des données avec la palette de couleurs viridis, ligne plus épaisse et axes ajustés
ggplot(tendances_publication, aes(x = publicationDateY_i, y = count, color = docType_s)) +
  geom_line(size = 1) +  # Ajuster l'épaisseur de la ligne selon vos préférences
  scale_color_viridis_d() +
  labs(
    title = "Tendances des publications sur la maladie d'Alzheimer au fil des années",
    x = "Année de publication",
    y = "Nombre de publications",
    color = "Type de document"
  ) +
  theme_minimal() +
  scale_x_continuous(breaks = unique(tendances_publication$publicationDateY_i), labels = unique(tendances_publication$publicationDateY_i))


# Viz 5 - Répartition des types de pubs -----------------------------------



# Répartition des types de publications en camembert
ggplot(tendances_publication, aes(x = "", y = count, fill = docType_s)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar(theta = "y") +
  labs(
    title = "Répartition des types de publications sur la maladie d'Alzheimer",
    fill = "Type de document"
  ) +
  theme_minimal()

