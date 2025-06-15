:- dynamic(location/1).
:- dynamic(inventory/1).
:- dynamic(door_open/1).
:- dynamic(hacked/1).
:- dynamic(alarm/0).
:- dynamic(time_left/1).
:- dynamic(character/1).
:- dynamic(force_energy/1).
:- dynamic(stormtrooper_location/1).
:- dynamic(disguise_active/0).
:- dynamic(shuttle_prepared/0).
:- dynamic(lightsaber_active/0).
:- dynamic(stealth_mode/0).
:- dynamic(game_over_flag/0).
:- dynamic(elite_stormtroopers/0).
:- dynamic(has_schaltplan/0).
:- dynamic(forced_combat/0).

connected(zelle, korridor).
connected(korridor, waffenkammer).
connected(korridor, kommandozentrale).
connected(korridor, hangar).
connected(waffenkammer, korridor).
connected(kommandozentrale, korridor).
connected(hangar, shuttle).
connected(korridor, zelle).

force_power(ezra, tierkommunikation).
force_power(ezra, gedankentrick).
force_power(ahsoka, kampfmeditation).
force_power(ahsoka, voraussicht).
force_power(kanan, lichtschwert_meisterschaft).
force_power(kanan, macht_sprung).

start :-
    story_intro,
    character_selection,
    init_game,
    game_loop.

story_intro :-
    nl,
    write('************************************************'), nl,
    write('*    STAR WARS: ESCAPE FROM THE CHIMAERA      *'), nl,
    write('************************************************'), nl, nl,
    write('Die Macht ist stark in dir, aber die Gefahr ist real...'), nl, nl,
    write('Grossadmiral Thrawn hat dich in den Tiefen der'), nl,
    write('Imperialen Sternenzerstoerer Chimaera gefangen.'), nl,
    write('Doch der treue Droide Chopper schaffte es, die'), nl,
    write('Zellentuer zu sabotieren!'), nl, nl,
    write('MISSION: Entkomme lebend von diesem Schiff!'), nl,
    write('Zeit bis zum Hyperraumsprung: 25 Einheiten'), nl, nl.

character_selection :-
    write('Waehle deinen Jedi-Helden:'), nl,
    write('1. Ezra Bridger - Jung und impulsiv'), nl,
    write('2. Ahsoka Tano - Erfahren und weise'), nl,
    write('3. Kanan Jarrus - Meister und Mentor'), nl,
    read(Choice),
    select_character(Choice).

select_character(1) :-
    !,
    asserta(character(ezra)),
    asserta(force_energy(100)),
    write('>>> Ezra Bridger ausgewaehlt <<<'), nl, nl.
select_character(2) :-
    !,
    asserta(character(ahsoka)),
    asserta(force_energy(120)),
    write('>>> Ahsoka Tano ausgewaehlt <<<'), nl, nl.
select_character(3) :-
    !,
    asserta(character(kanan)),
    asserta(force_energy(110)),
    write('>>> Kanan Jarrus ausgewaehlt <<<'), nl, nl.
select_character(_) :-
    write('Ungueltiger Auswahl! Waehle 1, 2 oder 3.'), nl,
    character_selection.

init_game :-
    cleanup_game_state,
    asserta(location(zelle)),
    asserta(time_left(25)),
    asserta(force_energy(100)),
    asserta(stormtrooper_location(hangar)),
    place_items,
    nl,
    write('Du erwachst in einer kalten Gefangenenzelle...'), nl,
    write('Chopper surrt leise - er hat die Zellentuer entsichert!'), nl,
    examine(zelle).

cleanup_game_state :-
    retractall(location(_)),
    retractall(inventory(_)),
    retractall(door_open(_)),
    retractall(hacked(_)),
    retractall(alarm),
    retractall(time_left(_)),
    retractall(force_energy(_)),
    retractall(stormtrooper_location(_)),
    retractall(disguise_active),
    retractall(shuttle_prepared),
    retractall(lightsaber_active),
    retractall(stealth_mode),
    retractall(elite_stormtroopers),
    retractall(item_at(_, _)),
    retractall(game_over_flag),
    retractall(has_schaltplan),
    retractall(forced_combat).

place_items :-
    asserta(item_at(blaster, waffenkammer)),
    asserta(item_at(imperialer_anzug, waffenkammer)),
    asserta(item_at(granate, waffenkammer)),
    asserta(item_at(schaltplan, kommandozentrale)),
    asserta(item_at(energiezelle, kommandozentrale)).

game_won :-
    location(shuttle),
    shuttle_prepared.

game_loop :-
    (game_over_flag -> ! ; true),
    time_left(T),
    (T =< 0 ->
        zeit_abgelaufen
    ; (
        show_status,
        (forced_combat ->
            elite_combat 
        ; (
            write('> Was tust du? '),
            read(UserInput),
            handle_action(UserInput),
            (game_over_flag -> ! ;
             NewT is T - 1,
             retract(time_left(T)),
             asserta(time_left(NewT)),
             check_events,
             check_win_condition,
             game_loop)
        ))
    )).

game_won :-
    location(shuttle),
    shuttle_prepared.

check_win_condition :-
    game_won,
    display_winning_scene,
    asserta(game_over_flag),
    !.

check_win_condition.


show_status :-
    (location(Ort) -> true ; Ort = unbekannt),
    (time_left(Zeit) -> true ; Zeit = 0),
    nl,
    write('+-------------------------------------+'), nl,
    write('| ORT: '), write(Ort), 
    write('  |  ZEIT: '), write(Zeit),
    write('  |'), nl,
    write('+-------------------------------------+'), nl,
    location(AktuellerOrt),
    findall(Ausgang, connected(AktuellerOrt, Ausgang), Ausgaenge),
    (Ausgaenge = [] -> 
        write('Keine Ausgaenge verfuegbar.') ;
        (write('Ausgaenge: '), write(Ausgaenge))), nl,
    (alarm -> write('*** ALARM AKTIV! ***'), nl ; true),
    (disguise_active -> write('*** Verkleidung aktiv ***'), nl ; true),
    (stealth_mode -> write('*** Stealth-Modus ***'), nl ; true).

handle_action(gehe) :-
    location(Aktuell),
    findall(Ort, connected(Aktuell, Ort), Orte),
    write('Wohin moechtest du gehen?'), nl,
    write('Verfuegbare Ausgaenge: '), write(Orte), nl,
    read(Ziel),
    move(Ziel).
handle_action(schaue) :-
    location(Ort),
    examine(Ort).
handle_action(nimm) :-
    write('Was soll genommen werden? '),
    read(Gegenstand),
    take_item(Gegenstand).
handle_action(nutze) :-
    write('Was soll benutzt werden? '), nl,
    read(Objekt),
    use(Objekt).
handle_action(inventar) :-
    show_inventory.
handle_action(hilfe) :-
    show_help.
handle_action(beenden) :-
    write('Flucht abgebrochen. Das Spiel ist beendet.'), nl,
    asserta(game_over_flag),
    game_over('Du hast die Mission abgebrochen. Vielleicht hast du beim naechsten Mal mehr Erfolg.'),
    !.
handle_action(_) :-
    write('Unbekannter Befehl! Nutze "hilfe" fuer Befehle.'), nl.

move(Ziel) :-
    location(Aktuell),
    connected(Aktuell, Ziel),
    move_check(Ziel, Aktuell),
    !.
move(_) :-
    write('Du kannst nicht dorthin gehen.'), nl,
    !.

move_check(hangar, _) :-
    \+ (hacked(terminal), door_open(hangar)),
    !,
    write('Die Hangartuer ist verschlossen! Das Sicherheitssystem ist noch aktiv.'), nl,
    write('Du musst zuerst den Schaltplan finden und Chopper das Terminal hacken lassen.'), nl.
move_check(shuttle, _) :-
    elite_stormtroopers,
    !,
    write('Die Elite-Sturmtruppen blockieren den Weg zum Shuttle!'), nl,
    write('Du musst sie zuerst ausschalten. Eine normale Waffe reicht dafuer nicht.'), nl,
    write('Nur eine Granate koennte genug Schaden anrichten!'), nl.
move_check(Ziel, Aktuell) :-
    retract(location(Aktuell)),
    asserta(location(Ziel)),
    write('Du gehst zu: '), write(Ziel), nl,
    examine(Ziel),
    check_encounter.

can_move_to(hangar) :-
    hacked(terminal),
    door_open(hangar),
    !.
can_move_to(shuttle) :-
    location(hangar),
    \+ elite_stormtroopers,
    !.
can_move_to(Ort) :-
    Ort \= hangar,
    Ort \= shuttle.

check_encounter :-
    location(hangar),
    elite_stormtroopers,
    \+ forced_combat, 
    write('Die Elite-Sturmtruppen haben ihre schweren Blaster auf dich gerichtet!'), nl,
    write('Mit ihrer fortschrittlichen Ruestung wirken sie unbesiegbar...'), nl,
    asserta(forced_combat),
    elite_combat.

check_encounter :-
    location(hangar),
    stormtrooper_location(hangar),
    \+ disguise_active,
    \+ stealth_mode,
    write('Ein Sturmtruppler-Squad entdeckt dich im Hangar!'), nl,
    hangar_combat.

check_encounter :-
    location(Ort),
    stormtrooper_location(Ort),
    Ort \= hangar,
    \+ disguise_active,
    \+ stealth_mode,
    write('Ein Sturmtruppler entdeckt dich!'), nl,
    (inventory(blaster) ->
        (write('Du ziehst deinen Blaster! Kampf!'), nl,
         combat_encounter)
    ;   (write('Du wirst gefangen genommen!'), nl,
         asserta(game_over_flag),
         game_over('Du wurdest ohne Waffe von Sturmtrupplern entdeckt! Ohne Blaster oder Macht-Nutzung warst du hilflos.'))).
check_encounter.


combat_encounter :-
    force_energy(FE),
    (FE > 30 ->
        (write('Du nutzt die Macht im Kampf!'), nl,
         NewFE is FE - 30,
         retractall(force_energy(_)),
         asserta(force_energy(NewFE)),
         write('Sturmtruppler besiegt!'), nl,
         retractall(stormtrooper_location(_)))
    ;   (write('Nicht genug Macht-Energie!'), nl,
         write('Du wirst ueberwaeltigt!'), nl,
         asserta(game_over_flag),
         game_over('Deine Macht-Energie war zu schwach! Ohne ausreichende Macht-Energie bist du gegen die Sturmtruppen chancenlos.'))).

hangar_combat :-
    write('Die Sturmtruppler haben ihre Blaster auf dich gerichtet!'), nl,
    write('Was tust du?'), nl,
    write('1. Macht einsetzen'), nl,
    write('2. Blaster benutzen'), nl,
    write('3. Fluchtversuch'), nl,
    read(Choice),
    hangar_combat_action(Choice).

hangar_combat_action(1) :-
    force_energy(FE),
    FE > 40,
    character(Char),
    NewFE is FE - 40,
    retract(force_energy(FE)),
    asserta(force_energy(NewFE)),
    write('Du setzt die Macht im Hangar ein!'), nl,
    hangar_force_message(Char),
    retractall(stormtrooper_location(hangar)),
    write('ALARM! Ein roter Alarm geht los!'), nl,
    write('*WOMPF* *WOMPF* Die Hangartuer oeffnet sich und schwer bewaffnete'), nl,
    write('Elite-Sturmtruppen in glaenzender Ruestung stuermen herein!'), nl,
    write('Sie positionieren sich schnell und blockieren den Weg zum Shuttle.'), nl,
    write('Ihre Ruestung schimmert seltsam - sie scheint gegen Macht-Angriffe geschuetzt zu sein!'), nl,
    write('Es sieht aus, als muesstest du sie in einem Kampf besiegen...'), nl,
    asserta(elite_stormtroopers),
    asserta(forced_combat),
    elite_combat, !.

hangar_combat_action(1) :-
    write('Nicht genug Macht-Energie!'), nl,
    write('Du wirst ueberwaeltigt!'), nl,
    asserta(game_over_flag),
    game_over('Deine Macht-Energie war zu schwach! Du konntest dich nicht gegen die Sturmtruppen durchsetzen.'), 
    !.


hangar_combat_action(2) :-
    inventory(blaster),
    !,
    write('Du ziehst deinen Blaster und feuerst auf die Sturmtruppler!'), nl,
    write('Aber ihre Ruestung ist zu stark! Deine Schuesse haben keine Wirkung!'), nl,
    write('Sie erwidern das Feuer und treffen dich...'), nl,
    asserta(game_over_flag),
    game_over('Ein Blaster gegen Sturmtruppen im Hangar? Ihr Ausbildungshandbuch besagt: "Bei Jedi im Hangar: Immer auf Verstaerkung warten!"').
hangar_combat_action(2) :-
    write('Du hast keinen Blaster!'), nl,
    write('Die Sturmtruppler schiessen dich sofort nieder.'), nl,
    asserta(game_over_flag),
    game_over('Ohne Waffe gegen bewaffnete Sturmtruppen? Das konnte nicht gut gehen. Ein Jedi braucht die Macht als Verbuendeten!').

hangar_combat_action(3) :-
    write('Du versuchst zu fliehen...'), nl,
    (time_left(T), T mod 2 =:= 0 ->
        (write('Mit einem beherzten Sprung schaffst du es hinter eine Kiste!'), nl,
         write('Von dort aus gelingt dir die Flucht zurueck zum Korridor.'), nl,
         retractall(location(_)),
         asserta(location(korridor)))
    ;   (write('Die Sturmtruppler sind zu schnell! Sie schneiden dir den Weg ab!'), nl,
         write('Du wirst ueberwaeltigt und gefangen genommen.'), nl,
         asserta(game_over_flag),
         game_over('Flucht ist nicht immer die Antwort. Die Sturmtruppen waren zu schnell und haben dich festgenommen. Thrawn wird erfreut sein.'))).
         
hangar_combat_action(_) :-
    write('Ungueltige Aktion! Die Sturmtruppler nutzen dein Zoegern und nehmen dich fest.'), nl,
    asserta(game_over_flag),
    game_over('In der Hitze des Gefechts hast du eine falsche Entscheidung getroffen. Das imperiale Gefaengnis wartet auf dich.').

hangar_force_message(ezra) :-
    write('Ezra konzentriert sich und nutzt seine Tierkommunikation...'), nl,
    write('Plotzlich hoert man ein ohrenbetaeubendes Gebruell aus den Lueftungsschaechten!'), nl,
    write('Die Sturmtruppler geraten in Panik: "Was war das?! Ein Weltraum-Rancor?!"'), nl,
    write('In ihrer Verwirrung prallen sie gegeneinander und gehen zu Boden!'), nl.

hangar_force_message(ahsoka) :-
    write('Ahsoka hebt beide Haende und ihre Augen leuchten auf...'), nl,
    write('Mit ihrer Kampfmeditation verlangsamt sie die Zeit um sich herum!'), nl,
    write('Die Blasterschuesse der Sturmtruppler bewegen sich wie in Zeitlupe,'), nl,
    write('waehrend sie elegant zwischen ihnen hindurch tanzt und sie ausschaltet!'), nl.

hangar_force_message(kanan) :-
    write('Kanan aktiviert sein Lichtschwert mit einem kraftvollen *WUMM*!'), nl,
    write('Mit seinem Macht-Sprung fliegt er ueber die Sturmtruppler hinweg'), nl,
    write('und landet elegant hinter ihnen. Bevor sie reagieren koennen,'), nl,
    write('nutzt er einen maechtigen Macht-Stoss um sie zu Boden zu werfen!'), nl.

examine(zelle) :-
    write('Eine duestere Gefangenenzelle. Die Tuer steht offen.'), nl.
examine(korridor) :-
    write('Ein langer Korridor mit metallischen Waenden.'), nl,
    write('Gaenge fuehren zur Waffenkammer, Kommandozentrale und zum Hangar.'), nl,
    (stormtrooper_location(korridor) ->
        write('Du hoerst entfernte Schritte von Sturmtrupplern...') ; 
        write('Der Korridor ist ruhig.')), nl.
examine(waffenkammer) :-
    write('Waffen und eine imperiale Uniform haengen an den Waenden.'), nl,
    list_items_here(waffenkammer).
examine(kommandozentrale) :-
    write('Blinkende Monitore und Schalttafeln.'), nl,
    (hacked(terminal) ->
        write('Das Terminal ist gehackt - die Hangartuer ist offen!') ; 
        (inventory(schaltplan) ->
            write('Chopper kann jetzt das Sicherheitssystem hacken - nutze "chopper"!') ;
            write('Du brauchst den Schaltplan, damit Chopper das System hacken kann.'))), nl,
    list_items_here(kommandozentrale).
examine(hangar) :-
    write('Ein riesiger Hangar mit imperialen Shuttles.'), nl,
    (elite_stormtroopers ->
        write('Schwer bewaffnete Elite-Sturmtruppen blockieren den Weg zum Shuttle!'), nl,
        write('Diese Spezialeinheit traegt schusssichere Ruestung und ist gegen die Macht resistent.'), nl,
        write('Sie beobachten dich mit erhobenen Waffen - bereit zum Angriff.') ;
        (stormtrooper_location(hangar) ->
            (disguise_active -> 
                write('Sturmtruppler sind hier, ignorieren dich aber dank deiner Verkleidung.') ;
                write('Sturmtruppler patrouillieren den Bereich - sei vorsichtig!'))
            ;
            write('Der Hangar ist leer.'))), nl,
    (shuttle_prepared ->
        write('Dein Shuttle ist startbereit!') ;
        write('Du musst ein Shuttle fuer die Flucht vorbereiten.')), nl.
examine(shuttle) :-
    write('Im Inneren des Shuttles - deine Rettung!'), nl,
    (shuttle_prepared ->
        write('Alle Systeme online. Bereit zum Start!') ;
        write('Das Shuttle braucht eine Energiezelle!')), nl.

use(chopper) :-
    location(kommandozentrale),
    inventory(schaltplan),
    \+ hacked(terminal),
    write('Chopper analysiert den Schaltplan...'), nl,
    write('*BEEP BOOP BEEP* Sicherheitsprotokolle identifiziert!'), nl,
    write('Chopper beginnt mit dem Hack des Hauptterminals...'), nl,
    write('*WHIRR CLICK BEEP* Zugriff erhalten!'), nl,
    asserta(hacked(terminal)),
    asserta(door_open(hangar)),
    write('SUCCESS! Das Sicherheitssystem ist deaktiviert!'), nl,
    write('Die Hangartuer ist jetzt geoeffnet!'), nl.
    
use(chopper) :-
    location(kommandozentrale),
    \+ inventory(schaltplan),
    write('Chopper versucht das Terminal zu hacken...'), nl,
    write('*BEEP BOOP* ERROR! ERROR!'), nl,
    write('Chopper kann das komplexe Sicherheitssystem nicht ohne'), nl,
    write('den entsprechenden Schaltplan knacken!'), nl,
    write('Du musst zuerst den Schaltplan hier in der Kommandozentrale finden.'), nl.

use(chopper) :-
    location(kommandozentrale),
    hacked(terminal),
    write('Chopper hat das System bereits erfolgreich gehackt!'), nl,
    write('Die Hangartuer ist offen.'), nl.

use(chopper) :-
    \+ location(kommandozentrale),
    write('Chopper kann nur in der Kommandozentrale hacken.'), nl,
    write('Dort befindet sich das Hauptterminal.'), nl.

use(macht) :-
    location(hangar),
    elite_stormtroopers,
    write('Du versuchst, die Macht gegen die Elite-Sturmtruppen einzusetzen...'), nl,
    write('Aber ihre schwere Ruestung und spezielle Ausbildung machen sie resistent!'), nl,
    write('Du brauchst eine staerkere Waffe - eine Granate koennte funktionieren!'), nl,
    !.

use(macht) :-
    character(ezra),
    force_energy(FE),
    FE > 20,
    NewFE is FE - 20,
    retractall(force_energy(_)),
    asserta(force_energy(NewFE)),
    (location(korridor), stormtrooper_location(korridor) ->
        (write('Du nutzt einen Gedankentrick!'), nl,
         write('"Das ist nicht der Jedi, den ihr sucht..."'), nl,
         retractall(stormtrooper_location(_)),
         asserta(stormtrooper_location(waffenkammer))) ;
        (write('Du spuerst die Macht um dich herum...'), nl,
         asserta(stealth_mode),
         write('Stealth-Modus aktiviert! Du bewegst dich lautlos.'), nl)).

use(macht) :-
    character(ahsoka),
    force_energy(FE),
    FE > 15,
    NewFE is FE - 15,
    retractall(force_energy(_)),
    asserta(force_energy(NewFE)),
    write('Du meditierst und spuerst die Umgebung...'), nl,
    (stormtrooper_location(Ort) ->
        (write('Du spuerst einen Sturmtruppler in: '), write(Ort), nl) ;
        write('Keine Feinde in der Naehe.')), nl.

use(macht) :-
    character(kanan),
    force_energy(FE),
    FE > 25,
    NewFE is FE - 25,
    retractall(force_energy(_)),
    asserta(force_energy(NewFE)),
    (lightsaber_active ->
        write('Du deaktivierst dein Lichtschwert.'), nl,
        retractall(lightsaber_active) ;
        (write('*WUMM* Dein Lichtschwert erwacht zum Leben!'), nl,
         asserta(lightsaber_active))).



use(blaster) :-
    inventory(blaster),
    location(hangar),
    elite_stormtroopers,
    write('Du ziehst deinen Blaster und feuerst auf die Elite-Sturmtruppen!'), nl,
    write('Die Laserschuesse prallen wirkungslos von ihrer Panzerung ab!'), nl,
    write('Sie bewegen sich langsam auf dich zu - du brauchst eine staerkere Waffe!'), nl,
    write('Eine Granate koennte genug Schaden anrichten...'), nl,
    !.

use(blaster) :-
    inventory(blaster),
    stormtrooper_location(Ort),
    location(Ort),
    write('Du ziehst deinen Blaster!'), nl,
    write('PEW PEW! Sturmtruppler ausgeschaltet!'), nl,
    retractall(stormtrooper_location(_)).

use(imperialer_anzug) :-
    inventory(imperialer_anzug),
    \+ disguise_active,
    asserta(disguise_active),
    write('Du schluepfst in die imperiale Uniform.'), nl,
    write('Perfekte Tarnung! Sturmtruppler ignorieren dich.'), nl.

use(energiezelle) :-
    inventory(energiezelle),
    location(shuttle),
    \+ shuttle_prepared,
    asserta(shuttle_prepared),
    write('Du installierst die Energiezelle im Shuttle.'), nl,
    write('Triebwerke online! Das Shuttle ist startklar!'), nl.

use(granate) :-
    inventory(granate),
    location(hangar),
    elite_stormtroopers,
    write('Du greifst nach der Granate, aber die Elite-Sturmtruppen haben dich bereits im Visier!'), nl,
    write('Du solltest im Kampf den Ueberraschungsmoment nutzen!'), nl,
    elite_combat.

use(granate) :-
    inventory(granate),
    \+ elite_stormtroopers,
    write('Es gibt hier kein geeignetes Ziel fuer die Granate.'), nl.

use(granate) :-
    \+ inventory(granate),
    write('Du hast keine Granate!'), nl.

use(_) :-
    write('Das funktioniert hier nicht.'), nl.


zeit_abgelaufen :-
    write('*** ZEIT IST UM! ***'), nl,
    write('Ein ohrenbetaeubender Alarm ertoent durch das Schiff!'), nl,
    write('"HYPERRAUMSPRUNG IN 3... 2... 1..."'), nl,
    write('Grossadmiral Thrawn: "Ihr bleibt mein Ehrengast."'), nl,
    asserta(game_over_flag),
    game_over('Die Zeit ist abgelaufen! Der Sternenzerstoerer ist in den Hyperraum gesprungen und du bleibst Thrawn\'s Gefangener fuer die kommenden Verhoere.'), !.

take_item(Gegenstand) :-
    location(Ort),
    item_at(Gegenstand, Ort),
    \+ inventory(Gegenstand),
    retractall(item_at(Gegenstand, Ort)),
    asserta(inventory(Gegenstand)),
    (Gegenstand = schaltplan -> 
        (write('WICHTIG: Du hast den Schaltplan gefunden!'), nl,
         write('Chopper kann jetzt das Sicherheitssystem hacken.'), nl) 
    ; true),
    write('Genommen: '), write(Gegenstand), nl.
take_item(Gegenstand) :-
    inventory(Gegenstand),
    write('Du hast das bereits!'), nl.
take_item(_) :-
    write('Das gibt es hier nicht.'), nl.

show_inventory :-
    findall(Item, inventory(Item), Items),
    (Items = [] ->
        write('Dein Inventar ist leer.') ;
        (write('Inventar: '), write(Items))), nl,
    (inventory(schaltplan) ->
        write('*** SCHALTPLAN VERFUEGBAR - Chopper kann hacken! ***'), nl ;
        true).

list_items_here(Ort) :-
    findall(Item, item_at(Item, Ort), Items),
    (Items = [] ->
        true ;
        (write('Hier liegen: '), write(Items), nl)).

check_events :-
    time_left(T),
    (T =< 5 ->
        (alarm, write('*** WARNUNG: Hyperraumsprung in '), write(T), 
         write(' Einheiten! ***'), nl) ;
        true),
    (T =< 8, \+ alarm ->
        (asserta(alarm),
         write('ALARM! Deine Flucht wurde bemerkt!'), nl) ;
        true).

show_help :-
    nl,
    write('=== BEFEHLE ==='), nl,
    write('gehe           - Bewege dich'), nl,
    write('schaue         - Untersuche aktuellen Ort'), nl,
    write('nimm           - Gegenstand aufheben'), nl,
    write('nutze          - Objekt/Faehigkeit verwenden'), nl,    write('inventar       - Zeige Inventar'), nl,
    write('hilfe          - Diese Hilfe'), nl,
    write('beenden        - Spiel verlassen'), nl,
    nl,
    write('=== KAMPF-TIPPS ==='), nl,
    write('* Gegen normale Sturmtruppen: Nutze die Macht oder einen Blaster'), nl,
    write('* Gegen Elite-Truppen: Nur Granaten sind effektiv!'), nl,
    write('* Tarnung kann Kaempfe komplett vermeiden'), nl,
    nl,
    write('=== WICHTIGER HINWEIS ==='), nl,
    write('Der Hangar ist nur zugaenglich, nachdem Chopper'), nl,
    write('das Sicherheitssystem mit dem Schaltplan gehackt hat!'), nl.

game_over :-
    game_over('Du bist gescheitert!').

game_over(Grund) :-
    nl,
    write('================================================'), nl,
    write('              === GAME OVER ===                  '), nl,
    write('================================================'), nl,
    nl,
    write(Grund), nl,
    nl,
    write('Was moechtest du tun?'), nl,
    write('1. Spiel neu starten'), nl,
    write('2. Spiel beenden'), nl,
    read(Wahl),
    handle_game_over(Wahl).

handle_game_over(1) :-
    write('Neustart...'), nl,
    !, start.

handle_game_over(2) :-
    write('Auf Wiedersehen!'), nl,
    halt.

handle_game_over(_) :-
    write('Ungueltige Eingabe! Bitte 1 oder 2 waehlen:'), nl,
    read(NeueWahl),
    handle_game_over(NeueWahl).

elite_combat :-
    write('Die Elite-Sturmtrupper umzingeln dich mit ihren schweren Waffen!'), nl,
    write('Was tust du?'), nl,
    write('1. Macht einsetzen'), nl,
    write('2. Blaster benutzen'), nl,
    write('3. Fluchtversuch'), nl, 
    write('4. Granate werfen'), nl,
    read(Choice),
    elite_combat_action(Choice).

elite_combat_action(1) :-
    write('Du konzentrierst dich und versuchst, die Macht einzusetzen...'), nl,
    write('Doch die Elitetruppen tragen spezielle Ausruestung, die sie gegen Machtangriffe schuetzt.'), nl,
    write('Ihre modifizierten Helme blockieren die Gedankentricks!'), nl,
    write('Sie feuern ihre schweren Repetierblasergewehre auf dich...'), nl,
    write('Du wirst niedergestreckt!'), nl,
    asserta(game_over_flag),
    game_over('Die Elite-Sturmtruppen waren immun gegen deine Macht-Faehigkeiten! Die speziell entwickelten Ruestungen wurden von Thrawn persoenlich entworfen, um gegen Jedi wirksam zu sein.'),
    !.

elite_combat_action(2) :-
    (inventory(blaster) ->
        (write('Du ziehst deinen Blaster und feuerst auf die Elitetruppen!'), nl,
        write('Die Laserstrahlen prallen wirkungslos an ihrer verstaerkten Ruestung ab!'), nl,
        write('"Typischer Rebellenabschaum. Diese primitiven Waffen sind nutzlos gegen uns!"'), nl,
        write('Sie erwidern das Feuer und treffen dich mehrfach...'), nl,
        asserta(game_over_flag),
        game_over('Dein Blaster war gegen die Ruestung der Elite-Sturmtruppen nutzlos. Die Imperiale Garde ist mit Phasenpanzerung ausgestattet, die einfache Energiewaffen abwehrt!')) ;
        (write('Du hast keinen Blaster!'), nl,
        write('Die Elite-Sturmtruppen feuern ihre schweren Waffen auf dich ab!'), nl,
        asserta(game_over_flag),
        game_over('Ohne Waffe gegen Elite-Sturmtruppen? Ein toedlicher Fehler! Haettest du doch nur eine Granate dabei gehabt...'))),
    !.

elite_combat_action(3) :-
    write('Du versuchst zu fliehen, aber die Elitetruppen haben den Hangar abgeriegelt!'), nl,
    write('Ihre Reaktionsgeschwindigkeit ist beeindruckend - schnell haben sie dich umzingelt.'), nl,
    write('Es gibt kein Entkommen!'), nl,
    write('Du wirst festgenommen und Thrawn persoenlich vorgefuehrt...'), nl,
    asserta(game_over_flag),
    game_over('Flucht ist keine Option gegen Elite-Sturmtruppen! Thrawn wird dich nun persoenlich verhoeren und deine Jedi-Geheimnisse entlocken.'),
    !.

elite_combat_action(4) :-
    inventory(granate),
    !,
    retractall(elite_stormtroopers),
    retractall(inventory(granate)),
    retractall(forced_combat),
    write('Du ziehst schnell die Granate heraus und wirfst sie mitten in die Gruppe!'), nl,
    write('BOOM! Eine gewaltige Explosion erschuettert den Hangar.'), nl,
    write('Als der Rauch sich lichtet, ist kein Sturmtruppler mehr zu sehen.'), nl,
    write('Teile ihrer weissen Ruestung liegen verstreut auf dem Boden.'), nl,
    write('Der Weg zum Shuttle ist nun frei!'), nl.

elite_combat_action(4) :-
    write('Du greifst nach einer Granate, aber du besitzt keine!'), nl,
    write('Die Elite-Sturmtruppen nutzen deine Verwirrung und nehmen dich gefangen!'), nl,
    asserta(game_over_flag),
    game_over('Eine gute Idee - aber ohne Granate! Haettest du doch nur vorher die Waffenkammer besucht und dich besser ausgeruestet...'),
    !.

elite_combat_action(_) :-
    write('Ungueltige Aktion! Die Elite-Sturmtruppen nutzen dein Zoegern aus.'), nl,
    write('Ihre Praezisionsschuesse treffen dich von allen Seiten!'), nl,
    asserta(game_over_flag),
    game_over('In der Hitze des Gefechts hast du gezoegert - ein fataler Fehler! Elite-Sturmtruppen sind darauf trainiert, solche Momente auszunutzen.').



display_winning_scene :-
    nl, nl,
    write('*** DU HAST GEWONNEN! ***'), nl, nl,

    write('           _____        '), nl,
    write('         _|_____]       '), nl,
    write('        |        |      '), nl,
    write('        |  ___   |      '), nl,
    write('       _|_|___|__|      '), nl,
    write('      |  CHOPPER |      '), nl,
    write('      |__________|      '), nl,
    write('      /  o  o  o \\      '), nl,
    write('     (===========)      '), nl,
    write('      ) *BEEP!* (       '), nl,
    write('     /___________\\      '), nl,
    write('      /         \\       '), nl,
    write('     /|   ___   |\\      '), nl,
    write('      |   | |   |       '), nl,
    write('      |___|_|___|       '), nl, nl,
    
    write('   *FROEHLICHES BEEP BEEP*   '), nl, nl,
    
    write('================================================'), nl,
    write('                SIEG!                    '), nl,
    write('================================================'), nl,
    nl,

    character(Char),
    winning_message(Char),
    
    nl, nl,
    write('Was moechtest du tun?'), nl,
    write('1. Erneut spielen'), nl,
    write('2. Spiel beenden'), nl,
    read(Wahl),
    handle_winning_choice(Wahl).

winning_message(ezra) :-
    write('Ezra Bridger schiesst das Shuttle durch den Hyperraum!'), nl,
    write('Seine Gefangenschaft war nur von kurzer Dauer.'), nl,
    write('Thrawn wird wutentbrannt sein, aber Ezras Instinkte'), nl,
    write('und seine starke Bindung zur Macht haben ihn gerettet.'), nl,
    write('Die Crew des Ghost wird stolz auf ihn sein!').
    
winning_message(ahsoka) :-
    write('Mit der Gelassenheit einer wahren Jedi-Meisterin steuert'), nl,
    write('Ahsoka Tano das gestohlene Shuttle durch den Hyperraum.'), nl,
    write('Ihre Weisheit und Erfahrung haben sie erneut gerettet.'), nl,
    write('Niemand haelt die ehemalige Padawan von Anakin Skywalker'), nl,
    write('fuer lange gefangen! Der Kampf gegen das Imperium geht weiter.').

winning_message(kanan) :-
    write('Kanan Jarrus lehnt sich zurueck und atmet erleichtert aus.'), nl,
    write('Der blinde Jedi-Ritter hat sich einmal mehr auf die Macht verlassen,'), nl,
    write('und sie hat ihn nicht im Stich gelassen. Nun kann er zu Hera'), nl,
    write('und den anderen zurueckkehren. Die Rebellenzelle auf Lothal'), nl,
    write('braucht ihren Anfuehrer - und ihren Glauben an die Macht.').

handle_winning_choice(1) :-
    write('Starte neues Spiel...'), nl,
    !, start.

handle_winning_choice(2) :-
    write('Moege die Macht mit dir sein, Jedi!'), nl,
    halt.

handle_winning_choice(_) :-
    write('Ungueltige Eingabe! Bitte 1 oder 2 waehlen:'), nl,
    read(NeueWahl),
    handle_winning_choice(NeueWahl).