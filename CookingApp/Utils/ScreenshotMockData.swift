#if DEBUG
import Foundation

// MARK: - Mock recipes for Fastlane screenshots
// These are only compiled in DEBUG builds and only activate when --screenshots is passed.

extension Recipe {

    // MARK: Pasta (shown on Home + Shopping List tabs)
    static let screenshotMock: Recipe = decodeRecipe("""
    {
        "id": null,
        "title": "Creamy Garlic Pasta",
        "description": "A rich and creamy garlic pasta with Parmesan, perfect for a weeknight dinner.",
        "descriptionNl": "Een rijke en romige knoflookpasta met Parmezaan, perfect voor een doordeweekse avond.",
        "descriptionFr": "Des pâtes crémeuses à l'ail avec du parmesan, parfaites pour un dîner en semaine.",
        "descriptionDe": "Cremige Knoblauchpasta mit Parmesan – ideal für einen Wochentagabend.",
        "descriptionIt": "Pasta cremosa all'aglio con parmigiano, perfetta per una cena infrasettimanale.",
        "ingredients": [
            {"name": "Spaghetti",      "amount": "400", "unit": "g"},
            {"name": "Heavy cream",    "amount": "200", "unit": "ml"},
            {"name": "Garlic cloves",  "amount": "4",   "unit": ""},
            {"name": "Parmesan",       "amount": "80",  "unit": "g"},
            {"name": "Butter",         "amount": "30",  "unit": "g"},
            {"name": "Fresh parsley",  "amount": "1",   "unit": "bunch"},
            {"name": "Black pepper",   "amount": "1",   "unit": "tsp"}
        ],
        "ingredientNamesNl": ["Spaghetti","Slagroom","Knoflookteentjes","Parmezaan","Boter","Verse peterselie","Zwarte peper"],
        "ingredientNamesFr": ["Spaghetti","Crème fraîche","Gousses d'ail","Parmesan","Beurre","Persil frais","Poivre noir"],
        "ingredientNamesDe": ["Spaghetti","Sahne","Knoblauchzehen","Parmesan","Butter","Frische Petersilie","Schwarzer Pfeffer"],
        "ingredientNamesIt": ["Spaghetti","Panna fresca","Spicchi d'aglio","Parmigiano","Burro","Prezzemolo fresco","Pepe nero"],
        "steps": [
            "Boil pasta in salted water until al dente. Reserve ½ cup pasta water before draining.",
            "Finely mince the garlic cloves.",
            "Melt butter in a large pan over medium heat. Sauté garlic for 1–2 minutes until fragrant.",
            "Pour in cream and simmer gently for 3 minutes until slightly thickened.",
            "Add drained pasta and toss well, adding pasta water as needed to loosen the sauce.",
            "Stir in Parmesan. Season with salt and pepper. Top with chopped parsley and serve."
        ],
        "stepsNl": [
            "Kook de pasta in gezouten water al dente. Bewaar een half kopje kookwater.",
            "Hak de knoflook fijn.",
            "Smelt boter op middelhoog vuur. Bak de knoflook 1–2 minuten tot hij geurig is.",
            "Voeg de slagroom toe en laat 3 minuten zachtjes sudderen.",
            "Voeg de pasta toe en meng goed. Voeg kookwater toe indien nodig.",
            "Roer de Parmezaan erdoor. Breng op smaak. Garneer met peterselie en serveer."
        ],
        "stepsFr": [
            "Cuire les pâtes al dente dans de l'eau salée. Réserver ½ tasse d'eau de cuisson.",
            "Hacher finement l'ail.",
            "Faire fondre le beurre à feu moyen. Faire revenir l'ail 1–2 minutes.",
            "Verser la crème et laisser mijoter 3 minutes.",
            "Ajouter les pâtes et bien mélanger. Allonger avec l'eau de cuisson si besoin.",
            "Incorporer le parmesan. Assaisonner. Garnir de persil haché et servir."
        ],
        "stepsDe": [
            "Nudeln in Salzwasser al dente kochen. ½ Tasse Nudelwasser aufbewahren.",
            "Knoblauch fein hacken.",
            "Butter bei mittlerer Hitze schmelzen. Knoblauch 1–2 Minuten anschwitzen.",
            "Sahne einrühren und 3 Minuten köcheln lassen.",
            "Pasta dazugeben und gut vermengen. Bei Bedarf Nudelwasser hinzufügen.",
            "Parmesan unterrühren. Abschmecken. Mit Petersilie garnieren und servieren."
        ],
        "stepsIt": [
            "Cuocere la pasta al dente in acqua salata. Conservare ½ tazza di acqua di cottura.",
            "Tritare finemente l'aglio.",
            "Sciogliere il burro a fuoco medio. Soffriggere l'aglio per 1–2 minuti.",
            "Aggiungere la panna e cuocere 3 minuti a fuoco basso.",
            "Aggiungere la pasta e amalgamare bene. Allungare con acqua di cottura se necessario.",
            "Incorporare il parmigiano. Aggiustare di sale. Guarnire con prezzemolo e servire."
        ],
        "dietaryTags": ["vegetarian"],
        "allergenFree": ["nuts", "shellfish", "fish", "soy", "sesame"],
        "prepTime": 10,
        "cookTime": 20,
        "imageURL": null,
        "servings": 4,
        "difficulty": "easy"
    }
    """)

    // MARK: Salad (shown in Favourites list)
    static let screenshotMockSalad: Recipe = decodeRecipe("""
    {
        "id": null,
        "title": "Mediterranean Salad",
        "description": "A fresh and vibrant salad with crisp vegetables, Kalamata olives, and creamy feta.",
        "descriptionNl": "Een frisse en levendige salade met knapperige groenten, Kalamata-olijven en romige feta.",
        "descriptionFr": "Une salade fraîche et colorée avec des légumes croquants, des olives et de la feta.",
        "descriptionDe": "Ein frischer Salat mit knackigem Gemüse, Kalamata-Oliven und cremigem Feta.",
        "descriptionIt": "Un'insalata fresca e colorata con verdure croccanti, olive Kalamata e feta cremosa.",
        "ingredients": [
            {"name": "Cherry tomatoes", "amount": "250", "unit": "g"},
            {"name": "Cucumber",        "amount": "1",   "unit": ""},
            {"name": "Red onion",       "amount": "½",   "unit": ""},
            {"name": "Kalamata olives", "amount": "80",  "unit": "g"},
            {"name": "Feta cheese",     "amount": "150", "unit": "g"},
            {"name": "Olive oil",       "amount": "3",   "unit": "tbsp"},
            {"name": "Lemon juice",     "amount": "2",   "unit": "tbsp"}
        ],
        "ingredientNamesNl": ["Cherrytomaatjes","Komkommer","Rode ui","Kalamata-olijven","Fetakaas","Olijfolie","Citroensap"],
        "ingredientNamesFr": ["Tomates cerises","Concombre","Oignon rouge","Olives Kalamata","Feta","Huile d'olive","Jus de citron"],
        "ingredientNamesDe": ["Kirschtomaten","Gurke","Rote Zwiebel","Kalamata-Oliven","Feta","Olivenöl","Zitronensaft"],
        "ingredientNamesIt": ["Pomodorini","Cetriolo","Cipolla rossa","Olive Kalamata","Feta","Olio d'oliva","Succo di limone"],
        "steps": [
            "Halve the cherry tomatoes. Dice the cucumber into bite-sized chunks.",
            "Thinly slice the red onion.",
            "Combine tomatoes, cucumber, onion, and olives in a large bowl.",
            "Crumble feta cheese over the top.",
            "Whisk together olive oil and lemon juice, season with salt and pepper.",
            "Drizzle dressing over the salad and serve immediately."
        ],
        "stepsNl": [
            "Halveer de tomaatjes. Snijd de komkommer in hapklare stukken.",
            "Snijd de rode ui in dunne ringen.",
            "Meng tomaten, komkommer, ui en olijven in een grote kom.",
            "Verkruimel de fetakaas erover.",
            "Klop olijfolie en citroensap samen, breng op smaak.",
            "Besprenkel met dressing en serveer meteen."
        ],
        "stepsFr": [
            "Couper les tomates en deux. Couper le concombre en morceaux.",
            "Émincer finement l'oignon rouge.",
            "Mélanger les tomates, concombre, oignon et olives dans un saladier.",
            "Émietter la feta par-dessus.",
            "Fouetter l'huile d'olive et le jus de citron, assaisonner.",
            "Arroser de vinaigrette et servir immédiatement."
        ],
        "stepsDe": [
            "Kirschtomaten halbieren. Gurke in mundgerechte Stücke schneiden.",
            "Rote Zwiebel in dünne Ringe schneiden.",
            "Tomaten, Gurke, Zwiebel und Oliven in einer Schüssel vermengen.",
            "Feta darüber bröseln.",
            "Olivenöl und Zitronensaft verquirlen, abschmecken.",
            "Dressing über den Salat träufeln und sofort servieren."
        ],
        "stepsIt": [
            "Tagliare i pomodorini a metà. Tagliare il cetriolo a pezzi.",
            "Affettare finemente la cipolla rossa.",
            "Mescolare pomodori, cetriolo, cipolla e olive in una ciotola.",
            "Sbricolare la feta sopra.",
            "Mescolare olio d'oliva e succo di limone, aggiustare di sale.",
            "Condire l'insalata e servire subito."
        ],
        "dietaryTags": ["vegetarian", "glutenFree"],
        "allergenFree": ["nuts", "shellfish", "fish", "soy", "sesame", "gluten"],
        "prepTime": 15,
        "cookTime": 0,
        "imageURL": null,
        "servings": 2,
        "difficulty": "easy"
    }
    """)

    // MARK: Chicken (shown in Favourites list)
    static let screenshotMockChicken: Recipe = decodeRecipe("""
    {
        "id": null,
        "title": "Lemon Herb Chicken",
        "description": "Tender chicken breast marinated in lemon, garlic and fresh herbs, pan-seared to golden perfection.",
        "descriptionNl": "Malse kipfilet gemarineerd in citroen, knoflook en verse kruiden, goudbruin gebakken.",
        "descriptionFr": "Blanc de poulet mariné au citron, à l'ail et aux herbes fraîches, poêlé à la perfection.",
        "descriptionDe": "Zartes Hähnchenbrustfilet in Zitronen-Kräuter-Marinade, goldbraun gebraten.",
        "descriptionIt": "Petto di pollo marinato con limone, aglio ed erbe fresche, rosolato in padella.",
        "ingredients": [
            {"name": "Chicken breasts", "amount": "2",  "unit": ""},
            {"name": "Lemon",           "amount": "1",  "unit": ""},
            {"name": "Garlic",          "amount": "3",  "unit": "cloves"},
            {"name": "Rosemary",        "amount": "2",  "unit": "sprigs"},
            {"name": "Thyme",           "amount": "3",  "unit": "sprigs"},
            {"name": "Olive oil",       "amount": "2",  "unit": "tbsp"}
        ],
        "ingredientNamesNl": ["Kipfilets","Citroen","Knoflook","Rozemarijn","Tijm","Olijfolie"],
        "ingredientNamesFr": ["Filets de poulet","Citron","Ail","Romarin","Thym","Huile d'olive"],
        "ingredientNamesDe": ["Hähnchenbrustfilets","Zitrone","Knoblauch","Rosmarin","Thymian","Olivenöl"],
        "ingredientNamesIt": ["Petti di pollo","Limone","Aglio","Rosmarino","Timo","Olio d'oliva"],
        "steps": [
            "Mix lemon juice, minced garlic, olive oil and herbs to make the marinade.",
            "Score the chicken breasts and coat with marinade. Rest for 20 minutes.",
            "Heat a pan over medium-high heat with a drizzle of oil.",
            "Cook chicken 5–6 minutes per side until golden and cooked through.",
            "Rest for 5 minutes before slicing. Serve with lemon wedges."
        ],
        "stepsNl": [
            "Meng citroensap, knoflook, olijfolie en kruiden voor de marinade.",
            "Kerf de kipfilets in en bestrijk met marinade. Laat 20 minuten rusten.",
            "Verhit een pan op middelhoog vuur.",
            "Bak de kip 5–6 minuten per kant goudbruin en gaar.",
            "Laat 5 minuten rusten voor het snijden. Serveer met citroenpartjes."
        ],
        "stepsFr": [
            "Mélanger le jus de citron, l'ail, l'huile et les herbes pour la marinade.",
            "Entailler les filets et les enrober. Laisser reposer 20 minutes.",
            "Chauffer une poêle à feu moyen-vif.",
            "Cuire 5–6 minutes de chaque côté jusqu'à dorure.",
            "Laisser reposer 5 minutes. Servir avec des quartiers de citron."
        ],
        "stepsDe": [
            "Zitronensaft, Knoblauch, Öl und Kräuter zur Marinade mischen.",
            "Hähnchen einritzen und mit Marinade bestreichen. 20 Minuten ruhen lassen.",
            "Pfanne auf mittlerer bis hoher Hitze vorheizen.",
            "Hähnchen je 5–6 Minuten pro Seite goldbraun braten.",
            "5 Minuten ruhen lassen. Mit Zitronenspalten servieren."
        ],
        "stepsIt": [
            "Mescolare succo di limone, aglio, olio ed erbe per la marinata.",
            "Incidere il pollo e ricoprire con la marinata. Riposare 20 minuti.",
            "Scaldare una padella a fuoco medio-alto.",
            "Cuocere 5–6 minuti per lato fino a doratura.",
            "Riposare 5 minuti prima di tagliare. Servire con spicchi di limone."
        ],
        "dietaryTags": ["glutenFree", "dairyFree", "lowCarb"],
        "allergenFree": ["nuts", "dairy", "gluten", "shellfish", "eggs", "soy", "fish", "sesame"],
        "prepTime": 25,
        "cookTime": 15,
        "imageURL": null,
        "servings": 2,
        "difficulty": "medium"
    }
    """)

    // MARK: - Helper
    private static func decodeRecipe(_ json: String) -> Recipe {
        guard let data = json.data(using: .utf8),
              let recipe = try? JSONDecoder().decode(Recipe.self, from: data) else {
            fatalError("ScreenshotMockData: failed to decode mock recipe — check the JSON")
        }
        return recipe
    }
}
#endif
