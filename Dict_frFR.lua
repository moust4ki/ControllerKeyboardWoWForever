local _, CK = ...
CK.Dicts = CK.Dicts or {}

-- Mots français courants (langage oral / chat), classés approximativement
-- du plus fréquent au moins fréquent. Liste de départ écrite à la main :
-- tools/build_dict.py peut générer une liste plus complète (~12 000 mots).
CK.Dicts.frFR = [[
je de est pas le vous la tu que un il et à a ne les ce en on ça une ai pour des
moi qui nous mais y me dans du bien elle si tout plus non mon suis te au avec va
oui toi fait ils as être faire se sa comme était sur quoi ici sais rien peut où
êtes lui là dit veux bon ma ton cette peu vais mes merci ta faut aussi avez vas
sont avoir alors quand juste leur ses vraiment trop très pourquoi comment ont vu
dois deux aller viens allez sommes étais eu vie temps était encore voir chose
fais sans besoin dire jamais même après toujours avant peux crois autre personne
avais quelque maintenant beaucoup vois veut elles ces pense tous moins accord
parce peut-être faites entre chez sait mec sûr aime cela celui celle ceux vos
votre notre nos leurs fois jour jours nuit soir matin demain hier aujourd'hui
salut bonjour bonsoir coucou ok okay d'accord désolé pardon super cool génial
parfait top grave trop ouais nan bah ben euh hein ah oh ha haha bof bref voilà
voila enfin déjà jamais souvent parfois vite lentement tard tôt mieux pire
rien chose choses gens groupe monde tout toute toutes tous quelqu'un quelque
chaque plusieurs aucun aucune autres autre même mêmes tel telle
avoir eu avait avons avaient aurai auras aura aurons aurez auront aurais aurait
être été étais était étions étiez étaient serai seras sera serons serez seront
serais serait
faire fait fais faisait faisais ferai fera ferais ferait faites font
aller vais vas va allons allez vont allais allait irai ira irais irait allé
pouvoir peux peut pouvons pouvez peuvent pouvais pouvait pourrai pourra
pourrais pourrait pu
vouloir veux veut voulons voulez veulent voulais voulait voudrais voudrait
voulu
savoir sais sait savons savez savent savais savait saurai saura su
devoir dois doit devons devez doivent devais devait devrais devrait dû
venir viens vient venons venez viennent venais venait viendrai viendra venu
voir vois voit voyons voyez voient voyais voyait verrai verra vu
dire dis dit disons dites disent disais disait dirai dira
prendre prends prend prenons prenez prennent prenais prenait prendrai pris
mettre mets met mettons mettez mettent mis
donner donne donnes donnons donnez donnent donnais donné donnerai
trouver trouve trouves trouvons trouvez trouvent trouvé
parler parle parles parlons parlez parlent parlé
passer passe passes passons passez passent passé
penser pense penses pensons pensez pensent pensé
aimer aime aimes aimons aimez aiment aimé
croire crois croit croyons croyez croient cru
laisser laisse laisses laissez laissé
attendre attends attend attendez attendent attendu
chercher cherche cherches cherchons cherchez cherchent cherché
jouer joue joues jouons jouez jouent joué
rester reste restes restons restez restent resté
partir pars part partons partez partent parti
sortir sors sort sortons sortez sortent sorti
arriver arrive arrives arrivons arrivez arrivent arrivé
entrer entre entres entrez entré
rentrer rentre rentres rentré
revenir reviens revient revenez revenu
tenir tiens tient tenez tenu
comprendre comprends comprend comprenez compris
connaître connais connaît connaissez connu
regarder regarde regardes regardez regardé
écouter écoute écoutes écoutez écouté
demander demande demandes demandez demandé
répondre réponds répond répondez répondu
montrer montre montres montrez montré
essayer essaie essaye essaies essayez essayé
commencer commence commences commencez commencé
finir finis finit finissons finissez fini
aider aide aides aidez aidé
appeler appelle appelles appelez appelé
tuer tue tues tuez tué
mourir meurs meurt mort morte morts
vivre vis vit vivez vécu
écrire écris écrit écrivez
lire lis lit lisez lu
manger mange manges mangez mangé
boire bois boit buvez bu
dormir dors dort dormez dormi
acheter achète achètes achetez acheté
vendre vends vend vendez vendu
payer paye paie payes payez payé
gagner gagne gagnes gagnez gagné
perdre perds perd perdez perdu
changer change changes changez changé
oublier oublie oublies oubliez oublié
rappeler rappelle rappelles rappelez
retrouver retrouve retrouves retrouvé
suivre suis suit suivez suivi
tomber tombe tombes tombé
porter porte portes portez porté
ouvrir ouvre ouvres ouvrez ouvert
fermer ferme fermes fermez fermé
monter monte montes montez monté
descendre descends descend descendez descendu
courir cours court courez couru
marcher marche marches marchez marché
tourner tourne tournes tournez tourné
garder garde gardes gardez gardé
rejoindre rejoins rejoint rejoignez
inviter invite invites invitez invité
utiliser utilise utilises utilisez utilisé
envoyer envoie envoies envoyez envoyé
recevoir reçois reçoit recevez reçu
sentir sens sent sentez senti
préférer préfère préfères préférez préféré
expliquer explique expliques expliquez expliqué
arrêter arrête arrêtes arrêtez arrêté
continuer continue continues continuez continué
occuper occupe occupé occupée
bouger bouge bouges bougez bougé
battre bats bat battez battu
choisir choisis choisit choisissez choisi
réussir réussis réussit réussi
dépêcher dépêche dépêchez
excuser excuse excusez excusé
chose choses truc trucs machin affaire idée problème question réponse raison
fois moment heure heures minute minutes seconde secondes semaine semaines mois
an ans année années week-end lundi mardi mercredi jeudi vendredi samedi dimanche
homme femme enfant enfants fille fils garçon père mère frère sœur ami amie amis
copain copine pote potes famille mari
nom place endroit maison ville pays route chemin porte côté fin début milieu
tête main mains yeux œil cœur corps pied pieds bras dos
argent or prix
travail boulot école partie jeu jeux match équipe
vrai vraie faux fausse grand grande grands petit petite petits gros grosse bon
bonne bons bonnes mauvais mauvaise beau belle beaux nouveau nouvelle vieux
vieille jeune long longue court haut bas premier première dernier dernière
seul seule prêt prête facile difficile dur dure simple possible impossible
important importante content contente fatigué fatiguée malade libre
rapide lent lente fort forte faible nul nulle énorme incroyable drôle bizarre
fou folle sympa gentil gentille méchant méchante heureux heureuse triste
noir noire blanc blanche rouge bleu bleue vert verte jaune gris violet orange
un deux trois quatre cinq six sept huit neuf dix onze douze vingt trente cent
mille premier deuxième troisième
ici là-bas dehors dedans dessus dessous devant derrière loin près partout
ailleurs autour ensemble surtout seulement presque vraiment plutôt assez tant
tellement environ exactement absolument évidemment sûrement probablement
justement franchement
car donc puis ensuite pourtant cependant sinon lorsque puisque tandis comme
depuis pendant vers contre sous sans selon malgré jusqu'à jusque parmi
qu'est-ce quelle quel quels quelles lequel laquelle combien
c'est c'était j'ai j'étais je suis t'es t'as il y a n'est n'ai n'as qu'il qu'elle
qu'on s'il m'a t'a l'ai
vraiment ouf pfff mdr lol ptdr xd jsp jpp tkt stp svp slt bjr bsr cc dsl pk pq
bcp mtn tlm qqn qqch osef oklm wesh frère gars mecs meuf
merci mercii de rien bienvenue félicitations bravo gg bien joué bonne chance
bonne nuit bonne soirée bonne journée à plus a+ à tout à l'heure à demain
au revoir bisous
oui non peut-être évidemment carrément clairement
besoin envie peur faim soif mal
aide aider aidez-moi attendez attends minute stop go allez vas-y venez viens
regarde regarde-moi écoute dis-moi
suis-je es-tu est-il
vite doucement attention
mort vivant morts
parti partie partis
fini finie finis
prêt prêts
bon ben bah hé hey yo
]]
